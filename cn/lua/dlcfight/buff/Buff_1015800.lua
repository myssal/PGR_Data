local Base = require("Common/XFightBase")

---@class XBuffScript1015800 : XFightBase
local XBuffScript1015800 = XDlcScriptManager.RegBuffScript(1015800, "XBuffScript1015800", Base)


--效果说明：敌人血量低于20%时，火伤增加30%

function XBuffScript1015800:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015801
    self.magicLevel = 1
    self.hpRate = 40    --触发效果所需敌人生命百分比（斩杀线）

    --Buff强化配置，效果说明：斩杀线提升
    self.rateUpBuffId = 1015840         --标记Id
    self.hpRateUp = 80                  --提升后的斩杀线
    self.isRateUP = false

    --Buff强化配置，效果说明：敌人生命提升至斩杀线以上时，增伤Buff不会立即删除，会在指定时间后后删除
    self.durBuffId = 1015841            --标记Id
    self.durTime = 5                    --持续时间
    self.durTimer = 0                   --持续时间计时器

    --Buff强化配置，效果说明：有此Buff时，当敌人生命低于指定值时，读取2级数值
    self.enhanceBuffId = 1015842        --标记Id
    self.hpRateEnhance = 10             --读取2级数值所需的敌人生命值百分比
    self.magicLevelEnhance = 2          --强化后的Buff等级
    self.enhanceIsAdd = false
    ------------执行------------
    self.runeId = self.magicId - 1015000 + 20000 - 1
    self.runeIdRateUpBuff = self.rateUpBuffId - 1015000 + 20000
    self.runeIdDurBuff = self.durBuffId - 1015000 + 20000
    self.runeIdEnhanceBuff = self.enhanceBuffId - 1015000 + 20000

end

---@param dt number @ delta time 
function XBuffScript1015800:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --如果有斩杀线提升的标记，则提高斩杀线
    if self._proxy:CheckBuffByKind(self._uuid, self.rateUpBuffId) and not self.isRateUP then
        self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeIdRateUpBuff)
        self.hpRate = self.hpRateUp
        self.isRateUP = true
    end

    local targetId = self._proxy:GetFightTargetId(self._uuid)
    if targetId == 0 then
        return
    end

    local enemyHpRate = self._proxy:GetNpcAttribRate(targetId, ENpcAttrib.Life) * 100
    local isEnhanceBuffActive = self._proxy:CheckBuffByKind(self._uuid, self.enhanceBuffId)
    local isDurBuffActive = self._proxy:CheckBuffByKind(self._uuid, self.durBuffId)
    local isBuffActive = self._proxy:CheckBuffByKind(self._uuid, self.magicId)

    --有强化Buff，且敌人生命低于强化Buff规定的血量时
    if enemyHpRate <= self.hpRateEnhance and isEnhanceBuffActive and isBuffActive and not self.enhanceIsAdd then
        self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeIdEnhanceBuff)
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevelEnhance)
        self.enhanceIsAdd = true
        self.durTimer = 0
        return
    end
    --有强化Buff，敌人生命高于强化Buff规定的血量，但低于常规斩杀线时，将强化Buff删除
    if enemyHpRate > self.hpRateEnhance and isEnhanceBuffActive and isBuffActive and self.enhanceIsAdd then
        self._proxy:RemoveBuff(self._uuid, self.magicId)
        self.enhanceIsAdd = false
    end
    --没有强化Buff，敌人生命低于常规斩杀线时
    if enemyHpRate <= self.hpRate and (not isBuffActive) then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self.durTimer = 0
        return
    end
    --敌人生命高于斩杀线时，删除Buff
    if enemyHpRate > self.hpRate and isBuffActive then
        --如果有延迟删除的Buff，判断下是否满足计时器条件，没有就直接删除
        if isDurBuffActive then
            self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeIdDurBuff)
            if self.durTimer == 0 then
                self.durTimer = self._proxy:GetNpcTime(self._uuid) + self.durTime
            elseif self._proxy:GetNpcTime(self._uuid) >= self.durTimer then
                self._proxy:RemoveBuff(self._uuid, self.magicId)
            end
        else
            self._proxy:RemoveBuff(self._uuid, self.magicId)
        end
    end

end

--region EventCallBack
function XBuffScript1015800:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

function XBuffScript1015800:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        --战斗开始时且给runeId重新赋值
        self.runeId = self.magicId - 1015000 + 20000 - 1
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015800:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015800:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015800
