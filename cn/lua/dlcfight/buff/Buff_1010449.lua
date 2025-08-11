local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010449 : XAfkItemSkillMagicBase
local XBuffScript1010449 = XDlcScriptManager.RegBuffScript(1010449, "XBuffScript1010449", Base)

function XBuffScript1010449:Init() --初始化
    ---------配置------------
    self.magicId = 1010449
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010449
