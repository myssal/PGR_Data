local Base = require("Buff/Buff_1015500")
---@class XBuffScript1015534 : XBuffScript1015000
local XBuffScript1015534 = XDlcScriptManager.RegBuffScript(1015534, "XBuffScript1015534", Base)


--效果说明：自身血量低于x时，增加回复y点

function XBuffScript1015534:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015535
    self.magicKind = 1015535
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015534

    