local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")

---@class XPacMan2Agency : XAgency
---@field private _Model XPacMan2Model
local XPacMan2Agency = XClass(XFubenActivityAgency, "XPacMan2Agency")
function XPacMan2Agency:OnInit()
    self:RegisterActivityAgency()

    -- 结算请求编号分配器，在同一个Agency实例内持续递增。
    -- ResetAll时不能归零，避免旧回调与新请求编号重复。
    self._SettleTokenCounter = 0
    -- 当前等待响应的结算请求编号，nil表示没有待响应请求。
    self._PendingSettleToken = nil

    -- 等待旧结算完成后执行的开局请求。
    -- 当前只允许存在一个待开始的Game。
    self._PendingStageStart = nil
end

function XPacMan2Agency:InitRpc()
    XRpc.NotifyPacMan2Activity = Handler(self, self.NotifyPacMan2Activity)
end

function XPacMan2Agency:OpenMain()
    ---@type XTablePacMan2Activity
    local activityConfig = self._Model:GetActivityConfig()
    
    -- 如果没有服务端的 activityId，从配置表获取最后一条配置来做时间判断，然后返回 false
    if not activityConfig then
        local allConfigs = self._Model:GetAllActivityConfigs()
        if allConfigs and not XTool.IsTableEmpty(allConfigs) then
            -- 找到 Id 最大的配置（最后一条）
            local lastConfig = nil
            local maxId = 0
            for _, config in pairs(allConfigs) do
                if config and config.Id and config.Id > maxId then
                    maxId = config.Id
                    lastConfig = config
                end
            end
            if lastConfig and lastConfig.TimeId then
                -- 使用配置表的配置进行时间判断
                self:_ShowTimeTip(lastConfig.TimeId)
            else
                -- 如果仍然没有配置，直接提示未开放
                XUiManager.TipText("ActivityBranchNotOpen")
            end
        else
            -- 配置表为空，直接提示未开放
            XUiManager.TipText("ActivityBranchNotOpen")
        end
        return false
    end
    
    local timeId = activityConfig.TimeId
    if not XFunctionManager.CheckInTimeByTimeId(timeId) then
        -- 判断是活动未开始还是已结束
        self:_ShowTimeTip(timeId)
        return false
    end
    XLuaUiManager.Open("UiPacMan2Main")
    return true
end

--- 显示时间提示（活动未开始或已结束）
---@param timeId number 时间ID
function XPacMan2Agency:_ShowTimeTip(timeId)
    local nowTime = XTime.GetServerNowTimestamp()
    local startTime = XFunctionManager.GetStartTimeByTimeId(timeId)
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    
    if startTime > 0 and nowTime < startTime then
        -- 活动未开始
        XUiManager.TipText("ActivityBranchNotOpen")
    elseif endTime > 0 and nowTime >= endTime then
        -- 活动已结束
        XUiManager.TipText("ActivityBranchOver")
    else
        -- 其他情况（可能时间配置有问题）
        XUiManager.TipText("ActivityBranchNotOpen")
    end
end

function XPacMan2Agency:NotifyPacMan2Activity(data)
    self._Model:SetDataFromServer(data)
end

function XPacMan2Agency:PacMan2StageStartRequest(stageId, callback, isOwnerValid)
    if isOwnerValid and not isOwnerValid() then
        return
    end
    if self._PendingSettleToken then
        self._PendingStageStart = function()
            self:PacMan2StageStartRequest(stageId,callback,isOwnerValid)
        end
        return
    end
    if self._Model.IsPlaying then
        XLog.Error("[XPacMan2Agency] 上一局尚未结束，不能发送开局请求")
        callback(false)
        return
    end
    
    XNetwork.Call("PacMan2StageStartRequest",{StageId = stageId}, function(res)
        if isOwnerValid and not isOwnerValid() then
            return
        end

        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            callback(false)
            return
        end
        self._Model.IsPlaying = true
        callback(true)
    end)
end

---提交一次已经结束的本地运行。
---@return boolean accepted 是否接收了本次提交，不代表服务器已结算成功
function XPacMan2Agency:PacMan2SettleRequest(data)
    if self._PendingSettleToken then
        XLog.Warning("[XPacMan2Agency] 已有结算请求等待响应，拒绝重复提交")
        return false
    end

    if not self._Model.IsPlaying then
        XLog.Warning("[XPacMan2Agency] 未开始游戏，不能提交结算")
        return false
    end
    
    self._SettleTokenCounter = self._SettleTokenCounter + 1
    local token = self._SettleTokenCounter
    self._PendingSettleToken = token
    
    local function onResponse(res)
        --不处理旧请求的回调。
        if self._PendingSettleToken ~= token then
            return
        end
        -- 这次本地运行已经结束。
        -- 不论服务器返回成功还是业务错误，都不应继续占用本地进行中状态。
        self._Model.IsPlaying = false
        if res then
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
            else
                if res.StageData then
                    self._Model:SetStageData(res.StageData)
                end

                if res.RewardGoodsList then
                    XUiManager.OpenUiObtain(res.RewardGoodsList)
                end
            end
        end
        
        self._PendingSettleToken = nil
        
        local pendingStart = self._PendingStageStart
        self._PendingStageStart = nil
        if pendingStart then
            pendingStart()
        end
    end
    XNetwork.Call("PacMan2SettleRequest", data, onResponse, nil,nil, function()
        onResponse(nil)
    end)
    return true
end

function XPacMan2Agency:ExCheckInTime()
    local activityConfig = self._Model:GetActivityConfig()
    if not activityConfig then
        return false
    end
    local isInTime = XFunctionManager.CheckInTimeByTimeId(activityConfig.TimeId)
    return isInTime
end

function XPacMan2Agency:HasStageNotPassedAndCanChallenge()
    local stages = self._Model:GetStageConfigs()
    for _, stage in ipairs(stages) do
        --  判断关卡是否通过
        if not self._Model:IsStagePassed(stage.Id) then
            --  判断时间
            if XFunctionManager.CheckInTimeByTimeId(stage.TimeId) then
                -- 判断前置关卡
                local preStageId = stage.PreStageId
                if preStageId == 0 or preStageId == nil or self._Model:IsStagePassed(preStageId) then
                    return true
                end
            end
        end
    end
    return false
end

function XPacMan2Agency:ResetAll()
    -- 保留请求编号计数器，避免旧、新请求复用编号。
    self._PendingSettleToken = nil
    self._PendingStageStart = nil
end

return XPacMan2Agency