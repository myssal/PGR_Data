local XBigWorldModel = require("XModule/XBigWorld/XBigWorldModel")

---@class XSkyGardenModel : XBigWorldModel
local XSkyGardenModel = XClass(XBigWorldModel, "XSkyGardenModel")
function XSkyGardenModel:OnInit()
    XBigWorldModel.OnInit(self)
end

function XSkyGardenModel:ClearPrivate()
    XBigWorldModel.ClearPrivate(self)
end

function XSkyGardenModel:ResetAll()
    XBigWorldModel.ResetAll(self)
end

return XSkyGardenModel