---@type XRelinkCharBase
local Base = require("Character/FightCharBase/XRelinkCharBase")

---首席指挥官角色脚本
---@class XChar1052 : XRelinkCharBase
local XChar1052 = XDlcScriptManager.RegCharScript(1052, "XChar1052", Base)

function XChar1052:Init()
    Base.Init(self)
end

---@param dt number @ delta time
function XChar1052:Update(dt)
    Base.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XChar1052:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar1052:Terminate()
    Base.Terminate(self)
end

return XChar1052