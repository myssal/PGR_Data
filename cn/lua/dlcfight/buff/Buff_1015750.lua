local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015750 : XBuffBase
local XBuffScript1015750 = XDlcScriptManager.RegBuffScript(1015750, "XBuffScript1015750", Base)
--效果说明：开局前10秒火伤提升30%
--1015790,开局效果提升+20%
--1015792,开局效果持续时间+5s
--1015794,持有开局效果时，每命中5次，开局类型的宝珠生效事件+1s

local ConfigMagicIdDict = {
    [1015750]=1015751,
    [1015752]=1015753,
    [1015754]=1015755,
    [1015756]=1015757,
    [1015758]=1015759,
    [1015760]=1015761,
    [1015762]=1015763,
    [1015764]=1015765,
    [1015766]=1015767,
    [1015768]=1015769,
    [1015770]=1015771,
    [1015772]=1015773,
    [1015774]=1015775,
    [1015776]=1015777,
    [1015778]=1015779,
    [1015780]=1015781,
    [1015782]=1015783,
    [1015784]=1015785,
    [1015786]=1015787,
    [1015788]=1015789
}
local ConfigRuneIdDict = {
    [1015750]=20750,
    [1015752]=20752,
    [1015754]=20754,
    [1015756]=20756,
    [1015758]=20758,
    [1015760]=20760,
    [1015762]=20762,
    [1015764]=20764,
    [1015766]=20766,
    [1015768]=20768,
    [1015770]=20770,
    [1015772]=20772,
    [1015774]=20774,
    [1015776]=20776,
    [1015778]=20778,
    [1015780]=20780,
    [1015782]=20782,
    [1015784]=20784,
    [1015786]=20786,
    [1015788]=20788
}



function XBuffScript1015750:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = ConfigMagicIdDict[self._buffId]   --火伤+30%的buff id
    self.magicLevel = 1 --初始buff等级1级
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.spMagicLevel = 2   --有开局效果提升buff时候的buff等级
    self.baseDuration = 12  --基础持续时间间隔
    self.hitCount = 0 --命中计数器
    self.targetHitCount = 5 --目标命中次数
    self.StrengthenBuffId = 1015790 --开局效果提升的buff id
    self.OverTimeBuffId = 1015792 --开局效果持续时间+5s的buff
    self.HitBuffId = 1015794  --持有开局效果时，每命中5次，开局类型的宝珠生效事件+1s
    self.skillType = 2    --跟战斗约定的起手技能类型，待定
    self.isActive = false  --buff激活状态
    self.isBuffRemoved = false
    ------------执行------------
    self.runeId = ConfigRuneIdDict[self._buffId]
    self.runeStrengthenId = 20790               --开局效果提升的buff id
    self.runeOverTimeId = 20792                 --开局效果持续时间+5s的buff
    self.runeHitId = 20794                      --持有开局效果时，每命中5次，开局类型的宝珠生效事件+1s

end

---@param dt number @ delta time
function XBuffScript1015750:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    if not self._proxy:CheckBuffByKind(self._uuid,self.battleStartBuffId) then
        return
    end

    if (not self.isActive) and (not self.isBuffRemoved) then
        --初始化阶段加上buff，初始化持续时间（包含OverTimeBuffId的加成）
        if self._proxy:CheckBuffByKind(self._uuid, self.OverTimeBuffId) then
            self.baseDuration = self.baseDuration + 5
            self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeOverTimeId)
            self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeOverTimeId, 1)
        end
        if self._proxy:CheckBuffByKind(self._uuid, self.StrengthenBuffId) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.spMagicLevel)
            self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)
            self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)
            self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeStrengthenId)
            self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeStrengthenId, 1)
        else
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
            self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)
            self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)
        end
        self.isActive = true
        self.buffTimer = self._proxy:GetNpcTime(self._uuid) + self.baseDuration
    end

    -- BUFF激活期间处理
    if self.isActive then
        -- 超时移除
        if self._proxy:GetNpcTime(self._uuid) > self.buffTimer then
            self._proxy:RemoveBuff(self._uuid, self.magicId)
            self._proxy:SetAutoChessGemData(self._uuid, self.runeStrengthenId, 0, 0)   --移除开局强化宝珠的激活状态
            if self._proxy:CheckBuffByKind(self._uuid, self.OverTimeBuffId) then
                self._proxy:SetAutoChessGemData(self._uuid, self.runeOverTimeId, 0, 0)   --移除开局时间增长宝珠的激活状态
            end
        end
    end
end


--region EventCallBack
function XBuffScript1015750:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)        -- OnNpcRemoveBuffEvent
end

function XBuffScript1015750:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    if self.isActive and launcherId == self._uuid then
        -- 只有持有1015794时才计数
        if self._proxy:CheckBuffByKind(self._uuid, self.HitBuffId) then
            self.hitCount = self.hitCount + 1
            if self.hitCount >= self.targetHitCount then
                self.buffTimer = self.buffTimer + 1
                self.hitCount = 0
                self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeHitId)
                self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeHitId, 1)
            end
        end
    end
end
function XBuffScript1015750:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._uuid then
        return
    end
    if buffId ~= self._buffId then
        return
    end
    if self._proxy:CheckBuffByKind(self._uuid, self.magicId) then
        return
    else
        self.isActive = false
        self.isBuffRemoved = true
        self.hitCount = 0
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015750:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015750:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015750
