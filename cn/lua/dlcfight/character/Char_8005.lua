---@type XRelinkCharBase
local Base = require("Common/XFightBase")

---白龙
---@class XChar8005 : XRelinkCharBase
local XChar8005 = XDlcScriptManager.RegCharScript(8005, "XChar8005", Base)

function XChar8005:Init()
    Base.Init(self)
end

---@param dt number @ delta time
function XChar8005:Update(dt)
    Base.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XChar8005:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar8005:Terminate()
    Base.Terminate(self)
end

return XChar8005