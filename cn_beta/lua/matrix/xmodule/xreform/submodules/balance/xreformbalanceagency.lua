---@class XReformBalanceAgency : XAgency
---@field private _Model XReformModel
---@field private _MainAgency XReformAgency
--- 4.9 天平质点子 Agency（一次性封存功能）
--- 配置表注册在子 Control 的 config 分部（XReformBalanceConfigControl.lua），不在 Agency。
--- 本 Agency 承载天平 RPC / 跨 Agency 事件（待协议接入时填）。
--- 封存时：删本夹 + 去 XReformAgency:OnInit 一行 AddSubAgency。
local XReformBalanceAgency = XClass(XAgency, "XReformBalanceAgency")

function XReformBalanceAgency:OnInit()
end

function XReformBalanceAgency:InitRpc()
    -- 天平相关 RPC 待协议接入时填
end

function XReformBalanceAgency:InitEvent()
    -- 天平跨 Agency 事件待实现时填
end

return XReformBalanceAgency
