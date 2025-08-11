local Base = require("Common/XFightBase")

---@class XBuffScript1015700 : XFightBase
local XBuffScript1015700 = XDlcScriptManager.RegBuffScript(1015700, "XBuffScript1015700", Base)

--效果说明：每隔5秒，有40%的概率获得火伤5%，持续5秒。
function XBuffScript1015700:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015701
    self.magicKind1 = 1015741   -- roll两次的宝珠
    self.magicKind2 = 1015742   -- 增加10%概率的宝珠
    self.magicKind3 = 1015740   -- 触发1.5倍效果的宝珠
    self.magicDef = 1015594    -- 减伤宝珠
    self.magicDefBuff = 1015595    -- 减伤buff
    self.skillCdBuff = 1015592   -- 放技能减cdbuff
    self.magicCount = 1015590  -- 检测次数的宝珠
    self.countBuff = 1015591   -- 检测次数buff
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.magicLevel = 1
    self.rollCd = 5          -- 初始时间间隔
    self.rollCd1 = 5
    self.rollCd2 = 2          -- 触发2次后缩短时间间隔
    self.timer = 0            -- 计时器
    self.rollTimeAdd = 1        -- 释放技能后提前的时间
    self.count = 0
    self.rollCount = 2          -- 定时触发次数上限
    self.twiceRoll = false
    self.exRoll = false
    self.seed1 = 100
    self.seed2 = 100            -- roll两次的种子
    self.judgeNumber = 40
    self.judgeNumberPlus = 80
    self.rollTable = { false, false }
    self.isAdd = false
    self.isFirstRoll = true
    ------------执行------------
    self.runeId = self.magicId - 1015000 + 20000 - 1
    self.runeIdKind1 = self.magicKind1 - 1015000 + 20000
    self.runeIdKind2 = self.magicKind2 - 1015000 + 20000
    self.runeIdKind3 = self.magicKind3 - 1015000 + 20000
    self.runeIdDef = self.magicDef - 1015000 + 20000
    self.runeIdCd = self.skillCdBuff - 1015000 + 20000
    self.runeIdCount = self.magicCount - 1015000 + 20000
    self:RegisterLuaEvent(EFightLuaEvent.AutoChessItemSkillComboStart)
end

---@param dt number @ delta time
function XBuffScript1015700:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    if not self._proxy:CheckBuffByKind(self._uuid,self.battleStartBuffId) then
        return
    end

    self.realTime = self._proxy:GetNpcTime(self._uuid) - self.timer - self.rollCd

    -- 到了时间间隔开始Roll
    if self.realTime >= 0 then
        -- 判断是否有roll两次的宝珠
        if self._proxy:CheckBuffByKind(self._uuid, self.magicKind1) then
            self.twiceRoll = true
            self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeIdKind1)
        end

        -- 判断是否有触发概率增加的宝珠
        if self._proxy:CheckBuffByKind(self._uuid, self.magicKind2) then
            self.judgeNumber = self.judgeNumberPlus
            self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeIdKind2)
        end

        -- 判断是否有1.5倍的宝珠
        if self._proxy:CheckBuffByKind(self._uuid, self.magicKind3) then
            self.exRoll = true
            self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeIdKind3)
        end

        -- roll第一次
        self.seed1 = self._proxy:Random(1, 100)
        self.seed2 = 100
        self.isFirstRoll = false

        -- roll第二次
        if self.twiceRoll then
            self.seed2 = self._proxy:Random(1, 100)
            while self.seed1 == self.seed2 do
                self.seed2 = self._proxy:Random(1, 100)
            end
        end
        self.timer = self._proxy:GetNpcTime(self._uuid)

        self.seedTable = { self.seed1, self.seed2 }

        -- 判断是否达成需求
        for i in ipairs(self.seedTable) do
            if self.seedTable[i] <= self.judgeNumber then
                self.rollTable[i] = true
            end
            -- 加buff
            if self.rollTable[i] and not self.isAdd then
                self.magicLevel = 1
                if self.exRoll then
                    self.magicLevel = 2
                end
                -- 本体buff
                self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
                self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)       --触发一次宝珠ui
                self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
                -- 如果有减cd宝珠
                if self._proxy:CheckBuffByKind(self._uuid, self.magicCount) then
                    self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeIdCd)
                    if self._proxy:GetBuffStacks(self._uuid, self.countBuff) < 2 then
                        -- 计数buff
                        self._proxy:ApplyMagic(self._uuid, self._uuid, self.countBuff, self.magicLevel)
                    end
                end
                -- 减伤buff
                if self._proxy:CheckBuffByKind(self._uuid, self.magicDef) then
                    self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeIdDef)
                    self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicDefBuff, self.magicLevel)
                end

                self.isAdd = true
                -- 触发2次后缩短时间间隔
                if self._proxy:GetBuffStacks(self._uuid, self.countBuff) == 2 then
                    self.rollCd = self.rollCd2
                else
                    self.rollCd = self.rollCd1
                end

            end
        end
        -- 重置变量
        self.rollTable = { false, false }
        self.isAdd = false
        self.seed2 = 100
    end
end

--region EventCallBack
function XBuffScript1015700:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)         -- OnNpcCastSkillEvent
end

function XBuffScript1015700:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        --战斗开始时记录时间，并且给runeId重新赋值
        self.timer = self._proxy:GetNpcTime(self._uuid)
        self.runeId = self.magicId - 1015000 + 20000 - 1
    end
end

---endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015700:HandleLuaEvent(eventType, eventArgs)
    --自定义事件
    Base.HandleLuaEvent(self, eventType, eventArgs)
    if eventType == EFightLuaEvent.AutoChessItemSkillComboStart then
        -- 判断是否有技能减cd的宝珠
        if not self._proxy:CheckBuffByKind(self._uuid, self.skillCdBuff) then
            return
        end

        if self.rollCd > 1 and eventArgs.NpcUUid == self._uuid then
            self.rollCd = self.rollCd - self.rollTimeAdd
            self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeIdCount)       --触发一次宝珠ui
            self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeIdCount, 1)  --记录一次触发
        end
    end
end

function XBuffScript1015700:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015700

    