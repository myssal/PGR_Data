local Base = require("Buff/Buff_1015500")
---@class XBuffScript1015514 : XBuffScript1015000
local XBuffScript1015514 = XDlcScriptManager.RegBuffScript(1015514, "XBuffScript1015514", Base)


--效果说明：自身血量低于x时，增加雷伤y点

function XBuffScript1015514:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015515
    self.magicKind = 1015515
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015514

    