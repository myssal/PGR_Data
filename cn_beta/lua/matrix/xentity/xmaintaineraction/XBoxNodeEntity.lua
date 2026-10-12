local XMaintainerActionNodeEntity = require("XEntity/XMaintainerAction/XMaintainerActionNodeEntity")
local XBoxNodeEntity = XClass(XMaintainerActionNodeEntity, "XBoxNodeEntity")
local CSTextManagerGetText = CS.XTextManager.GetText

function XBoxNodeEntity:Ctor()
    self.RewardId = 0
end

function XBoxNodeEntity:GetRewardId()
    return self.RewardId
end

function XBoxNodeEntity:GetRewardTitle()
    return CS.XTextManager.GetText("MaintainerActionBoxReward")
end

function XBoxNodeEntity:OpenDescTip()
    XLuaUiManager.Open("UiFubenMaintaineractionDetailsTips", self, true)
end

function XBoxNodeEntity:DoEvent(data)
    if not data then return end
    local gameData = XDataCenter.MaintainerActionManager.GetGameData()
    gameData:PlusBoxCount()
    
    XLuaUiManager.Open("UiFubenMaintaineractionTreasurechest", self:GetRewardId(), nil,
        CSTextManagerGetText("MaintainerActionBoxGetTitleText"), 
        CSTextManagerGetText("MaintainerActionBoxGetSubTitleText"), 
        gameData:GetBoxCount(), 
        gameData:GetMaxBoxCount(),function ()
            local IsAllComplete = XDataCenter.MaintainerActionManager.CheckIsAllComplete()
            if IsAllComplete then
                XDataCenter.MaintainerActionManager.AddMessageType(XMaintainerActionConfigs.MessageType.EventComplete)
                XScheduleManagerPro.ScheduleOnce(self._OnDoEventScheduleCb, self, 100)
            end
        end)
    
    data.player:MarkNodeEvent()
    if data.cb then data.cb() end
end

function XBoxNodeEntity:_OnDoEventScheduleCb()
    XDataCenter.MaintainerActionManager.CheckEventCompleteMessage()
end

return XBoxNodeEntity