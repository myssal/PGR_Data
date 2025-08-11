local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010429 : XAfkItemSkillMagicBase
local XBuffScript1010429 = XDlcScriptManager.RegBuffScript(1010429, "XBuffScript1010429", Base)

function XBuffScript1010429:Init() --初始化
    ---------配置------------
    self.magicId = 1010429
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010429
