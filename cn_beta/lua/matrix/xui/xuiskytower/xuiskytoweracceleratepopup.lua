---@class XUiSkyTowerAcceleratePopup : XLuaUi
---@field _Control XSkyTowerControl
local XUiSkyTowerAcceleratePopup = XLuaUiManager.Register(XLuaUi, "UiSkyTowerAcceleratePopup")

--region 生命周期
function XUiSkyTowerAcceleratePopup:OnAwake()
    self:RegisterUiEvents()
end

function XUiSkyTowerAcceleratePopup:OnStart(floorId, index, count)
    self._FloorId = floorId
    self._Index = index
    self._Count = count or 1
    local itemId = self._Control:GetIntConfigValue("SpeedUpItemId")
    self.RImgIcon:SetRawImage(self._Control:GetItemIcon(itemId))
    self.TxtProductMax.text = self._Control:GetClientConfigText("AcceleratePopupText", 3)
    self.TxtProductLack.text = self._Control:GetClientConfigText("AcceleratePopupText", 4)
end

function XUiSkyTowerAcceleratePopup:OnEnable()
    self:RefreshView()
end
--endregion

--region 事件
function XUiSkyTowerAcceleratePopup:OnGetLuaEvents()
    return {
        XEventId.EVENT_SKY_TOWER_DATA_CHANGE,
        XEventId.EVENT_SKY_TOWER_STORAGE_CHANGE,
        XEventId.EVENT_SKY_TOWER_WORK_POS_CHANGE,
        XEventId.EVENT_SKY_TOWER_FLOOR_CHANGE,
        XEventId.EVENT_SKY_TOWER_LEVEL_CHANGE,
        XEventId.EVENT_SKY_TOWER_SKILL_ACTIVE_CHANGE,
        XEventId.EVENT_SKY_TOWER_STAFF_CHANGE,
    }
end

function XUiSkyTowerAcceleratePopup:OnNotify(event, ...)
    self:RefreshView()
end
--endregion

--region 界面刷新
function XUiSkyTowerAcceleratePopup:RefreshView()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self._MaxCount = self._Control:GetSpeedUpSelectableMaxCount()
    local workInfo = self._Control:GetWorkPos(self._FloorId, self._Index)
    self.RImgProduct:SetRawImageEx(self._Control:GetSpeedUpProductIcon(workInfo))
    self:SetCount(self._Count)
end

function XUiSkyTowerAcceleratePopup:SetCount(count)
    self._Count = math.min(self._MaxCount, math.max(1, count))
    self.TxtNum.text = self._Count
    self.TxtCont.text = self._Control:GetClientConfigText("AcceleratePopupText", 2, self._Count)
    local totalTime = self._Count * self._Control:GetIntConfigValue("AccelerateTime")
    self.TxtSpeedTime.text = self._Control:GetClientConfigText("AcceleratePopupText", 1, totalTime)
    self:RefreshProduct(totalTime)
    self:RefreshButtons()
end

function XUiSkyTowerAcceleratePopup:RefreshProduct(totalTime)
    local workInfo = self._Control:GetWorkPos(self._FloorId, self._Index)
    local count, isFull, isLack = self._Control:GetSpeedUpProductPreview(self._FloorId, self._Index, workInfo, totalTime)
    self._IsFull = isFull
    self._IsLack = isLack
    self.TxtProductCount.text = count
    self.TxtProductMax.gameObject:SetActiveEx(isFull)
    self.TxtProductLack.gameObject:SetActiveEx(isLack)
end

function XUiSkyTowerAcceleratePopup:RefreshButtons()
    local disableReduce = self._Count <= 1
    local disableAdd = not self:CanAddCount()
    local disableConfirm = self._Count <= 0 or not self._Control:CheckCanAccelerate(self._FloorId, self._Index)
    self.BtnReduce:SetDisable(disableReduce, not disableReduce)
    self.BtnAdd:SetDisable(disableAdd, not disableAdd)
    self.BtnMax:SetDisable(disableAdd, not disableAdd)
    self.BtnConfirm:SetDisable(disableConfirm, not disableConfirm)
end

function XUiSkyTowerAcceleratePopup:CanAddCount()
    return self._Count < self._MaxCount and not self._IsFull and not self._IsLack
end
--endregion

--region 按钮
function XUiSkyTowerAcceleratePopup:RegisterUiEvents()
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnCancel:AddEventListener(handler(self, self.OnBtnCancelClick))
    self.BtnReduce:AddEventListener(handler(self, self.OnBtnReduceClick))
    self.BtnAdd:AddEventListener(handler(self, self.OnBtnAddClick))
    self.BtnMax:AddEventListener(handler(self, self.OnBtnMaxClick))
    self.BtnConfirm:AddEventListener(handler(self, self.OnBtnConfirmClick))
end

function XUiSkyTowerAcceleratePopup:OnBtnReduceClick()
    self:SetCount(self._Count - 1)
end

function XUiSkyTowerAcceleratePopup:OnBtnAddClick()
    if not self:CanAddCount() then
        return
    end
    self:SetCount(self._Count + 1)
end

function XUiSkyTowerAcceleratePopup:OnBtnMaxClick()
    if not self:CanAddCount() then
        return
    end
    local workInfo = self._Control:GetWorkPos(self._FloorId, self._Index)
    local accelerateTime = self._Control:GetIntConfigValue("AccelerateTime")
    local maxCount = self._MaxCount
    for count = self._Count + 1, self._MaxCount do
        local _, isFull, isLack = self._Control:GetSpeedUpProductPreview(self._FloorId, self._Index, workInfo, count * accelerateTime)
        if isFull or isLack then
            maxCount = count
            break
        end
    end
    self:SetCount(maxCount)
end

function XUiSkyTowerAcceleratePopup:OnBtnCloseClick()
    self:Close()
end

function XUiSkyTowerAcceleratePopup:OnBtnCancelClick()
    self:Close()
end

function XUiSkyTowerAcceleratePopup:OnBtnConfirmClick()
    self._Control:RequestUseSpeedUpItem(self._FloorId, self._Index, self._Count, function()
        self:Close()
    end)
end
--endregion

return XUiSkyTowerAcceleratePopup
-endregion

return XUiSkyTowerAcceleratePopup
