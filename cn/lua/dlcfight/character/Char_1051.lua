---@type XRelinkCharBase
local Base = require("Character/FightCharBase/XRelinkCharBase")

---Relink-R5露西亚脚本
---@class XChar1051 : XRelinkCharBase
local XChar1051 = XDlcScriptManager.RegCharScript(1051, "XChar1051", Base)
function XChar1051:Ctor(proxy)
    self._proxy = proxy

    -- AI总控
    self._canCastSkill = false
    self._useShenglong = false
    self._addDenglongBuff = true
end


function XChar1051:Init()
    Base.Init(self)
    
    --设置剑气技能组
    self._skillGroup = {}

    self._skillGroup[1] = 105141 
    self._skillGroup[2] = 105142
    self._skillGroup[3] = 105143

    --设置剑气技能计数器
    self._jianqiCounter = 0

    self._proxy:AddBuff(self._uuid, 1051001)
end

---@param dt number @ delta time
function XChar1051:Update(dt)
    Base.Update(self, dt)
    if(self._addDenglongBuff == true) then
        if(self._proxy:GetNpcAttribValue(self._uuid, 48) == 200) then
            self._proxy:AddBuff(self._uuid, 1051006)
            self._addDenglongBuff = false
        end
    end

    if(self._canCastSkill == true) then
        if(self._proxy:CheckSkillTiming(self._uuid,18)) then
            XLog.Warning("登龙时间到")
            self._proxy:AbortSkill(self._uuid,true)
            XLog.Warning("打断了当前技能")
            self._proxy:CastSkill(self._uuid,105162)
            XLog.Warning("释放登龙斩")

            self._proxy:RemoveBuff(self._uuid, 1051006)
            self._canCastSkill = false
            self._addDenglongBuff = true
        end
    end

    self:ProcessFirstJianqi()

    --按键检测
    self:JianqiKeyDown()
    --剑气连击情况判断
    self:JianqiCombo()
end

---@param eventType number
---@param eventArgs userdata
function XChar1051:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar1051:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    XLog.Warning("添加了buff："..buffId)

    if (buffId == 10513101) then
        XLog.Warning("添加了buff："..10513101)
        self._proxy:SetNpcAnimationLayer(self._uuid, 1)
        self._proxy:SetNpcInputActionGroup(self._uuid, 105151)
    end

    if (buffId == 10514001) then
        XLog.Warning("添加剑气状态buff")
        self._canUseJianqi = true
    end
end

function XChar1051:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)--寻找一个攻击目标
    XLog.Warning("移除了buff："..buffId)

    if (buffId == 10513101) then
         if (self._useShenglong == false) then
            self._proxy:AbortSkill(self._uuid,true)
            XLog.Warning("打断了当前技能")
            self._proxy:CastSkill(self._uuid,105161)
            XLog.Warning("释放登龙斩")
         end
    end
end

--技能释放前事件
function XChar1051:OnNpcCastSkillBeforeEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)
    if (SkillId == 105161) then
        XLog.Warning("升龙成功")
        self._useShenglong = true
        self._canCastSkill = true      
        self._proxy:SetNpcAnimationLayer(self._uuid, 0)
        self._proxy:SetNpcInputActionGroup(self._uuid, 105101)
        self._proxy:RemoveBuff(self._uuid, 10513101)
    end
   
    if (SkillId == 105162) then
        XLog.Warning("登龙斩成功")
        self._useShenglong = false
    end

    -- 剑气状态使用其他技能直接结束
    if(self._proxy:CheckBuffByKind(self._uuid,10514001)) then
        if(SkillId ~= 105141 and SkillId ~= 105142 and SkillId ~= 105143 and SkillId ~= 105144 and SkillId ~= 105140) then
            self._jianqiCounter = 0
            self._proxy:RemoveBuff(self._uuid, 10514001)
        end
    end
end

--技能释放后事件
function XChar1051:OnNpcCastSkillAfterEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbandt)
    --剑气第一剑自动连击
    XLog.Warning("释放了技能"..SkillId)
    if (SkillId == 105140) then
        self._firstJianqi = true
        XLog.Warning("释放了技能剑气闪避")
    end
end

function XChar1051:ProcessFirstJianqi()
    if(self._firstJianqi == true) then
        if(self._proxy:CheckSkillTiming(self._uuid,16)) then
            XLog.Warning("剑气时间到")
            local targetNpc = self._proxy:SearchNpc(self._uuid,ENpcCampType.Camp2,4,15,-1)
            -- --无战斗目标释放技能
            if (targetNpc == 0)or (not targetNpc) then

                self._proxy:AbortSkill(self._uuid,true)
                XLog.Warning("打断了当前技能")
                self._proxy:CastSkill(self._uuid, 105141)
                XLog.Warning("无目标释放剑气")

                self._proxy:AddBuff(self._uuid, 10514001)               
                self._firstJianqi = false
                return
            end

            --有战斗目标释放技能
            local targetPos = self._proxy:GetNpcPosition(targetNpc)
        
            self._proxy:SetNpcLookAtPosition(self._uuid,targetPos)  --转向
            self._proxy:SetFightTarget(self._uuid,targetNpc)  --设置战斗目标
            self._proxy:SetNpcFocusTarget(self._uuid,targetNpc)  --镜头锁定

            self._proxy:AbortSkill(self._uuid,true)
            XLog.Warning("打断了当前技能")

            self._proxy:CastSkillToTarget(self._uuid, 105141, targetNpc)
            XLog.Warning("释放剑气第一段:") 

            self._proxy:AddBuff(self._uuid, 10514001)  

            self._firstJianqi = false
        end
    end
end

function XChar1051:JianqiKeyDown()
    if(self._proxy:CheckBuffByKind(self._uuid,10514001)) then
        --监听按下攻击键
        if (self._proxy:IsKeyDown(ENpcOperationKey.Attack)) then
            if(self._canUseJianqi == true) then
                self._jianqiCounter = self._jianqiCounter + 1 --剑气计数器+1
                if(self._jianqiCounter <= 3) then 
                    self._useJianqi = true  --剑气连击
                    self._canUseJianqi = false
                    XLog.Warning("剑气连击+1" ..self._jianqiCounter)
                else
                    self._useJianqi = false
                end
            end
        end
    end
end


function XChar1051:JianqiCombo()
    if(self._proxy:CheckBuffByKind(self._uuid,10514001)) then
        if(self._proxy:CheckSkillTiming(self._uuid,17)) then
            XLog.Warning("剑气衔接点" ..tostring(self._useJianqi))
            
            --进行剑气连击
            if self._useJianqi then
                XLog.Warning("剑气时间到")
                self._proxy:AbortSkill(self._uuid,true)
                XLog.Warning("打断了当前技能")

                local targetNpc = self._proxy:SearchNpc(self._uuid,ENpcCampType.Camp2,4,15,-1)
                
                --无目标释放技能
                if (targetNpc == 0)or (not targetNpc) then
                    self._proxy:CastSkill(self._uuid,self._skillGroup[self._proxy:Random(1,3)])
                    self._useJianqi = false
                    self._canUseJianqi = true

                    XLog.Warning("释放剑气攻击" ..self._jianqiCounter)
                    return
                end

                --有目标释放技能
                local targetPos = self._proxy:GetNpcPosition(targetNpc)
        
                self._proxy:SetNpcLookAtPosition(self._uuid,targetPos)  --转向
                self._proxy:SetFightTarget(self._uuid,targetNpc)  --设置战斗目标
                self._proxy:SetNpcFocusTarget(self._uuid,targetNpc)  --镜头锁定

                self._proxy:CastSkillToTarget(self._uuid,self._skillGroup[self._proxy:Random(1,3)],targetNpc)

                XLog.Warning("释放剑气攻击" ..self._jianqiCounter)

                self._useJianqi = false
                XLog.Warning("消耗剑气缓存" ..self._jianqiCounter)
                self._canUseJianqi = true
                XLog.Warning("重置输入" ..self._jianqiCounter)
                return

            --不进行剑气连击
            else
                XLog.Warning("剑气结束")
                self._proxy:AbortSkill(self._uuid,true)
                XLog.Warning("打断了当前技能")

                local targetNpc = self._proxy:SearchNpc(self._uuid,ENpcCampType.Camp2,4,15,-1)
                
                --无目标释放技能
                if (targetNpc == 0)or (not targetNpc) then
                    self._proxy:CastSkill(self._uuid, 105145)
                    self._useJianqi = false
                    self._jianqiCounter = 0 
                    self._proxy:RemoveBuff(self._uuid, 10514001)
                    return
                end

                --有目标释放技能
                local targetPos = self._proxy:GetNpcPosition(targetNpc)
        
                self._proxy:SetNpcLookAtPosition(self._uuid,targetPos)  --转向
                self._proxy:SetFightTarget(self._uuid,targetNpc)  --设置战斗目标
                self._proxy:SetNpcFocusTarget(self._uuid,targetNpc)  --镜头锁定

                self._proxy:CastSkillToTarget(self._uuid, 105145,targetNpc)

                self._useJianqi = false
                self._jianqiCounter = 0 
                self._proxy:RemoveBuff(self._uuid, 10514001)
            end
        end
    end
end

return XChar1051