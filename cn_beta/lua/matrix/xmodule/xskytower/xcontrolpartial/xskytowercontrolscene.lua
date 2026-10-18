---Control部分类，此处用于楼层场景（Room）的创建、进出与表现刷新
---@type XSkyTowerControl
local XSkyTowerControl = XClassPartial('XSkyTowerControl')

function XSkyTowerControl:InitScene()
    self._NeedRequestWhenRelease = false
    ---@type table<number, XSkyTowerRoom>
    self._Rooms = {}
    --当前所在楼层
    self._CurFloorId = 0
    require("XSkyTower/XSkyTowerCharAgent")
    require("XSkyTower/XSkyTowerPerformAgent")
    ---@type XSkyTowerPool
    self._WorkbenchPool = self:AddEntity(require("XModule/XSkyTower/XGameObject/XSkyTowerPool"), "WorkbenchPool")
end

function XSkyTowerControl:ReleaseScene()
    -- 离场结算由服务端在收到退出请求时做，界面已经释放，回包不用管
    if self._NeedRequestWhenRelease then
        self:RequestExit()
    end
    self._NeedRequestWhenRelease = false
    self._Rooms = {}
    self._CurFloorId = nil
    self._DragEdgeGroupId = nil
end

--- 获取楼层工位数量
---@param floorId number 不传取当前楼层
---@return number
function XSkyTowerControl:GetWorkPosCount(floorId)
    return self._Model:GetFloorWorkPosCount(floorId or self:GetCurFloorId())
end

--- 获取楼层内指定工作类型的工位下标列表
---@param workType number XMVCA.XSkyTower.WorkType
---@param floorId number 不传取当前楼层
---@return number[]
function XSkyTowerControl:GetWorkPosIndexes(workType, floorId)
    local list = {}
    local infos = self._Model:GetFloorWorkPosInfos(floorId or self:GetCurFloorId())
    if XTool.IsTableEmpty(infos) then
        return list
    end
    for index, workPos in ipairs(infos) do
        if not workType or workPos.WorkType == workType then
            table.insert(list, index)
        end
    end
    return list
end

---获取通天塔场景
---@param floorId number 楼层Id，不传取当前楼层
---@return XSkyTowerRoom
function XSkyTowerControl:GetRoom(floorId)
    floorId = floorId or self:GetCurFloorId()
    local room = self._Rooms[floorId]
    if not room then
        room = self:AddEntity(require("XModule/XSkyTower/XGameObject/XSkyTowerRoom"), floorId)
        self._Rooms[floorId] = room
    end
    return room
end

function XSkyTowerControl:IsExistRoom(floorId)
    return self._Rooms[floorId] ~= nil
end

---进入场景
---@param floorId number 楼层Id
function XSkyTowerControl:EnterRoom()
    self._CurFloorId = self._Model:GetMaxFloorId()
    --初始化任务进度
    self:UpdateTaskSchedule()
    --设置全局光
    XUiHelper.SetSceneType(CS.XSceneType.Dormitory)
    --加载行为树
    XLuaBehaviorManager.LoadBehaviorTree(CS.BehaviorTree.XGamePlayType.SkyTower)
    --添加场景相机
    self._Camera = self:AddEntity(require("XModule/XSkyTower/XGameObject/XSkyTowerCamera"))
    -- 场景类型和相机就绪后统一应用光照，所有楼层共用主场景配置。
    XMVCA.XSkyTower:InitSceneSetting()
    --进入场景
    for floorId, floorGo in pairs(XMVCA.XSkyTower:GetFloorObjHash()) do
        self:GetRoom(floorId):SetGameObject(floorGo)
    end
    self:StartSimulation()
end

---退出场景
function XSkyTowerControl:ExitRoom()
    self:RecordProductionStatistics()
    self:StopSimulation()
    if self:IsActivityInTime() then
        self._NeedRequestWhenRelease = true
    end
    --避免界面非正常关闭时，资源未被销毁
    XLuaUiManager.Remove("UiSkyTowerCommon")
    XLuaUiManager.Remove("UiSkyTowerMain")
end

function XSkyTowerControl:ExitRoomClearRes()
    --场景释放
    for _, room in pairs(self._Rooms) do
        room:Release()
    end
    self._Rooms = {}
    --资源释放
    XMVCA.XSkyTower:ResetSceneObj()
    --卸载行为树
    XLuaBehaviorManager.UnloadBehaviorTree(CS.BehaviorTree.XGamePlayType.SkyTower)
end

---3D房间表现推进（每秒回调）
---只推进当前楼层区间，其余区间不刷顾客
---@param nowTime number 服务器当前时间戳
function XSkyTowerControl:OnRoomSimulation(nowTime)
    for _, floorId in ipairs(self._Model:GetFloorIdsByGroupId(self:GetCurFloorGroupId())) do
        local room = self._Rooms[floorId]
        if room then
            room:Simulation(nowTime)
        end
    end
end

---清掉指定楼层区间内所有楼层的顾客
---@param groupId number 区间Id
function XSkyTowerControl:ClearCustomerByGroupId(groupId)
    if not XTool.IsNumberValid(groupId) then
        return
    end
    for _, floorId in ipairs(self._Model:GetFloorIdsByGroupId(groupId)) do
        local room = self._Rooms[floorId]
        if room then
            room:ClearCustomers()
        end
    end
end

---摄像机数据以及模型
---@return XSkyTowerCamera
function XSkyTowerControl:GetCameraModel()
    return self._Camera
end

---摄像机定位到指定楼层，并把该楼层记为当前所在楼层
---@param floorId number 楼层Id，无效值时不做任何处理
---@param immediate boolean 是否瞬移，为false时播放快速移动
---@return boolean 是否成功发起定位
function XSkyTowerControl:LocateFloor(floorId, immediate, offsetY)
    if not XTool.IsNumberValid(floorId) or floorId > self._Model:GetMaxFloorId() then
        return false
    end
    local camera = self:GetCameraModel()
    if not camera then
        return false
    end
    XLuaUiManager.SetMask(true)
    return camera:LocateFloor(floorId, immediate, function()
        XLuaUiManager.SetMask(false)
        self:SetCurFloorId(floorId)
    end, offsetY)
end

---摄像机定位到演出所在楼层的对应挂点，并把该楼层记为当前所在楼层
---@param performId number 演出Id
---@param immediate boolean 是否瞬移，为false时播放快速移动
---@return boolean 是否成功发起定位，配置无效或楼层未加载时返回false
function XSkyTowerControl:LocatePerform(performId, immediate)
    if not XTool.IsNumberValid(performId) then
        return false
    end
    local config = self:GetPerformConfig(performId)
    local floorId = config.FloorId
    if not XTool.IsNumberValid(floorId) or floorId > self._Model:GetMaxFloorId() then
        return false
    end
    local camera = self:GetCameraModel()
    local room = self._Rooms[floorId]
    if not camera or not room then
        return false
    end
    XLuaUiManager.SetMask(true)
    local node = room:GetPerformNode(config.Type)
    return camera:LocateNode(node, floorId, immediate, function()
        XLuaUiManager.SetMask(false)
        self:SetCurFloorId(floorId)
    end)
end

---设置当前所在楼层，变化时通知3D工位刷新
---@param floorId number
function XSkyTowerControl:SetCurFloorId(floorId)
    if self._CurFloorId == floorId then
        return
    end
    local lastGroupId = self:GetCurFloorGroupId()
    self._CurFloorId = floorId
    local groupId = self:GetCurFloorGroupId()
    if groupId ~= lastGroupId then
        --顾客只在当前区间出现，离开的区间直接清场
        self:ClearCustomerByGroupId(lastGroupId)
        XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_CUR_FLOOR_GROUP_CHANGE, groupId)
    end
end

---@return XSkyTowerPool
function XSkyTowerControl:GetWorkbenchPool()
    return self._WorkbenchPool
end

--region 工位拖动时的镜头边缘滚动
--- 起拖时锁定当前楼层区间，镜头只能在该区间内滚动
function XSkyTowerControl:BeginDragEdgeScroll()
    local camera = self:GetCameraModel()
    if not camera then
        return
    end
    -- 区间锁在起拖那一刻取，之后镜头越入相邻区间也不会改变工作区域UI的显示范围；
    local groupId = self:GetCurFloorGroupId()
    self._DragEdgeGroupId = groupId
    local floorIds = self:GetFloorIdsByGroupId(groupId)
    if #floorIds <= 0 then
        return
    end
    camera:SetHeightLimit(camera:GetFloorLocalY(floorIds[1]), camera:GetFloorCeilingLocalY(floorIds[#floorIds]))
end

--- 抬手时解锁区间
function XSkyTowerControl:EndDragEdgeScroll()
    self._DragEdgeGroupId = nil
    local camera = self:GetCameraModel()
    if not camera then
        return
    end
    camera:ClearHeightLimit()
end

--- 按指针到屏幕上下边缘的距离滚动镜头，拖动期间每帧调用
---@param pointerScreenY number 指针屏幕纵坐标，为空表示取不到指针
---@param screenHeight number 屏幕高度（像素）
function XSkyTowerControl:UpdateDragEdgeScroll(pointerScreenY, screenHeight)
    local camera = self:GetCameraModel()
    if not camera then
        return
    end
    camera:MoveHeightByScreenEdge(pointerScreenY, screenHeight)
end

function XSkyTowerControl:GetCurEdgeGroupId()
    return self._DragEdgeGroupId or self:GetCurFloorGroupId()
end
--endregion

return XSkyTowerControl
