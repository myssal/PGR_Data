local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010431 : XAfkItemSkillMagicBase
local XBuffScript1010431 = XDlcScriptManager.RegBuffScript(1010431, "XBuffScript1010431", Base)

function XBuffScript1010431:Init() --初始化
    ---------配置------------
    self.magicId = 1010431
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010431
