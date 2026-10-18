---Control部分类，此处用于工位状态展示、生产参数与仓储查询
---工位统一按 floorId + index（WorkPosInfos列表下标）定位，在线生产本地推进，正常回包校准数据
---@type XSkyTowerControl
local XSkyTowerControl = XClassPartial('XSkyTowerControl')

function XSkyTowerControl:InitBusiness()
    self._LocalProductionEntries = {}
    self._LocalProductionEntryPool = {}
    self._LocalProductionChangedGroups = {}
    self._LocalProductionInputsDict = {}
end

function XSkyTowerControl:ReleaseBusiness()
    self:StopSimulation()
    self._FoodIngredientsDict = nil
    self._FoodConsumesDict = nil
    self._ProductionStatistics = nil
    self._ProductionStatisticsDirty = nil
    self._ProductionCountsDirty = nil
    self._LocalProductionEntries = nil
    self._LocalProductionEntryPool = nil
    self._LocalProductionChangedGroups = nil
    self._LocalProductionInputsDict = nil
end

---服务端数据下发后刷新已加载的房间表现
function XSkyTowerControl:OnBusinessDataChange()
    self:ClearSkillShareIndex()
    for floorId, room in pairs(self._Rooms) do
        room:UpdateWork(floorId)
    end
end

--region 私有辅助

---@return number 工位所在楼层区间Id
function XSkyTowerControl:_GetGroupId(floorId)
    return self:GetFloorGroupIdByFloorId(floorId)
end

---@return XSkyTowerWorkPosInfoProtocol
function XSkyTowerControl:GetWorkPos(floorId, index)
    return self._Model:GetFloorWorkPosInfo(floorId, index)
end

---工位工作类型（备菜/做菜/售卖，同时用作产品所属区域）
---@return number XMVCA.XSkyTower.WorkType
function XSkyTowerControl:GetWorkType(floorId, index)
    local workPos = self:GetWorkPos(floorId, index)
    return workPos and workPos.WorkType or XMVCA.XSkyTower.WorkType.None
end

---@return number 工位产品Id
function XSkyTowerControl:GetProductId(floorId, index)
    local workPos = self:GetWorkPos(floorId, index)
    return workPos and workPos.ProductId or 0
end

---@return number 工位员工Id
function XSkyTowerControl:GetCharacterId(floorId, index)
    local workPos = self:GetWorkPos(floorId, index)
    return workPos and workPos.CharacterId or 0
end

---产品类型对应的区域类型（仓库上限配置按区域索引）
---@return number XMVCA.XSkyTower.WorkType
function XSkyTowerControl:_GetWorkTypeByProductType(productType)
    if productType == XMVCA.XSkyTower.ProductType.Ingredient then
        return XMVCA.XSkyTower.WorkType.Ingredient
    end
    return XMVCA.XSkyTower.WorkType.Food
end

--endregion

--region 工位状态查询

---当前工作状态，沿用协议枚举，与WorkType（备材/制作/售卖）无关
---@return number XMVCA.XSkyTower.ServerWorkState
function XSkyTowerControl:GetServerState(floorId, index)
    local workPos = self:GetWorkPos(floorId, index)
    return workPos and workPos.State or XMVCA.XSkyTower.ServerWorkState.Stop
end

---UI与角色行为树使用的表现状态，由当前工位数据映射
---@return number XMVCA.XSkyTower.WorkState
function XSkyTowerControl:GetWorkState(floorId, index)
    local WorkState = XMVCA.XSkyTower.WorkState
    if self:IsWorkPosFree(floorId, index) then
        return WorkState.Free
    end
    if self:GetServerState(floorId, index) == XMVCA.XSkyTower.ServerWorkState.Normal then
        return WorkState.Working
    end
    --主动停工仍保留员工和产品，在场景中显示停工表现
    return WorkState.Pause
end

function XSkyTowerControl:IsWorking(floorId, index)
    return self:GetWorkState(floorId, index) == XMVCA.XSkyTower.WorkState.Working
end

---因缺料或满仓暂停，区别于玩家主动停止工作
function XSkyTowerControl:IsPause(floorId, index)
    if self:IsWorkPosFree(floorId, index) then
        return false
    end
    local state = self:GetServerState(floorId, index)
    local ServerWorkState = XMVCA.XSkyTower.ServerWorkState
    return state == ServerWorkState.WaitForStorage or state == ServerWorkState.WaitForConsume
end

function XSkyTowerControl:IsRunning(floorId, index)
    return self:IsWorking(floorId, index) or self:IsPause(floorId, index)
end

---工位是否空闲（未安排工作、员工或产品）
function XSkyTowerControl:IsWorkPosFree(floorId, index)
    local workPos = self:GetWorkPos(floorId, index)
    if not workPos or (workPos.WorkType or 0) == XMVCA.XSkyTower.WorkType.None then
        return true
    end
    return not (XTool.IsNumberValid(workPos.CharacterId) and XTool.IsNumberValid(workPos.ProductId))
end

---本轮已投入秒数，与当前库存和预扣材料配套使用，回包时重新校准
function XSkyTowerControl:GetWorkedSeconds(floorId, index)
    local workPos = self:GetWorkPos(floorId, index)
    if not workPos or self:IsWorkPosFree(floorId, index) then
        return 0
    end
    return math.max(0, workPos.WorkedSeconds or 0)
end

---在每秒本地结算之间补齐显示进度，跨轮产出由OnSimulationTick统一处理
function XSkyTowerControl:GetWorkDisplaySeconds(floorId, index)
    local singleTime = self:GetProduceSingleTime(floorId, index)
    if singleTime <= 0 or self:IsWorkPosFree(floorId, index) then
        return 0
    end
    local seconds = self:GetWorkedSeconds(floorId, index)
    local syncTime = self._Model:GetWorkPosSyncTime(floorId, index)
    if self:IsWorking(floorId, index) and syncTime then
        seconds = seconds + math.max(0, XTime.GetServerNowTimestamp() - syncTime)
    end
    return math.min(singleTime, seconds)
end

---当前生产进度（0~1）
function XSkyTowerControl:GetWorkProgress(floorId, index)
    local singleTime = self:GetProduceSingleTime(floorId, index)
    return singleTime > 0 and self:GetWorkDisplaySeconds(floorId, index) / singleTime or 0
end

---当前产出倒计时（秒）
function XSkyTowerControl:GetCountDown(floorId, index)
    if self:IsWorkPosFree(floorId, index) then
        return 0
    end
    return math.max(0, self:GetProduceSingleTime(floorId, index) - self:GetWorkDisplaySeconds(floorId, index))
end

---本轮已预扣的实际输入，停工返还按此列表展示，不重新按现配方推算
function XSkyTowerControl:GetReservedInputs(floorId, index)
    local workPos = self:GetWorkPos(floorId, index)
    if not workPos then
        return table.empty
    end
    return workPos.ReservedInputs or table.empty
end

---本轮是否已有预扣材料
function XSkyTowerControl:IsConsume(floorId, index)
    return not XTool.IsTableEmpty(self:GetReservedInputs(floorId, index))
end

--endregion

--region 场景与倒计时刷新

---进入房间后每秒刷新表现，沿用原有定时器入口
function XSkyTowerControl:StartSimulation()
    if XScheduleManagerPro.HasSchedule(self._OnStartSimulationScheduleCb, self) then
        self:StopSimulation()
    end
    self._ActivityDataRequestInterval = self:GetIntClientConfigValue("ActivityDataRequestInterval")
    self._NextActivityDataRequestTime = nil
    XScheduleManagerPro.ScheduleForever(self._OnStartSimulationScheduleCb, self, XScheduleManagerPro.SECOND, XScheduleManagerPro.SECOND)
end

function XSkyTowerControl:_OnStartSimulationScheduleCb()
    self:OnSimulationTick()
end

function XSkyTowerControl:StopSimulation()
    XScheduleManagerPro.UnSchedule(self._OnStartSimulationScheduleCb, self)
    self._NextActivityDataRequestTime = nil
end

function XSkyTowerControl:OnSimulationTick()
    local nowTime = XTime.GetServerNowTimestamp()
    self:AdvanceLocalProduction(nowTime)
    self:OnRoomSimulation(nowTime)
    self:_UpdateActivityDataRequest(nowTime)
    self:OnTaskTick()
end

--- 模拟运行期间定时请求服务端结算
function XSkyTowerControl:_UpdateActivityDataRequest(nowTime)
    if not self:IsActivityInTime() then
        return
    end
    if not self._NextActivityDataRequestTime then
        self._NextActivityDataRequestTime = nowTime + self._ActivityDataRequestInterval
    end
    if nowTime < self._NextActivityDataRequestTime then
        return
    end
    -- 先推进请求时间，失败后等待下个周期，卡顿恢复也不连续补发
    self._NextActivityDataRequestTime = nowTime + self._ActivityDataRequestInterval
    self:RequestSettleToNow()
end

---本轮开工所需材料；售卖消耗一份食物，制作按现有配方消耗
---按工作类型和产品缓存；返回的列表及条目只读，工位预扣材料与快照会共用引用
function XSkyTowerControl:GetLocalProductionInputs(workPos)
    local WorkType = XMVCA.XSkyTower.WorkType
    local workType = workPos.WorkType
    if workType ~= WorkType.Sale and workType ~= WorkType.Food then
        return table.empty
    end
    local inputsDict = self._LocalProductionInputsDict[workType]
    if not inputsDict then
        inputsDict = {}
        self._LocalProductionInputsDict[workType] = inputsDict
    end
    local productId = workPos.ProductId
    local inputs = inputsDict[productId]
    if inputs then
        return inputs
    end
    inputs = {}
    if workType == WorkType.Sale then
        inputs[1] = { ProductType = XMVCA.XSkyTower.ProductType.Food, ProductId = workPos.ProductId, Count = 1 }
    elseif workType == WorkType.Food then
        local inputDict = {}
        for _, consume in ipairs(self:GetFoodConsumes(workPos.ProductId)) do
            if consume.Count > 0 then
                local key = self._Model:MakeStorageKey(consume.ProductType, consume.Id)
                local input = inputDict[key]
                if not input then
                    input = { ProductType = consume.ProductType, ProductId = consume.Id, Count = 0 }
                    inputDict[key] = input
                    inputs[#inputs + 1] = input
                end
                input.Count = input.Count + consume.Count
            end
        end
    end
    inputsDict[productId] = inputs
    return inputs
end

---材料与仓位都满足才预扣并开工；返回值表示本次是否成功开工
function XSkyTowerControl:TryStartLocalProduction(entry, time, changedGroups)
    if entry.Running or entry.Time > time then
        return false
    end
    local workPos = entry.WorkPos
    local state = XMVCA.XSkyTower.ServerWorkState.Normal
    for _, input in ipairs(entry.Inputs) do
        if self:GetStorageProductCount(entry.GroupId, input.ProductType, input.ProductId) < input.Count then
            state = XMVCA.XSkyTower.ServerWorkState.WaitForConsume
            break
        end
    end
    if state == XMVCA.XSkyTower.ServerWorkState.Normal and workPos.WorkType ~= XMVCA.XSkyTower.WorkType.Sale
        and self:GetFreeCapacity(entry.GroupId, workPos.ProductType, workPos.ProductId) <= 0 then
        state = XMVCA.XSkyTower.ServerWorkState.WaitForStorage
    end
    if workPos.State ~= state then
        workPos.State = state
        entry.Changed = true
    end
    if state ~= XMVCA.XSkyTower.ServerWorkState.Normal then
        return false
    end
    for _, input in ipairs(entry.Inputs) do
        local count = self:GetStorageProductCount(entry.GroupId, input.ProductType, input.ProductId)
        self._Model:UpdateStorageCount(entry.GroupId, input.ProductType, input.ProductId, count - input.Count)
        changedGroups[entry.GroupId] = true
    end
    workPos.ReservedInputs = entry.Inputs
    entry.Time = time
    entry.Running = true
    return true
end

---同一时刻先全部出货再统一开工；扣料释放仓位后，前面的满仓工位也能在这一刻复工
function XSkyTowerControl:StartLocalProductionRound(entries, time, changedGroups)
    for _ = 1, #entries do
        local started = false
        for _, entry in ipairs(entries) do
            if self:TryStartLocalProduction(entry, time, changedGroups) then
                started = true
            end
        end
        if not started then
            return
        end
    end
end

---本地完成一轮：产品按增产倍率入库，售卖按实际售价直接增加活动金币
---@return number 本轮销售金币
function XSkyTowerControl:CompleteLocalProduction(entry, changedGroups)
    local workPos = entry.WorkPos
    local goldCount = 0
    if workPos.WorkType == XMVCA.XSkyTower.WorkType.Sale then
        goldCount = self:GetFoodSinglePrice(entry.FloorId, entry.Index)
        self:AddTaskCommand(XMVCA.XSkyTower.PerformTaskType.SellOut, workPos.ProductId, 1)
    else
        local capacity = self:GetFreeCapacity(entry.GroupId, workPos.ProductType, workPos.ProductId)
        if capacity > 0 then
            local ratioBase = XMVCA.XSkyTower.TenThousandRate
            local outputRatio = math.floor(self:GetOutputCount(entry.FloorId, entry.Index) * ratioBase + 0.5)
            local total = outputRatio + (workPos.ProduceRemainder or 0)
            local outputCount = math.min(math.floor(total / ratioBase), capacity)
            workPos.ProduceRemainder = total % ratioBase
            if outputCount > 0 then
                local count = self:GetStorageProductCount(entry.GroupId, workPos.ProductType, workPos.ProductId)
                self._Model:UpdateStorageCount(entry.GroupId, workPos.ProductType, workPos.ProductId, count + outputCount)
                if workPos.WorkType == XMVCA.XSkyTower.WorkType.Food then
                    self:AddTaskCommand(XMVCA.XSkyTower.PerformTaskType.Production, workPos.ProductId, outputCount)
                end
                changedGroups[entry.GroupId] = true
            end
        end
    end
    workPos.WorkedSeconds = 0
    workPos.ReservedInputs = table.empty
    entry.Running = false
    entry.Changed = true
    return goldCount
end

local function SortLocalProductionEntry(a, b)
    return a.Key < b.Key
end

---在线时间按完成时刻推进，可补齐掉帧时错过的轮次，不发送生产结算协议
function XSkyTowerControl:AdvanceLocalProduction(nowTime)
    if not self:IsActivityInTime() then
        return
    end
    local currentTime = nowTime

    local infos = self._Model:GetAllWorkPosInfos()
    if XTool.IsTableEmpty(infos) then
        return
    end
    local entries = self._LocalProductionEntries
    local changedGroups = self._LocalProductionChangedGroups
    local entryPool = self._LocalProductionEntryPool
    -- 事件同步回调可能再次推进生产；外层仍持有 entries 时，内层使用独立容器。
    if #entries > 0 then
        entries = {}
        changedGroups = {}
    end
    for key, workPos in pairs(infos) do
        local floorId, index = self:ParseWorkPosKey(key)
        local groupId = self:GetFloorGroupIdByFloorId(floorId)
        if self:IsWorkPosFree(floorId, index) or workPos.State == XMVCA.XSkyTower.ServerWorkState.Stop then
            goto continue
        end
        local cycle = self:GetProduceSingleTime(floorId, index)
        local syncTime = self._Model:GetWorkPosSyncTime(floorId, index) or nowTime
        if cycle <= 0 or syncTime > nowTime then
            goto continue
        end
        self._Model:SaveLocalWorkPosSnapshot(floorId, index)
        local inputs = self:GetLocalProductionInputs(workPos)
        local entry = table.remove(entryPool) or {}
        entry.FloorId = floorId
        entry.Index = index
        entry.GroupId = groupId
        entry.WorkPos = workPos
        entry.Key = self:MakeWorkPosKey(floorId, index)
        entry.Cycle = cycle
        entry.Time = syncTime
        entry.Inputs = inputs
        entry.Running = workPos.State == XMVCA.XSkyTower.ServerWorkState.Normal and (#inputs == 0 or not XTool.IsTableEmpty(workPos.ReservedInputs))
        entry.Changed = false
        entries[#entries + 1] = entry
        currentTime = math.min(currentTime, syncTime)
        :: continue ::
    end
    if #entries == 0 then
        return
    end
    table.sort(entries, SortLocalProductionEntry)
    local goldCount = 0
    self:StartLocalProductionRound(entries, currentTime, changedGroups)
    repeat
        local nextTime = nowTime
        for _, entry in ipairs(entries) do
            if entry.Time > currentTime then
                nextTime = math.min(nextTime, entry.Time)
            elseif entry.Running then
                nextTime = math.min(nextTime, entry.Time + math.max(0, entry.Cycle - (entry.WorkPos.WorkedSeconds or 0)))
            end
        end
        for _, entry in ipairs(entries) do
            if entry.Time <= nextTime then
                local workPos = entry.WorkPos
                if entry.Running then
                    workPos.WorkedSeconds = (workPos.WorkedSeconds or 0) + nextTime - entry.Time
                    if workPos.WorkedSeconds >= entry.Cycle then
                        goldCount = goldCount + self:CompleteLocalProduction(entry, changedGroups)
                    end
                end
                entry.Time = nextTime
            end
        end
        self:StartLocalProductionRound(entries, nextTime, changedGroups)
        currentTime = nextTime
    until currentTime >= nowTime

    for _, entry in ipairs(entries) do
        self._Model:UpdateWorkPosSyncTime(entry.FloorId, entry.Index, entry.Time)
    end
    if goldCount > 0 then
        self._Model:ApplyLocalGoldProduction(goldCount)
        XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_LEVEL_CONDITION_CHANGE)
    end
    for groupId in pairs(changedGroups) do
        XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_STORAGE_CHANGE, groupId)
    end
    for _, entry in ipairs(entries) do
        if entry.Changed then
            XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_WORK_POS_CHANGE, entry.FloorId, entry.Index)
        end
    end
    for i = #entries, 1, -1 do
        local entry = entries[i]
        -- 只回收 entry 外壳，Inputs 仍可能被工位的 ReservedInputs 或快照引用。
        entry.WorkPos = nil
        entry.Inputs = nil
        entryPool[#entryPool + 1] = entry
        entries[i] = nil
    end
    for groupId in pairs(changedGroups) do
        changedGroups[groupId] = nil
    end
end

--endregion

--region 工位操作

--- 工位复合键，UI侧拖动落点标识用它做唯一Id
---@return number
function XSkyTowerControl:MakeWorkPosKey(floorId, index)
    return self._Model:MakeWorkPosKey(floorId, index)
end

--- 工位复合键解码
---@return number, number floorId, index
function XSkyTowerControl:ParseWorkPosKey(key)
    return self._Model:ParseWorkPosKey(key)
end

--endregion

--region 生产参数

---基础生产周期（每轮所需秒数，未计加成）
---@param override table 布局override，为空表示按当前实际布局算，用于拖动预览
function XSkyTowerControl:GetBaseProduceSpeed(floorId, index, override)
    local workPosInfo = self:_GetWorkPosView(override, floorId, index)
    -- 空闲判定内联：IsWorkPosFree只看实际布局，假设布局下的空闲要按override判
    if not workPosInfo or not (XTool.IsNumberValid(workPosInfo.CharacterId) and XTool.IsNumberValid(workPosInfo.ProductId)) then
        return 0
    end
    local workType = workPosInfo.WorkType
    local productId = workPosInfo.ProductId
    local WorkType = XMVCA.XSkyTower.WorkType
    if workType == WorkType.Ingredient then
        return self:GetIngredientBaseProduceSpeed(productId)
    elseif workType == WorkType.Food then
        return self:GetFoodBaseProduceSpeed(productId)
    elseif workType == WorkType.Sale then
        return self:GetFoodBaseSellSpeed(productId)
    end
    return 0
end

--- 每轮生产实际所需秒数，仅计算周期缩短；平均每件耗时需再除以平均每轮产量
---@param override table 布局override，为空表示按当前实际布局算，用于拖动预览
---@param previewRatios table<number, table<number, number>> 假设布局下的条件系数，override为空时不传
function XSkyTowerControl:GetProduceSingleTime(floorId, index, override, previewRatios)
    local baseSpeed = self:GetBaseProduceSpeed(floorId, index, override)
    if baseSpeed <= 0 then
        return 0
    end
    -- 周期减到0工位会以极限速度空转，故封在下限
    local reduceTime = self:GetAdditions(floorId, index, override, previewRatios)
    return math.max(baseSpeed - reduceTime, XMVCA.XSkyTower.MinCycleDuration)
end

--- 工位的三类加成合计（员工技能）
---@param override table 布局override，为空表示按当前实际布局算，用于拖动预览
---@param previewRatios table<number, table<number, number>> 假设布局下的条件系数，override为空时不传
---@return number, number, number 生产周期缩短秒数、产出数量提升万分比、售卖单价金币增量
function XSkyTowerControl:GetAdditions(floorId, index, override, previewRatios)
    local workPosInfo = self:_GetWorkPosView(override, floorId, index)
    if not workPosInfo or not (XTool.IsNumberValid(workPosInfo.CharacterId) and XTool.IsNumberValid(workPosInfo.ProductId)) then
        return 0, 0, 0
    end
    -- 技能来源不限本工位角色，还含光环覆盖过来的技能
    return self:GetWorkPosSkillAdditions(floorId, index, override, previewRatios)
end

--- 平均每轮产出份数：收集与制作的基数恒为1，仅计算增产；实际整件产出通过跨轮余数累计
---@param override table 布局override，为空表示按当前实际布局算，用于拖动预览
---@param previewRatios table<number, table<number, number>> 假设布局下的条件系数，override为空时不传
function XSkyTowerControl:GetOutputCount(floorId, index, override, previewRatios)
    local _, upProduceRatio = self:GetAdditions(floorId, index, override, previewRatios)
    return math.max((XMVCA.XSkyTower.TenThousandRate + upProduceRatio) / XMVCA.XSkyTower.TenThousandRate, XMVCA.XSkyTower.MinOutputCount)
end

--- 售卖单价相对基础售价的金币增量，仅包含单价提升加成，供工位详情展示
---@param override table 布局override，为空时读取实际工位
---@param previewRatios table<number, table<number, number>> 与override同源的技能条件系数
function XSkyTowerControl:GetFoodPriceAddition(floorId, index, override, previewRatios)
    local _, _, upPriceCount = self:GetAdditions(floorId, index, override, previewRatios)
    return upPriceCount
end

---单位时间产量（售卖台不产出，恒为0）
---@param timeUnit number 时间单位（秒），默认小时
function XSkyTowerControl:GetProductiveness(floorId, index, timeUnit)
    timeUnit = timeUnit or XMVCA.XSkyTower.TimeUnit.Hour
    if self:GetWorkType(floorId, index) == XMVCA.XSkyTower.WorkType.Sale then
        return 0
    end
    if self:IsWorkPosFree(floorId, index) then
        return 0
    end
    local produceNeedTime = self:GetProduceSingleTime(floorId, index)
    if produceNeedTime == 0 then
        return timeUnit
    end
    -- 周期数乘上单轮产出份数才是实际产量
    return timeUnit / produceNeedTime * self:GetOutputCount(floorId, index)
end

---单位时间对指定产品的消耗量（做菜台消耗食材与手作、售卖台消耗食物）
---@param consumeProductId number 被消耗的产品Id
---@param consumeWorkType number 被消耗产品的区域类型，做菜台的食材与手作可能同Id，靠它区分；不传则不区分
function XSkyTowerControl:GetConsumption(floorId, index, consumeProductId, timeUnit, consumeWorkType)
    timeUnit = timeUnit or XMVCA.XSkyTower.TimeUnit.Hour
    if self:IsWorkPosFree(floorId, index) then
        return 0
    end
    local workType = self:GetWorkType(floorId, index)
    local productId = self:GetProductId(floorId, index)
    local WorkType = XMVCA.XSkyTower.WorkType
    if workType == WorkType.Food then
        local addSpeed = self:GetProduceSingleTime(floorId, index)
        if addSpeed <= 0 then
            XLog.Error("食物的生产速度小于等于0，请检查配置! foodId = ", productId)
            return timeUnit
        end
        local speed = 0
        local count = timeUnit / addSpeed
        for _, consume in ipairs(self:GetFoodConsumes(productId)) do
            local match = consume.Id == consumeProductId and (not consumeWorkType or consume.WorkType == consumeWorkType)
            if match then
                speed = speed + consume.Count * count
            end
        end
        return speed
    elseif workType == WorkType.Sale then
        if consumeProductId ~= productId then
            return 0
        end
        local saleNeedTime = self:GetProduceSingleTime(floorId, index)
        if saleNeedTime <= 0 then
            XLog.Error("食物的售卖速度小于等于0，请检查配置! foodId = ", productId)
            return timeUnit
        end
        return timeUnit / saleNeedTime
    end
    return 0
end

---售卖单份食物的成交价，仅受售卖单价提升加成影响
---@param override table 布局override，为空表示按当前实际布局算，用于拖动预览
---@param previewRatios table<number, table<number, number>> 假设布局下的条件系数，override为空时不传
function XSkyTowerControl:GetFoodSinglePrice(floorId, index, override, previewRatios)
    local workPosInfo = self:_GetWorkPosView(override, floorId, index)
    -- 空闲判定内联：IsWorkPosFree只看实际布局，假设布局下的空闲要按override判
    if not workPosInfo or not (XTool.IsNumberValid(workPosInfo.CharacterId) and XTool.IsNumberValid(workPosInfo.ProductId)) then
        return 0
    end
    local _, _, upPriceCount = self:GetAdditions(floorId, index, override, previewRatios)
    local basePrice = self:GetFoodBaseSellPrice(workPosInfo.ProductId)
    return basePrice + upPriceCount
end

--endregion

--region 工位判定

---产出是否已满
---@param override table 布局override，为空时读取实际工位
function XSkyTowerControl:IsFull(floorId, index, override)
    local workPos = self:_GetWorkPosView(override, floorId, index)
    if not workPos or not XTool.IsNumberValid(workPos.ProductId) then
        return false
    end
    local groupId = self:_GetGroupId(floorId)
    if workPos.WorkType == XMVCA.XSkyTower.WorkType.Sale then
        return false --销售没有上限
    end
    return self:IsStorageProductFull(groupId, self:GetProductTypeByWorkType(workPos.WorkType), workPos.ProductId)
end

---原料是否不足（备菜台无原料消耗，恒为false）
---@param override table 布局override，为空时读取实际工位
function XSkyTowerControl:IsInsufficient(floorId, index, override)
    local workPos = self:_GetWorkPosView(override, floorId, index)
    if not workPos then
        return true
    end
    local WorkType = XMVCA.XSkyTower.WorkType
    if workPos.WorkType == WorkType.Ingredient then
        return false
    end
    if not XTool.IsNumberValid(workPos.ProductId) then
        return true
    end
    local groupId = self:_GetGroupId(floorId)
    if workPos.WorkType == WorkType.Food then
        return not self:IsStorageSufficientMaterial(groupId, workPos.ProductId, 1)
    elseif workPos.WorkType == WorkType.Sale then
        return self:GetStorageProductCount(groupId, XMVCA.XSkyTower.ProductType.Food, workPos.ProductId) <= 0
    end
    return true
end

---工位能否加速
function XSkyTowerControl:CheckCanAccelerate(floorId, index)
    --使用达到上限
    if self._Model:IsAccelerateUpperLimit() then
        return false
    end
    --道具不够
    if self._Model:GetSpeedUpItemCount() <= 0 then
        return false
    end
    --未在工作
    if not self:IsWorking(floorId, index) then
        return false
    end
    --Normal表示服务端已开工；预扣后库存可能已为0，不能据此再判定缺料
    return true
end

--endregion

--region 区间仓库

--- 区间仓库产品数量（取整）
function XSkyTowerControl:GetStorageProductCount(groupId, productType, productId)
    return math.floor(self._Model:GetStorageCount(groupId, productType, productId))
end

---区间仓库产品上限（取整）
function XSkyTowerControl:GetStorageProductLimit(groupId, productType, productId)
    local workType = self:_GetWorkTypeByProductType(productType)
    return self:GetStorageLimit(workType, self:GetSkyTowerLv(), productId)
end

function XSkyTowerControl:IsStorageProductFull(groupId, productType, productId)
    return self:GetStorageProductCount(groupId, productType, productId) >= self:GetStorageProductLimit(groupId, productType, productId)
end

function XSkyTowerControl:IsStorageProductSufficient(groupId, productType, productId, count)
    return self:GetStorageProductCount(groupId, productType, productId) >= (count or 0)
end

---仓库剩余容量
function XSkyTowerControl:GetFreeCapacity(groupId, productType, productId)
    return math.max(0, self:GetStorageProductLimit(groupId, productType, productId) - self:GetStorageProductCount(groupId, productType, productId))
end

---仓库是否够制作指定份数的食物（食材 + 手作一并校验）
function XSkyTowerControl:IsStorageSufficientMaterial(groupId, foodId, count)
    count = count or 1
    for _, consume in ipairs(self:GetFoodConsumes(foodId)) do
        local need = consume.Count * count
        if not self:IsStorageProductSufficient(groupId, consume.ProductType, consume.Id, need) then
            return false
        end
    end
    return true
end

--- 分区仓库的有序展示列表：当前配方所需物品优先，其余按类型与Id排序，库存为0也展示
---@param groupId number
---@param productId number 当前选中的产品，未选时只按类型与Id定序
---@return XSkyTowerStorageInfoProtocol[]
function XSkyTowerControl:GetSortedStorageList(groupId, productId)
    local list = {}
    local workTypeEnum = XMVCA.XSkyTower.WorkType
    for _, workType in ipairs({ workTypeEnum.Ingredient, workTypeEnum.Food }) do
        local productType = self:GetProductTypeByWorkType(workType)
        for _, id in ipairs(self:GetUnlockProductIds(workType)) do
            if self:IsProductInFloorGroup(groupId, productType, id) then
                --库存协议可能没有尚未产出的物品，只构造展示数据，数量仍从对应分区读取
                table.insert(list, {
                    ProductType = productType,
                    ProductId = id,
                    Count = self:GetStorageProductCount(groupId, productType, id),
                })
            end
        end
    end

    local consumeDict = self:GetFoodConsumeDict(productId)
    table.sort(list, function(a, b)
        local needA = consumeDict[a.ProductType] and consumeDict[a.ProductType][a.ProductId] or false
        local needB = consumeDict[b.ProductType] and consumeDict[b.ProductType][b.ProductId] or false
        if needA ~= needB then
            return needA
        end
        if a.ProductType ~= b.ProductType then
            return a.ProductType < b.ProductType
        end
        -- 同组内按Id定序
        return a.ProductId < b.ProductId
    end)
    return list
end

--- 食物配方需求，按 [产品类型][产品Id] 索引
---@param foodId number
---@return table<number, table<number, boolean>>
function XSkyTowerControl:GetFoodConsumeDict(foodId)
    if not XTool.IsNumberValid(foodId) then
        return table.empty
    end
    local dict = {}
    for _, consume in ipairs(self:GetFoodConsumes(foodId)) do
        local productType = consume.ProductType
        dict[productType] = dict[productType] or {}
        dict[productType][consume.Id] = true
    end
    return dict
end

--endregion

--region 区间总速度统计

function XSkyTowerControl:GetOrCreateProductionGroup(statistics, groupId)
    local groupData = statistics[groupId]
    if not groupData then
        local ProductType = XMVCA.XSkyTower.ProductType
        groupData = {
            GoldSpeed = 0,
            CharacterSpeed = 0,
            TheoreticalGoldSpeed = 0,
            TheoreticalCharacterSpeed = 0,
            Products = { [ProductType.Food] = {}, [ProductType.Ingredient] = {} },
        }
        statistics[groupId] = groupData
    end
    return groupData
end

function XSkyTowerControl:GetOrCreateProductionProduct(groupData, productType, productId)
    local products = groupData.Products[productType]
    if not products then
        products = {}
        groupData.Products[productType] = products
    end
    local data = products[productId]
    if not data then
        data = {
            ProduceSpeed = 0, ConsumeSpeed = 0, ChangeSpeed = 0,
            TheoreticalProduceSpeed = 0, TheoreticalConsumeSpeed = 0, TheoreticalChangeSpeed = 0,
            Count = 0,
        }
        products[productId] = data
    end
    return data
end

function XSkyTowerControl:InvalidateProductionStatistics()
    self._ProductionStatisticsDirty = true
    self._ProductionCountsDirty = true
end

function XSkyTowerControl:InvalidateProductionCounts()
    self._ProductionCountsDirty = true
end

---产销与收益统计，全部速率为每小时原始值；原字段仅计入正常工作工位，供趋势与任务使用
---Theoretical前缀字段计入已安排的暂停、停工工位，仅供统计页展示理论能力；库存Count共用
---返回由Control持有、原地更新的共享记录，调用方只读，展示时再取整
---@return table 分区Id -> { GoldSpeed, CharacterSpeed, TheoreticalGoldSpeed, TheoreticalCharacterSpeed, Products }
function XSkyTowerControl:GetProductionStatistics()
    local statistics = self._ProductionStatistics
    if not statistics then
        statistics = {}
        self._ProductionStatistics = statistics
        self:InvalidateProductionStatistics()
    end
    if not self._Model:IsDataReady() then
        self:InvalidateProductionStatistics()
        self:_ResetProductionStatistics(statistics)
        return statistics
    end

    local updateSpeeds = self._ProductionStatisticsDirty
    if not updateSpeeds and not self._ProductionCountsDirty then
        return statistics
    end

    local maxGroupId = self:GetMaxFloorGroupId()
    if updateSpeeds then
        self:_ResetProductionStatistics(statistics)
        self:_InitProductionStatisticsProducts(statistics, maxGroupId)
        self:_AccumulateProductionWorkPos(statistics, maxGroupId)
    end

    self:_RefreshProductionStatistics(statistics, maxGroupId, updateSpeeds)
    self._ProductionStatisticsDirty = false
    self._ProductionCountsDirty = false
    return statistics
end

---退出玩法时每个已开放分区上报一次；与统计页一致，使用每小时理论速率的原始值
function XSkyTowerControl:RecordProductionStatistics()
    if not self._Model:IsOpen() then
        return
    end
    local statistics = self:GetProductionStatistics()
    local towerLevel = self:GetSkyTowerLv()
    local ProductType = XMVCA.XSkyTower.ProductType
    local record = {}
    for groupId = 1, self:GetMaxFloorGroupId() do
        local groupData = statistics[groupId]
        local ingredientProduce, ingredientConsume, ingredientChange = {}, {}, {}
        local foodProduce, foodConsume, foodChange = {}, {}, {}
        for productType, products in pairs(groupData.Products) do
            local produce, consume, change
            if productType == ProductType.Ingredient then
                produce, consume, change = ingredientProduce, ingredientConsume, ingredientChange
            elseif productType == ProductType.Food then
                produce, consume, change = foodProduce, foodConsume, foodChange
            else
                goto continue
            end
            for productId, data in pairs(products) do
                --XRecord将LuaTable转为字符串键字典，不能直接使用数值Id作键
                local key = tostring(productId)
                produce[key] = data.TheoreticalProduceSpeed
                consume[key] = data.TheoreticalConsumeSpeed
                change[key] = data.TheoreticalChangeSpeed
            end
            :: continue ::
        end
        table.insert(record, {
            role_id = XPlayer.Id,
            tower_level = towerLevel,
            floor_group = string.char(string.byte("A") + groupId - 1),
            floor_group_id = groupId,
            ingredient_produce_speed = ingredientProduce,
            ingredient_consume_speed = ingredientConsume,
            ingredient_change_speed = ingredientChange,
            food_produce_speed = foodProduce,
            food_consume_speed = foodConsume,
            food_change_speed = foodChange,
            gold_produce_speed = groupData.TheoreticalGoldSpeed,
        })
    end
    CS.XRecord.Record(record, "1000052", "SkyTowerProductionSpeed")
end

---保留分区、分类和产品记录，状态或安排变更、数据清除后，两套速率均不能残留上一轮数值
function XSkyTowerControl:_ResetProductionStatistics(statistics)
    for _, groupData in pairs(statistics) do
        groupData.GoldSpeed = 0
        groupData.CharacterSpeed = 0
        groupData.TheoreticalGoldSpeed = 0
        groupData.TheoreticalCharacterSpeed = 0
        for _, products in pairs(groupData.Products) do
            for _, data in pairs(products) do
                data.ProduceSpeed = 0
                data.ConsumeSpeed = 0
                data.ChangeSpeed = 0
                data.TheoreticalProduceSpeed = 0
                data.TheoreticalConsumeSpeed = 0
                data.TheoreticalChangeSpeed = 0
                data.Count = 0
            end
        end
    end
end

---没有安排工位的分区也要显示配置中的产品及库存
function XSkyTowerControl:_InitProductionStatisticsProducts(statistics, maxGroupId)
    local ProductType = XMVCA.XSkyTower.ProductType
    for groupId = 1, maxGroupId do
        local groupData = self:GetOrCreateProductionGroup(statistics, groupId)
        local config = self:GetFloorGroupConfig(groupId)
        for _, productId in ipairs(config.FoodIds) do
            self:GetOrCreateProductionProduct(groupData, ProductType.Food, productId)
        end
        for _, productId in ipairs(config.IngredientIds) do
            self:GetOrCreateProductionProduct(groupData, ProductType.Ingredient, productId)
        end
    end
end

---扁平工位表只遍历一次，不创建逐分区、逐工位的回调闭包
function XSkyTowerControl:_AccumulateProductionWorkPos(statistics, maxGroupId)
    local maxFloorId = self:GetMaxFloorId()
    for key, workPos in pairs(self._Model:GetAllWorkPosInfos() or table.empty) do
        local floorId, index = self._Model:ParseWorkPosKey(key)
        if floorId > 0 and floorId <= maxFloorId then
            self:_AccumulateWorkPosProduction(statistics, maxGroupId, floorId, index, workPos)
        end
    end
end

---已安排工位累计理论能力，仅正常工作工位同时累计趋势与任务使用的速率
---@param workPos XSkyTowerWorkPosInfoProtocol
function XSkyTowerControl:_AccumulateWorkPosProduction(statistics, maxGroupId, floorId, index, workPos)
    local groupId = self:GetFloorGroupIdByFloorId(floorId)
    if not (groupId > 0 and groupId <= maxGroupId) then
        return
    end

    local workType = workPos.WorkType
    local WorkType = XMVCA.XSkyTower.WorkType
    if workType ~= WorkType.Ingredient and workType ~= WorkType.Food and workType ~= WorkType.Sale then
        return
    end
    if self:IsWorkPosFree(floorId, index) then
        return
    end
    local cycle = self:GetProduceSingleTime(floorId, index)
    if not (cycle > 0) then
        return
    end

    local isWorking = self:IsWorking(floorId, index)
    local groupData = statistics[groupId]
    local ProductType = XMVCA.XSkyTower.ProductType
    local productType = workType == WorkType.Ingredient and ProductType.Ingredient or ProductType.Food
    local data = self:GetOrCreateProductionProduct(groupData, productType, workPos.ProductId)
    local cyclesPerHour = XMVCA.XSkyTower.TimeUnit.Hour / cycle
    if workType == WorkType.Sale then
        --同产品在不同售卖工位的售价可能不同，逐工位累计
        local goldSpeed = cyclesPerHour * self:GetFoodSinglePrice(floorId, index)
        data.TheoreticalConsumeSpeed = data.TheoreticalConsumeSpeed + cyclesPerHour
        groupData.TheoreticalGoldSpeed = groupData.TheoreticalGoldSpeed + goldSpeed
        if isWorking then
            data.ConsumeSpeed = data.ConsumeSpeed + cyclesPerHour
            groupData.GoldSpeed = groupData.GoldSpeed + goldSpeed
        end
        return
    end

    local produceSpeed = cyclesPerHour * self:GetOutputCount(floorId, index)
    data.TheoreticalProduceSpeed = data.TheoreticalProduceSpeed + produceSpeed
    if isWorking then
        data.ProduceSpeed = data.ProduceSpeed + produceSpeed
    end
    if workType == WorkType.Food then
        self:_AccumulateFoodProductionConsumes(groupData, workPos.ProductId, cyclesPerHour, isWorking)
    end
end

---读取缓存配方，避免构造本轮生产用的临时材料表
function XSkyTowerControl:_AccumulateFoodProductionConsumes(groupData, foodId, cyclesPerHour, isWorking)
    for _, consume in ipairs(self:GetFoodConsumes(foodId)) do
        if consume.Count > 0 then
            local consumeData = self:GetOrCreateProductionProduct(groupData, consume.ProductType, consume.Id)
            local consumeSpeed = cyclesPerHour * consume.Count
            consumeData.TheoreticalConsumeSpeed = consumeData.TheoreticalConsumeSpeed + consumeSpeed
            if isWorking then
                consumeData.ConsumeSpeed = consumeData.ConsumeSpeed + consumeSpeed
            end
        end
    end
end

---共用分区遍历更新速率和库存；仅库存变化时跳过收益配置与速率计算
function XSkyTowerControl:_RefreshProductionStatistics(statistics, maxGroupId, updateSpeeds)
    local characterItemPerGold = 0
    if updateSpeeds then
        local goldBase = self:GetIntConfigValue("GoldTransCharaLvUpItemBase")
        characterItemPerGold = goldBase > 0 and self:GetIntConfigValue("GoldTransCharaLvUpItemNum") / goldBase or 0
    end

    for groupId, groupData in pairs(statistics) do
        if updateSpeeds then
            groupData.CharacterSpeed = groupData.GoldSpeed * characterItemPerGold
            groupData.TheoreticalCharacterSpeed = groupData.TheoreticalGoldSpeed * characterItemPerGold
        end
        local updateCounts = groupId > 0 and groupId <= maxGroupId
        if updateSpeeds or updateCounts then
            self:_RefreshProductionGroupStatistics(groupId, groupData, updateSpeeds, updateCounts)
        end
    end
end

---单个分区的产品只遍历一次，按需更新每小时净速率与库存数量
function XSkyTowerControl:_RefreshProductionGroupStatistics(groupId, groupData, updateSpeeds, updateCounts)
    for productType, products in pairs(groupData.Products) do
        for productId, data in pairs(products) do
            if updateSpeeds then
                data.ChangeSpeed = data.ProduceSpeed - data.ConsumeSpeed
                data.TheoreticalChangeSpeed = data.TheoreticalProduceSpeed - data.TheoreticalConsumeSpeed
            end
            if updateCounts then
                data.Count = self:GetStorageProductCount(groupId, productType, productId)
            end
        end
    end
end

---区间内某产品的总生产速度
---@param workType number 产品所属区域（备菜区统计备菜台，做菜区统计做菜台）
function XSkyTowerControl:GetGroupProduceTotalSpeed(groupId, workType, productId, timeUnit)
    if workType == XMVCA.XSkyTower.WorkType.Sale then
        return 0
    end
    local total = 0
    local floorIds = self:GetFloorIdsByGroupId(groupId)
    for _, floorId in pairs(floorIds) do
        for index = 1, self:GetFloorWorkNum(floorId) do
            local workPos = self._Model:GetFloorWorkPosInfo(floorId, index)
            if workPos and (not workType or workPos.WorkType == workType) and not self:IsWorkPosFree(floorId, index) and workPos.ProductId == productId then
                total = total + self:GetProductiveness(floorId, index, timeUnit)
            end
        end
    end
    return total
end

---区间内某产品的总消耗速度
---食材只被做菜台消耗；手作既被售卖台卖掉，也可能被做菜台当组合材料吃掉
function XSkyTowerControl:GetGroupConsumeTotalSpeed(groupId, workType, productId, timeUnit)
    local WorkType = XMVCA.XSkyTower.WorkType
    local isIngredient = workType == WorkType.Ingredient
    --售卖区选的产品本身就是手作，归一化后才能和做菜台的配方对上
    local productWorkType = isIngredient and WorkType.Ingredient or WorkType.Food
    local total = 0
    local floorIds = self:GetFloorIdsByGroupId(groupId)
    for _, floorId in pairs(floorIds) do
        for index = 1, self:GetFloorWorkNum(floorId) do
            local workPos = self._Model:GetFloorWorkPosInfo(floorId, index)
            if self:IsWorkPosFree(floorId, index) then
                goto continue
            end
            if isIngredient and workPos.WorkType ~= WorkType.Food then
                goto continue
            end
            if not isIngredient and workPos.WorkType ~= WorkType.Sale and workPos.WorkType ~= WorkType.Food then
                goto continue --食物区与售卖区的产品都会被售卖台卖出，食物还会被做菜台用作组合材料
            end
            total = total + self:GetConsumption(floorId, index, productId, timeUnit, productWorkType)
            :: continue ::
        end
    end
    return total
end

--- 区间内正在生产/售卖某产品的最高楼层，供仓库点击定位镜头
--- 食材只由备菜台产出；手作既由做菜台产出，也由售卖台卖出，两类工位都算
---@param workType number 产品所属区域（XMVCA.XSkyTower.WorkType）
---@return number 0表示区间内没有工位在生产/售卖该产品
function XSkyTowerControl:GetGroupMaxProduceFloorId(groupId, workType, productId)
    if not XTool.IsNumberValid(groupId) or not XTool.IsNumberValid(productId) then
        return 0
    end
    local WorkType = XMVCA.XSkyTower.WorkType
    local isIngredient = workType == WorkType.Ingredient
    local maxFloorId = 0
    local floorIds = self:GetFloorIdsByGroupId(groupId)
    for _, floorId in pairs(floorIds) do
        for index = 1, self:GetFloorWorkNum(floorId) do
            local workPos = self._Model:GetFloorWorkPosInfo(floorId, index)
            -- 空闲工位（未安排员工）不算在产
            if self:IsWorkPosFree(floorId, index) or workPos.ProductId ~= productId then
                goto continue
            end
            if isIngredient and workPos.WorkType ~= WorkType.Ingredient then
                goto continue
            end
            if not isIngredient and workPos.WorkType ~= WorkType.Food and workPos.WorkType ~= WorkType.Sale then
                goto continue
            end
            maxFloorId = math.max(maxFloorId, floorId)
            :: continue ::
        end
    end
    return maxFloorId
end

---食材是否告急（按当前产销差推算耗尽时间，只判定食材）
function XSkyTowerControl:IsGroupUrgentProduct(groupId, workType, productId)
    if workType ~= XMVCA.XSkyTower.WorkType.Ingredient then
        return false
    end
    local timeUnit = XMVCA.XSkyTower.TimeUnit.Hour
    local produceSpeed = self:GetGroupProduceTotalSpeed(groupId, workType, productId, timeUnit)
    local consumeSpeed = self:GetGroupConsumeTotalSpeed(groupId, workType, productId, timeUnit)
    if produceSpeed == 0 and consumeSpeed == 0 then
        return false
    end
    --产大于销不会告急
    if produceSpeed >= consumeSpeed then
        return false
    end
    local count = self:GetStorageProductCount(groupId, XMVCA.XSkyTower.ProductType.Ingredient, productId)
    local second = (count / (consumeSpeed - produceSpeed)) * timeUnit
    return second <= self:GetConfigUrgentTime()
end

--endregion

--region 已解锁产品与排序

---已解锁产品Id列表
---@param workType number 区域类型（备菜区取食材，其余取食物）
---@param isSort boolean 是否排序
---@return number[]
function XSkyTowerControl:GetUnlockProductIds(workType, isSort)
    local list = {}
    if workType == XMVCA.XSkyTower.WorkType.Ingredient then
        for _, ingredientId in ipairs(self:GetAllIngredientIds()) do
            if self._Model.ClientRun:CheckIngredientUnlock(ingredientId) then
                table.insert(list, ingredientId)
            end
        end
        if isSort then
            table.sort(list, function(a, b)
                local priorityA = self:GetIngredientPriority(a)
                local priorityB = self:GetIngredientPriority(b)
                if priorityA ~= priorityB then
                    return priorityA < priorityB
                end
                return a < b
            end)
        end
        return list
    end
    for _, food in ipairs(self._Model:GetFoodConfigs()) do
        if self._Model.ClientRun:CheckFoodUnlock(food.Id) then
            table.insert(list, food.Id)
        end
    end
    if isSort then
        table.sort(list, function(a, b)
            local priorityA = self:GetFoodPriority(a)
            local priorityB = self:GetFoodPriority(b)
            if priorityA ~= priorityB then
                return priorityA < priorityB
            end
            return a < b
        end)
    end
    return list
end

--- 楼层所属分区内已解锁的产品Id列表
---@param floorId number
---@param workType number 区域类型（备菜区取食材，其余取食物）
---@param isSort boolean 是否排序
---@return number[]
function XSkyTowerControl:GetFloorGroupUnlockProductIds(floorId, workType, isSort)
    local groupId = self:GetFloorGroupIdByFloorId(floorId)
    local productType = self:GetProductTypeByWorkType(workType)
    local list = {}
    local config = self._Model:GetFloorGroupConfig(groupId)
    if not config then
        return list
    end
    local groupProductIds = productType == XMVCA.XSkyTower.ProductType.Ingredient and config.IngredientIds or config.FoodIds
    local productIdSet = {}
    for _, productId in ipairs(groupProductIds or table.empty) do
        productIdSet[productId] = true
    end
    for _, productId in ipairs(self:GetUnlockProductIds(workType, isSort)) do
        if productIdSet[productId] then
            table.insert(list, productId)
        end
    end
    return list
end

---已解锁产品数量
function XSkyTowerControl:GetUnlockProductCount(workType)
    return #self:GetUnlockProductIds(workType)
end

--endregion

--region 提示文案

---库存满提示
---@return string, string 标题, 内容
---@param override table 布局override，为空时读取实际工位
function XSkyTowerControl:GetFullTitleAndContent(floorId, index, override)
    local key = "StorageFullTip"
    local workPos = self:_GetWorkPosView(override, floorId, index)
    local productName = self:GetProductName(workPos.WorkType, workPos.ProductId)
    if workPos.WorkType == XMVCA.XSkyTower.WorkType.Sale then
        return nil, nil
    end
    local title = self:GetClientConfigValue(key, 3)
    local content = self:GetClientConfigValue(key, 4)
    content = XUiHelper.ReplaceTextNewLine(string.format(content, productName, productName))
    return title, content
end

---原料不足提示（备菜台无原料消耗，返回nil）
---@return string, string 标题, 内容
---@param override table 布局override，为空时读取实际工位
function XSkyTowerControl:GetInsufficientTitleAndContent(floorId, index, override)
    local key = "ProductNotEnough"
    local workPos = self:_GetWorkPosView(override, floorId, index)
    local workType = workPos.WorkType
    local WorkType = XMVCA.XSkyTower.WorkType
    local productName = self:GetProductName(workType, workPos.ProductId)
    if workType == WorkType.Food then
        local title = self:GetClientConfigValue(key, 1)
        local content = self:GetClientConfigValue(key, 2)
        content = XUiHelper.ReplaceTextNewLine(string.format(content, productName, productName, productName))
        return title, content
    elseif workType == WorkType.Sale then
        local title = self:GetClientConfigValue(key, 3)
        local content = self:GetClientConfigValue(key, 4)
        content = XUiHelper.ReplaceTextNewLine(string.format(content, productName, productName))
        return title, content
    end
end

---终止工作提示
---@return string, string 标题, 内容
function XSkyTowerControl:GetStopTipTitleAndContent(floorId, index)
    local key = "StopProduceTip"
    local workType = self:GetWorkType(floorId, index)
    local WorkType = XMVCA.XSkyTower.WorkType
    local name = self:GetWorkPosProductName(floorId, index)
    if workType == WorkType.Ingredient then
        local title = self:GetClientConfigValue(key, 1)
        local content = self:GetClientConfigValue(key, 2)
        return string.format(title, name), XUiHelper.ReplaceTextNewLine(string.format(content, name))
    elseif workType == WorkType.Food then
        local title = self:GetClientConfigValue(key, 3)
        local content
        if self:IsConsume(floorId, index) then
            --按服务端的预扣快照展示返还数量，配方热更也不改变这批已扣材料
            local returnTip = ""
            for _, consume in ipairs(self:GetReservedInputs(floorId, index)) do
                local consumeWorkType = self:_GetWorkTypeByProductType(consume.ProductType)
                returnTip = string.format("%s%s*%s ", returnTip, self:GetProductName(consumeWorkType, consume.ProductId), consume.Count)
            end
            content = self:GetClientConfigValue(key, 4)
            content = string.format(content, name, returnTip)
        else
            content = self:GetClientConfigValue(key, 5)
            content = string.format(content, name)
        end
        return string.format(title, name), XUiHelper.ReplaceTextNewLine(content)
    elseif workType == WorkType.Sale then
        local title = self:GetClientConfigValue(key, 6)
        local content
        if self:IsConsume(floorId, index) then
            content = self:GetClientConfigValue(key, 7)
            content = string.format(content, name, name)
        else
            content = self:GetClientConfigValue(key, 8)
            content = string.format(content, name)
        end
        return string.format(title, name), XUiHelper.ReplaceTextNewLine(content)
    end
    return "", ""
end

--endregion

--region 产品信息

---工位产品名字
function XSkyTowerControl:GetWorkPosProductName(floorId, index)
    local productId = self:GetProductId(floorId, index)
    if self:GetWorkType(floorId, index) == XMVCA.XSkyTower.WorkType.Ingredient then
        return self:GetIngredientName(productId)
    end
    return self:GetFoodName(productId)
end

---工位产品图标
function XSkyTowerControl:GetWorkPosProductIcon(floorId, index)
    local productId = self:GetProductId(floorId, index)
    if self:GetWorkType(floorId, index) == XMVCA.XSkyTower.WorkType.Ingredient then
        return self:GetIngredientIcon(productId)
    end
    return self:GetFoodIcon(productId)
end

---区域类型转产品类型
---@param workType number XMVCA.XSkyTower.WorkType
---@return number XMVCA.XSkyTower.ProductType
function XSkyTowerControl:GetProductTypeByWorkType(workType)
    if workType == XMVCA.XSkyTower.WorkType.Ingredient then
        return XMVCA.XSkyTower.ProductType.Ingredient
    end
    return XMVCA.XSkyTower.ProductType.Food
end

---产品售价（食材返回0）
function XSkyTowerControl:GetProductSellPrice(workType, productId)
    if workType == XMVCA.XSkyTower.WorkType.Ingredient then
        return 0
    end
    return self:GetFoodBaseSellPrice(productId)
end

---产品排序优先级已在“已解锁产品与排序”提供：GetProductPriority(workType, productId)

---产品是否解锁
function XSkyTowerControl:IsProductUnlock(workType, productId)
    if workType == XMVCA.XSkyTower.WorkType.Ingredient then
        return self._Model.ClientRun:CheckIngredientUnlock(productId)
    end
    return self._Model.ClientRun:CheckFoodUnlock(productId)
end

--endregion

--region 离线账单与升级

--- 是否展示离线账单，金币和角色券收益都为0时不弹
function XSkyTowerControl:IsOfflineBillReady()
    return XTool.IsNumberValid(self._Model:GetOfflineBill()) or XTool.IsNumberValid(self._Model:GetOfflineCharacterLvUpItemCount())
end

---通天塔升级（刷新等级与已解锁产品）
function XSkyTowerControl:LevelUp(level)
    self._Model:UpdateSkyTowerLv(level)
    ---实例化新楼层（已预加载）
    local maxFloorId = self._Model:GetMaxFloorId()
    for floorId = 1, maxFloorId do
        if not self:IsExistRoom(floorId) then
            local go = XMVCA.XSkyTower:LoadFloor(floorId)
            self:GetRoom(floorId):SetGameObject(go)
        end
    end
    --新楼层创建完成后立即同步镜头范围，避免后续界面事件中断时仍沿用旧高度上限
    local camera = self:GetCameraModel()
    if camera then
        camera:RefreshMoveRange()
    end
    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_LEVEL_CHANGE)
end

--endregion

return XSkyTowerControl
