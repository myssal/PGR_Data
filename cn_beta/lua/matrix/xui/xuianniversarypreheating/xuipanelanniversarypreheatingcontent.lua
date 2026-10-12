local TickInterval = 50
local LoopPositionTolerance = 0.001

---@class XUiPanelAnniversaryPreHeatingContent : XUiNode
---@field _Control XAnniversaryPreHeatingControl
local XUiPanelAnniversaryPreHeatingContent = XClass(XUiNode, "XUiPanelAnniversaryPreHeatingContent")

function XUiPanelAnniversaryPreHeatingContent:OnStart()
    self._ContentId = self._ContentId or 0
    self._IsEnabled = false
    self._BannerInterval = self._Control:GetBannerInterval()
    self._TextScrollSpeed = self._Control:GetTextScrollSpeed()
    self._TextWaitSeconds = self._Control:GetTextScrollWait()
    self:_InitBanner()
    self:_InitText()
    self:_InitReward()
    self:_InitVideo()
    self:_StopContent()
end

function XUiPanelAnniversaryPreHeatingContent:OnEnable()
    self._IsEnabled = true
    if self._ContentId > 0 then
        self:_RefreshContent()
    end
end

function XUiPanelAnniversaryPreHeatingContent:OnDisable()
    self._IsEnabled = false
    self:_StopContent()
end

function XUiPanelAnniversaryPreHeatingContent:OnDestroy()
    XScheduleManagerPro.UnScheduleAllByHandlerObject(self)
    self._CenterScroll:RegisterEndDragCallBack(nil)
    self._BannerWidget:RemoveBeginDragListener(self._BannerBeginDragCallback)
    self._TextWidget:RemoveBeginDragListener(self._TextBeginDragCallback)
    self._TextWidget:RemoveEndDragListener(self._TextEndDragCallback)
    self.BtnReward.CallBack = nil
    self._BtnCloseReward.CallBack = nil
    self.BtnPlayAgain.CallBack = nil
    if not XTool.UObjIsNil(self._VideoWidget) then
        self._VideoWidget:RemovePointerClickListener(self._VideoClickCallback)
    end
    if not XTool.UObjIsNil(self._VideoPlayer) then
        self._VideoPlayer.ActionPlayed = nil
        self._VideoPlayer.ActionEnded = nil
        self._VideoPlayer.ActionError = nil
        self._VideoPlayer:Stop()
    end
end

---@param contentId number AnniversaryPreHeatingContent 表主键
function XUiPanelAnniversaryPreHeatingContent:Update(contentId)
    self._ContentId = contentId
    if self._IsEnabled then
        self:_RefreshContent()
    end
end

function XUiPanelAnniversaryPreHeatingContent:_RefreshContent()
    self:_StopContent()
    local config = self._Control:GetContentConfigById(self._ContentId)
    self._HasReward = XTool.IsNumberValid(config.Tag)
    self._ShowRewardId = config.ShowRewardId
    self._VideoId = config.VideoId

    if self._VideoId > 0 then
        self._IsVideoActive = true
        self._CanPlayVideo = not XTool.UObjIsNil(self._VideoPlayer)
        self.PanelVideo.gameObject:SetActiveEx(true)
        self:_StartVideo()
        self.Parent:_RequestContentRead(self._ContentId)  -- 视频不会存在轮播，可以直接发协议
    else
        self:_RefreshText()
        self.BtnReward.gameObject:SetActiveEx(self._HasReward)
        self:_ShowBanner(config.ActivityBg)
    end
end

function XUiPanelAnniversaryPreHeatingContent:_StopContent()
    self._IsVideoActive = false
    self._IsVideoStarting = false
    self._IsTextDragging = false
    XScheduleManagerPro.UnScheduleAllByHandlerObject(self)
    self._IsBannerDragging = false
    self._CenterScroll.enabled = false
    self._BannerScrollRect.enabled = false
    self._BannerScrollRect:StopMovement()
    self.PanelBanner.gameObject:SetActiveEx(false)
    self.PanelDot.gameObject:SetActiveEx(false)
    self.PanelTxt.gameObject:SetActiveEx(false)
    self.BubbleRewardPreview.gameObject:SetActiveEx(false)
    self.BtnReward.gameObject:SetActiveEx(false)
    self.BtnPlayAgain.gameObject:SetActiveEx(false)
    if not XTool.UObjIsNil(self._VideoPlayer) then
        self._VideoPlayer:Stop()
    end
    self.PanelVideo.gameObject:SetActiveEx(false)
end

--region 轮播和圆点

function XUiPanelAnniversaryPreHeatingContent:_InitBanner()
    self._CenterScroll = self.PanelBanner
    self._BannerScrollRect = self._CenterScroll.TargetScrollRect
    self._DotGrids = {}
    self._PagePaths = {}
    self._BannerReadStateMap = {}
    self._ImageCount = 0
    self._SelectedImageIndex = 1
    -- RefreshCustomizedList用
    self._RefreshBannerImageCallback = handler(self, self._RefreshBannerImage)
    self._RefreshDotCallback = handler(self, self._RefreshDotState)
    -- 玩家开始拖拽时暂停自动轮播，结束后由CenterScroll页码回调重启
    self._BannerBeginDragCallback = handler(self, self._OnBannerBeginDrag)
    -- CenterScroll划完后的回调
    self._CenterScroll:RegisterEndDragCallBack(handler(self, self._OnBannerPageChanged))
    self._BannerWidget = self._CenterScroll:GetComponent(typeof(CS.XUiWidget))
    self._BannerWidget:AddBeginDragListener(self._BannerBeginDragCallback)
end

function XUiPanelAnniversaryPreHeatingContent:_ShowBanner(imagePaths)
    self.PanelBanner.gameObject:SetActiveEx(true)
    self._ImageCount = #imagePaths
    self._SelectedImageIndex = 1
    table.clear(self._PagePaths)
    if not self._BannerReadStateMap[self._ContentId] then
        self._BannerReadStateMap[self._ContentId] = {
            ViewedPageMap = {},
        } -- 记录content下已观看的真实轮播页，只有全部看完才记录进度
    end
    local hasMultipleImages = self._ImageCount > 1
    if hasMultipleImages then
        -- 首尾各放一张副本，滑到副本后跳回相同的真实图片。头部假页
        self._PagePaths[1] = imagePaths[self._ImageCount]
    end
    for _, imagePath in ipairs(imagePaths) do
        self._PagePaths[#self._PagePaths + 1] = imagePath
    end
    if hasMultipleImages then
        self._PagePaths[#self._PagePaths + 1] = imagePaths[1] -- 尾部假页
        self.PanelDot.gameObject:SetActiveEx(true)
        self._DotGrids = XUiHelper.RefreshUiObjectList(self._DotGrids, self.PanelDot, self.GridDot,
            self._ImageCount, self._RefreshDotCallback)
    end
    XUiHelper.RefreshCustomizedList(self._BannerScrollRect.content, self.RImgDetail,
        #self._PagePaths, self._RefreshBannerImageCallback)
    self._CenterScroll:UpdatePages()
    if hasMultipleImages then
        -- SetIndex 对相同索引会早退，先切到假页保证重新定位。
        self._IsInitBannerIndex = true
        self._CenterScroll:SetIndex(0)
        self._CenterScroll:SetIndex(1)
        self._IsInitBannerIndex = false
        self:_MarkBannerPageViewed(1)
    else
        self._BannerScrollRect.horizontalNormalizedPosition = 0
        self.Parent:_RequestContentRead(self._ContentId)
    end
    self._BannerScrollRect.enabled = hasMultipleImages
    self._CenterScroll.enabled = hasMultipleImages
    if hasMultipleImages then
        XScheduleManagerPro.ScheduleForever(self._OnBannerLoopTimer, self, TickInterval)
    end
end

function XUiPanelAnniversaryPreHeatingContent:_RefreshBannerImage(index, grid)
    local imagePath = self._PagePaths[index]
    local rawImage = grid:GetComponent(typeof(CS.UnityEngine.UI.RawImage))
    if string.IsNilOrEmpty(imagePath) then
        rawImage:SetRawImage(nil)
        return
    end
    rawImage:SetRawImage(imagePath)
end

function XUiPanelAnniversaryPreHeatingContent:_RefreshDotState(index, dot)
    local isSelected = index == self._SelectedImageIndex
    dot.ImgOn.gameObject:SetActiveEx(isSelected)
    dot.ImgOff.gameObject:SetActiveEx(not isSelected)
end

-- 阅读完所有的轮播图才发协议
function XUiPanelAnniversaryPreHeatingContent:_MarkBannerPageViewed(pageIndex)
    local readState = self._BannerReadStateMap[self._ContentId]
    if readState.ViewedPageMap[pageIndex] then
        return
    end

    readState.ViewedPageMap[pageIndex] = true
    for index = 1, self._ImageCount do
        if not readState.ViewedPageMap[index] then
            return
        end
    end

    self.Parent:_RequestContentRead(self._ContentId)
end

function XUiPanelAnniversaryPreHeatingContent:_RestartBannerAutoTimer()
    XScheduleManagerPro.UnSchedule(self._OnBannerAutoTimer, self)
    if not self._IsEnabled or self._IsBannerDragging or self._ImageCount <= 1 then
        return
    end
    XScheduleManagerPro.ScheduleOnce(self._OnBannerAutoTimer, self, self._BannerInterval * XScheduleManagerPro.SECOND)
end

function XUiPanelAnniversaryPreHeatingContent:_OnBannerAutoTimer()
    self._CenterScroll:NextPage()
end

function XUiPanelAnniversaryPreHeatingContent:_OnBannerBeginDrag()
    self._IsBannerDragging = true
    XScheduleManagerPro.UnSchedule(self._OnBannerAutoTimer, self)
end

---@param index number C# 页码，从 0 开始，注意，这里要额外处理index，index包含假的首尾页。
--- 1. 刷新轮播图下面的点 2.重新计时自动滚动
function XUiPanelAnniversaryPreHeatingContent:_OnBannerPageChanged(index)
    self._IsBannerDragging = false
    self._PageIndex = index
    if self._ImageCount <= 1 then
        return
    end
    local realIndex = (index - 1) % self._ImageCount + 1
    self._SelectedImageIndex = realIndex
    if not self._IsInitBannerIndex then
        self:_MarkBannerPageViewed(realIndex)
    end
    for dotIndex = 1, self._ImageCount do
        self:_RefreshDotState(dotIndex, self._DotGrids[dotIndex])
    end
    self:_RestartBannerAutoTimer()
end

--在即将划到首位假页时（horizontalNormalizedPosition<LoopPositionTolerance）强行跳转到真页，同时修正位置
function XUiPanelAnniversaryPreHeatingContent:_OnBannerLoopTimer()
    if self._IsBannerDragging then
        return
    end
    local position = self._BannerScrollRect.horizontalNormalizedPosition
    if self._PageIndex == 0 and position <= LoopPositionTolerance then
        self._BannerScrollRect:StopMovement()
        self._CenterScroll:SetIndex(self._ImageCount)
    elseif self._PageIndex == self._ImageCount + 1 and position >= 1 - LoopPositionTolerance then
        self._BannerScrollRect:StopMovement()
        self._CenterScroll:SetIndex(1)
    end
end

--endregion

--region 标题和正文

function XUiPanelAnniversaryPreHeatingContent:_InitText()
    self._TextBeginDragCallback = handler(self, self._OnTextBeginDrag)
    self._TextEndDragCallback = handler(self, self._OnTextEndDrag)
    self._TextWidget = self.ScrollList:GetComponent(typeof(CS.XUiWidget))
    self._TextWidget:AddBeginDragListener(self._TextBeginDragCallback)
    self._TextWidget:AddEndDragListener(self._TextEndDragCallback)
end

function XUiPanelAnniversaryPreHeatingContent:_RefreshText()
    XScheduleManagerPro.UnSchedule(self._OnTextScrollTimer, self)
    local config = self._Control:GetContentConfigById(self._ContentId)
    self.TxtActiviyTitle.text = config.Title
    self.TxtActiviyDetail.text = config.Desc
    self.PanelTxt.gameObject:SetActiveEx(true)
    local viewportHeight = self.ScrollList.viewport.rect.height
    local contentHeight = math.max(self.TxtActiviyDetail.preferredHeight, viewportHeight)
    self.ScrollList.content:SetSizeWithCurrentAnchors(
        CS.UnityEngine.RectTransform.Axis.Vertical, contentHeight)  -- Content的高度需要同步子物体Text的高度
    self._TextScrollDistance = contentHeight - viewportHeight
    self.ScrollList:StopMovement()
    self.ScrollList.verticalNormalizedPosition = 1  -- 滚动的起点，vertical是1
    self.ScrollList.vertical = self._TextScrollDistance > 0
    self._TextElapsedSeconds = 0
    if self._IsEnabled and self._TextScrollDistance > 0 then  -- 文本超框了才会跑马灯
        XScheduleManagerPro.ScheduleForever(self._OnTextScrollTimer, self, TickInterval)
    end
end

function XUiPanelAnniversaryPreHeatingContent:_OnTextBeginDrag()
    self._IsTextDragging = true
    self._TextElapsedSeconds = 0
end

function XUiPanelAnniversaryPreHeatingContent:_OnTextEndDrag()
    self._IsTextDragging = false
    self._TextElapsedSeconds = 0
end

function XUiPanelAnniversaryPreHeatingContent:_OnTextScrollTimer()
    if self._IsTextDragging then
        return
    end
    local deltaSeconds = TickInterval / XScheduleManagerPro.SECOND
    self._TextElapsedSeconds = self._TextElapsedSeconds + deltaSeconds
    if self._TextElapsedSeconds < self._TextWaitSeconds then
        return
    end
    local position = self.ScrollList.verticalNormalizedPosition
    if position <= 0 then
        self.ScrollList.verticalNormalizedPosition = 1
        self._TextElapsedSeconds = 0
        return
    end
    position = math.max(position - self._TextScrollSpeed * deltaSeconds / self._TextScrollDistance, 0)
    self.ScrollList.verticalNormalizedPosition = position
    if position == 0 then
        self._TextElapsedSeconds = 0
    end
end

--endregion

--region 奖励预览

function XUiPanelAnniversaryPreHeatingContent:_InitReward()
    self._RewardGrids = {}
    local rewardUi = XTool.InitUiObjectByUi({}, self.BubbleRewardPreview)
    self._RewardTemplate = rewardUi.Grid256New
    self._RewardTemplate.gameObject:SetActiveEx(false)
    self._BtnCloseReward = rewardUi.BtnClose
    self._BtnCloseReward.CallBack = handler(self, self._CloseReward)
    self.BtnReward.CallBack = handler(self, self._OnRewardClick)
end

function XUiPanelAnniversaryPreHeatingContent:_OnRewardClick()
    if self.BubbleRewardPreview.gameObject.activeSelf then
        self:_CloseReward()
        return
    end
    self.BubbleRewardPreview.gameObject:SetActiveEx(true)
    XTool.UpdateDynamicGridCommon(self._RewardGrids, self._Control:GetRewardList(self._ShowRewardId),
        self._RewardTemplate, self.Parent)
end

function XUiPanelAnniversaryPreHeatingContent:_CloseReward()
    self.BubbleRewardPreview.gameObject:SetActiveEx(false)
end

--endregion

--region 视频

function XUiPanelAnniversaryPreHeatingContent:_InitVideo()
    self._VideoPlayer = self.Video:GetComponent(typeof(CS.XVideoPlayerUGUI))
    self._VideoPlayer.ActionPlayed = handler(self, self._OnVideoPlayed)
    self._VideoPlayer.ActionEnded = handler(self, self._OnVideoEnded)
    self._VideoPlayer.ActionError = handler(self, self._OnVideoError)
    self._VideoClickCallback = handler(self, self._OnVideoClick)
    self._VideoWidget = self.Video:GetComponent(typeof(CS.XUiWidget))
    self._VideoWidget:AddPointerClickListener(self._VideoClickCallback)
    self.BtnPlayAgain.CallBack = self._VideoClickCallback
end

function XUiPanelAnniversaryPreHeatingContent:_StartVideo()
    if not self._CanPlayVideo then
        self:_SetVideoState(false)
        return
    end
    self._IsVideoStarting = true
    self:_SetVideoState(true)
    if not self._VideoPlayer:SetInfoByVideoId(self._VideoId) then
        self:_OnVideoError()
        return
    end
    self._VideoPlayer:RePlay()
end

function XUiPanelAnniversaryPreHeatingContent:_OnVideoClick()
    if not self._IsEnabled or not self._IsVideoActive or self._IsVideoStarting or not self._CanPlayVideo then
        return
    end
    if self._VideoPlayer:IsPaused() then  -- 继续播
        self._VideoPlayer:Resume()
        self:_SetVideoState(true)
    elseif self._VideoPlayer:IsPlaying() then  -- 暂停
        self._VideoPlayer:Pause()
        self:_SetVideoState(false)
    else -- 重播
        self:_StartVideo()
    end
end

function XUiPanelAnniversaryPreHeatingContent:_OnVideoPlayed()
    if not self._IsEnabled or not self._IsVideoActive then
        self._VideoPlayer:Stop()
        return
    end
    self._IsVideoStarting = false
end

function XUiPanelAnniversaryPreHeatingContent:_OnVideoEnded()
    if not self._IsEnabled or not self._IsVideoActive then
        return
    end
    self._IsVideoStarting = false
    self:_SetVideoState(false)
end

function XUiPanelAnniversaryPreHeatingContent:_OnVideoError()
    self._CanPlayVideo = false
    self._IsVideoStarting = false
    if self._IsEnabled and self._IsVideoActive then
        self:_SetVideoState(false)
    end
end

function XUiPanelAnniversaryPreHeatingContent:_SetVideoState(isPlaying) -- 根据视频播放状态刷新相关UI
    if isPlaying then
        self.PanelTxt.gameObject:SetActiveEx(false)
        XScheduleManagerPro.UnSchedule(self._OnTextScrollTimer, self)
        self._IsTextDragging = false
        self.BubbleRewardPreview.gameObject:SetActiveEx(false)
    else
        self:_RefreshText()
    end
    self.BtnPlayAgain.gameObject:SetActiveEx(not isPlaying and self._CanPlayVideo)
    self.BtnReward.gameObject:SetActiveEx(not isPlaying and self._HasReward)
end

--endregion

return XUiPanelAnniversaryPreHeatingContent
