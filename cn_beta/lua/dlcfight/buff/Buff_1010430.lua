local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010430 : XAfkItemSkillMagicBase
local XBuffScript1010430 = XDlcScriptManager.RegBuffScript(1010430, "XBuffScript1010430", Base)

function XBuffScript1010430:Init() --初始化
    ---------配置------------
    self.magicId = 1010430
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010430
