local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010444 : XAfkItemSkillMagicBase
local XBuffScript1010444 = XDlcScriptManager.RegBuffScript(1010444, "XBuffScript1010444", Base)

function XBuffScript1010444:Init() --初始化
    ---------配置------------
    self.magicId = 1010444
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010444
