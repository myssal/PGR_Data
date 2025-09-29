---@class XBigWorldInstanceAgency : XAgency
---@field private _Model XBigWorldInstanceModel
---@field private _Settle XBigWorldSettle
local XBigWorldInstanceAgency = XClass(XAgency, "XBigWorldInstanceAgency")

function XBigWorldInstanceAgency:OnInit()
end

function XBigWorldInstanceAgency:InitRpc()
end

function XBigWorldInstanceAgency:InitEvent()
end

function XBigWorldInstanceAgency:GetSettleUiName(settleId)
    return self._Model:GetSettleUiName(settleId)
end

function XBigWorldInstanceAgency:OpenSettle(data)
    if not data then
        return
    end
    self:GetSettle():DoSettle(data.SettleData)
end

function XBigWorldInstanceAgency:OnSettleClosed()
    self:GetSettle():DoSettleClosed()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_SETTLEMENT)
end

---@return XBigWorldSettle
function XBigWorldInstanceAgency:GetSettle()
    if not self._Settle then
        self._Settle = require("XModule/XBigWorldInstance/Settle/XBigWorldSettle").New()
    end
    return self._Settle
end

return XBigWorldInstanceAgency