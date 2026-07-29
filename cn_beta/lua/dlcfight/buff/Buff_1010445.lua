local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010445 : XAfkItemSkillMagicBase
local XBuffScript1010445 = XDlcScriptManager.RegBuffScript(1010445, "XBuffScript1010445", Base)

function XBuffScript1010445:Init() --初始化
    ---------配置------------
    self.magicId = 1010445
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010445
