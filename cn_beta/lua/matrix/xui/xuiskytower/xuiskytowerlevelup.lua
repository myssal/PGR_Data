local RowTypeEnum = XMVCA.XSkyTower.LevelUpRowType
local UnlockItemType = XMVCA.XSkyTower.UnlockItemType
local SkyTowerCoin = XMVCA.XSkyTower.ItemId.SkyTowerCoin

--镜头blend结束的轮询间隔，单位毫秒
local BlendCheckInterval = 100
local BlendTimeOut = 3000

---@class XUiSkyTowerLevelUp : XLuaUi 楼层升级弹窗
---@field _Control XSkyTowerControl
local XUiSkyTowerLevelUp = XLuaUiManager.Register(XLuaUi, "UiSkyTowerLevelUp")

function XUiSkyTowerLevelUp:OnAwake()
    XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
    self.BtnLevelUp:AddEventListener(handler(self, self.OnBtnLevelUpClick))
    self.BtnEmpty:AddEventListener(handler(self, self.Close))
end

function XUiSkyTowerLevelUp:OnStart()
    self._UnlockAreaDefaultValue = self._Control:GetIntClientConfigValue("UnlockAreaDefaultValue")
    ---顿号（、）
    self._Symbol1 = self._Control:GetClientConfigText("Symbol", 1)
    ---&
    self._Symbol2 = self._Control:GetClientConfigText("Symbol", 2)
    ---@type XUiGridSkyTowerLevelUpBuff
    self._GridWork = require("XUi/XUiSkyTower/XUiGrid/XUiGridSkyTowerLevelUpBuff").New(self.GridWork, self)
    --self._GridWork:SetLimitShowCount(self._Control:GetIntClientConfigValue("FloorLevelUpMaxShowItemCount", 1))
    ---@type XUiGridSkyTowerLevelUpBuff
    --self._GridDrance = require("XUi/XUiSkyTower/XUiGrid/XUiGridSkyTowerLevelUpBuff").New(self.GridDrance, self)
    --self._GridDrance:SetLimitShowCount(self._Control:GetIntClientConfigValue("FloorLevelUpMaxShowItemCount", 2))
    self._CoinCount = self._Control:GetItemCount(SkyTowerCoin)
end

function XUiSkyTowerLevelUp:OnEnable()
    self.Super.OnEnable(self)
    self:AddEventListener()
    self:UpdateView()
    self:UpdateItem()
    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_HIDE_UI, true)
end

function XUiSkyTowerLevelUp:OnDisable()
    self:RemoveEventListener()
    self:StopWaitCameraBlend()
    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_HIDE_UI, false)
end

function XUiSkyTowerLevelUp:OnDestroy()
    self:StopWaitCameraBlend()
end

function XUiSkyTowerLevelUp:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_LEVEL_CHANGE, self.UpdateView, self)
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_LEVEL_CONDITION_CHANGE, self.UpdateView, self)
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_PERFORM_STATE_CHANGE, self.UpdateView, self)
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_DATA_CHANGE, self.UpdateItem, self)
end

function XUiSkyTowerLevelUp:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_LEVEL_CHANGE, self.UpdateView, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_LEVEL_CONDITION_CHANGE, self.UpdateView, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_PERFORM_STATE_CHANGE, self.UpdateView, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_DATA_CHANGE, self.UpdateItem, self)
end

--region 界面刷新
---刷新界面，始终预览当前等级的下一级
function XUiSkyTowerLevelUp:UpdateView()
    self._CoinCount = self._Control:GetItemCount(SkyTowerCoin)
    self._CurLevel = self._Control:GetSkyTowerLv()
    self._IsMaxLevel = self._Control:IsFloorMaxLevel(self._CurLevel)
    self._TargetLv = self._IsMaxLevel and self._CurLevel or self._CurLevel + 1
    self._CurFloorId = self._Control:GetLvFloorId(self._CurLevel)
    self._TargetFloorId = self._Control:GetLvFloorId(self._TargetLv)

    self:UpdateLevelPreview()
    self:UpdateLevelUpButton()
    self:UpdateList()
end

function XUiSkyTowerLevelUp:UpdateLevelPreview()
    self.TxtLvBefore.text = string.format("LV.%d", self._CurLevel)
    if self._IsMaxLevel then
        self.Arrow.gameObject:SetActiveEx(false)
        self.TxtLvAfter.gameObject:SetActiveEx(false)
    else
        self.Arrow.gameObject:SetActiveEx(true)
        self.TxtLvAfter.gameObject:SetActiveEx(true)
        self.TxtLvAfter.text = string.format("LV.%d", self._TargetLv)
    end
end

function XUiSkyTowerLevelUp:UpdateItem()
    self._CoinCount = self._Control:GetItemCount(SkyTowerCoin)
    self:UpdateLevelUpButton()
end

---升级按钮：满级禁用，条件未满足时显示事件入口，其余显示下一级金币消耗
function XUiSkyTowerLevelUp:UpdateLevelUpButton()
    if self._IsMaxLevel then
        --满级走Disable样式，不触发回调
        self.BtnLevelUp:SetDisable(true, false)
        self.BtnLevelUp:ShowReddot(false)
        self.PanelMaxLv.gameObject:SetActiveEx(true)
        self.PanelFinishEvent.gameObject:SetActiveEx(false)
        self.AbleLevelUp = false
        return
    end

    local isUnlock, desc = self._Control:GetFloorUnlockCondition(self._CurLevel + 1)
    if not isUnlock then
        self.BtnLevelUp:SetDisable(true, true)
        self.BtnLevelUp:ShowReddot(false)
        self.BtnLevelUp:SetNameByGroup(1, desc)
        self.PanelMaxLv.gameObject:SetActiveEx(false)
        self.PanelFinishEvent.gameObject:SetActiveEx(true)
        self.AbleLevelUp = false
        return
    end
    
    --显示升到下一级的金币消耗，与实际扣款口径一致
    local need = self._Control:GetFloorLevelUpTotalGold(self._TargetLv)
    local enough = self._CoinCount >= need
    local color = self._Control:GetClientConfigValue("EnoughColor", enough and 1 or 2)
    self.AbleLevelUp = enough
    self.BtnLevelUp:SetDisable(false, true)
    self.BtnLevelUp:SetNameAndColorByGroup(0, tostring(need), XUiHelper.Hexcolor2Color(color))
    self.BtnLevelUp:ShowReddot(self.AbleLevelUp)
    self.BtnLevelUp:SetSprite(self._Control:GetItemIcon(SkyTowerCoin))
end
--endregion

--region 列表项
function XUiSkyTowerLevelUp:UpdateList()
    self._GridWork:Refresh(self:GetWorkList())
    --self._GridDrance:Refresh(self:GetDanceList())
end

function XUiSkyTowerLevelUp:GetWorkList()
    ---@type XSkyTowerLevelUpParam[]
    local datas = {}

    if not self._IsMaxLevel then
        --新楼层
        if self._CurFloorId ~= self._TargetFloorId then
            table.insert(datas, {
                RowType = RowTypeEnum.Value,
                Title = self._Control:GetClientConfigText("FloorLevelUpWorkText", 1),
                Value = self._Control:GetClientConfigText("FloorText", 1, self._TargetFloorId),
            })
        end

        --自动进入新楼层
        --if self._Control:IsDanceMoveUnlock() then
        --    table.insert(datas, {
        --        RowType = RowTypeEnum.Toggle,
        --        Title = self._Control:GetClientConfigText("FloorLevelUpWorkText", 2),
        --        Key = "FloorLevelUpWorkbench",
        --    })
        --end

        --新工位
        local workDesc = self:GetUnlockWorkDesc()
        if not string.IsNilOrEmpty(workDesc) then
            table.insert(datas, {
                RowType = RowTypeEnum.Value,
                Title = self._Control:GetClientConfigText("FloorLevelUpWorkText", 3),
                Value = workDesc,
            })
        end

        --新内容
        local functionalDesc = self:GetNewWorkFunctional()
        if not string.IsNilOrEmpty(functionalDesc) then
            table.insert(datas, {
                RowType = RowTypeEnum.Value,
                Title = self._Control:GetClientConfigText("FloorLevelUpWorkText", 4),
                Value = functionalDesc,
            })
        end
    end

    --离线收益上限（常驻）
    local oldOfflineBillAdd = self._Control:GetLvOfflineBillAdd(self._CurLevel)
    local newOfflineBillAdd = self._Control:GetLvOfflineBillAdd(self._TargetLv)
    table.insert(datas, {
        RowType = oldOfflineBillAdd == newOfflineBillAdd and RowTypeEnum.Value or RowTypeEnum.ValueChange,
        Title = self._Control:GetClientConfigText("FloorLevelUpWorkText", 5),
        Value = oldOfflineBillAdd,
        AfterValue = newOfflineBillAdd,
    })

    return datas
end

function XUiSkyTowerLevelUp:GetDanceList()
    ---@type XSkyTowerLevelUpParam[]
    local datas = {}
    local curDance = self._Control:GetDanceConfig(self._CurLevel)
    local nextDace = self._Control:GetDanceConfig(self._TargetLv)

    --金币收益（常驻）
    local oldGold, newGold = curDance.IncreaseGold, nextDace.IncreaseGold
    table.insert(datas, {
        RowType = oldGold == newGold and RowTypeEnum.Value or RowTypeEnum.ValueChange,
        Title = self._Control:GetClientConfigText("FloorLevelUpEffectText", 1),
        Value = oldGold,
        AfterValue = newGold,
    })

    --激活时间（常驻）
    local oldTime, newTime = curDance.IncreaseTime, nextDace.IncreaseTime
    table.insert(datas, {
        RowType = oldTime == newTime and RowTypeEnum.Value or RowTypeEnum.ValueChange,
        Title = self._Control:GetClientConfigText("FloorLevelUpEffectText", 2),
        Value = string.format("%ss", oldTime),
        AfterValue = string.format("%ss", newTime),
    })

    --冷却时间（常驻）
    local oldCd, newCd = curDance.DecreaseCd, nextDace.DecreaseCd
    table.insert(datas, {
        RowType = oldCd == newCd and RowTypeEnum.Value or RowTypeEnum.ValueChange,
        Title = self._Control:GetClientConfigText("FloorLevelUpEffectText", 3),
        Value = string.format("%ss", oldCd),
        AfterValue = string.format("%ss", newCd),
    })

    --之前所有等级都为空，并且下一级为空，则不显示
    local isHideIncreaseAuto, isHideDecreaseWorkTime = true, true
    for i = 1, self._TargetLv do
        local danceCfg = self._Control:GetDanceConfig(i)
        if XTool.IsNumberValid(danceCfg.IncreaseAuto) then
            isHideIncreaseAuto = false
        end
        if XTool.IsNumberValid(danceCfg.DecreaseWorkTime) then
            isHideDecreaseWorkTime = false
        end
        if not isHideIncreaseAuto and not isHideDecreaseWorkTime then
            break
        end
    end

    --自动充能速率
    if not isHideIncreaseAuto then
        local oldAuto, newAuto = curDance.IncreaseAuto / curDance.NeedEnergy, nextDace.IncreaseAuto / nextDace.NeedEnergy
        oldAuto = math.floor(oldAuto * 100)
        newAuto = math.floor(newAuto * 100)
        table.insert(datas, {
            RowType = oldAuto == newAuto and RowTypeEnum.Value or RowTypeEnum.ValueChange,
            Title = self._Control:GetClientConfigText("FloorLevelUpEffectText", 4),
            Value = string.format("%s%%", oldAuto),
            AfterValue = string.format("%s%%", newAuto),
        })
    end

    --强化工时增益
    if not isHideDecreaseWorkTime then
        local oldWorkTime, newWorkTime = curDance.DecreaseWorkTime, nextDace.DecreaseWorkTime
        table.insert(datas, {
            RowType = oldWorkTime == newWorkTime and RowTypeEnum.Value or RowTypeEnum.ValueChange,
            Title = self._Control:GetClientConfigText("FloorLevelUpEffectText", 5),
            Value = string.format("%ss", oldWorkTime),
            AfterValue = string.format("%ss", newWorkTime),
        })
    end

    if not self._IsMaxLevel then
        --强化区域拓展
        local unlockAreas = self._Control:GetDanceUnlockArea(self._TargetLv)
        if not string.IsNilOrEmpty(unlockAreas) then
            --目前只会用到一个
            local unlockArea = unlockAreas[1]
            local areaDesc
            if unlockArea == self._UnlockAreaDefaultValue then
                areaDesc = self._Control:GetClientConfigText("FloorUnlockWorkbenchText", 1)
            elseif unlockArea > 0 then
                areaDesc = self._Control:GetClientConfigText("FloorUnlockWorkbenchText", 2, unlockArea)
            else
                areaDesc = self._Control:GetClientConfigText("FloorUnlockWorkbenchText", 3, math.abs(unlockArea))
            end
            table.insert(datas, {
                RowType = RowTypeEnum.Value,
                Title = self._Control:GetClientConfigText("FloorLevelUpEffectText", 6),
                Value = areaDesc,
            })
        end

        --新功能
        local functionalDesc = self:GetNewDanceFunctional()
        if not string.IsNilOrEmpty(functionalDesc) then
            table.insert(datas, {
                RowType = RowTypeEnum.Value,
                Title = self._Control:GetClientConfigText("FloorLevelUpEffectText", 7),
                Value = functionalDesc,
            })
        end
    end

    return datas
end

--同层1个：8层左侧工位
--同层2个：8层左侧、中间工位
--同层3个：8层所有工位
--跨层属于配置错误，不实现（例如，8层左侧工位、9层右侧工位）
function XUiSkyTowerLevelUp:GetUnlockWorkDesc()
    --本次升级解锁的工位数
    local unlockWorkNum = 0
    for lv = self._CurLevel + 1, self._TargetLv do
        unlockWorkNum = unlockWorkNum + self._Control:GetLvUnlockWorkNum(lv)
    end
    if not XTool.IsNumberValid(unlockWorkNum) then
        return nil
    end
    local desc = {}
    local floorId, workPosIndex = self._Control:GetLastUnlockedWork()
    local floorMaxWork = self._Control:GetFloorWorkNum(floorId)
    --当前层还有工位时继续预览本层，避免在最高层读取不存在的下一层配置
    if workPosIndex >= floorMaxWork then
        floorId = floorId + 1
        workPosIndex = 0
        floorMaxWork = self._Control:GetFloorWorkNum(floorId)
    end
    --装入【x层】
    table.insert(desc, self._Control:GetClientConfigText("FloorText", 1, floorId))
    --装入【x侧】/【所有】
    if unlockWorkNum >= floorMaxWork then
        table.insert(desc, self._Control:GetClientConfigText("DirectionText", 4))
    else
        for i = 1, unlockWorkNum do
            if i > 1 then
                --装入【、】
                table.insert(desc, self._Symbol1)
            end
            local newIndex = (workPosIndex + i) % floorMaxWork
            newIndex = newIndex == 0 and floorMaxWork or newIndex
            table.insert(desc, self._Control:GetClientConfigText("DirectionText", newIndex))
        end
    end
    --装入【工位】
    table.insert(desc, self._Control:GetClientConfigText("WorkbenchText"))
    --拼接
    return table.concat(desc)
end

--本次升级解锁的新事件&订单&角色&物品，按类型去重
function XUiSkyTowerLevelUp:GetNewWorkFunctional()
    local desc = {}
    local performTypeHash = {}
    local hasCharacter, hasFood, hasIngredient = false, false, false
    for lv = self._CurLevel + 1, self._TargetLv do
        for _, performId in ipairs(self._Control:GetLvPerformIds(lv)) do
            local performType = self._Control:GetPerformType(performId)
            if not performTypeHash[performType] then
                if performType == XMVCA.XSkyTower.PerformType.Indent then
                    --装入【订单】
                    table.insert(desc, self._Control:GetClientConfigText("FloorUnlockNewFunctionalText", 2))
                else
                    --装入【事件】
                    table.insert(desc, self._Control:GetClientConfigText("FloorUnlockNewFunctionalText", 1))
                end
                performTypeHash[performType] = true
            end
        end
        hasCharacter = hasCharacter or not XTool.IsTableEmpty(self._Control:GetLvUnlockCharacter(lv))
        hasFood = hasFood or not XTool.IsTableEmpty(self._Control:GetLvUnlockFood(lv))
        hasIngredient = hasIngredient or not XTool.IsTableEmpty(self._Control:GetLvUnlockIngredient(lv))
    end
    --装入【角色】
    if hasCharacter then
        table.insert(desc, self._Control:GetClientConfigText("FloorUnlockNewFunctionalText", 3))
    end
    --装入【物品】
    if hasFood then
        table.insert(desc, self._Control:GetClientConfigText("FloorUnlockNewFunctionalText", 4))
    end
    --装入【原料】
    if hasIngredient then
        table.insert(desc, self._Control:GetClientConfigText("FloorUnlockNewFunctionalText", 5))
    end
    --拼接
    if XTool.IsTableEmpty(desc) then
        return nil
    end
    return self._Control:GetClientConfigText("NewText") .. table.concat(desc, self._Symbol2)
end

--本次升级解锁的增幅&可移动&自动充能
function XUiSkyTowerLevelUp:GetNewDanceFunctional()
    local desc = {}
    local hasWorkTime, hasAuto = false, false
    for lv = self._CurLevel + 1, self._TargetLv do
        local danceCfg = self._Control:GetDanceConfig(lv)
        hasWorkTime = hasWorkTime or XTool.IsNumberValid(danceCfg.DecreaseWorkTime)
        hasAuto = hasAuto or XTool.IsNumberValid(danceCfg.IncreaseAuto)
    end
    --装入【增幅】【可移动】
    if hasWorkTime then
        table.insert(desc, self._Control:GetClientConfigText("DanceUnlockNewFunctionalText", 1))
        table.insert(desc, self._Control:GetClientConfigText("DanceUnlockNewFunctionalText", 2))
    end
    --装入【自动充能】
    if hasAuto then
        table.insert(desc, self._Control:GetClientConfigText("DanceUnlockNewFunctionalText", 3))
    end
    --拼接
    if XTool.IsTableEmpty(desc) then
        return nil
    end
    return table.concat(desc, self._Symbol2)
end
--endregion

--region 升级操作
---点击提升一级，条件不满足时给出对应提示
function XUiSkyTowerLevelUp:OnBtnLevelUpClick()
    if self.IsRequesting then
        return
    end
    self:UpdateView()
    if self._IsMaxLevel then
        return
    end
    if not self.AbleLevelUp then
        self:TipLevelUpBlock()
        return
    end
    self:RequestLevelUp()
end

---条件未满足的原因提示，条件优先于金币
function XUiSkyTowerLevelUp:TipLevelUpBlock()
    local isUnLock, desc = self._Control:GetFloorUnlockCondition(self._CurLevel + 1)
    if not isUnLock then
        local performId = self._Control:GetFloorUnlockPerformId(self._CurLevel + 1)
        if XTool.IsNumberValid(performId) and self._Control:IsOnGoing(performId) and self._Control:IsPerformShow(performId) then
            self._Control:OpenPerformUi(performId)
        else
            XMVCA.XSkyTower:TipMsg(desc)
        end
        return
    end
    XMVCA.XSkyTower:TipMsg(self._Control:GetClientConfigText("GoldNoEnoughTip"))
end

---每次请求只提升一级
function XUiSkyTowerLevelUp:RequestLevelUp()
    if self.IsRequesting then
        return
    end
    local startLv = self._CurLevel
    if self._Control:IsFloorMaxLevel(startLv) then
        return
    end
    local targetLv = startLv + 1
    --回包会先刷新货币，保留目标等级供按钮计算消耗，回调中再通过UpdateView重建预览
    self.IsRequesting = true
    self._Control:RequestFloorLevelUp(targetLv, function(result)
        self.IsRequesting = false
        self._CoinCount = self._Control:GetItemCount(SkyTowerCoin)
        self:UpdateView()
        self:PlayLevelUpShow(startLv, result)
    end, function()
        self.IsRequesting = false
        self._CoinCount = self._Control:GetItemCount(SkyTowerCoin)
        self:UpdateView()
    end)
end

--endregion

--region 升级后表演
---升级后的表演：只升1级时先播镜头动画、完成后再开解锁弹窗，
---升超过1级时不播镜头动画、直接开解锁弹窗
---@param startLv number 升级前的等级
---@param result XSkyTowerLevelUpResultProtocol 升级协议结果
function XUiSkyTowerLevelUp:PlayLevelUpShow(startLv, result)
    if not result then
        return
    end
    local newLv = result.SkyTowerLv
    if newLv <= startLv then
        return
    end
    local finishCallBack = function()
        self._GridWork:PlayRefreshAnimation()
        self:OpenLevelUpUnlockTip(startLv, newLv)
        XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_UPDATE_LEVEL_UP_CAM)
    end
    --跨多级时可聚焦的目标有多个，无法确定播哪个，直接开弹窗
    if newLv - startLv > 1 then
        finishCallBack()
        return
    end
    if not self:PlayFocusCamera(startLv, newLv, result, finishCallBack) then
        finishCallBack()
    end
end

---按本次实际解锁的内容选择聚焦目标并播放镜头动画
---新楼层优先于新工位，两者都没有时不播
---@param startLv number 升级前的等级
---@param newLv number 升级后的等级
---@param result XSkyTowerLevelUpResultProtocol 升级协议结果
---@param onFinish function 镜头动画播放完成的回调
---@return boolean 是否发起了镜头动画
function XUiSkyTowerLevelUp:PlayFocusCamera(startLv, newLv, result, onFinish)
    local newFloorId = self._Control:GetLvFloorId(newLv)
    if not XTool.IsNumberValid(newFloorId) then
        return false
    end
    --解锁了新楼层，聚焦到新楼层中心
    if self._Control:GetLvFloorId(startLv) ~= newFloorId then
        self._Control:GetRoom(newFloorId):LookAtFloor()
        self:BeginCameraShow(onFinish)
        return true
    end
    --解锁了新工位，聚焦到新工位，工位以服务端回包为准
    if not XTool.IsTableEmpty(result.NewWorkPosIds) then
        local floorId, index = self:ParseNewWorkPos(result.NewWorkPosIds[#result.NewWorkPosIds])
        self._Control:GetRoom(floorId):LookAtWork(index)
        self:BeginCameraShow(onFinish)
        return true
    end
    return false
end

---解析升级回包里的新工位，兼容服务端下发复合键与下发纯下标两种口径
---@param workPosId number 回包中的工位标识
---@return number, number 楼层Id、工位下标
function XUiSkyTowerLevelUp:ParseNewWorkPos(workPosId)
    local floorId, index = self._Control:ParseWorkPosKey(workPosId)
    local maxWork = self._Control:GetFloorWorkNum(floorId)
    if maxWork > 0 then
        index = math.max(1, math.min(index, maxWork))
    end
    return floorId, index
end

---镜头动画开始：屏蔽玩家操作，等blend结束后恢复并回调
---@param onFinish function 镜头动画播放完成的回调
function XUiSkyTowerLevelUp:BeginCameraShow(onFinish)
    local camera = self._Control:GetCameraModel()
    if not camera then
        if onFinish then
            onFinish()
        end
        return
    end
    XUiHelper.HideAllUi()
    camera:SetMainInputEnabled(false)
    camera:SetScenePickEnabled(false)
    self:WaitCameraBlendFinish(function()
        local curCamera = self._Control:GetCameraModel()
        if curCamera then
            curCamera:SetMainInputEnabled(true)
            curCamera:SetScenePickEnabled(true)
        end
        XUiHelper.ShowAllUi()
        if onFinish then
            onFinish()
        end
    end)
end

---等待虚拟相机的blend结束
---切换虚拟相机的那一帧Brain还没执行LateUpdate，IsBlending仍是false，
---所以要先等它变true、再等它变回false，否则会立刻误判为已完成
---@param onFinish function blend结束或超时后的回调
function XUiSkyTowerLevelUp:WaitCameraBlendFinish(onFinish)
    self:StopWaitCameraBlend()
    local camera = self._Control:GetCameraModel()
    local brain = camera and camera:GetBrain()
    if XTool.UObjIsNil(brain) then
        if onFinish then
            onFinish()
        end
        return
    end
    local elapsed = 0
    local isBlendStarted = false
    self._BlendTimer = XScheduleManager.ScheduleForever(function()
        elapsed = elapsed + BlendCheckInterval
        if brain.IsBlending then
            isBlendStarted = true
            return
        end
        --未在超时前检测到blend开始，说明Brain没有配混合时长，按已完成处理
        if not isBlendStarted and elapsed < BlendTimeOut then
            return
        end
        self:StopWaitCameraBlend()
        if onFinish then
            onFinish()
        end
    end, BlendCheckInterval)
end

function XUiSkyTowerLevelUp:StopWaitCameraBlend()
    if self._BlendTimer then
        XScheduleManager.UnSchedule(self._BlendTimer)
        self._BlendTimer = nil
    end
end

---打开升级解锁弹窗，跨区间时标题带上新区间名
---@param startLv number 升级前的等级
---@param newLv number 升级后的等级
function XUiSkyTowerLevelUp:OpenLevelUpUnlockTip(startLv, newLv)
    local unlockItems = self:GetUnlockItems(startLv, newLv)
    if XTool.IsTableEmpty(unlockItems) then
        return
    end
    local title
    local oldGroupId = self._Control:GetFloorGroupIdByFloorId(self._Control:GetLvFloorId(startLv))
    local newGroupId = self._Control:GetFloorGroupIdByFloorId(self._Control:GetLvFloorId(newLv))
    local isNewGroup = oldGroupId ~= newGroupId
    if isNewGroup then
        title = self._Control:GetClientConfigText("UnlockNewGroupTitle", 1)
    else
        title = self._Control:GetClientConfigText("UnlockNewGroupTitle", 2)
    end
    self._Control:OpenUnlockTip(title, unlockItems, isNewGroup)
end

---汇总一段等级区间内解锁的原料、物品与角色
---@param startLv number 升级前的等级，不含
---@param newLv number 升级后的等级，含
---@return table<number, number[]>
function XUiSkyTowerLevelUp:GetUnlockItems(startLv, newLv)
    local datas = {}
    local insert = function(itemType, ids)
        if XTool.IsTableEmpty(ids) then
            return
        end
        datas[itemType] = datas[itemType] or {}
        for _, id in ipairs(ids) do
            table.insert(datas[itemType], id)
        end
    end
    for lv = startLv + 1, newLv do
        local cfg = self._Control:GetLvConfig(lv)
        if cfg then
            insert(UnlockItemType.Illustrated, cfg.UnlockIngredient)
            insert(UnlockItemType.Food, cfg.UnlockFood)
            insert(UnlockItemType.Character, cfg.UnlockCharacter)
        end
    end
    return datas
end
--endregion

return XUiSkyTowerLevelUp
