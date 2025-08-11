local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010441 : XAfkItemSkillMagicBase
local XBuffScript1010441 = XDlcScriptManager.RegBuffScript(1010441, "XBuffScript1010441", Base)

function XBuffScript1010441:Init() --初始化
    ---------配置------------
    self.magicId = 1010441
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010441
