---@class XSkyTowerModel : XModel
---@field ClientRun XSkyTowerClientRunModel
---@field Perform XSkyTowerPerformModel
local XSkyTowerModel = XClass(XModel, "XSkyTowerModel", true)

--region 部分类初始化
XClassPartialRequire("XModule/XSkyTower/XModelPartial/XSkyTowerModelConfig", "XSkyTowerModel")
XClassPartialRequire("XModule/XSkyTower/XModelPartial/XSkyTowerModelSave", "XSkyTowerModel")
--endregion

local WORK_POS_FLOOR_FACTOR = 10
local STORAGE_TYPE_FACTOR = 100

function XSkyTowerModel:OnInit()
    self:OnInitConfig()
    self:OnInitSave()

    self.ClientRun = self:AddSubModel(require("XModule/XSkyTower/XSubModel/XSkyTowerClientRunModel"))
    self.Perform = self:AddSubModel(require("XModule/XSkyTower/XSubModel/XSkyTowerPerformModel"))

    self._ActivityId = 0
    ---@type XSkyTowerDataDbProtocol
    self._DataDb = nil
    self:InitClientData()
end

--- 初始化客户端运行时数据（非服务端下发）
function XSkyTowerModel:InitClientData()
    self:ClearFloorWorkPosCache()
    -- 离线账单展示快照
    self._OfflineBill = 0
    self._OfflineSeconds = 0
    self._OfflineCharacterLvUpItemCount = 0
    --工位进度的时间基准：回包校准，本地每次推进后更新，避免重复累计同一段时间
    self._WorkPosSyncTimes = {}
    self._LocalWorkPosSnapshots = {}
    self._LocalStorageSnapshots = {}
end

function XSkyTowerModel:ClearPrivate()
    self:ConfigClearPrivate()
end

function XSkyTowerModel:ResetAll()
    XMVCA.XSkyTower:OnLoginOut()
    self:ClearPrivate()
    self:ConfigResetAll()
    self._DataDb = nil
    self._ActivityId = 0
    self:InitClientData()
end

--region 活动切换
function XSkyTowerModel:GetActivityId()
    return self._ActivityId
end

function XSkyTowerModel:UpdateActivityId(activityId)
    if XTool.IsNumberValid(activityId) then
        XMVCA.XSkyTower:InitOnce()
    end
    if self._ActivityId > 0 and self._ActivityId ~= activityId then
        self:DoActivityChanged(activityId)
        return
    end
    self._ActivityId = activityId
end

function XSkyTowerModel:DoActivityChanged(activityId)
    if XMain.IsEditorDebug then
        local logs = string.format("活动Id由%s变成了%s", self._ActivityId, activityId)
        XLog.Error(logs)
    end
    self._ActivityId = activityId
    self._DataDb = nil
    self:InitClientData()

    XMVCA.XSkyTower:OnActivityEnd()
end

function XSkyTowerModel:ResetActivity()
    self:DoActivityChanged(0)
end

--endregion

--region 服务端数据入口
--- 全量数据下发（NotifySkyTowerData），整体保存不拆解
---@param data XSkyTowerDataDbProtocol
function XSkyTowerModel:UpdateNotifyData(data)
    self:UpdateActivityId(data.ActivityId)

    local oldLevel = self:GetSkyTowerLv()
    self._DataDb = data
    self:ClearFloorWorkPosCache()
    self._LocalWorkPosSnapshots = {}
    self._LocalStorageSnapshots = {}
    local nowTime = XTime.GetServerNowTimestamp()
    local settleTime = data.LastSettleTime or 0
    local syncTime = settleTime > 0 and math.min(settleTime, nowTime) or nowTime
    self._WorkPosSyncTimes = {}
    for key in pairs(data.WorkPosInfos or table.empty) do
        self._WorkPosSyncTimes[key] = syncTime
    end
    self.ClientRun:UpdateUnlockProduct()

    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_DATA_CHANGE)
    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_STORAGE_CHANGE)
    if oldLevel ~= self._DataDb.SkyTowerLv then
        XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_LEVEL_CHANGE)
    end
end

--- 离线账单更新
---@param offlineBill number 离线期间累计的金币收益
---@param offlineSeconds number 离线时长（秒）
---@param offlineCharacterLvUpItemCount number 离线期间实际获得的角色券
function XSkyTowerModel:UpdateAccount(offlineBill, offlineSeconds, offlineCharacterLvUpItemCount)
    self._OfflineBill = offlineBill or 0
    self._OfflineSeconds = offlineSeconds or 0
    self._OfflineCharacterLvUpItemCount = offlineCharacterLvUpItemCount or 0
    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_BILL_CHANGE)
end

--endregion

--region 服务端数据增量更新
--请求回包/推送的局部数据按Id原地替换，并派发对应变更事件

function XSkyTowerModel:UpdateSkyTowerLv(level)
    self._DataDb.SkyTowerLv = level
    self.ClientRun:UpdateUnlockProduct()
end

function XSkyTowerModel:UpdateSkyTowerLvLoginIn(level)
    self._DataDb = {}
    self._DataDb.SkyTowerLv = level
end

--- 金币数量更新（SkyTowerFloorUpLevelResponse.Result回带剩余金币）
function XSkyTowerModel:UpdateGoldItemCount(count)
    if not self._DataDb then
        return
    end
    local changeValue = count - self._DataDb.GoldItemCount
    self._DataDb.GoldItemCount = count or 0
    if changeValue > 0 then
        XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_TASK_ADD_COMMAND, XMVCA.XSkyTower.PerformTaskType.GainGold, nil, changeValue)
    end
end

--- 角色券数量更新（SkyTowerCharacterUpLevelResponse回带剩余数量）
function XSkyTowerModel:UpdateCharacterLvUpItemCount(count)
    if not self._DataDb then
        return
    end
    self._DataDb.CharacterLvUpItemCount = count or 0
end

--- 结算增量落库，字段都是变更后的终值，直接覆盖不累加
--- 未变更的工位与仓库不在字典里，三种道具余额则每次都填当前值
---@param data XSkyTowerDataUpdateProtocol
function XSkyTowerModel:ApplyDataUpdate(data)
    if not self._DataDb or not data then
        return
    end
    -- 增量中的“未变化”是相对上次服务端数据而言，先抹掉本地预测，避免完整一轮进度相同却重复产出
    local restoredGroups = self:RestoreLocalProduction()
    -- 字典键已是服务端全局WorkPosId，与本地复合键同编码，不再二次换算
    self:MergeWorkPosInfos(data.ChangedWorkPosInfos)
    self:MergeStorages(data.ChangedStorages)
    self:UpdateSpeedUpItemCount(data.SpeedUpItemCount)
    self:UpdateGoldItemCount(data.GoldItemCount)
    self:UpdateCharacterLvUpItemCount(data.CharacterLvUpItemCount)
    for groupId in pairs(restoredGroups) do
        if not data.ChangedStorages or not data.ChangedStorages[groupId] then
            XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_STORAGE_CHANGE, groupId)
        end
    end
    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_DATA_CHANGE)
end

--- 按道具上限截断累加，返回累加后数量与实际入账数量
---@return number, number newCount, granted
function XSkyTowerModel:_AddCountWithItemMax(itemIdConfigKey, oldCount, addCount)
    local itemConfig = self:GetItemConfig(self:GetIntConfigValue(itemIdConfigKey))
    local maxCount = itemConfig and itemConfig.MaxCount > 0 and itemConfig.MaxCount or XMath.IntMax()
    local newCount = math.min(maxCount, oldCount + addCount)
    return newCount, newCount - oldCount
end

--- 本地产出按实际入账金币累计转券；服务端余额覆盖不走此入口
function XSkyTowerModel:ApplyLocalGoldProduction(goldCount)
    local oldGoldCount = self:GetGoldCount()
    local newGoldCount, goldGranted = self:_AddCountWithItemMax("GoldItemId", oldGoldCount, goldCount)
    if goldGranted <= 0 then
        return
    end

    local totalGoldProduced = self:GetTotalGoldProduced() + goldGranted
    self._DataDb.TotalGoldProduced = totalGoldProduced
    local totalTransItemCount = self:GetTotalTransCharacterLvUpItem()
    local transBase = self:GetIntConfigValue("GoldTransCharaLvUpItemBase")
    local transNum = self:GetIntConfigValue("GoldTransCharaLvUpItemNum")
    local pendingItemCount = 0
    if transBase > 0 and transNum > 0 then
        pendingItemCount = math.floor(totalGoldProduced / transBase) * transNum - totalTransItemCount
    end
    if pendingItemCount > 0 then
        local newItemCount, itemGranted = self:_AddCountWithItemMax("CharacterLvUpItemId", self:GetCharacterLvUpItemCount(), pendingItemCount)
        if itemGranted > 0 then
            self._DataDb.TotalTransCharacterLvUpItem = totalTransItemCount + itemGranted
            self:UpdateCharacterLvUpItemCount(newItemCount)
        end
    end
    self:UpdateGoldItemCount(newGoldCount)
end

---每次服务端回包之间只保留一份生产前快照，用于增量回包校准，不保存另一套生产状态机
function XSkyTowerModel:SaveLocalWorkPosSnapshot(floorId, index)
    local key = self:MakeWorkPosKey(floorId, index)
    local workPos = self:GetFloorWorkPosInfo(floorId, index)
    local snapshot = self._LocalWorkPosSnapshots[key]
    if not workPos or (snapshot and snapshot.WorkPos == workPos) then
        return
    end
    self._LocalWorkPosSnapshots[key] = {
        WorkPos = workPos, State = workPos.State, WorkedSeconds = workPos.WorkedSeconds,
        ProduceRemainder = workPos.ProduceRemainder, ReservedInputs = workPos.ReservedInputs,
    }
end

function XSkyTowerModel:RestoreLocalProduction()
    for key, snapshot in pairs(self._LocalWorkPosSnapshots) do
        local workPos = self._DataDb.WorkPosInfos and self._DataDb.WorkPosInfos[key]
        if workPos == snapshot.WorkPos then
            workPos.State = snapshot.State
            workPos.WorkedSeconds = snapshot.WorkedSeconds
            workPos.ProduceRemainder = snapshot.ProduceRemainder
            workPos.ReservedInputs = snapshot.ReservedInputs
        end
    end
    local nowTime = XTime.GetServerNowTimestamp()
    for key in pairs(self._DataDb.WorkPosInfos or table.empty) do
        self._WorkPosSyncTimes[key] = nowTime
    end
    local restoredGroups = self._LocalStorageSnapshots
    for groupId, storage in pairs(restoredGroups) do
        self._DataDb.Storages[groupId] = storage or nil
    end
    self._LocalWorkPosSnapshots = {}
    self._LocalStorageSnapshots = {}
    return restoredGroups
end

function XSkyTowerModel:UpdateSpeedUpDailyUsedCount(count)
    if not self._DataDb then
        return
    end
    self._DataDb.SpeedUpDailyUsedCount = count or 0
end

--- 工位字典增量合并（按复合键覆盖，并按楼层聚合派发变更事件）
---@param workPosInfos table<number, XSkyTowerWorkPosInfoProtocol>
function XSkyTowerModel:MergeWorkPosInfos(workPosInfos)
    if not self._DataDb or XTool.IsTableEmpty(workPosInfos) then
        return
    end
    local infos = self._DataDb.WorkPosInfos
    if not infos then
        infos = {}
        self._DataDb.WorkPosInfos = infos
    end
    --同层多个工位只派发一次整层事件，避免UI重复刷新
    local changedFloors = {}
    --增量协议没有结算时间戳，按回包时刻校准；未下发的工位保留原时间基准
    local syncTime = XTime.GetServerNowTimestamp()
    for key, workPosInfo in pairs(workPosInfos) do
        local floorId = self:ParseWorkPosKey(key)
        local oldInfo = infos[key]
        if oldInfo ~= workPosInfo then
            self:ClearFloorWorkPosCache(floorId, oldInfo ~= nil)
        end
        infos[key] = workPosInfo
        self._WorkPosSyncTimes[key] = syncTime
        changedFloors[floorId] = true
    end
    for floorId in pairs(changedFloors) do
        local floorGroupId = self:GetFloorGroupIdByFloorId(floorId)
        XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_TASK_ADD_COMMAND, XMVCA.XSkyTower.PerformTaskType.GainGoldSpeed, floorGroupId)
        XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_FLOOR_CHANGE, floorId)
        --index传nil表示整层工位都变了
        XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_WORK_POS_CHANGE, floorId, nil)
    end
end

--- 区间仓库整体更新
---@param storage XSkyTowerFloorGroupStorageProtocol
function XSkyTowerModel:UpdateGroupStorage(groupId, storage)
    if not self._DataDb then
        return
    end
    if not self._DataDb.Storages then
        self._DataDb.Storages = {}
    end
    self._DataDb.Storages[groupId] = storage
    self._LocalStorageSnapshots[groupId] = nil
    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_STORAGE_CHANGE, groupId)
end

--- 仓库字典增量合并（按区间Id整体覆盖）
---@param storages table<number, XSkyTowerFloorGroupStorageProtocol>
function XSkyTowerModel:MergeStorages(storages)
    if not self._DataDb or XTool.IsTableEmpty(storages) then
        return
    end
    for groupId, storage in pairs(storages) do
        self:UpdateGroupStorage(groupId, storage)
    end
end

--- 员工解锁（随通天塔等级下发，服务端下发过即视为已解锁，本地补一条）
function XSkyTowerModel:UnlockCharacter(characterId, characterLv)
    if not self._DataDb then
        return
    end
    if not self._DataDb.CharacterInfos then
        self._DataDb.CharacterInfos = {}
    end
    local info = self:GetCharacterInfo(characterId)
    if info then
        info.CharacterLv = characterLv or info.CharacterLv
    else
        self._DataDb.CharacterInfos[characterId] = {
            CharacterLv = characterLv or XMVCA.XSkyTower.StaffLevelMin,
        }
    end
    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_STAFF_CHANGE, characterId)
end

--- 员工等级更新
function XSkyTowerModel:UpdateCharacterLv(characterId, characterLv)
    local info = self:GetCharacterInfo(characterId)
    if not info then
        return
    end
    info.CharacterLv = characterLv
    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_STAFF_CHANGE, characterId)
end

--- 角色信息增量更新
---@param changedCharacterInfos table<number, XSkyTowerCharacterInfoProtocol>
function XSkyTowerModel:UpdateCharacterInfos(changedCharacterInfos)
    if not self._DataDb or XTool.IsTableEmpty(changedCharacterInfos) then
        return
    end
    if not self._DataDb.CharacterInfos then
        self._DataDb.CharacterInfos = {}
    end
    for characterId, info in pairs(changedCharacterInfos) do
        self._DataDb.CharacterInfos[characterId] = info
    end
end

--- 演出/订单列表更新（逐条按PerformId原地替换）
---@param performInfos XSkyTowerPerformInfoProtocol[]
function XSkyTowerModel:UpdatePerformInfos(performInfos)
    if not self._DataDb or XTool.IsTableEmpty(performInfos) then
        return
    end
    for _, performInfo in pairs(performInfos) do
        self:UpdatePerformInfo(performInfo)
    end
end

--- 演出/订单单条更新（按PerformId原地替换，不存在则插入）
---@param performInfo XSkyTowerPerformInfoProtocol
function XSkyTowerModel:UpdatePerformInfo(performInfo)
    if not self._DataDb or not performInfo then
        return
    end
    local floorId = self:GetPerformConfig(performInfo.PerformId).FloorId
    local infos = self._DataDb.PerformInfos
    if not infos then
        infos = {}
        self._DataDb.PerformInfos = infos
    end
    infos[performInfo.PerformId] = performInfo
    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_TASK_SCHEDULE_REBUILD)
    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_PERFORM_STATE_CHANGE, floorId)
end

--- 演出/订单状态更新
function XSkyTowerModel:UpdatePerformState(performId, state)
    local info = self:GetPerformInfo(performId)
    local floorId = self:GetPerformConfig(performId).FloorId
    if not info then
        return
    end
    info.State = state
    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_PERFORM_STATE_CHANGE, floorId)
end

--endregion

--region 服务端数据访问
--- 全量活动数据是否已到达（未进过玩法界面时为false）
function XSkyTowerModel:IsDataReady()
    return self._DataDb ~= nil
end

function XSkyTowerModel:GetCurLvCfg()
    return self:GetLvConfig(self._DataDb.SkyTowerLv)
end

---当前已解锁的最高楼层
function XSkyTowerModel:GetMaxFloorId()
    return self:GetCurLvCfg().FloorId
end

function XSkyTowerModel:GetSkyTowerLv()
    return self._DataDb and self._DataDb.SkyTowerLv or 0
end

function XSkyTowerModel:GetLastSettleTime()
    return self._DataDb and self._DataDb.LastSettleTime or 0
end

--- 全部工位（扁平字典，键为复合键）
---@return table<number, XSkyTowerWorkPosInfoProtocol>
function XSkyTowerModel:GetAllWorkPosInfos()
    return self._DataDb and self._DataDb.WorkPosInfos or nil
end

function XSkyTowerModel:UpdateLastUnlockedWork(workPosIndex, floorId)
    local info = self._DataDb.LastUnlockedWorkPosLocation or {}
    info.WorkPosIndex = workPosIndex
    info.FloorId = floorId
    self._DataDb.LastUnlockedWorkPosLocation = info
end

---获取最后解锁的工位
function XSkyTowerModel:GetLastUnlockedWork()
    return self._DataDb.LastUnlockedWorkPosLocation
end

--- 遍历全部工位
---@param func fun(groupId:number, floorId:number, index:number, workPosInfo:XSkyTowerWorkPosInfoProtocol)
function XSkyTowerModel:EachWorkPos(func)
    local infos = self:GetAllWorkPosInfos()
    if XTool.IsTableEmpty(infos) then
        return
    end
    for key, workPosInfo in pairs(infos) do
        local floorId, index = self:ParseWorkPosKey(key)
        func(self:GetFloorGroupIdByFloorId(floorId), floorId, index, workPosInfo)
    end
end

---清理楼层工位查询缓存，必须在派发数据变更事件前调用
---@param floorId number 不传则清全部
---@param keepCount boolean 只替换已有工位对象时可保留数量
function XSkyTowerModel:ClearFloorWorkPosCache(floorId, keepCount)
    if not floorId then
        self._FloorWorkPosInfosCache = {}
        self._FloorWorkPosCountCache = {}
        return
    end
    self._FloorWorkPosInfosCache[floorId] = nil
    if not keepCount then
        self._FloorWorkPosCountCache[floorId] = nil
    end
end

--- 楼层工位列表（只读缓存，按index排列，元素引用协议工位对象）
---调用方不能增删或重排列表；工位对象被替换后，下次查询会重建该层列表
---@return XSkyTowerWorkPosInfoProtocol[]
function XSkyTowerModel:GetFloorWorkPosInfos(floorId)
    local infos = self:GetAllWorkPosInfos()
    if XTool.IsTableEmpty(infos) then
        return nil
    end
    local list = self._FloorWorkPosInfosCache[floorId]
    if list then
        return list
    end
    list = {}
    local index = 1
    --工位下标连续，从1开始逐个取到断为止，保证返回的是可ipairs的数组
    while true do
        local info = infos[self:MakeWorkPosKey(floorId, index)]
        if not info then
            break
        end
        list[index] = info
        index = index + 1
    end
    self._FloorWorkPosInfosCache[floorId] = list
    self._FloorWorkPosCountCache[floorId] = index - 1
    return list
end

---楼层连续工位数量，只查询数量时不构造列表，空楼层缓存为0
---@param floorId number
---@return number
function XSkyTowerModel:GetFloorWorkPosCount(floorId)
    local count = self._FloorWorkPosCountCache[floorId]
    if count ~= nil then
        return count
    end
    local infos = self:GetAllWorkPosInfos()
    count = 0
    if infos then
        while infos[self:MakeWorkPosKey(floorId, count + 1)] do
            count = count + 1
        end
    end
    self._FloorWorkPosCountCache[floorId] = count
    return count
end

--- 工位数据（工位按列表下标定位，index从1开始）
---@return XSkyTowerWorkPosInfoProtocol
function XSkyTowerModel:GetFloorWorkPosInfo(floorId, index)
    local infos = self:GetAllWorkPosInfos()
    if XTool.IsTableEmpty(infos) then
        return nil
    end
    return infos[self:MakeWorkPosKey(floorId, index)]
end

---当前工位进度的时间基准，本地安排预览不修改此时间
---@return number|nil
function XSkyTowerModel:GetWorkPosSyncTime(floorId, index)
    return self._WorkPosSyncTimes[self:MakeWorkPosKey(floorId, index)]
end

---本地推进后更新进度的时间基准，服务端回包仍会重新校准
function XSkyTowerModel:UpdateWorkPosSyncTime(floorId, index, time)
    self._WorkPosSyncTimes[self:MakeWorkPosKey(floorId, index)] = time
end

--- 区间仓库（XSkyTowerFloorGroupStorage）
---@return XSkyTowerFloorGroupStorageProtocol
function XSkyTowerModel:GetGroupStorage(groupId)
    local storages = self._DataDb and self._DataDb.Storages
    return storages and storages[groupId] or nil
end

--- 区间仓库条目字典（键为ProductType * 100 + ProductId）
---@return table<number, XSkyTowerStorageInfoProtocol>
function XSkyTowerModel:GetStorageInfos(groupId)
    local storage = self:GetGroupStorage(groupId)
    return storage and storage.StorageInfos or nil
end

--- 区间仓库单项
---@return XSkyTowerStorageInfoProtocol
function XSkyTowerModel:GetStorageInfo(groupId, productType, productId)
    local infos = self:GetStorageInfos(groupId)
    if XTool.IsTableEmpty(infos) then
        return
    end
    return infos[self:MakeStorageKey(productType, productId)]
end

function XSkyTowerModel:GetStorageCount(groupId, productType, productId)
    local info = self:GetStorageInfo(groupId, productType, productId)
    return info and info.Count or 0
end

---本地生产与扣料只修改对应仓库格，由Control在本次结算完成后统一通知界面
function XSkyTowerModel:UpdateStorageCount(groupId, productType, productId, count)
    if not self._DataDb then
        return
    end
    self._DataDb.Storages = self._DataDb.Storages or {}
    local storage = self._DataDb.Storages[groupId]
    if self._LocalStorageSnapshots[groupId] == nil then
        self._LocalStorageSnapshots[groupId] = storage and XTool.Clone(storage) or false
    end
    if not storage then
        storage = { StorageInfos = {} }
        self._DataDb.Storages[groupId] = storage
    end
    storage.StorageInfos = storage.StorageInfos or {}
    local key = self:MakeStorageKey(productType, productId)
    local info = storage.StorageInfos[key]
    if not info then
        info = { ProductType = productType, ProductId = productId }
        storage.StorageInfos[key] = info
    end
    info.Count = math.max(0, count)
end

--- 金币数量（XSkyTowerDataDb.GoldItemCount）
function XSkyTowerModel:GetGoldCount()
    return self._DataDb and self._DataDb.GoldItemCount or 0
end

--- 角色券数量（XSkyTowerDataDb.CharacterLvUpItemCount）
function XSkyTowerModel:GetCharacterLvUpItemCount()
    return self._DataDb and self._DataDb.CharacterLvUpItemCount or 0
end

--- 加速道具数量（XSkyTowerDataDb.SpeedUpItemCount）
function XSkyTowerModel:GetSpeedUpItemCount()
    return self._DataDb and self._DataDb.SpeedUpItemCount or 0
end

function XSkyTowerModel:UpdateSpeedUpItemCount(count)
    if not self._DataDb then
        return
    end
    self._DataDb.SpeedUpItemCount = count or 0
end

---活动内货币读取当前余额（包含本地售卖），其余道具沿用通用背包数量
function XSkyTowerModel:GetItemCount(itemId)
    local itemIds = XMVCA.XSkyTower.ItemId
    if itemId == itemIds.SkyTowerCoin then
        return self:GetGoldCount()
    elseif itemId == itemIds.SkyTowerUpgradeCoin then
        return self:GetCharacterLvUpItemCount()
    elseif itemId == itemIds.SkyTowerAccelerate then
        return self:GetSpeedUpItemCount()
    end
    return XDataCenter.ItemManager.GetCount(itemId)
end

--- 加速道具当日已用次数（XSkyTowerDataDb.SpeedUpDailyUsedCount，服务端每日重置回调清零）
function XSkyTowerModel:GetAccelerateUseTimes()
    return self._DataDb and self._DataDb.SpeedUpDailyUsedCount or 0
end

function XSkyTowerModel:IsAccelerateUpperLimit()
    return self:GetAccelerateUseTimes() >= self:GetConfigAccelerateUseLimit()
end

--- 已发放加速道具的天数
function XSkyTowerModel:GetSpeedUpGrantedDays()
    return self._DataDb and self._DataDb.SpeedUpGrantedDays or 0
end

--- 金币累计产出
--- 金币会被楼层升级消耗，故转化角色券的进度只能按累计产出算，不能读余额
function XSkyTowerModel:GetTotalGoldProduced()
    return self._DataDb and self._DataDb.TotalGoldProduced or 0
end

--- 已由金币转化出的角色升级券总数
function XSkyTowerModel:GetTotalTransCharacterLvUpItem()
    return self._DataDb and self._DataDb.TotalTransCharacterLvUpItem or 0
end

--- 已获得角色信息字典（XSkyTowerDataDb.CharacterInfos，键为characterId）
---@return table<number, XSkyTowerCharacterInfoProtocol>
function XSkyTowerModel:GetCharacterInfos()
    return self._DataDb and self._DataDb.CharacterInfos or nil
end

--- 员工数据（服务端下发过即视为已解锁）
---@return XSkyTowerCharacterInfoProtocol
function XSkyTowerModel:GetCharacterInfo(characterId)
    local infos = self:GetCharacterInfos()
    return infos and infos[characterId] or nil
end

function XSkyTowerModel:GetCharacterLv(characterId)
    local info = self:GetCharacterInfo(characterId)
    return info and info.CharacterLv or 1
end

--- 角色当前处于激活状态的技能
---@return table<number, number>
function XSkyTowerModel:GetCharacterActiveSkillRatios(characterId)
    local info = self:GetCharacterInfo(characterId)
    return info and info.ActiveSkillRatios or table.empty
end

--- 员工是否已解锁
function XSkyTowerModel:IsCharacterUnlocked(characterId)
    return self:GetCharacterInfo(characterId) ~= nil
end

--- 已解锁员工数
function XSkyTowerModel:GetUnlockCharacterCount()
    local infos = self:GetCharacterInfos()
    if XTool.IsTableEmpty(infos) then
        return 0
    end
    local count = 0
    for _ in pairs(infos) do
        count = count + 1
    end
    return count
end

--- 等级大于等于目标等级的已解锁员工数（通天塔升级条件用）
function XSkyTowerModel:GetGreaterLevelCharacterCount(level)
    local count = 0
    local infos = self:GetCharacterInfos()
    if XTool.IsTableEmpty(infos) then
        return count
    end
    for _, info in pairs(infos) do
        if info.CharacterLv >= level then
            count = count + 1
        end
    end
    return count
end

--- 演出/订单字典（XSkyTowerDataDb.PerformInfos，键为PerformId）
---@return table<number, XSkyTowerPerformInfoProtocol>
function XSkyTowerModel:GetPerformInfos()
    return self._DataDb and self._DataDb.PerformInfos or nil
end

function XSkyTowerModel:GetPerformInfo(performId)
    local infos = self:GetPerformInfos()
    return infos and infos[performId] or nil
end

function XSkyTowerModel:GetPerformState(performId)
    local info = self:GetPerformInfo(performId)
    return info and info.State or XMVCA.XSkyTower.PerformState.NotStart
end

--- 进行中的演出/订单
---@param performType number XMVCA.XSkyTower.PerformType
---@return XSkyTowerPerformInfoProtocol
function XSkyTowerModel:GetRunningPerformInfo(performType, floorId)
    local infos = self:GetPerformInfos()
    if XTool.IsTableEmpty(infos) then
        return
    end
    local PerformState = XMVCA.XSkyTower.PerformState
    for _, info in pairs(infos) do
        if floorId ~= self:GetPerformConfig(info.PerformId).FloorId then
            goto continue
        end
        if info.Type == performType then
            if info.State == PerformState.OnGoing then
                return info
            end
        end
        :: continue ::
    end
    return nil
end

---@return table Key为对话Id，Value为回答下标（从1开始）
function XSkyTowerModel:GetPerformStoryRecord(performId)
    local info = self:GetPerformInfo(performId)
    return info and info.PerformStoryInfo
end

--endregion

function XSkyTowerModel:GetOfflineBill()
    return self._OfflineBill or 0
end

--- 离线期间实际获得的角色券
function XSkyTowerModel:GetOfflineCharacterLvUpItemCount()
    return self._OfflineCharacterLvUpItemCount or 0
end

--- 离线时长（秒）
function XSkyTowerModel:GetOfflineSeconds()
    return self._OfflineSeconds or 0
end

--- 服务端制定的Id规则
--- 工位 DataDb.WorkPosInfos   Key = FloorId * 10 + WorkPosIdx
--- 仓库 DataDb.Storages[组].StorageInfos   Key = ProductType * 100 + ProductId
--- 服务端WorkPosIdx从0开始，Lua侧工位下标沿用ipairs的从1开始，两种基准只在这一对编解码里换算
---@param index number 工位下标，从1开始
function XSkyTowerModel:MakeWorkPosKey(floorId, index)
    if XMain.IsEditorDebug then
        --FloorId不受进制约束（1~20层都合法），只有工位下标必须压在个位
        if index < 1 or index > WORK_POS_FLOOR_FACTOR then
            XLog.Error(string.format("通天塔工位键溢出，工位下标必须在1~10之间：floorId=%s index=%s", floorId, index))
        end
    end
    return floorId * WORK_POS_FLOOR_FACTOR + index - 1
end

--- 工位复合键解码（Key不含区间，groupId由楼层配置反查）
---@return number, number floorId, index（已换算回从1开始）
function XSkyTowerModel:ParseWorkPosKey(key)
    return math.floor(key / WORK_POS_FLOOR_FACTOR), key % WORK_POS_FLOOR_FACTOR + 1
end

---仓库复合键
function XSkyTowerModel:MakeStorageKey(productType, productId)
    if XMain.IsEditorDebug then
        if productId >= STORAGE_TYPE_FACTOR then
            XLog.Error(string.format("通天塔仓库键溢出，产品Id必须小于100：productType=%s productId=%s", productType, productId))
        end
    end
    return productType * STORAGE_TYPE_FACTOR + productId
end

---通天塔局内道具唯一Id，需落在 38000000~38999999 段，由 XArrange.GetGoodsType 推导为 SkyTowerItem
function XSkyTowerModel:IsSkyTowerItem(itemId)
    return itemId >= 38000000 and itemId <= 38999999
end

return XSkyTowerModel
tType, productId)
    if XMain.IsEditorDebug then
        if productId >= STORAGE_TYPE_FACTOR then
            XLog.Error(string.format("通天塔仓库键溢出，产品Id必须小于100：productType=%s productId=%s", productType, productId))
        end
    end
    return productType * STORAGE_TYPE_FACTOR + productId
end

---通天塔局内道具唯一Id，需落在 38000000~38999999 段，由 XArrange.GetGoodsType 推导为 SkyTowerItem
function XSkyTowerModel:IsSkyTowerItem(itemId)
    return itemId >= 38000000 and itemId <= 38999999
end

return XSkyTowerModel
