local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010412 : XAfkItemSkillMagicBase
local XBuffScript1010412 = XDlcScriptManager.RegBuffScript(1010412, "XBuffScript1010412", Base)

function XBuffScript1010412:Init() --初始化
    ---------配置------------
    self.magicId = 1010412
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010412
