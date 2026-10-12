---Control部分类，此处用于发送协议
---@type XSkyTowerControl
local XSkyTowerControl = XClassPartial('XSkyTowerControl')

local XNetworkCallCd = require("XCommon/XNetworkCallCd")
local SettleRequestInterval = 2

function XSkyTowerControl:ReleaseRequest()
    self._CharacterUpLevelRequest = nil
    self._WorkPosAssignRequest = nil
    self._WorkPosUnassignRequest = nil
    self._WorkPosSwapRequest = nil
    self._WorkPosSetProductRequest = nil
    self._WorkPosStopRequest = nil
    self._LastSettleRequestTime = nil
end

function XSkyTowerControl:OnPerformFinish(performId, func)
    local finish = XMVCA.XSkyTower.PerformState.Finish
    self._Model:UpdatePerformState(performId, finish)

    local room = self:GetPerformRoom(performId)
    if room then
        if self:IsIndent(performId) then
            room:ChangeIndentNpcState(finish)
        elseif self:IsPerform(performId) then
            room:StopPerformance()
        elseif self:IsFloorGroupPerform(performId) then
            room:StopFloorGroupPerformance()
        end
    end

    self:AddTaskCommand(XMVCA.XSkyTower.PerformTaskType.PerformTimes, performId, 1)
    self:AddTaskCommand(XMVCA.XSkyTower.PerformTaskType.Perform, performId)

    if func then
        func()
    end
end

--region 工位变更
--- 工位变更回包统一落库
---@param dataUpdate XSkyTowerDataUpdateProtocol
function XSkyTowerControl:OnWorkPosChanged(dataUpdate, cb)
    -- 落库内部按楼层聚合派发FLOOR_CHANGE与WORK_POS_CHANGE，界面据此重刷
    self._Model:ApplyDataUpdate(dataUpdate)
    if cb then
        cb()
    end
    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_WORK_BENCH_CHANGE_STAFF)
end

--- 角色上工位（目标工位原有角色会被顶下工，通用角色可同时占多个工位）
---@param floorId number
---@param index number 工位下标，从1开始
---@param characterId number
---@param cb function
function XSkyTowerControl:RequestAssignWorkPos(floorId, index, characterId, cb)
    if not XTool.IsNumberValid(characterId) then
        return
    end
    if not self._WorkPosAssignRequest then
        self._WorkPosAssignRequest = XNetworkCallCd.New("SkyTowerWorkPosAssignRequest", 1, XMVCA.XSkyTower)
    end
    local req = {
        CharacterId = characterId,
        WorkPosId = self._Model:MakeWorkPosKey(floorId, index),
    }
    self._WorkPosAssignRequest:Call(req, function(res)
        self:OnWorkPosChanged(res.DataUpdate, cb)
    end)
end

--- 两个工位对换（角色连同工作内容整槽互换，服务端会双向校验区间与指定工作限制）
---@param fromIndex number 工位下标，从1开始
---@param toIndex number 工位下标，从1开始
---@param finishCb function 成功、失败或被请求CD拦截后结束等待表现
function XSkyTowerControl:RequestSwapWorkPos(fromFloorId, fromIndex, toFloorId, toIndex, cb, finishCb)
    if not self._WorkPosSwapRequest then
        self._WorkPosSwapRequest = XNetworkCallCd.New("SkyTowerWorkPosSwapRequest", 1, XMVCA.XSkyTower)
    end
    local req = {
        FromWorkPosId = self._Model:MakeWorkPosKey(fromFloorId, fromIndex),
        ToWorkPosId = self._Model:MakeWorkPosKey(toFloorId, toIndex),
    }
    self._WorkPosSwapRequest:Call(req, function(res)
        self:OnWorkPosChanged(res.DataUpdate, cb)
    end, finishCb, finishCb)
end

--- 设置工位的生产内容，角色不变
---@param index number 工位下标，从1开始
---@param workType number 工作类型，取XMVCA.XSkyTower.WorkType
---@param productType number 产品类型，取XMVCA.XSkyTower.ProductType
function XSkyTowerControl:RequestSetWorkPosProduct(floorId, index, workType, productType, productId, cb)
    if not XTool.IsNumberValid(productId) then
        return
    end
    if not self._WorkPosSetProductRequest then
        self._WorkPosSetProductRequest = XNetworkCallCd.New("SkyTowerWorkPosSetProductRequest", 1, XMVCA.XSkyTower)
    end
    local req = {
        WorkPosId = self._Model:MakeWorkPosKey(floorId, index),
        WorkType = workType,
        ProductType = productType,
        ProductId = productId,
    }
    self._WorkPosSetProductRequest:Call(req, function(res)
        self:OnWorkPosChanged(res.DataUpdate, cb)
    end)
end

--- 工位停工，角色仍留在工位上但不再生产
---@param index number 工位下标，从1开始
function XSkyTowerControl:RequestStopWorkPos(floorId, index, cb)
    if not self._WorkPosStopRequest then
        self._WorkPosStopRequest = XNetworkCallCd.New("SkyTowerWorkPosStopRequest", 1, XMVCA.XSkyTower)
    end
    local req = {
        WorkPosId = self._Model:MakeWorkPosKey(floorId, index),
    }
    self._WorkPosStopRequest:Call(req, function(res)
        self:OnWorkPosChanged(res.DataUpdate, cb)
    end)
end

--- 一次安排工作：先定生产内容再上人
---@param index number 工位下标，从1开始
---@param workType number 工作类型，取XMVCA.XSkyTower.WorkType
---@param productId number 生产内容
---@param characterId number 安排的员工
function XSkyTowerControl:RequestAssignWork(floorId, index, workType, productId, characterId, cb)
    if not XTool.IsNumberValid(productId) or not XTool.IsNumberValid(characterId) then
        return
    end
    local productType = self:GetProductTypeByWorkType(workType)
    self:RequestSetWorkPosProduct(floorId, index, workType, productType, productId, function()
        self:RequestAssignWorkPos(floorId, index, characterId, cb)
    end)
end
--endregion

--- 升级员工，支持一次连升多级
---@param characterId number
---@param targetLevel number 目标等级，不传按当前等级+1
---@param cb function 成功回调，参数为角色Id
---@param failCb function 失败回调
function XSkyTowerControl:RequestLevelUpStaff(characterId, targetLevel, cb, failCb)
    local curLevel = self:GetCurCharacterLevel(characterId)
    if curLevel >= self:GetCharacterLvMaxLevel(characterId) then
        if failCb then failCb() end
        return
    end

    targetLevel = math.min(targetLevel or curLevel + 1, self:GetCharacterLvMaxLevel(characterId))
    if targetLevel <= curLevel then
        if failCb then failCb() end
        return
    end

    -- 消耗按curLevel+1到targetLevel逐级累加
    local needCount = 0
    for level = curLevel + 1, targetLevel do
        needCount = needCount + self:GetCharacterLvNeedItemCount(characterId, level)
    end
    local ownCount = self._Model:GetCharacterLvUpItemCount()
    if ownCount < needCount then
        XMVCA.XSkyTower:TipText("CommonCoinNotEnough")
        if failCb then failCb() end
        return
    end

    local isSuccess = false
    local responseCb = function(res)
        isSuccess = true
        -- 回包带升级后等级与剩余角色券，支持一次连升多级，不能按本地+1推进
        self._Model:UpdateCharacterLv(res.CharacterId, res.CharacterLv)
        self._Model:ApplyDataUpdate(res.DataUpdate)

        self:AddTaskCommand(XMVCA.XSkyTower.PerformTaskType.RoleLevel, characterId)
        if self:GetCharacterWorkType(characterId) == XMVCA.XSkyTower.WorkType.Sale then
            self:AddTaskCommand(XMVCA.XSkyTower.PerformTaskType.GainGoldSpeed, self:GetCharacterFloorGroup(characterId))
        end

        XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_LEVEL_CONDITION_CHANGE)
        if cb then
            cb(res.CharacterId)
        end
    end

    local req = {
        CharacterId = characterId,
        CharacterLv = targetLevel,
    }
    if not self._CharacterUpLevelRequest then
        self._CharacterUpLevelRequest = XNetworkCallCd.New("SkyTowerCharacterUpLevelRequest", 1, XMVCA.XSkyTower)
    end
    -- 公共完成回调同时覆盖成功和冷却拦截，只有后者需要通知失败
    local completeCb = function()
        if not isSuccess and failCb then
            failCb()
        end
    end
    self._CharacterUpLevelRequest:Call(req, responseCb, completeCb, failCb, true)
end

---请求楼层升级到目标等级，长按连升时可跨多级
---@param targetLv number 目标等级
---@param cb function 升级成功回调，参数：协议结果
function XSkyTowerControl:RequestFloorLevelUp(targetLv, cb, failCb)
    local curLevel = self:GetSkyTowerLv()
    if not XTool.IsNumberValid(targetLv) or targetLv <= curLevel or targetLv > XMVCA.XSkyTower.MaxLv then
        if failCb then
            failCb()
        end
        return
    end
    if self:IsFloorMaxLevel(curLevel) then
        if failCb then
            failCb()
        end
        return
    end
    local enough = self:CheckFloorGoldEnoughToLv(targetLv)
    if not enough then
        XMVCA.XSkyTower:TipMsg(self:GetClientConfigText("GoldNoEnoughTip"))
        if failCb then
            failCb()
        end
        return
    end
    --条件逐级判定，中间任意一级不满足都不能跨过去
    for lv = curLevel + 1, targetLv do
        local isUnLock, desc = self:GetFloorUnlockCondition(lv)
        if not isUnLock then
            XMVCA.XSkyTower:TipMsg(desc)
            if failCb then
                failCb()
            end
            return
        end
    end
    local req = {
        SkyTowerLv = targetLv
    }
    XNetwork.Call("SkyTowerFloorUpLevelRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XMVCA.XSkyTower:TipCode(res.Code)
            if failCb then
                failCb()
            end
            return
        end
        ---@type XSkyTowerLevelUpResultProtocol
        local result = res.Result
        -- 升级会触发一次结算，同时抬高仓库上限、解锁新工位
        self._Model:ApplyDataUpdate(result.DataUpdate)
        self._Model:UpdateGoldItemCount(result.GoldItemCount)
        if not XTool.IsTableEmpty(result.NewWorkPosIds) then
            local floorId = self:GetLvFloorId(result.SkyTowerLv)
            self._Model:UpdateLastUnlockedWork(result.NewWorkPosIds[#result.NewWorkPosIds], floorId)
        end
        self:UpdateLevelUpUnlock(result.NewCharacterIds, result.NewPerformIds)
        self:LevelUp(result.SkyTowerLv)
        self:AddTaskCommand(XMVCA.XSkyTower.PerformTaskType.TowerLevel)
        if cb then
            cb(result)
        end
    end)
end

function XSkyTowerControl:RequestFinishPerform(performId, func)
    if self:IsNotStart(performId) then
        return
    end
    if not self:CheckPerformFinish(performId) then
        return
    end
    local req = {
        PerformId = performId,
    }
    XNetwork.Call("SkyTowerFinishPerformRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XMVCA.XSkyTower:TipCode(res.Code)
            return
        end
        -- 回包带的是结算后的终值，先落库再走奖励表现
        self._Model:UpdatePerformInfo(res.PerformInfo)
        if not XTool.IsTableEmpty(res.RewardGoodsList) then
            local syncOpen = asynTask(function(goodsList, cb)
                XUiManager.OpenUiObtain(goodsList, nil, cb, cb)
            end)
            RunAsyn(function()
                syncOpen(res.RewardGoodsList)
                self:OnPerformFinish(performId, func)
            end)
        else
            self:OnPerformFinish(performId, func)
        end
        XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_LEVEL_CONDITION_CHANGE)
    end)
end

---对单个工位使用加速道具
---@param index number 工位下标，从1开始
---@param count number 使用张数
---@param cb function 成功回调
function XSkyTowerControl:RequestUseSpeedUpItem(floorId, index, count, cb)
    if count <= 0 or count > self:GetSpeedUpSelectableMaxCount() or not self:CheckCanAccelerate(floorId, index) then
        return
    end
    local oldUsedCount = self:GetAccelerateUseTimes()
    local req = {
        WorkPosId = self._Model:MakeWorkPosKey(floorId, index),
        Count = count,
    }
    XNetwork.Call("SkyTowerUseSpeedUpItemRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XMVCA.XSkyTower:TipCode(res.Code)
            return
        end
        local usedCount = res.SpeedUpDailyUsedCount - oldUsedCount
        self._Model:UpdateSpeedUpDailyUsedCount(res.SpeedUpDailyUsedCount)
        self._Model:ApplyDataUpdate(res.DataUpdate)
        if cb then
            cb(self:MakeSpeedUpProduce(res))
        end
        if usedCount > 0 and usedCount < count then
            self:OpenSpeedUpReturnPopup(count - usedCount)
        end
    end)
end

--- 加速产出增量，供收获表现使用
---@return XSkyTowerSpeedUpProduce
function XSkyTowerControl:MakeSpeedUpProduce(res)
    return {
        GoldCount = res.GoldCount or 0,
        ProductType = res.ProductType or 0,
        ProductId = res.ProductId or 0,
        ProduceCount = res.ProduceCount or 0,
    }
end

--- 退出活动，由ReleaseScene触发，此时界面已释放、玩家多半已回主界面，失败也没有可操作项，故不弹错误码
function XSkyTowerControl:RequestExit(cb)
    XNetwork.Call("SkyTowerExitRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            return
        end
        if cb then
            cb()
        end
    end, nil, nil, nil, true)
end

--- 拉取全部演出/订单数据，供日志、总览等只关心事件的界面单独刷新
function XSkyTowerControl:RequestPerformData(cb)
    XNetwork.Call("SkyTowerPerformDataRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XMVCA.XSkyTower:TipCode(res.Code)
            return
        end
        self._Model:UpdatePerformInfos(res.PerformInfos)
        if cb then
            cb()
        end
    end)
end

---保存进行中事件的剧情选择
---@param record table 对话选项记录，talkId到选项下标
function XSkyTowerControl:RequestSavePerformStory(performId, record, cb)
    if not self:IsOnGoing(performId) then
        return
    end
    if not XTool.IsTableEmpty(record) then
        XMessagePack.MarkAsTable(record)
    end
    local req = {
        PerformId = performId,
        PerformStoryInfo = record
    }
    XNetwork.Call("SkyTowerSavePerformStoryRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XMVCA.XSkyTower:TipCode(res.Code)
            return
        end
        self._Model:UpdatePerformInfo(res.PerformInfo)
        if cb then
            cb()
        end
    end)
end

--- 请求结算
---@param cb function|nil 已发起请求成功或失败回包后执行，CD拦截时不执行
---@return boolean 是否已发起请求，不代表服务端处理成功
function XSkyTowerControl:RequestSettleToNow(cb)
    local nowTime = XTime.GetServerNowTimestamp()
    if self._LastSettleRequestTime and nowTime - self._LastSettleRequestTime < SettleRequestInterval then
        return false
    end
    self._LastSettleRequestTime = nowTime
    XNetwork.Call("SkyTowerSettleToNowRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XMVCA.XSkyTower:TipCode(res.Code)
        else
            self._Model:ApplyDataUpdate(res.DataUpdate)
        end
        if cb then
            cb()
        end
    end)
    return true
end

return XSkyTowerControl

---@class XSkyTowerSpeedUpProduce
---@field GoldCount number 本次加速产出的金币
---@field ProductType number 产出的产品类型，取XMVCA.XSkyTower.ProductType
---@field ProductId number
---@field ProduceCount number 产出份数
