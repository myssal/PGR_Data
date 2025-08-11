local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010408 : XAfkItemSkillMagicBase
local XBuffScript1010408 = XDlcScriptManager.RegBuffScript(1010408, "XBuffScript1010408", Base)

function XBuffScript1010408:Init() --初始化
    ---------配置------------
    self.magicId = 1010408
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010408
