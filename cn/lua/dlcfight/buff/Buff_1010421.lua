local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010421 : XAfkItemSkillMagicBase
local XBuffScript1010421 = XDlcScriptManager.RegBuffScript(1010421, "XBuffScript1010421", Base)

function XBuffScript1010421:Init() --初始化
    ---------配置------------
    self.magicId = 1010421
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010421
