local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010407 : XAfkItemSkillMagicBase
local XBuffScript1010407 = XDlcScriptManager.RegBuffScript(1010407, "XBuffScript1010407", Base)

function XBuffScript1010407:Init() --初始化
    ---------配置------------
    self.magicId = 1010407
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010407