local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010451 : XAfkItemSkillMagicBase
local XBuffScript1010451 = XDlcScriptManager.RegBuffScript(1010451, "XBuffScript1010451", Base)

function XBuffScript1010451:Init() --初始化
    ---------配置------------
    self.magicId = 1010451
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010451
