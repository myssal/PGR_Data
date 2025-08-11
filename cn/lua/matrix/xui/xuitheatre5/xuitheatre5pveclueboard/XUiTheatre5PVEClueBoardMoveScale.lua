---线索板移动和缩放
---@class XUiTheatre5PVEClueBoardMoveScale: XUiNode
---@field protected _Control XTheatre5Control
local XUiTheatre5PVEClueBoardMoveScale = XClass(XUiNode, 'XUiTheatre5PVEClueBoardMoveScale')
local Vector3 = CS.UnityEngine.Vector3
local Vector2 = CS.UnityEngine.Vector2
local Vector3Zero = CS.UnityEngine.Vector3.zero
local Screen = CS.UnityEngine.Screen
local UiCamera = CS.XUiManager.Instance.UiCamera
local Offset = 0.001 --数值误差
function XUiTheatre5PVEClueBoardMoveScale:OnStart()
    self._BoundCorner = {}
    self:InitData()
    XUiHelper.RegisterSliderChangeEvent(self, self.ScaleSlider, self.OnSliderChanged, true)
    self.BtnAdd:AddEventListener(handler(self, self.OnClickAdd))
    self.BtnMinus:AddEventListener(handler(self, self.OnClickMinus))
    self._Timer = XScheduleManager.ScheduleForever(handler(self, self.OnRefreshSliderScale), 100, 0)
    self._MaskScaleTimer = XScheduleManager.ScheduleForever(handler(self, self.OnRefreshMaskScale), 20, 0) --频率高些，不然卡ppt
end

function XUiTheatre5PVEClueBoardMoveScale:InitData()
    self._DragAreaMinValue = self.DragArea.MinScale
    self._DragAreaMaxValue = self.DragArea.MaxScale
    self._MaskMinValue = self._Control.PVEControl:GetClueBoardMaskScaleMinOrMax(true)
    self._MaskMaxValue = self._Control.PVEControl:GetClueBoardMaskScaleMinOrMax()
    self.ScaleSlider.minValue = self._DragAreaMinValue
    self.ScaleSlider.maxValue = self._DragAreaMaxValue
    self.ScaleSlider.value = self._DragAreaMinValue
    self.DragArea.transform.localScale = Vector3(self._DragAreaMinValue, self._DragAreaMinValue, 1)
    self.RImgBgMask.transform.localScale = Vector3(self._MaskMaxValue, self._MaskMaxValue, 1)
    self._ClueBoardScaleLimitPoint = self._Control.PVEControl:GetClueBoardScaleLimitPoint()
    self._AreaWidth = self._Control.PVEControl:GetMainClueBoardRect(true)
    self._AreaHeight = self._Control.PVEControl:GetMainClueBoardRect()
    self._FocusTime = self._Control.PVEControl:GetClueBoardFocusTime()
    local processStep = self._Control.PVEControl:GetClueBoardProcessStep()
    self._StepValue = (self.DragArea.MaxScale - self.DragArea.MinScale) /processStep

end

function XUiTheatre5PVEClueBoardMoveScale:Update(mainClueCfgs)
    if XTool.IsTableEmpty(mainClueCfgs) then
        return
    end
    local posTransList = {}
    local focusPosTrans
    local curIndex = 0
    for k, clueCfg in pairs(mainClueCfgs) do
        local posTrans = XUiHelper.TryGetComponent(self.LayerClueFirst, tostring(clueCfg.Index), nil)
        if posTrans then
            local clueState = self._Control.PVEControl:GetClueState(clueCfg.Id)
            if clueState ~= XMVCA.XTheatre5.EnumConst.PVEClueState.NoShow and clueState ~= XMVCA.XTheatre5.EnumConst.PVEClueState.Lock then
                table.insert(posTransList, posTrans) 
                if clueState == XMVCA.XTheatre5.EnumConst.PVEClueState.Deduce then  --优先定位可推演的
                    curIndex = math.huge
                    focusPosTrans = posTrans
                end
                if clueCfg.Index > curIndex then
                    curIndex = clueCfg.Index
                    focusPosTrans = posTrans
                end    
            end    
        end        
    end
    self:CalculateBounds(posTransList)
    if focusPosTrans then
        self:FocusTarget(focusPosTrans)
    end            
end

function XUiTheatre5PVEClueBoardMoveScale:CalculateBounds(posTransList)
    if XTool.IsTableEmpty(posTransList) then
        self.MoveArea.position = self.DragArea.transform.position
        self.MoveArea.sizeDelta = self.PanelCharacter.sizeDelta --赋予最大的拖拽区域
        return
    end
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    for _, pos in ipairs(posTransList) do
        minX = math.min(minX, pos.localPosition.x)
        maxX = math.max(maxX, pos.localPosition.x)
        minY = math.min(minY, pos.localPosition.y)
        maxY = math.max(maxY, pos.localPosition.y)
    end
    local addWidth = self._AreaWidth --* self.DragArea.transform.localScale.x
    local addHeigh = self._AreaHeight --* self.DragArea.transform.localScale.y
    minX = minX - addWidth/2
    maxX = maxX + addWidth/2
    minY = minY - addHeigh/2
    maxY = maxY + addHeigh/2

    local centerX = (minX + maxX) / 2
    local centerY = (minY + maxY) / 2
    local width = maxX - minX
    local height = maxY - minY

    local worldPos = self.LayerClueFirst:TransformPoint(Vector3(centerX, centerY, 0))
    self.MoveArea.position = worldPos
    --self.MoveArea.localPosition = Vector3(centerX, centerY, 0)
    self.MoveArea.sizeDelta = Vector2(width, height)
end

function XUiTheatre5PVEClueBoardMoveScale:FocusTarget(focusPosTrans)
    if not focusPosTrans then
        return
    end
        
    local scale = self:GetDragAreaScaleX()
    self.DragArea:FocusTarget(focusPosTrans, scale, 0.25, Vector3Zero)
end

function XUiTheatre5PVEClueBoardMoveScale:FocusToDetailClue(focusPosTrans)
    if not focusPosTrans then
        return
    end
    self.ScaleSlider.value = self._ClueBoardScaleLimitPoint 
    self.DragArea:FocusTarget(focusPosTrans, self._ClueBoardScaleLimitPoint, self._FocusTime, Vector3Zero)   
end

function XUiTheatre5PVEClueBoardMoveScale:OnSliderChanged(value)
    local scaleX = self:GetDragAreaScaleX()
    local changeValue = math.abs(value - scaleX)
    if changeValue < Offset then
        return
    end
    local centerPos = UiCamera:ScreenToWorldPoint(Vector3(Screen.width / 2, Screen.height / 2, self.DragArea.transform.position.z))
    self.DragArea:FocusPos(centerPos, value, 0, Vector3Zero)  --给C#组件的缩放赋值，不然两端不一致  
    self:OnChangeScale(value)  
end

function XUiTheatre5PVEClueBoardMoveScale:OnClickAdd()
    self.ScaleSlider.value = self.ScaleSlider.value + self._StepValue
end

function XUiTheatre5PVEClueBoardMoveScale:OnClickMinus()
    self.ScaleSlider.value = self.ScaleSlider.value - self._StepValue
end

--手指或滚轮缩放时
function XUiTheatre5PVEClueBoardMoveScale:OnRefreshSliderScale()
    local scaleX = self:GetDragAreaScaleX()
    local changeValue = math.abs(self.ScaleSlider.value - scaleX)
    if changeValue < Offset then
        return
    end
    self.ScaleSlider.value = scaleX
    self:OnChangeScale(self.ScaleSlider.value)    
end

function XUiTheatre5PVEClueBoardMoveScale:OnRefreshMaskScale()
    local scaleX = self:GetDragAreaScaleX()
    local DragAreaInterval = self._DragAreaMaxValue - self._DragAreaMinValue
    local maskInterval = self._MaskMaxValue - self._MaskMinValue
    if not XTool.IsNumberValid(DragAreaInterval) then
        return
    end
    local factor =  maskInterval/DragAreaInterval
    local targetValue = self._MaskMaxValue - (scaleX - self._DragAreaMinValue) * factor
    self.RImgBgMask.transform.localScale = Vector3(targetValue, targetValue, 1)  
end

function XUiTheatre5PVEClueBoardMoveScale:OnChangeScale(value)
      if self.Parent:IsDetailsShow() then
        if value + Offset < self._ClueBoardScaleLimitPoint then
            self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_CLUE_BOARD_SWITCH, false)
        end
    else
        if value + Offset >= self._ClueBoardScaleLimitPoint then
            self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_CLUE_BOARD_SWITCH, true)
        end
    end
    self.DragArea.transform.localScale = Vector3(value, value, 1)            
    self.DragArea:ActiveCheckArea()
end

function XUiTheatre5PVEClueBoardMoveScale:GetDragAreaScaleX()
     return self.DragArea.transform.localScale.x
end

function XUiTheatre5PVEClueBoardMoveScale:OnDestroy()
     if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end

    if self._MaskScaleTimer then
        XScheduleManager.UnSchedule(self._MaskScaleTimer)
        self._MaskScaleTimer = false
    end    
    self._BoundCorner = nil
    self._ClueBoardScaleLimitPoint = nil
    self._AreaWidth = nil
    self._AreaHeight = nil
    self._FocusTime = nil
    self._DragAreaMinValue = nil
    self._DragAreaMaxValue = nil
    self._MaskMinValue = nil
    self._MaskMaxValue = nil
end

return XUiTheatre5PVEClueBoardMoveScale