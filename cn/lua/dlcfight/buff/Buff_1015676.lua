local Base = require("Buff/Buff_1015650")
---@class XBuffScript1015676 : XBuffScript1015650
local XBuffScript1015676 = XDlcScriptManager.RegBuffScript(1015676, "XBuffScript1015676", Base)


--效果说明：疲劳阶段，护盾增加10%

function XBuffScript1015676:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015677
    self.magicKind = 1015677
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015676

    