local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010425 : XAfkItemSkillMagicBase
local XBuffScript1010425 = XDlcScriptManager.RegBuffScript(1010425, "XBuffScript1010425", Base)

function XBuffScript1010425:Init() --初始化
    ---------配置------------
    self.magicId = 1010425
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010425
