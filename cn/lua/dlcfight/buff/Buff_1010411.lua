local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010411 : XAfkItemSkillMagicBase
local XBuffScript1010411 = XDlcScriptManager.RegBuffScript(1010411, "XBuffScript1010411", Base)

function XBuffScript1010411:Init() --初始化
    ---------配置------------
    self.magicId = 1010411
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010411
