---@class XReformBalanceModel : XModel
--- 4.9 天平质点子 Model 脚手架（服务端运行时数据 / 本地存档待实现时填）
--- 封存时随本夹一并删除。当前未挂载到子 Agency（无运行时数据），待天平数据流落地时 wiring + 填实现。
local XReformBalanceModel = XClass(XModel, "XReformBalanceModel")

function XReformBalanceModel:OnInit()
end

return XReformBalanceModel
