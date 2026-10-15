local XUiGridSkyTower3DBase = require("XUi/XUiSkyTower/XUiGrid/3D/XUiGridSkyTower3DBase")
local XUiCommonDraggable = require("XUi/XUiCommon/XCommonDrag/XUiCommonDraggable")

---@class XUiGridSkyTower3DWorkBench : XUiGridSkyTower3DBase
---@field ImgQuality UnityEngine.UI.Image
---@field RImgIcon UnityEngine.UI.RawImage
---@field ImgFull UnityEngine.UI.Image
---@field TxtCount UnityEngine.UI.Text
---@field Add UnityEngine.UI.RawImage
---@field BtnClick XUiComponent.XUiButton
---@field CanvasGroupRoot UnityEngine.CanvasGroup 拖动时源工位变淡用
---@field PanelHighlight UnityEngine.RectTransform 悬浮可放入高亮
---@field PanelDisable UnityEngine.RectTransform 不可放入标记
---@field _Control XSkyTowerControl
local XUiGridSkyTower3DWorkBench = XClass(XUiGridSkyTower3DBase, "XUiGridSkyTower3DWorkBench")

function XUiGridSkyTower3DWorkBench:InitUi()
    self.BubbleSkillTip.gameObject:SetActiveEx(false)
end

function XUiGridSkyTower3DWorkBench:InitCb()
    self.BtnClick:AddEventListener(handler(self, self.OnBtnClick))
end

function XUiGridSkyTower3DWorkBench:OnEnable()
    self:AddEventListener()
    -- 隐藏期间数据可能已经变化，重新开启时补一次刷新
    self:OnRefresh()
end

function XUiGridSkyTower3DWorkBench:OnDisable()
    self:RemoveEventListener()
end

function XUiGridSkyTower3DWorkBench:OnDestroy()
    self:RemoveEventListener()
    self:ReleaseDraggable()
end

-- 进对象池前清理：Grid会被复用到其他工位
function XUiGridSkyTower3DWorkBench:OnRecycle()
    self:ResetDraggable()
    self.BubbleSkillTip.gameObject:SetActiveEx(false)
    self:Hide()
    self.FloorId = nil
    self.Index = nil
    self.CurState = nil
    self.LastState = nil
    self.Target = nil
end

function XUiGridSkyTower3DWorkBench:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_WORK_POS_CHANGE, self.OnWorkPosChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_SKILL_ACTIVE_CHANGE, self.OnCharacterChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_STAFF_CHANGE, self.OnCharacterChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_DATA_CHANGE, self.OnCharacterChange, self)
end

function XUiGridSkyTower3DWorkBench:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_WORK_POS_CHANGE, self.OnWorkPosChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_SKILL_ACTIVE_CHANGE, self.OnCharacterChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_STAFF_CHANGE, self.OnCharacterChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_DATA_CHANGE, self.OnCharacterChange, self)
end

---工位数据变化
---@param floorId number 变化的楼层
---@param index number 变化的工位下标，为空表示整层工位都变化了
function XUiGridSkyTower3DWorkBench:OnWorkPosChange(floorId, index)
    if floorId == self.FloorId and (not XTool.IsNumberValid(index) or index == self.Index) then
        self:OnRefresh()
    else
        -- 光环的目标工位变化时，发出方的失效气泡也要同步刷新
        self:RefreshSkillTip()
    end
    self:RefreshRedPoint()
end

---角色数据变化
function XUiGridSkyTower3DWorkBench:OnCharacterChange()
    self:RefreshSkillTip()
    self:RefreshRedPoint()
end

-- 刷新工作台显示
---@param floorId number 楼层Id，不传沿用上一次缓存的工位坐标
---@param index number 工位下标
function XUiGridSkyTower3DWorkBench:OnRefresh(floorId, index)
    --等待交换回包的副本保留松手时的内容，避免回包事件先把它刷成原工位的新内容
    if self._IsSwapWaiting then
        return
    end
    -- 允许无参调用，走上一次缓存的工位坐标
    if XTool.IsNumberValid(floorId) and XTool.IsNumberValid(index) then
        self.FloorId = floorId
        self.Index = index
        -- 首次显示和对象池复用时补刷红点，每帧无参刷新不重复检查
        self:RefreshRedPoint()
    end
    if not XTool.IsNumberValid(self.FloorId) or not XTool.IsNumberValid(self.Index) then
        return
    end
    local state = self._Control:GetWorkState(self.FloorId, self.Index)
    self.CurState = state
    self:OnGlobalUpdate(state)
end

-- 沿用详情页的单技能选择规则，只展示当前真实布局下未生效的那一条
function XUiGridSkyTower3DWorkBench:RefreshSkillTip()
    -- 交换副本冻结整份显示，技能推送也不能提前改掉松手时的内容
    if self._IsSwapWaiting then
        return
    end
    if self._IsDragClone or not XTool.IsNumberValid(self.FloorId) or not XTool.IsNumberValid(self.Index) then
        self.BubbleSkillTip.gameObject:SetActiveEx(false)
        return
    end
    local characterId, skillId, state = self._Control:GetStaffSkillEffectList(self.FloorId, self.Index)
    local showTip = state == XMVCA.XSkyTower.SkillEffectState.NotActive
    self.BubbleSkillTip.gameObject:SetActiveEx(showTip)
    if showTip then
        local iconType = self._Control:GetSkillIconType(characterId, skillId)
        self.IconSkillType:SetSprite(self._Control:GetClientConfigValue("SkillTypeIcon", iconType))
    end
end

---全局更新
---@param state number 工位表现状态
function XUiGridSkyTower3DWorkBench:OnGlobalUpdate(state)
    local floorId, index = self.FloorId, self.Index
    --主动停工仍保留角色、产品和停工图标；详情页是否可加速另按IsRunning判断
    local hasWork = state ~= XMVCA.XSkyTower.WorkState.Free
    local isWorking = self._Control:IsWorking(floorId, index)
    local isPause = state == XMVCA.XSkyTower.WorkState.Pause
    local isLimitWork = self._Control:IsLimitWork(floorId, index)
    local qualityIcon

    self.PanelCount.gameObject:SetActiveEx(hasWork)
    self.ImgFull.gameObject:SetActiveEx(hasWork and self._Control:GetServerState(floorId, index) == XMVCA.XSkyTower.ServerWorkState.WaitForStorage)
    self.ImgProgress.gameObject:SetActiveEx(isWorking)
    self.TagRoleType.gameObject:SetActiveEx(hasWork)
    self.TagRoleTypeNormal.gameObject:SetActiveEx(hasWork and not isLimitWork)
    self.TagRoleTypeDisable.gameObject:SetActiveEx(hasWork and isLimitWork)
    self.Add.gameObject:SetActiveEx(not hasWork and not isLimitWork)
    self.ImgStop.gameObject:SetActiveEx(isPause)
    self.RImgIcon.gameObject:SetActiveEx(hasWork)
    self.ImgTagIcon.gameObject:SetActiveEx(not hasWork and isLimitWork)

    if hasWork then
        local icon = self._Control:GetWorkPosProductIcon(floorId, index)
        self.RImgIcon:SetRawImage(icon)
        local txt = isPause and XUiHelper.GetText("GoldenMinerStopTipsTitle") or XUiHelper.GetTime(self._Control:GetCountDown(floorId, index), XUiHelper.TimeFormatType.MINUTE_SECOND)
        self.TxtCount.text = txt
        local productId = self._Control:GetProductId(floorId, index)
        local workType = self._Control:GetWorkType(floorId, index)
        qualityIcon = self._Control:GetProductQualityIcon(workType, productId, true)
        local workTypeIcon = self._Control:GetClientConfigValue("WorkTypeIcon", workType)
        self.ImgTagIcon1:SetSprite(workTypeIcon)
        self.ImgTagIcon2:SetSprite(workTypeIcon)
    else
        if isLimitWork then
            --限定工位为空时，显示该指定工作的Icon，不显示加号
            local workType = self._Control:GetFloorAppointWorkByIndex(floorId, index)
            self.ImgTagIcon:SetSprite(self._Control:GetClientConfigValue("WorkTypeIcon", workType))
        end
        qualityIcon = self._Control:GetCommonQualityIcon(true)
    end
    if isWorking then
        local progress = self._Control:GetWorkProgress(floorId, index)
        self.ImgProgress.fillAmount = progress
    end
    self.ImgQuality:SetSprite(qualityIcon)
    self.LastState = state
end

function XUiGridSkyTower3DWorkBench:OnBtnClick()
    if self._DragHost and self._DragHost:IsWorkPosSwapPending() then
        return
    end
    if not XTool.IsNumberValid(self.FloorId) or not XTool.IsNumberValid(self.Index) then
        return
    end
    local workType = self._Control:GetWorkType(self.FloorId, self.Index)
    XLuaUiManager.Open("UiSkyTowerWork", workType, self.Index, self.FloorId)
end

function XUiGridSkyTower3DWorkBench:RefreshRedPoint()
    -- 克隆体只是跟手的一份表现，不参与红点
    if self._IsDragClone or XTool.UObjIsNil(self.RedPoint) then
        return
    end
    if not XTool.IsNumberValid(self.FloorId) or not XTool.IsNumberValid(self.Index) then
        return
    end
    self.RedPoint.gameObject:SetActiveEx(self._Control:CheckWorkBenchRedPoint(self.Index, self.FloorId))
end

--region 拖动换位
-- 声明本工位为拖动源与落点
---@param host XUiSkyTowerCommon 持有拖拽上下文的界面
function XUiGridSkyTower3DWorkBench:InitDraggable(host)
    if not host then
        return
    end
    local context = host:GetDragContext()
    if not context then
        return
    end
    self._DragHost = host
    if self._Draggable then
        self:ResetDraggable()
        return
    end
    -- 按钮事件与拖动会互抢指针，点击改由拖动源的OnClick派发
    self.BtnClick.enabled = false
    ---@type XUiCommonDraggable
    self._Draggable = XUiCommonDraggable.New(self.BtnClick.transform, {
        Context = context,
        -- 3D工位每帧被重定位，故用Direct
        Mode = XEnumConst.CommonDrag.TriggerMode.Direct,
        CanDrag = function()
            return self:CanDrag()
        end,
        GetPayload = function()
            return self:GetWorkPosKey()
        end,
        CloneFactory = function(payload)
            return host:CreateDragClone(payload)
        end,
        CloneRecycle = function(cloneObj)
            host:RecycleDragClone(cloneObj)
        end,
        OnClick = function()
            self:OnBtnClick()
        end,
    })
    self._Draggable:SetOnDragBegin(function()
        host:OnWorkPosDragBegin(self:GetWorkPosKey())
    end)
    self._Draggable:SetOnDragEnd(function()
        host:OnWorkPosDragEnd()
    end)
end

function XUiGridSkyTower3DWorkBench:ReleaseDraggable()
    if self._Draggable then
        self._Draggable:Destroy()
        self._Draggable = nil
    end
    self._DragHost = nil
end

-- 格子复用到新工位时重置拖动状态，避免沿用上一个工位的拖动进度
function XUiGridSkyTower3DWorkBench:ResetDraggable()
    if self._Draggable then
        self._Draggable:Reset()
    end
    self:SetSwapHidden(false)
    self:SetDragSourceFaded(false)
    self:SetDropHighlight(false)
    self:SetDropDisable(false)
end

-- 改造成跟手克隆体：上下文只写anchoredPosition，锚点与轴心必须都落在中心
function XUiGridSkyTower3DWorkBench:SetupAsDragClone()
    self._IsDragClone = true
    -- 跟手不显示技能气泡
    self.BubbleSkillTip.gameObject:SetActiveEx(false)
    local center = CS.UnityEngine.Vector2(0.5, 0.5)
    self.Transform.anchorMin = center
    self.Transform.anchorMax = center
    self.Transform.pivot = center
    self.BtnClick.enabled = false
    self.RedPoint.gameObject:SetActiveEx(false)
    self:SetDragSourceFaded(false)
    self:SetDropHighlight(false)
    self:SetDropDisable(false)
    if not XTool.UObjIsNil(self.CanvasGroupRoot) then
        self.CanvasGroupRoot.blocksRaycasts = false
    end
    if self.StandIcon then
        local characterId = self._Control:GetCharacterId(self.FloorId, self.Index)
        local hasCharacter = XTool.IsNumberValid(characterId)
        self.RoleHead.gameObject:SetActiveEx(hasCharacter)
        if hasCharacter then
            local portrait = self._Control:GetCharacterPortrait(characterId)
            self.StandIcon:SetRawImageEx(portrait)
        end
    end
end

---@return boolean 工位上有角色才可拖
function XUiGridSkyTower3DWorkBench:CanDrag()
    if self._DragHost and self._DragHost:IsWorkPosSwapPending() then
        return false
    end
    if not XTool.IsNumberValid(self.FloorId) or not XTool.IsNumberValid(self.Index) then
        return false
    end
    return XTool.IsNumberValid(self._Control:GetCharacterId(self.FloorId, self.Index))
end

---@return number 工位复合键，拖动上下文用它做落点唯一Id
function XUiGridSkyTower3DWorkBench:GetWorkPosKey()
    return self._Control:MakeWorkPosKey(self.FloorId, self.Index)
end

-- 源工位变淡（拖动中内容跟着克隆体走，源工位不能隐藏）
function XUiGridSkyTower3DWorkBench:SetDragSourceFaded(isFaded)
    self._IsDragSourceFaded = isFaded
    if XTool.UObjIsNil(self.CanvasGroupRoot) then
        return
    end
    self.CanvasGroupRoot.alpha = self._IsSwapHidden and 0 or (isFaded and XMVCA.XSkyTower.DragSourceAlpha or 1)
end

--真实格子继续刷新，但等待期间由固定在交换位置的副本负责显示
function XUiGridSkyTower3DWorkBench:SetSwapHidden(isHidden)
    self._IsSwapHidden = isHidden
    self:SetDragSourceFaded(self._IsDragSourceFaded)
end

function XUiGridSkyTower3DWorkBench:SetSwapWaiting(isWaiting)
    self._IsSwapWaiting = isWaiting
end

-- 悬浮在本工位且可放入时的高亮
function XUiGridSkyTower3DWorkBench:SetDropHighlight(isOn)
    if XTool.UObjIsNil(self.PanelHighlight) then
        return
    end
    self.PanelHighlight.gameObject:SetActiveEx(isOn)
end

-- 不可放入标记，拖动期间常显，与是否悬浮无关
function XUiGridSkyTower3DWorkBench:SetDropDisable(isOn)
    if XTool.UObjIsNil(self.PanelDisable) then
        return
    end
    self.PanelDisable.gameObject:SetActiveEx(isOn)
end

-- 淡化态刷新，只有拖动源本身变淡
---@param fromKey number 拖动源工位复合键，为空表示拖动结束
function XUiGridSkyTower3DWorkBench:RefreshDragSourceFaded(fromKey)
    if not XTool.IsNumberValid(fromKey) then
        self:SetDragSourceFaded(false)
        return
    end
    self:SetDragSourceFaded(self:GetWorkPosKey() == fromKey)
end

-- 不可放入标记刷新，拖动源自身不标记
---@param fromKey number 拖动源工位复合键，为空表示拖动结束
function XUiGridSkyTower3DWorkBench:RefreshDropDisable(fromKey)
    if not XTool.IsNumberValid(fromKey) then
        self:SetDropDisable(false)
        return
    end
    if self:GetWorkPosKey() == fromKey then
        self:SetDropDisable(false)
        return
    end
    local fromFloorId, fromIndex = self._Control:ParseWorkPosKey(fromKey)
    self:SetDropDisable(not self._Control:CanDropWorkPos(fromFloorId, fromIndex, self.FloorId, self.Index))
end

-- 悬浮态刷新，只有可放入的工位才亮高亮
---@param fromKey number 拖动源工位复合键
---@param isHover boolean 指针是否悬浮在本工位上
function XUiGridSkyTower3DWorkBench:RefreshDropHover(fromKey, isHover)
    if not isHover or not XTool.IsNumberValid(fromKey) then
        self:SetDropHighlight(false)
        return
    end
    local selfKey = self:GetWorkPosKey()
    if selfKey == fromKey then
        self:SetDropHighlight(false)
        return
    end
    local fromFloorId, fromIndex = self._Control:ParseWorkPosKey(fromKey)
    self:SetDropHighlight(self._Control:CanDropWorkPos(fromFloorId, fromIndex, self.FloorId, self.Index))
end
--endregion

return XUiGridSkyTower3DWorkBench
