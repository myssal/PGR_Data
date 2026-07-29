local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010426 : XAfkItemSkillMagicBase
local XBuffScript1010426 = XDlcScriptManager.RegBuffScript(1010426, "XBuffScript1010426", Base)

function XBuffScript1010426:Init() --初始化
    ---------配置------------
    self.magicId = 1010426
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010426
