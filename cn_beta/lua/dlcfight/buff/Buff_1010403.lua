local Base = require("Buff/BuffBase/XAfkItemSkillMagicBase")
---@class XBuffScript1010403 : XAfkItemSkillMagicBase
local XBuffScript1010403 = XDlcScriptManager.RegBuffScript(1010403, "XBuffScript1010403", Base)

function XBuffScript1010403:Init() --初始化
    ---------配置------------
    self.magicId = 1010403
    ---------父类逻辑初始化------------
    Base.Init(self)
end

return XBuffScript1010403
