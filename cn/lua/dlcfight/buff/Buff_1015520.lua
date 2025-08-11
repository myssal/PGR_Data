local Base = require("Buff/Buff_1015500")
---@class XBuffScript1015520 : XBuffScript1015000
local XBuffScript1015520 = XDlcScriptManager.RegBuffScript(1015520, "XBuffScript1015520", Base)


--效果说明：自身血量低于x时，增加冰伤y点

function XBuffScript1015520:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015521
    self.magicKind = 1015521
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015520

    