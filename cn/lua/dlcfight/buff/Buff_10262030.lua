local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10262030 : XTheatre6SkillBase
local XBuffScript10262030 = XDlcScriptManager.RegBuffScript(10262030, "XBuffScript10262030", XTheatre6SkillBase)

--效果说明：【狂暴】期间，每次怒火<=50时触发：
-- · 造成50%攻击伤害；
-- · 恢复50点【怒火】。每次使用此技能，本场战斗中此技能的怒火恢复-30/20/15点。

function XBuffScript10262030:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self._Count = 0
    self.AngerCheck = 50
    self._stackCountHitDown = 0
    self._angerCost = 50
    self._angerRecover = 50
    self._damageMagicId = 1026203 --注册超算成功技1伤害id，5.10已换
    if self._skillId == 10262031 then self._angerCostPerHappened = 30
    else if self._skillId == 10262032 then self._angerCostPerHappened = 20
    else self._angerCostPerHappened = 15
    end
    end
end

function XBuffScript10262030:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._HitDownController = self:GetNpc():GetHitDownController()
end

function XBuffScript10262030:OnLuaAttackerChange(eventArgs)
    ---出手权交换时重置计数
    if eventArgs._newAttackerUUID == self._npcUUID then
    self.ChanceCheck = 1
    end
end

function XBuffScript10262030:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.originAttrib1 = self._proxy:GetBuffStacks( self._npcUUID,XTheatre6AngerController.StackBuffAnger)
    if self.originAttrib1 <= self.AngerCheck then
        self._level:RequestInsertSkill(self._npcUUID,self.TargetSkill)
    end
    if eventArgs._skillId ~= self._skillId then return end
    self._AngerController:CastStackBuff(self._angerRecover, self._npcUUID)
    self._angerRecover = self._angerRecover - self._angerCostPerHappened
    if self._angerRecover <= 0 then self._angerRecover = 0
    end
end

function XBuffScript10262030:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

function XBuffScript10262030:ChangeDamageBeforeCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self._damageMagicId then return end
    if self._hasChangedDamage then return end
    self._exDamageRate = self._Count * self._exDamageRateBase
    local FinalDMGRate = eventArgs.PhysicalPermyriad + self._exDamageRate
    self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, FinalDMGRate, eventArgs.ElementPermyriad, eventArgs.HackDamage, eventArgs.HackPermyriad, eventArgs.isCrity)
    self._hasChangedDamage = true
end

return XBuffScript10262030

--无法获取到击飞事件