local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010409 : XAfkItemSkillMagicBase
local XBuffScript1010409 = XDlcScriptManager.RegBuffScript(1010409, "XBuffScript1010409", Base)

function XBuffScript1010409:Init() --初始化
    ---------配置------------
    self.magicId = 1010409
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010409
