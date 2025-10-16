local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1016027 : XBuffBase
local XBuffScript1016027 = XDlcScriptManager.RegBuffScript(1016027, "XBuffScript1016027", Base)
--效果说明：【定时】类符纹触发x次后，会召唤1个火球攻击敌人，每次召唤后，火球的伤害和尺寸都会增加

function XBuffScript1016027:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.missileIds = { 10210118, 10210120, 10210122, 10210124 }
    self.dmgMissileIds = { 10210119, 10210121, 10210123, 10210125 }
    self.magicLevel = 1
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.signalId = 1015911 --【定时】标记
    self.cnt = 0
    self.cntTarget = 3
    self.level = 0
    self.maxLevel =4
    self.enhBuffId = 1016244    --【定时】通用强化buff标记
    ------------执行------------
end
---@param dt number @ delta time
function XBuffScript1016027:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --Buff不存在时，不运行后续逻辑
end

--region EventCallBack
function XBuffScript1016027:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

function XBuffScript1016027:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --开局时，获得目标
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        self.targetId = self._proxy:GetFightTargetId(self._uuid)
        --更新magic等级
        self.magicLevel = self._proxy:GetBuffStacks(self._uuid,self.enhBuffId)
    end
    if npcUUID == self._uuid and buffId == self.signalId then
        self.cnt = self.cnt + 1
        if self.cnt >= self.cntTarget then
            self._proxy:LaunchMissile(self._uuid,self.targetId,self.missileIds[self.level],self.missileIds[self.level],self.magicLevel)
            self._proxy:LaunchMissile(self._uuid,self.targetId,self.dmgMissileIds[self.level],self.dmgMissileIds[self.level],self.magicLevel)
            self.level = math.min(self.level +1 ,self.maxLevel)
        end

    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1016027:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1016027:Terminate()
    Base.Terminate(self)
end

return XBuffScript1016027
