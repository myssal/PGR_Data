local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010406 : XAfkItemSkillMagicBase
local XBuffScript1010406 = XDlcScriptManager.RegBuffScript(1010406, "XBuffScript1010406", Base)

function XBuffScript1010406:Init() --初始化
    ---------配置------------
    self.magicId = 1010406
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010406
