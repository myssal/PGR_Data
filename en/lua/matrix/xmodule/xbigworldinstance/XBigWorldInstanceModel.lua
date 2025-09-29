---@class XBigWorldInstanceModel : XModel
local XBigWorldInstanceModel = XClass(XModel, "XBigWorldInstanceModel")

local TableKey = {
    BigWorldSettle = {
        CacheType = XConfigUtil.CacheType.Normal,
        DirPath = XConfigUtil.DirectoryType.Client,
    }
}
function XBigWorldInstanceModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/Instance", TableKey)
end

function XBigWorldInstanceModel:ClearPrivate()
end

function XBigWorldInstanceModel:ResetAll()
end

---@return XTableBigWorldSettle
function XBigWorldInstanceModel:GetSettleTemplate(settleId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BigWorldSettle, settleId)
end

function XBigWorldInstanceModel:GetSettleUiName(settleId)
    local t = self:GetSettleTemplate(settleId)
    return t and t.UiName or nil
end


return XBigWorldInstanceModel