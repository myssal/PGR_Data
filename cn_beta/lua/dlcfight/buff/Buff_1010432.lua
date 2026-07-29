local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010432 : XAfkItemSkillMagicBase
local XBuffScript1010432 = XDlcScriptManager.RegBuffScript(1010432, "XBuffScript1010432", Base)

function XBuffScript1010432:Init() --初始化
    ---------配置------------
    self.magicId = 1010432
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010432
