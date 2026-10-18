local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010404 : XAfkItemSkillMagicBase
local XBuffScript1010404 = XDlcScriptManager.RegBuffScript(1010404, "XBuffScript1010404", Base)

function XBuffScript1010404:Init() --初始化
    ---------配置------------
    self.magicId = 1010404
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010404
