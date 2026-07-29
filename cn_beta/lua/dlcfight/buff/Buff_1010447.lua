local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010447 : XAfkItemSkillMagicBase
local XBuffScript1010447 = XDlcScriptManager.RegBuffScript(1010447, "XBuffScript1010447", Base)

function XBuffScript1010447:Init() --初始化
    ---------配置------------
    self.magicId = 1010447
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010447
