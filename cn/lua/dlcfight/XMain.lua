XMain = XMain or {}
XMain.IsClient = CS.StatusSyncFight.XFightConfig.IsClient
-- 战斗lua在客户端和服务端都有运行，故需判断IsClient
if XMain.IsClient then
    XMain.IsDebug = CS.XRemoteConfig.Debug --XRemoteConfig是客户端的类
else
    XMain.IsDebug = true --服务端默认开启
end

local lockGMeta = {
    __newindex = function(t, k)
        XLog.Error("can't assign " .. k .. " in _G")
    end,
    __index = function(t, k)
        XLog.Error("can't index " .. k .. " in _G, which is nil")
    end
}

function LuaLockG()
    setmetatable(_G, lockGMeta)
end

if XMain.IsDebug and XMain.IsClient then
    -- 初始化lua调试器，不同设备安装的路径可能不一样，可自行选择在这里粘贴调试配置里给出的启动代码
end

--只用于require整个文件夹的lua，单文件直接用require
function import(fileName)
    XLuaEngine:Import(fileName)
end

require("Common/XClass")
require("Common/XTool")
require("Common/XLog")
require("Common/XScriptTool")
require("Common/XDlcFightLuaEvent")
require("Common/XDlcFightConst")

XMain.StepDlc = function()
    require("Common/XDlcNpcAttribType")
    require("XDlcScriptManager")
    require("DlcHotReload/XDlcHotReload")
    require("XDlcQuestHotfixManager")

    LuaLockG()
end