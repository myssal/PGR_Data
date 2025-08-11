local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010402 : XAfkItemSkillMagicBase
local XBuffScript1010402 = XDlcScriptManager.RegBuffScript(1010402, "XBuffScript1010402", Base)

function XBuffScript1010402:Init() --初始化
    ---------配置------------
    self.magicId = 1010402
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010402
