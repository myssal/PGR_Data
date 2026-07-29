local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010424 : XAfkItemSkillMagicBase
local XBuffScript1010424 = XDlcScriptManager.RegBuffScript(1010424, "XBuffScript1010424", Base)

function XBuffScript1010424:Init() --初始化
    ---------配置------------
    self.magicId = 1010424
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010424
