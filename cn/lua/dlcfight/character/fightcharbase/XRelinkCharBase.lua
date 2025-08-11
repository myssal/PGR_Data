local base = require("Common/XFightBase")
---Relink角色底层
---@class XRelinkCharBase : XFightBase
---@field _followController XNpcFollowController 跟随组件
local XRelinkCharBase = XClass(base, "XRelinkCharBase")

function XRelinkCharBase:Init() --初始化
    base.Init(self)
    self:RegisterKeyboard()   --注册按键映射
    self:InitHandleJumpTurnSpeedParams()  --初始化跳跃相关逻辑
    -- 这其实是每个Npc都在调用Camera的全局开关, 行为树版本也一样，待v0.3或v0.4版本优化
    self._proxy:SetCameraIgnoreHeightLerpOnAir(false)
end

---@param dt number @ delta time 
function XRelinkCharBase:Update(dt)
    if self._proxy:IsNpcBackState(self._uuid) then -- 在后台不触发逻辑
        return
    end
    
    self:ProcessChangeMoveState()
    self:ProcessResetSprintMoveTypeOnJump()
    self:ProcessHandleJumpTurnSpeed()
    self:ProcessChangeJumpState()
end

---@param eventType number
---@param eventArgs userdata
function XRelinkCharBase:HandleEvent(eventType, eventArgs) --事件中转站
    base.HandleEvent(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcCastSkillByInputActionBefore then
        -- XLog.Warning("InputNPC:" ..eventArgs.LauncherId)
        self:OnNpcCastSkillByInputActionBeforeEvent(eventArgs)
    end
end

function XRelinkCharBase:Terminate()
end

--region Keyboard 按键映射
function XRelinkCharBase:RegisterKeyboard()  --按键注册
    -- XLog.Warning("----------准备注册按键映射----------")
    self._proxy:RegisterKeyboardOperator(1000, ENpcOperationKey.Attack, EOperationType.Down, false) --鼠标左键 攻击
    -- self._proxy:RegisterKeyboardOperator(1000, ENpcOperationKey.Attack, EOperationType.Hold, false) --鼠标左键 攻击
    self._proxy:RegisterKeyboardOperator(1001, ENpcOperationKey.Dodge, EOperationType.Down, false) --鼠标右键 闪避
    self._proxy:RegisterKeyboardOperator(49, ENpcOperationKey.Ball1, EOperationType.Down, false) --键盘1 技能1
    self._proxy:RegisterKeyboardOperator(50, ENpcOperationKey.Ball2, EOperationType.Down, false) --键盘2 技能2
    self._proxy:RegisterKeyboardOperator(51, ENpcOperationKey.Ball3, EOperationType.Down, false) --键盘3 技能3
    self._proxy:RegisterKeyboardOperator(114, ENpcOperationKey.ExSkill, EOperationType.Down, false) --键盘3 技能3
    self._proxy:RegisterKeyboardOperator(119, ENpcOperationKey.MoveForward, EOperationType.Hold, false) --键盘W 向前
    self._proxy:RegisterKeyboardOperator(115, ENpcOperationKey.MoveBack, EOperationType.Hold, false) --键盘S 向后
    self._proxy:RegisterKeyboardOperator(97, ENpcOperationKey.MoveLeft, EOperationType.Hold, false) --键盘A 向左
    self._proxy:RegisterKeyboardOperator(100, ENpcOperationKey.MoveRight, EOperationType.Hold, false) --键盘D 向右
    self._proxy:RegisterKeyboardOperator(122, ENpcOperationKey.SwitchCameraControlMethod, EOperationType.Down, false) --键盘Z 鼠标转换
    self._proxy:RegisterKeyboardOperator(113, ENpcOperationKey.RelinkQte, EOperationType.Down, false) --键盘Q 破韧QTE
    self._proxy:RegisterKeyboardOperator(99, ENpcOperationKey.RelinkLimitSkill, EOperationType.Down, false) --键盘C 极限技
    -- XLog.Warning("----------注册按键映射完成----------")
end
--endregion

--region AttackTarget 索敌

--endregion


--region ChangeMoveState 空花角色移动状态逻辑
function XRelinkCharBase:ProcessChangeMoveState()
    -- Try Do = Check Can Do + Select Do What
    local isChange, nextMoveType = self:TryDoChangeMoveState()
    -- Do
    if not isChange then
        return
    end
    self._proxy:SetNpcMoveType(self._uuid, nextMoveType)
end
---决策将要切换的移动状态
---@return boolean,number isChange, ENpcMoveType
function XRelinkCharBase:TryDoChangeMoveState()

    -- Select Do What
    local curMoveType = self._proxy:GetNpcMoveType(self._uuid)      -- Npc当前移动状态
    local nextMoveType = curMoveType                                -- Npc将要切换的移动状态
    local moveNormalizedDist = self._proxy:GetMoveNormalizedDist()  -- 摇杆用力量化长度
    local normalizedWalk2Run = 0.4                                  -- 慢走阈值
    local normalizedRun2Sprint = 1                                  -- 疾跑阈值


    if curMoveType == ENpcMoveType.Walk then
        if moveNormalizedDist >= normalizedWalk2Run and moveNormalizedDist < normalizedRun2Sprint then                  -- 摇杆大于慢走阈值则切换为普通跑
            nextMoveType = ENpcMoveType.Run
        end
    elseif curMoveType == ENpcMoveType.Run then
        if moveNormalizedDist > 0 and moveNormalizedDist <= normalizedWalk2Run then                                     -- 摇杆小于慢走阈值且不为0则切换为慢走
            nextMoveType = ENpcMoveType.Walk
        end
    elseif curMoveType == ENpcMoveType.Sprint then
        if moveNormalizedDist == 0 then                                                                                 -- 停止输入切换到普通跑
            nextMoveType = ENpcMoveType.Run
        elseif moveNormalizedDist <= normalizedWalk2Run and moveNormalizedDist > normalizedWalk2Run then                -- 摇杆小于慢走阈值且不为0则切换为慢走
            nextMoveType = ENpcMoveType.Walk
        elseif self._proxy:IsKeyDown(ENpcOperationKey.SwitchWalk) then                                                  -- 点击了慢走切换按键则切换为慢走
            nextMoveType = ENpcMoveType.Walk
        elseif self._proxy:IsKeyDown(ENpcOperationKey.SwitchSprint) then                                                -- 点击了疾跑切换则切换为普通跑
            nextMoveType = ENpcMoveType.Run
        end
    end
    return curMoveType ~= nextMoveType, nextMoveType
end
--endregion

--region HandleJumpTurnSpeed 空花角色处理跳跃转向速度
function XRelinkCharBase:InitHandleJumpTurnSpeedParams()
    self._proxy:SetNpcJumpLookAtSpeed(self._uuid, 0)--初始甚至成0
    self._jumpTurnSpeed_IdleJumpUp = 700
    self._jumpTurnSpeed_IdleJumpOnAir = 700
    self._jumpTurnSpeed_IdleJumpUpToDown = 550
    self._jumpTurnSpeed_IdleJumpDown = 0
    self._jumpTurnSpeed_IdleJumpDownLoop = 0
    self._jumpTurnSpeed_MoveJumpUp = 700
    self._jumpTurnSpeed_MoveJumpOnAir = 700
    self._jumpTurnSpeed_MoveJumpUpToDown = 550
    self._jumpTurnSpeed_MoveJumpDown = 0
    self._jumpTurnSpeed_MoveJumpDownLoop = 0
end

function XRelinkCharBase:ProcessHandleJumpTurnSpeed()
    -- Check Can Do
    if not self._proxy:CheckNpcAction(self._uuid, ENpcAction.Jump) then -- 不是跳跃状态不设置速度
        return
    end
    -- Select & Do
    if self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.IdleJumpUp) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_IdleJumpUp)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.IdleJumpOnAir) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_IdleJumpOnAir)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.IdleJumpUpToDown) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_IdleJumpUpToDown)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.IdleJumpDown) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_IdleJumpDown)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.IdleJumpDownLoop) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_IdleJumpDownLoop)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.MoveJumpUp) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_MoveJumpUp)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.MoveJumpOnAir) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_MoveJumpOnAir)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.MoveJumpUpToDown) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_MoveJumpUpToDown)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.MoveJumpDown) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_MoveJumpDown)
    elseif self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.MoveJumpDownLoop) then
        self._proxy:SetNpcJumpLookAtSpeed(self._uuid, self._jumpTurnSpeed_MoveJumpDownLoop)
    end
end
--endregion

--region ChangeJumpMoveState 空花角色空中根据输入重置冲刺移动状态
function XRelinkCharBase:ProcessResetSprintMoveTypeOnJump()
    -- Check Can Do
    if not self._proxy:CheckNpcAction(self._uuid, ENpcAction.Jump) then -- 角色不在跳跃不重置
        return false
    end
    if not (self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.None) or
            self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.IdleJumpToStand) or
            self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.MoveJumpToStand)) then    -- 除跳跃落地阶段外外，其它状态无法跳跃
        return false
    end
    -- Select Do What
    local curMoveType = self._proxy:GetNpcMoveType(self._uuid)          -- Npc当前移动状态
    local moveNormalizedDist = self._proxy:GetMoveNormalizedDist()      -- 摇杆用力量化长度
    local normalizedRun2Sprint = 1                                      -- 疾跑阈值

    if curMoveType == ENpcMoveType.Sprint and moveNormalizedDist < normalizedRun2Sprint then
        self._proxy:SetNpcMoveType(self._uuid, ENpcMoveType.Run)
    end
end
--endregion

--region ChangeJumpState 空花角色跳跃状态逻辑
function XRelinkCharBase:ProcessChangeJumpState()
    -- Check Can Do
    if not self._proxy:IsKeyDown(ENpcOperationKey.Jump) then                                -- 没有按键也不跳 (低频条件可优先判断)
        return false
    end
    if self._proxy:CheckNpcOnAir(self._uuid) then                                           -- 空中没有二段跳
        return false
    end
    if not (self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.None) or
            self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.IdleJumpToStand) or
            self._proxy:CheckNpcJumpState(self._uuid, ENpcJumpState.MoveJumpToStand)) then    -- 除跳跃落地阶段外外，其它状态无法跳跃
        return false
    end
    -- Select Do What
    local isHasMoveInput = self._proxy:HasMoveInput()
    -- Do Jump
    if isHasMoveInput then
        self._proxy:Jump(self._uuid, true)
    else
        self._proxy:Jump(self._uuid, false)
    end
end
--endregion

--region EventCallBack
function XRelinkCharBase:InitEventCallBackRegister()
    --按需求解除注释进行注册
    XLog.Warning("开始注册")

    --self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcCastSkillBefore)         -- OnNpcCastSkillBeforeEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcCastSkillAfter)         -- OnNpcCastSkillAfterEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcCastSkillByInputActionBefore)         -- OnNpcCastSkillByInputActionBeforeEvent
    --self._proxy:RegisterEvent(EWorldEvent.NpcExitSkill)         -- OnNpcExitSkillEvent
    --self._proxy:RegisterEvent(EWorldEvent.NpcDie)               -- OnNpcDieEvent
    --self._proxy:RegisterEvent(EWorldEvent.NpcRevive)            -- OnNpcReviveEvent
    --self._proxy:RegisterEvent(EWorldEvent.NpcLoadComplete)      -- OnNpcLoadCompleteEvent
    --self._proxy:RegisterEvent(EWorldEvent.Behavior2ScriptMsg)   -- OnBehavior2ScriptMsgEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- OnNpcAddBuffEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)        -- OnNpcRemoveBuffEvent
    --self._proxy:RegisterEvent(EWorldEvent.MissileHit)           -- OnMissileHitEvent
    --self._proxy:RegisterEvent(EWorldEvent.MissileDead)          -- OnMissileDeadEvent
    --self._proxy:RegisterEvent(EWorldEvent.MissileCreate)        -- OnMissileCreateEvent
    XLog.Warning("Relink基类注册事件")
end

function XRelinkCharBase:OnNpcCastSkillByInputActionBeforeEvent(args)
    local skillId = args.SkillId
    local launcher = args.LauncherUUID

    if not launcher == self._uuid then
        return
    end

    local tempNpcId = self._proxy:SearchNpc(launcher,ENpcCampType.Camp2,4,15,-1)

    if (tempNpcId == 0)or (not tempNpcId) then
        return
    end

    local targetPos = self._proxy:GetNpcPosition(tempNpcId)
    
    args.TargetUUID = tempNpcId
    args.TargetPosition = targetPos --设置技能
    args.TargetType = ESkillTargetType.Npc --设置技能索敌类型
    
    self._proxy:SetNpcLookAtPosition(launcher,targetPos)  --转向
    self._proxy:SetFightTarget(launcher,tempNpcId)  --设置战斗目标
    self._proxy:SetNpcFocusTarget(launcher,tempNpcId)  --镜头锁定
    -- XLog.Warning("找到目标将其设为锁定目标"..launcher..tempNpcId)


end

--endregion

return XRelinkCharBase
