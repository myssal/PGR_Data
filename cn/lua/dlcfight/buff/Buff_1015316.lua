local Base = require("Common/XFightBase")

---@class XBuffScript1015316 : XFightBase
local XBuffScript1015316 = XDlcScriptManager.RegBuffScript(1015316, "XBuffScript1015316", Base)

--效果说明：生命值首次低于20%时，接下来的5s内，免疫所有伤害，每局1次
function XBuffScript1015316:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015317
    self.magicLevel = 1
    self.isAdd = false
    ------------执行------------
    self.runeId = self.magicId - 1015000 + 20000 - 1
end

---@param dt number @ delta time 
function XBuffScript1015316:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015316:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
end

function XBuffScript1015316:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    if self._proxy:GetNpcAttribRate(self._uuid, ENpcAttrib.Life) < 0.2 and not self.isAdd then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self.isAdd = true
        self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)       --触发一次宝珠ui
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015316:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015316:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015316

    