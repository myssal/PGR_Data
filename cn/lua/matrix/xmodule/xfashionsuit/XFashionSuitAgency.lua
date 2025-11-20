---@class XFashionSuitAgency : XAgency
---@field private _Model XFashionSuitModel
local XFashionSuitAgency = XClass(XAgency, "XFashionSuitAgency")

function XFashionSuitAgency:OnInit()
    --初始化一些变量
end

function XFashionSuitAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XFashionSuitAgency:InitEvent()
    
end

----------public start----------

function XFashionSuitAgency:SetFashionSuitData(fashionSuitList)
    self._Model:SetFashionSuitData(fashionSuitList)
end

function XFashionSuitAgency:OpenMain()
    XLuaUiManager.Open("UiFashionSuitMain")
end

function XFashionSuitAgency:IsRed()
    --功能未开启
    if not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FashionSuit) then
        return false
    end
    --涂装上新、全收集奖励未领取
    local configs = self._Model:GetFashionSuitConfigs()
    for _, config in pairs(configs) do
        local ownCount = 0
        for _, fashionId in pairs(config.FashionIds) do
            if not self._Model:IsFashionViewed(fashionId) then
                return true
            end
            if XDataCenter.FashionManager.CheckHasFashion(fashionId) then
                ownCount = ownCount + 1
            end
        end
        if ownCount == #config.FashionIds and not self._Model:IsSuitRewardGain(config.Id) then
            return true
        end
    end
    return false
end

----------public end----------

----------private start----------


----------private end----------

return XFashionSuitAgency