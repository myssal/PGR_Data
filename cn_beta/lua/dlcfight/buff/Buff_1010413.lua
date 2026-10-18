local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010413 : XAfkItemSkillMagicBase
local XBuffScript1010413 = XDlcScriptManager.RegBuffScript(1010413, "XBuffScript1010413", Base)

function XBuffScript1010413:Init() --初始化
    ---------配置------------
    self.magicId = 1010413
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010413
