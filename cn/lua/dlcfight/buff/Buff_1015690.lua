local Base = require("Common/XFightBase")

---@class XBuffScript1015690 : XFightBase
local XBuffScript1015690 = XDlcScriptManager.RegBuffScript(1015690, "XBuffScript1015690", Base)

--效果说明：最大生命值提升50%，未进入疲劳阶段时，攻击力降低50%
function XBuffScript1015690:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId1 = 1015691
    self.magicId2 = 1015692
    self.magicHeal = 1015697
    self.magicKind1 = 1015691
    self.magicKind2 = 1015692
    self.magicLevel = 1
    self.tiredBuff = 1010029
    self.isAdd = false
    ------------执行------------
    self.runeId = self.magicId1 - 1015000 + 20000 - 1
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId1, self.magicLevel)
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicHeal, self.magicLevel)
    self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
end

---@param dt number @ delta time 
function XBuffScript1015690:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    -- 没进疲劳加buff
    if not self._proxy:CheckBuffByKind(self._uuid, self.tiredBuff) and not self.isAdd then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId2, self.magicLevel)
        self.isAdd = true
    end
    -- 进疲劳删buff
    if self._proxy:CheckBuffByKind(self._uuid, self.tiredBuff) and self.isAdd then
        self._proxy:RemoveBuff(self._uuid, self.magicKind2)
        self.isAdd = false
    end
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015690:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015690:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015690

    