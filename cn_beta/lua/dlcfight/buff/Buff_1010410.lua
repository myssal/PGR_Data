local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010410 : XAfkItemSkillMagicBase
local XBuffScript1010410 = XDlcScriptManager.RegBuffScript(1010410, "XBuffScript1010410", Base)

function XBuffScript1010410:Init() --初始化
    ---------配置------------
    self.magicId = 1010410
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010410
