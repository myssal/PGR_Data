local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010423 : XAfkItemSkillMagicBase
local XBuffScript1010423 = XDlcScriptManager.RegBuffScript(1010423, "XBuffScript1010423", Base)

function XBuffScript1010423:Init() --初始化
    ---------配置------------
    self.magicId = 1010423
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010423
