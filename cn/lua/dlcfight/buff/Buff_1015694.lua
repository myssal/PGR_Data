local Base = require("Common/XFightBase")

---@class XBuffScript1015694 : XFightBase
local XBuffScript1015694 = XDlcScriptManager.RegBuffScript(1015694, "XBuffScript1015694", Base)

--效果说明：未进入疲劳阶段时，受到伤害降低20%
function XBuffScript1015694:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015695
    self.magicKind = 1015695
    self.magicLevel = 1
    self.tiredBuff = 1010029
    ------------执行------------
    self.runeId = self.magicId - 1015000 + 20000 - 1
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
    self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
end

---@param dt number @ delta time 
function XBuffScript1015694:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    -- 进疲劳删buff
    if self._proxy:CheckBuffByKind(self._uuid, self.tiredBuff) then
        self._proxy:RemoveBuff(self._uuid, self.magicKind)
        self._proxy:SetAutoChessGemData(self._uuid, self.runeId, 0, 0)
    end
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015694:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015694:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015694

    