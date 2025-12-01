---@class XRadioSignAgency : XAgency
---@field private _Model XRadioSignModel
local XRadioSignAgency = XClass(XAgency, "XRadioSignAgency")
function XRadioSignAgency:OnInit()
    --初始化一些变量
end

function XRadioSignAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyRadioSignPlayerDataDb = Handler(self, self.NotifyRadioSignPlayerDataDb)
end

function XRadioSignAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------public start----------

function XRadioSignAgency:OpenMain()
    if self:IsInTime(true) then
        XLuaUiManager.Open("UiRadioSignMain")
        return true
    end
    return false
end

function XRadioSignAgency:NotifyRadioSignPlayerDataDb(data)
    self._Model:SetDataFromServer(data.RadioSignDataDb)
end

function XRadioSignAgency:IsInTime(tipText)
    ---@type XTableRadioSignActivity
    local activityConfig = self._Model:GetActivityConfig()
    if not activityConfig then
        if tipText then
            XUiManager.TipText("ActivityBranchNotOpen")
        end
        return false
    end
    local timeId = activityConfig.TimeId
    if not XFunctionManager.CheckInTimeByTimeId(timeId) then
        if tipText then
            XUiManager.TipText("ActivityBranchNotOpen")
        end
        return false
    end
    return true
end

function XRadioSignAgency:Popup()
    if self:IsInTime() then
        local contentOpened
        local contents = self._Model:GetContentConfigs()
        for _, content in pairs(contents) do
            local timeId = content.TimeId
            if XFunctionManager.CheckInTimeByTimeId(timeId) then
                if not self._Model:IsContentReceived(content.Id) then
                    contentOpened = content
                end
            end
        end
        if contentOpened then
            XLuaUiManager.Open("UiRadioSignPopupHall", contentOpened)
            return true
        end
    end
    return false
end

function XRadioSignAgency:DebugOpenPopup()
    local contentOpened
    local contents = self._Model:GetContentConfigs()
    for _, content in pairs(contents) do
        local timeId = content.TimeId
        if XFunctionManager.CheckInTimeByTimeId(timeId) then
            if not self._Model:IsContentReceived(content.Id) then
                contentOpened = content
                break
            end
        end
    end
    if not contentOpened then
        for _, content in pairs(contents) do
            contentOpened = content
            break
        end
    end
    if contentOpened then
        XLuaUiManager.Open("UiRadioSignPopupHall", contentOpened)
    end
end

function XRadioSignAgency:RadioSignGainRewardRequest(signContextId, callback, delayShowReward)
    XNetwork.Call("RadioSignGainRewardRequest", {
        SignContextId = signContextId
    }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if callback then
                callback(false, nil)
            end
            return
        end
        
        -- 请求成功后，更新model中的缓存
        self._Model:AddContentReceived(signContextId)
        XLog.Debug("[XRadioSignAgency] RadioSignGainRewardRequest: 请求成功，已更新缓存, signContextId =", signContextId)
        
        -- 如果不需要延后显示奖励，立即弹出
        if not delayShowReward and res.RewardGoodsList then
            XUiManager.OpenUiObtain(res.RewardGoodsList)
        end
        
        if callback then
            -- 将奖励列表通过回调返回，让调用方决定何时弹出
            callback(true, res.RewardGoodsList)
        end
    end)
end

-- 检查是否有可领取的奖励（用于红点系统）
-- @return boolean 如果有符合时间且未领取的奖励，返回true
function XRadioSignAgency:HasRewardAvailable()
    local contents = self._Model:GetContentConfigs()
    if not contents then
        return false
    end

    -- 遍历所有 content，检查是否有符合时间且未领取的奖励
    for _, content in pairs(contents) do
        if content and content.TimeId then
            -- 检查时间是否符合
            if XFunctionManager.CheckInTimeByTimeId(content.TimeId) then
                -- 检查是否已领取
                if not self._Model:IsContentReceived(content.Id) then
                    -- 符合时间且有奖励可领取，返回 true
                    return true
                end
            end
        end
    end

    return false
end

return XRadioSignAgency