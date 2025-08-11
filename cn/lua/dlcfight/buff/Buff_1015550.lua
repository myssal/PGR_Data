local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015550 : XBuffBase
local XBuffScript1015550 = XDlcScriptManager.RegBuffScript(1015550, "XBuffScript1015550", Base)
--效果说明：每间隔10秒，触发一次火伤+30%的效果，持续5秒;
--1015592,释放技能后，1015550的触发时间提前1秒
--1015590，触发两次1015550后，基础触发时间缩短至5秒

local ConfigMagicIdDict = {
    [1015550] = 1015551,
    [1015552] = 1015553,
    [1015554] = 1015555,
    [1015556] = 1015557,
    [1015558] = 1015559,
    [1015560] = 1015561,
    [1015562] = 1015563,
    [1015564] = 1015565,
    [1015566] = 1015567,
    [1015568] = 1015569,
    [1015570] = 1015571,
    [1015572] = 1015573,
    [1015574] = 1015575,
    [1015576] = 1015577,
    [1015578] = 1015579,
    [1015580] = 1015581,
    [1015582] = 1015583,
    [1015584] = 1015585,
    [1015586] = 1015587,
    [1015588] = 1015589
}
local ConfigRuneIdDict = {
    [1015550] = 20550,
    [1015552] = 20552,
    [1015554] = 20554,
    [1015556] = 20556,
    [1015558] = 20558,
    [1015560] = 20560,
    [1015562] = 20562,
    [1015564] = 20564,
    [1015566] = 20566,
    [1015568] = 20568,
    [1015570] = 20570,
    [1015572] = 20572,
    [1015574] = 20574,
    [1015576] = 20576,
    [1015578] = 20578,
    [1015580] = 20580,
    [1015582] = 20582,
    [1015584] = 20584,
    [1015586] = 20586,
    [1015588] = 20588
}

function XBuffScript1015550:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.BuffTimer = 0 --初始计时器
    self.BuffId = ConfigMagicIdDict[self._buffId]   --持续5秒的火伤+30%的buffid
    self.magicLevel = 1 --buff等级1级
    self.phase = 1  --阶段标记，1为初始，2为触发了两次定时效果
    self.baseInterval = 5  --基础触发间隔
    self.skillBoost = 0 --技能触发次数
    self.ItemRune = 1015590 --基础触发时间减少的宝珠
    self.SkillReduceTimeBuffId = 1015592 --释放技能触发时间提前1s的buff
    self.ReduceTimeBuffid = 1015591 --基础触发时间减少
    self.ReduceInjuries = 1015594   --受伤-20%的宝珠id
    self.ReduceInjuriesId = 1015595   --受伤-20%的buffid
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.skillType = 2    --跟战斗约定的起手技能类型，待定
    self.skillcost = 0  --技能释放次数
    self.FireTime = 0   --动态触发时间
    ------------执行------------
    self.runeId = ConfigRuneIdDict[self._buffId]     --增伤宝珠Id
    self.runeReduceInjuriesId = 20590                   --减伤宝珠Id
    self.runeSkillReduceTimeId = 20592                  --释放技能加速触发宝珠Id
    self.runeReduceTimeId = 20594                       --释放两次后加速触发宝珠Id
end

---@param dt number @ delta time
function XBuffScript1015550:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    if not self._proxy:CheckBuffByKind(self._uuid, self.battleStartBuffId) then
        return
    end

    self.BuffTimer = self.BuffTimer + dt    --更新计时器
    self.FireTime = self.baseInterval
    if self.phase == 1 and self._proxy:CheckBuffByKind(self._uuid, self.ItemRune) and self._proxy:GetBuffStacks(self._uuid, self.ReduceTimeBuffid) >= 2 then
        self.baseInterval = 2
        self.phase = 2
        self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeReduceTimeId)
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeReduceTimeId, 1)
    end

    if self._proxy:CheckBuffByKind(self._uuid, self.ItemRune) then
        self.FireTime = math.max(1, self.baseInterval - self.skillBoost)
        self.skillBoost = 0
    end
    if self.BuffTimer >= self.FireTime then
        --达到触发时间触发
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.BuffId, self.magicLevel)    --加火伤buff
        self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.ReduceTimeBuffid, self.magicLevel)  --叠层buff计数+1
        self.BuffTimer = self.BuffTimer - self.FireTime  --重置计时器
        self.skillBoost = 0 --重置技能计数器
        if self._proxy:CheckBuffByKind(self._uuid, self.ReduceInjuries) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.ReduceInjuriesId, self.magicLevel)
            self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeReduceInjuriesId)
            self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeReduceInjuriesId, 1)
        end
    end
end


--region EventCallBack
function XBuffScript1015550:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcCastSkillAfter)         -- OnNpcCastSkillEvent
end

function XBuffScript1015550:OnNpcCastSkillAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    --未持有技能减cd的buff直接返回
    if not self._proxy:CheckBuffByKind(self._uuid, self.SkillReduceTimeBuffId) then
        return
    end

    --不是自己释放的就返回
    if launcherId ~= self._uuid then
        return
    end

    --如果不是技能起手就返回
    local skillTypeTemp = self._proxy:GetSkillType(skillId)
    if skillTypeTemp ~= self.skillType then
        return
    end

    --管理Buff释放&计数器，如果已经大于目标次数了，直接返回
    if self.skillBoost >= 4 then
        return
    end

    self.skillBoost = self.skillBoost + 1       --释放次数+1
    self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeSkillReduceTimeId)
    self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeSkillReduceTimeId, 1)

end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015550:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015550:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015550
