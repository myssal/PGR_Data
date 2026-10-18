---@class XUiPokerGuessing2ToastRound : XLuaUi
---@field _Control XPokerGuessing2Control
local XUiPokerGuessing2ToastRound = XLuaUiManager.Register(XLuaUi, "UiPokerGuessing2ToastRound")

function XUiPokerGuessing2ToastRound:OnAwake()
    self:BindExitBtns()
end

function XUiPokerGuessing2ToastRound:OnStart()
    XScheduleManagerPro.ScheduleOnce(self._OnStartScheduleCb, self, 3 * XScheduleManagerPro.SECOND)
    self:Update()
end

function XUiPokerGuessing2ToastRound:_OnStartScheduleCb()
                XLuaUiManager.SafeClose(self.Name)
end

function XUiPokerGuessing2ToastRound:OnDestroy()
    XScheduleManagerPro.UnSchedule(self._OnStartScheduleCb, self)
end

function XUiPokerGuessing2ToastRound:Update()
    local round = self._Control:GetRound()
    -- 根据回合数显示对应的数字图片，隐藏其他的
    local numImages = {
        self.RImgNum1,
        self.RImgNum2,
        self.RImgNum3,
        self.RImgNum4,
        self.RImgNum5,
    }
    
    -- 回合数从1开始，超过5就显示最后一个
    local index = math.min(round, 5)
    
    for i = 1, #numImages do
        local img = numImages[i]
        if img then
            img.gameObject:SetActiveEx(i == index)
        end
    end
end

return XUiPokerGuessing2ToastRound