local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010442 : XAfkItemSkillMagicBase
local XBuffScript1010442 = XDlcScriptManager.RegBuffScript(1010442, "XBuffScript1010442", Base)

function XBuffScript1010442:Init() --初始化
    ---------配置------------
    self.magicId = 1010442
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010442
