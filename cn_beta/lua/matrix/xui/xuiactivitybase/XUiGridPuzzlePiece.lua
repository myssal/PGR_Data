local XUiGridPuzzlePiece = XClass(nil, "XUiGridPuzzlePiece")

function XUiGridPuzzlePiece:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)
    self.GameObject:SetActiveEx(true)
    self:SetButtonCallBack()
    self.LastState = XPuzzleActivityConfigs.PuzzleCondition.Activated
    self.EffectHint.gameObject:SetActiveEx(false)
    self.EffectFlip.gameObject:SetActiveEx(false)
end

function XUiGridPuzzlePiece:OnDestroy()
end

function XUiGridPuzzlePiece:RemoveTimer()
    XScheduleManagerPro.UnSchedule(XUiGridPuzzlePiece._OnOpenEffectScheduleCb, self)
    XScheduleManagerPro.UnSchedule(XUiGridPuzzlePiece._OnCloseEffectScheduleCb, self)
end

function XUiGridPuzzlePiece:SetButtonCallBack()
    self.Btn.CallBack = function()
        self:OnBtnActiveClick()
    end
end

function XUiGridPuzzlePiece:OnBtnActiveClick()
    if self.State ~= XPuzzleActivityConfigs.PuzzleRewardState.CanReward then
        if self.State == XPuzzleActivityConfigs.PuzzleRewardState.Unrewarded then
            XUiManager.TipText("ActivityPuzzleNoItem")
        end
        return
    end
    XDataCenter.PuzzleActivityManager.PuzzleActivityFlipPieceRequest(self.PuzzleId, self.Index)
end

function XUiGridPuzzlePiece:Refresh()
    self.State = XDataCenter.PuzzleActivityManager.GetPuzzleActPieceData(self.PuzzleId ,self.Index)
    if self.State ~= self.LastState then
        if self.State == XPuzzleActivityConfigs.PuzzleCondition.NotCollected then
            -- do nothing
        elseif self.State == XPuzzleActivityConfigs.PuzzleCondition.Inactivated then
            self.EffectHint.gameObject:SetActiveEx(true)
        elseif self.State == XPuzzleActivityConfigs.PuzzleCondition.Activated then
            self:ShowFlipEffect()
        end
    end
    if self.State == XPuzzleActivityConfigs.PuzzleCondition.Activated  then
        self.Btn:SetButtonState(CS.UiButtonState.Disable)
    end
    self.LastState = self.State
end

function XUiGridPuzzlePiece:ShowFlipEffect()
    self:RemoveTimer()
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.Common_UiObtain)
    XScheduleManagerPro.ScheduleOnce(XUiGridPuzzlePiece._OnOpenEffectScheduleCb, self, 20)
    XScheduleManagerPro.ScheduleOnce(XUiGridPuzzlePiece._OnCloseEffectScheduleCb, self, 1500)
end

function XUiGridPuzzlePiece:Init(puzzleId, index)
    self.PuzzleId = puzzleId
    self.Index = index    
    self.PieceTemplate = XDataCenter.PuzzleActivityManager.GetPieceTemplate(puzzleId, index)
    self.Btn:SetRawImage(self.PieceTemplate.CoverImage)
end

function XUiGridPuzzlePiece:_OnOpenEffectScheduleCb()
    self.EffectFlip.gameObject:SetActiveEx(true)
end

function XUiGridPuzzlePiece:_OnCloseEffectScheduleCb()
    self.EffectFlip.gameObject:SetActiveEx(false)
end

return XUiGridPuzzlePiece