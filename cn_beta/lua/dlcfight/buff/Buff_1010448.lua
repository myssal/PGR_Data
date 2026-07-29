local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010448 : XAfkItemSkillMagicBase
local XBuffScript1010448 = XDlcScriptManager.RegBuffScript(1010448, "XBuffScript1010448", Base)

function XBuffScript1010448:Init() --初始化
    ---------配置------------
    self.magicId = 1010448
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010448
