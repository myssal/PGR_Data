local Base = require("Buff/Buff_1015226")
---@class XBuffScript1015336 : XBuffScript1015226
local XBuffScript1015336 = XDlcScriptManager.RegBuffScript(1015336, "XBuffScript1015336", Base)


--效果说明：每获得2.5%额外【回复强度】，提升1%雷伤，至多提升160%火伤

function XBuffScript1015336:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015337
    self.magicKind = 1015337
    self.attrib = ENpcAttrib.HealAmpP
    ------------执行------------
    self.magicIdFire = 1015031
    self.magicIdThunder = 1015133
    self.magicIdIce = 1015435
end

return XBuffScript1015336

    