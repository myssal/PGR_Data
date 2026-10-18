local XUiUnionKillTipCardShare = XLuaUiManager.Register(XLuaUi, "UiUnionKillTipCardShare")
local XUiGridUnionShareCharItem = require("XUi/XUiFubenUnionKill/XUiGridUnionShareCharItem")


function XUiUnionKillTipCardShare:OnAwake()
    self.BtnMask.CallBack = function() self:OnBtnMaskClick() end

    self.ShareCharacters = {}
end

function XUiUnionKillTipCardShare:OnDestroy()
        XScheduleManagerPro.UnSchedule(self._OnCloseScheduleCb, self)
end

function XUiUnionKillTipCardShare:OnStart(shareInfos)
    for i = 1, #shareInfos do
        if not self.ShareCharacters[i] then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridMainLineCharacter.gameObject)
            ui.transform:SetParent(self.GridCharacterContent, false)
            self.ShareCharacters[i] = XUiGridUnionShareCharItem.New(ui, self)
        end
        self.ShareCharacters[i].GameObject:SetActiveEx(true)
        self.ShareCharacters[i]:Refresh(shareInfos[i])
    end
    -- 超出的隐藏
    for i = #shareInfos + 1, #self.ShareCharacters do
        self.ShareCharacters[i].GameObject:SetActiveEx(false)
    end

    XScheduleManagerPro.ScheduleOnce(self._OnCloseScheduleCb, self, 3000)
end

function XUiUnionKillTipCardShare:_OnCloseScheduleCb()
    self:Close()
end

function XUiUnionKillTipCardShare:OnBtnMaskClick()
    self:Close()
end
