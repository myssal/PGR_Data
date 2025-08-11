local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010446 : XAfkItemSkillMagicBase
local XBuffScript1010446 = XDlcScriptManager.RegBuffScript(1010446, "XBuffScript1010446", Base)

function XBuffScript1010446:Init() --初始化
    ---------配置------------
    self.magicId = 1010446
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010446
