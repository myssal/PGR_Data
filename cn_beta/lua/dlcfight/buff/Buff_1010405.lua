local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010405 : XAfkItemSkillMagicBase
local XBuffScript1010405 = XDlcScriptManager.RegBuffScript(1010405, "XBuffScript1010405", Base)

function XBuffScript1010405:Init() --初始化
    ---------配置------------
    self.magicId = 1010405
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010405
