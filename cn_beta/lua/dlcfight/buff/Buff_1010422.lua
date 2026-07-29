local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010422 : XAfkItemSkillMagicBase
local XBuffScript1010422 = XDlcScriptManager.RegBuffScript(1010422, "XBuffScript1010422", Base)

function XBuffScript1010422:Init() --初始化
    ---------配置------------
    self.magicId = 1010422
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010422
