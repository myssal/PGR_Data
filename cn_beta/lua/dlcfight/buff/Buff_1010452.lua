local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010452 : XAfkItemSkillMagicBase
local XBuffScript1010452 = XDlcScriptManager.RegBuffScript(1010452, "XBuffScript1010452", Base)

function XBuffScript1010452:Init() --初始化
    ---------配置------------
    self.magicId = 1010452
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010452
