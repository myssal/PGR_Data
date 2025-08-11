local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010443 : XAfkItemSkillMagicBase
local XBuffScript1010443 = XDlcScriptManager.RegBuffScript(1010443, "XBuffScript1010443", Base)

function XBuffScript1010443:Init() --初始化
    ---------配置------------
    self.magicId = 1010443
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010443
