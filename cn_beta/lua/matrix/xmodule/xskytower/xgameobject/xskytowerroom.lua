---@type UnityEngine.Vector3
local CsVector3 = CS.UnityEngine.Vector3
local CsRandom = CS.UnityEngine.Random
local CsTween = CS.DG.Tweening

---@type XSkyTowerIScene
local XSkyTowerIScene = require("XModule/XSkyTower/XGameObject/XSkyTowerIScene")
local XSkyTowerRole = require("XModule/XSkyTower/XGameObject/XSkyTowerRole")
local XSkyTowerOrderNpc = require("XModule/XSkyTower/XGameObject/XSkyTowerOrderNpc")
local XSkyTowerCustomer = require("XModule/XSkyTower/XGameObject/XSkyTowerCustomer")
local XSkyTowerPerformer = require("XModule/XSkyTower/XGameObject/XSkyTowerPerformer")

---@class XSkyTowerRoom : XSkyTowerIScene 通天塔房间
---@field _SkyTowerCamera XSkyTowerCamera
---@field _SceneSetting XSceneSetting
---@field _RandomPoints table[] 随机点哈希与世界坐标缓存
---@field _FreeRandomPoints table[] 复用的候选点缓冲区
---@field _RandomPointUsed table<number, boolean> 随机点占用标记
---@field _PointsMap table<number, number> 工位下标索引随机点
---@field _CharacterMap table<number, XSkyTowerRole> 按工位下标保存角色模型，通用员工可以同时占多个工位
---@field _OrderNpc XSkyTowerOrderNpc
---@field _StartPoint UnityEngine.Vector3
---@field _RedPoint UnityEngine.Vector3
---@field _GreenPoint UnityEngine.Vector3
---@field _RandomArea UnityEngine.Bounds
---@field _CustomerList XSkyTowerCustomer[]
---@field _Perform XSkyTowerPerform
---@field _FloorGroupPerform XSkyTowerPerform
---@field _FloorId number 房间所属楼层
local XSkyTowerRoom = XClass(XSkyTowerIScene, "XSkyTowerRoom")

--- 房间由主Control按楼层创建：AddEntity(XSkyTowerRoom, floorId)
---@param floorId number 楼层Id
function XSkyTowerRoom:OnInit(floorId)
    self._FloorId = floorId or 0
    self._FloorHeight = XMVCA.XSkyTower:GetFloorBuildHeight()
    --房间是场景根节点，没有父节点
    XSkyTowerIScene.OnInit(self, nil)
end

function XSkyTowerRoom:AddEvent()
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_WORK_POS_CHANGE, self.UpdateWork, self)
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_PERFORM_STATE_CHANGE, self.OnPerformStateChanged, self)
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_DATA_CHANGE, self.UpdatePerform, self)
end

function XSkyTowerRoom:RemoveEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_WORK_POS_CHANGE, self.UpdateWork, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_PERFORM_STATE_CHANGE, self.OnPerformStateChanged, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_DATA_CHANGE, self.UpdatePerform, self)
end

function XSkyTowerRoom:Init()
    self._WorkModel = {}
    ---@type table<number, string> 工位下标索引当前工作台的模型路径，回收时按路径归桶
    self._WorkModelUrl = {}
    ---@type table<number, number> 工位下标索引当前已表现的工作类型，用于判断是否需要重建
    self._WorkType = {}
    self._CharacterMap = {}
    --只缓存已经呈现的分配，用于识别换人/换位/状态变化，不作为生产数据
    self._WorkAssignments = {}
    self._WorkRolesReady = false
    self._CustomerList = {}

    self._NextLoadCustomer = 0
    self._CustomerIds = self._Model:GetCustomerIds()

    local min, max = self._Model:GetCustomerProperty()
    self._RandomMin = min
    self._RandomMax = max
end

function XSkyTowerRoom:SetGameObject(gameObject)
    self._SkyTowerCamera = self._OwnControl:GetCameraModel()
    self._WorkbenchPool = self._OwnControl:GetWorkbenchPool()
    self._UiObj = {}
    XUiHelper.InitUiClass(self._UiObj, gameObject)
    self._GameObject = self._UiObj.GameObject
    self._GameObject.name = self:GetObjName()
    self._Transform = self._UiObj.Transform
    self._Transform:SetLocalPosition(0, self._FloorHeight * (self._FloorId - 1), 0)
    self:OnLoadSuccess()
end

function XSkyTowerRoom:OnLoadSuccess()
    --订单NPC创建时会保存父节点，必须在加载任何角色前初始化。
    self._CharacterRoot = self._UiObj.Character
    if XTool.UObjIsNil(self._CharacterRoot) then
        local go = CS.UnityEngine.GameObject("Character")
        go.transform:SetParent(self._UiObj.GroupBase, false)
        self:TryResetTransform(go.transform)
        self._CharacterRoot = go.transform
    end

    self:LoadGlobalSO()
    self:InitPerform()
    self:InitNavMesh()
    self:InitCustomer()
    self:InitSceneSetting()
    self:LoadWorkModels()
    self:StartBusiness()
    self:InitFlootGroupName()
end

function XSkyTowerRoom:InitFlootGroupName()
    if not self._UiObj.TxtFloorGroup then
        return
    end
    local groupId = self._OwnControl:GetFloorGroupIdByFloorId(self._FloorId)
    local groupName = self._OwnControl:GetFloorGroupName(groupId)
    local maxFloorGroupCount = self._OwnControl:GetIntClientConfigValue("FloorGroupCount")
    local wordIndex
    if groupId == 1 then
        wordIndex = 1
    elseif groupId < maxFloorGroupCount then
        wordIndex = 2
    else
        wordIndex = 3
    end
    self._UiObj.TxtFloorGroup.text = self._OwnControl:GetClientConfigText("FloorGroup3DName", wordIndex, groupName)
end

--- 按服务端工位状态加载本楼层角色表现
function XSkyTowerRoom:TryWorking()
    self._WorkRolesReady = true
    self:RefreshWorkRoles()
end

function XSkyTowerRoom:RefreshWorkRoles()
    if not self._WorkRolesReady or not self:IsInBusinessScene() or not self:Exist() or XTool.UObjIsNil(self._CharacterRoot) then
        return
    end
    local assignments = {}
    for index, workPos in ipairs(self._Model:GetFloorWorkPosInfos(self._FloorId) or table.empty) do
        if not self._OwnControl:IsWorkPosFree(self._FloorId, index) then
            assignments[index] = {
                CharacterId = workPos.CharacterId,
                Index = index,
                WorkType = workPos.WorkType,
                State = self._OwnControl:GetWorkState(self._FloorId, index),
            }
        end
    end
    -- 先撤下换人或清空的工位，再分配，通用员工不按角色Id合并
    for index, old in pairs(self._WorkAssignments) do
        local assignment = assignments[index]
        if not assignment or assignment.CharacterId ~= old.CharacterId then
            self:UnAssignWork(old.CharacterId, index)
        end
    end
    local previous = self._WorkAssignments
    self._WorkAssignments = assignments
    for index, assignment in pairs(assignments) do
        local old = previous[index]
        local role = self:GetCharacterModel(assignment.CharacterId, index)
        if not old or old.CharacterId ~= assignment.CharacterId or old.WorkType ~= assignment.WorkType
            or not role or (not role:Exist() and not role:IsLoading()) then
            self:AssignWork(assignment.CharacterId, assignment.WorkType, index)
        elseif old.State ~= assignment.State then
            self:ChangeStaffState(assignment.CharacterId, assignment.State, index)
        end
    end
end

function XSkyTowerRoom:OnPerformStateChanged(floorId)
    if floorId ~= self._FloorId then
        return
    end
    self:UpdatePerform()
end

function XSkyTowerRoom:UpdatePerform()
    self:TryLoadIndent()
end

function XSkyTowerRoom:TryLoadIndent()
    if not self:Exist() or not self:IsInBusinessScene() or XTool.UObjIsNil(self._CharacterRoot) then
        return
    end
    local performId = self._OwnControl:GetRunningIndentId(self._FloorId)
    if not XTool.IsNumberValid(performId) or self._OwnControl:IsFinish(performId) then
        return
    end
    if self._OrderNpc then
        --完成回包先更新数据，再播放离场；等旧NPC释放后再加载下一张订单
        if self._OwnControl:IsFinish(self._OrderNpc:GetId()) then
            return
        end
        if self._OrderNpc:GetId() == performId then
            if self._OrderNpc:IsLoading() then
                return
            end
            if self._OrderNpc:Exist() then
                if self._OrderNpc:IsHide() then
                    self._OrderNpc:Show()
                end
                return
            end
        end
    end
    self:LoadOrderNpc(performId)
end

function XSkyTowerRoom:InitPerform()
    self._Perform = self._OwnControl:AddEntity(require("XModule/XSkyTower/XGameObject/XSkyTowerPerform"))
    self._Perform:SetGameObject(self._UiObj.PerformPoint.gameObject)

    self._FloorGroupPerform = self._OwnControl:AddEntity(require("XModule/XSkyTower/XGameObject/XSkyTowerPerform"))
    self._FloorGroupPerform:SetGameObject(self._UiObj.FloorGroupPerformPoint.gameObject)
    self._FloorGroupPerform:SetFloorGroupPerform(true)
end

function XSkyTowerRoom:InitSceneSetting()
    self._SceneSetting = self._Transform:GetComponent("XSceneSetting")
    if self._SceneSetting then
        self._SceneSetting.enabled = true
        CS.XGraphicManager.BindScene(self._SceneSetting)
    end
end

function XSkyTowerRoom:LoadGlobalSO()
    --场景加载完
    XUiHelper.SetSceneType(CS.XSceneType.Dormitory)
    local path = self._Model:GetGlobalIllumination()
    local loader = self._OwnControl:GetLoader()
    local asset = loader:Load(path)
    if not asset then
        XLog.Error("skyTower load resource error: asset path = " .. path)
        return
    end
    CS.XGlobalIllumination.SetGlobalIllumSO(asset)
    self._GOPath = path
end

function XSkyTowerRoom:InitNavMesh()
    self:AddNavMeshObstacleSizeByCollider(self._UiObj.Furniture)
    self:AddNavMeshObstacleSizeByCollider(self._UiObj.DanceHideFurniture)
    self:AddNavMeshObstacleSizeByCollider(self._UiObj.EventFurniture)
    self._RandomPoints = {}
    self._FreeRandomPoints = {}
    self._RandomPointUsed = {}
    self._PointsMap = {}
    if not XTool.UObjIsNil(self._UiObj.Path) then
        for i = 0, self._UiObj.Path.childCount - 1 do
            local transform = self._UiObj.Path:GetChild(i)
            transform.gameObject.name = "Point" .. i + 1
            -- 房间定位后路径点保持固定，世界坐标和哈希只读取一次
            local point = { HashCode = transform:GetHashCode(), Position = transform.position }
            self._RandomPoints[i + 1] = point
            self._FreeRandomPoints[i + 1] = point
            self._RandomPointUsed[point.HashCode] = false
        end
    end
    if not XTool.UObjIsNil(self._UiObj.Floor) then
        CS.XNavMeshUtility.SetColliderNavMeshSurfaceAndBuild(self._UiObj.Floor.gameObject)
    end
end

function XSkyTowerRoom:InitCustomer()
    self._StartPoint = self._UiObj.Start.position
    self._GreenPoint = self._UiObj.Green.position
    self._RedPoint = self._UiObj.Red.position
    self._PointMin = self._UiObj.Point1.position
    self._PointMax = self._UiObj.Point2.position
    --部分楼层的Start节点低于地板，出生和离场统一使用本层顾客活动平面的高度。
    self._StartPoint.y = self._PointMin.y
    self._MaxCustomerCount = self._Model:GetLvCustomerLimit()
    --不在营业期，不加载
    if not self._Model:IsActivityInTime() then
        self._MaxCustomerCount = 0
    end
end

function XSkyTowerRoom:GetObjName()
    return string.format("Lv%s-Floor%s", self._Model:GetSkyTowerLv(), self._FloorId)
end

function XSkyTowerRoom:Release()
    if not string.IsNilOrEmpty(self._GOPath) then
        local loader = self._OwnControl:GetLoader()
        loader:Unload(self._GOPath)
        self._GOPath = nil
    end

    self.Super.Release(self)
    for _, role in pairs(self._CharacterMap) do
        role:Release()
    end
    for _, customer in pairs(self._CustomerList) do
        customer:Release()
    end
    if self._OrderNpc then
        self._OrderNpc:Release()
    end

    if self._Perform then
        self._Perform:Release()
    end
    if self._FloorGroupPerform then
        self._FloorGroupPerform:Release()
    end

    self._WorkModel = {}
    self._WorkModelUrl = {}
    self._WorkType = {}
    self._CharacterMap = {}
    self._CustomerList = {}
    self._RandomPoints = nil
    self._FreeRandomPoints = nil
    self._RandomPointUsed = nil
    self._PointsMap = nil
    self._CharacterRoot = nil
    self._SceneSetting = nil
    self._OrderNpc = nil
    self._Perform = nil
    self._FloorGroupPerform = nil

    self._NextLoadCustomer = 0
    self._FocusHidden = false
    self:StopWorkUnlockBreath()
    --场景销毁
    XUiHelper.SetSceneType(CS.XSceneType.Ui)
end

function XSkyTowerRoom:AddNavMeshObstacleSizeByCollider(transform)
    if XTool.UObjIsNil(transform) then
        return
    end
    CS.XNavMeshUtility.AddNavMeshObstacleSizeByCollider(transform.gameObject)
end

function XSkyTowerRoom:StartBusiness()
    -- 模型异步加载也会检查此标记，必须先设置，避免加载成功后马上被Hide
    self._IsInBussScene = true
    self:TryLoadIndent()
    self:PlayPerformance()
    self:PlayFloorGroupPerformance()
    self:TryWorking()
    if not self._FocusHidden then
        for index, role in pairs(self._CharacterMap) do
            if self._WorkAssignments[index] and role:Exist() and role:IsHide() then
                role:Show()
            end
        end
    end
end

function XSkyTowerRoom:IsInBusinessScene()
    return self._IsInBussScene
end

function XSkyTowerRoom:PlayPerformance()
    if not self._Perform then
        return
    end
    local performId = self._OwnControl:GetRunningPerformId(self._FloorId)
    if not XTool.IsNumberValid(performId) or self._OwnControl:IsFinish(performId) then
        return
    end
    self._Perform:StartPerformance(performId)
end

function XSkyTowerRoom:StopPerformance()
    if not self._Perform then
        return
    end
    self._Perform:StopPerformance()
end

function XSkyTowerRoom:PlayFloorGroupPerformance()
    if not self._FloorGroupPerform then
        return
    end
    local performId = self._OwnControl:GetRunningFloorGroupPerformId(self._FloorId)
    if not XTool.IsNumberValid(performId) or self._OwnControl:IsFinish(performId) then
        return
    end
    self._FloorGroupPerform:StartPerformance(performId)
end

function XSkyTowerRoom:StopFloorGroupPerformance()
    if not self._FloorGroupPerform then
        return
    end
    self._FloorGroupPerform:StopPerformance()
end

--- 加载角色模型
---@param characterId number 角色Id
---@param onLoadCb function 加载成功回调
---@param index number 工位下标
---@return void
function XSkyTowerRoom:LoadCharacter(characterId, onLoadCb, index)
    local role = self:GetCharacterModel(characterId, index)
    -- 在途回调会读取最新分配，不重复Born，避免同一工位累加引用
    if role and role:IsLoading() then
        return
    end
    if not role or not role:Exist() then
        local previous = self._CharacterMap[index]
        if previous and not previous:IsLoading() then
            previous:DisposeImmediately()
        end
        role = self._OwnControl:AddEntity(XSkyTowerRole, self._CharacterRoot, characterId, self._FloorId, index)
        self._CharacterMap[index] = role
    end
    role:Born(function()
        -- 旧角色尚在加载时可能已被换掉，等加载结束再释放，且不能操作新角色
        if not self:Exist() or self._CharacterMap[index] ~= role then
            role:DisposeImmediately()
            return
        end
        if onLoadCb then
            onLoadCb()
        end
    end)
end

--- 释放角色资源
---@param characterId number 角色Id
---@param index number 工位下标
---@return void
function XSkyTowerRoom:ReleaseCharacter(characterId, index)
    local role = self:GetCharacterModel(characterId, index)
    if not role then
        return
    end
    self._CharacterMap[role:GetWorkPosIndex()] = nil
    role:DisposeImmediately()
end

--- 获取角色模型
---@param characterId number 角色Id
---@param index number 工位下标
---@return XSkyTowerRole
function XSkyTowerRoom:GetCharacterModel(characterId, index)
    if index then
        local role = self._CharacterMap[index]
        return role and role:GetId() == characterId and role or nil
    end
    for _, role in pairs(self._CharacterMap) do
        if role:GetId() == characterId then
            return role
        end
    end
end

--- 员工是否在场景中
---@param characterId number 角色Id
---@param index number 工位下标
---@return boolean
function XSkyTowerRoom:IsStaffInRoom(characterId, index)
    local role = self:GetCharacterModel(characterId, index)
    if not role then
        return false
    end
    return role:Exist()
end

--- 分配工作
---@param characterId number
---@param workType number 区域类型（与工位WorkType数值一致）
---@param index number 工位下标
---@param onLoadCb function 只有未加载时才会执行
---@return void
function XSkyTowerRoom:AssignWork(characterId, workType, index, onLoadCb)
    if not XTool.IsNumberValid(characterId) then
        return
    end
    local roleNode = self:GetWorkRoleOffsetNode(index)
    if XTool.UObjIsNil(roleNode) then
        return
    end
    self:LoadCharacter(characterId, function()
        if not self:Exist() then
            return
        end
        --加载期间可能已换岗或撤下，只应用最新分配，避免旧回调把角色放回旧工位
        local assignment = self._WorkAssignments[index]
        if not assignment or assignment.CharacterId ~= characterId then
            self:UnAssignWork(characterId, index)
            return
        end
        if onLoadCb then
            onLoadCb()
        end
        local target = self:GetWorkBenchModel(assignment.Index)
        local role = self:GetCharacterModel(characterId, index)
        if not role or not role:Exist() then
            return
        end
        local pos = roleNode.position
        if self._OwnControl:IsSaleArea(assignment.WorkType) then
            role:TryAddNavMeshAgent()
        end
        role:SetWorkBench(target, pos, assignment.WorkType)
        role:ChangeState(assignment.State)
        if self._FocusHidden or not self:IsInBusinessScene() then
            role:Hide()
        end
    end, index)

end

--- 取消工作
---@param characterId number
---@param index number 工位下标
---@return void
function XSkyTowerRoom:UnAssignWork(characterId, index)
    if not XTool.IsNumberValid(characterId) then
        return
    end
    local exist = self:IsStaffInRoom(characterId, index)
    if not exist then
        return
    end
    local role = self:GetCharacterModel(characterId, index)
    role:UnAssignWork()
    self._PointsMap[role:GetWorkPosIndex()] = nil
end

--- 员工状态改变
---@param characterId number 员工Id
---@param state number 员工状态，目前这个参数无效
---@param index number 工位下标
function XSkyTowerRoom:ChangeStaffState(characterId, state, index)
    if not XTool.IsNumberValid(characterId) then
        return
    end
    local exist = self:IsStaffInRoom(characterId, index)
    if not exist then
        return
    end
    self:GetCharacterModel(characterId, index):ChangeState(state)
end

---@return UnityEngine.Transform
function XSkyTowerRoom:GetWorkComponent(key, index)
    local nodeName = key .. index
    local node = self._UiObj[nodeName]
    if not node then
        XLog.Error("楼层%s不存在工作台节点：%s", self._FloorId, nodeName)
    end
    return node
end

---获取工作台
---@param index number 工作台下标
function XSkyTowerRoom:GetWorkBenchModel(index)
    return self:GetWorkComponent("WorkPos", index)
end

---获取工作台UI节点
function XSkyTowerRoom:GetWorkUiOffsetNode(index)
    return self:GetWorkComponent("3DUiOffset", index)
end

---获取工作台角色站位节点
function XSkyTowerRoom:GetWorkRoleOffsetNode(index)
    local nodeName = "RoleOffset" .. index
    local node = self._UiObj[nodeName]
    if XTool.UObjIsNil(node) then
        local workPos = self:GetWorkBenchModel(index)
        node = not XTool.UObjIsNil(workPos) and workPos:Find(nodeName) or nil
        self._UiObj[nodeName] = node
    end
    if XTool.UObjIsNil(node) then
        XLog.Error("楼层%s不存在角色站位节点：WorkPos%s/%s", self._FloorId, index, nodeName)
    end
    return node
end

---获取工作台未解锁时的模型（箱子）
function XSkyTowerRoom:GetWorkUnlockModel(index)
    return self:GetWorkComponent("LockFurniture", index)
end

---获取楼层分区文本节点
function XSkyTowerRoom:GetFloorGroupAreaNode()
    return self._UiObj.FloorGroupNamePoint
end

---按演出类型获取场景挂点（不包含图标偏移）
---@param performType number XMVCA.XSkyTower.PerformType
---@return UnityEngine.Transform
function XSkyTowerRoom:GetPerformNode(performType)
    if not self:Exist() or not self._UiObj then
        return nil
    end
    local typeEnum = XMVCA.XSkyTower.PerformType
    if performType == typeEnum.Event then
        return self._UiObj.PerformPoint
    elseif performType == typeEnum.FloorGroup then
        return self._UiObj.FloorGroupPerformPoint
    elseif performType == typeEnum.Indent then
        return self._UiObj.IndentPoint
    end
    return nil
end

---获取事件（演出）节点
function XSkyTowerRoom:GetPerformIconNode()
    return self._UiObj.PerformIconPoint
end

---获取楼层区间事件（演出）节点
function XSkyTowerRoom:GetGroupPerformIconNode()
    return self._UiObj.FloorGroupPerformIconPoint
end

---获取订单节点
function XSkyTowerRoom:GetIndentIconNode()
    return self._UiObj.IndentIconPoint
end

function XSkyTowerRoom:LoadWorkModels()
    for i = 1, self._OwnControl:GetFloorWorkNum(self._FloorId) do
        self:LoadWorkModel(i)
    end
end

---@param index number 工位下标
function XSkyTowerRoom:LoadWorkModel(index)
    local boxModel = self:GetWorkUnlockModel(index)
    local info = self._Model:GetFloorWorkPosInfo(self._FloorId, index)
    if not info then
        self:AddNavMeshObstacleSizeByCollider(boxModel)
        return
    end
    local workType = info.WorkType
    --限定工位即使尚未安排员工，也提前显示指定工作类型的家具模型
    if workType == XMVCA.XSkyTower.WorkType.None then
        workType = self._OwnControl:GetFloorAppointWorkByIndex(self._FloorId, index)
    end
    --工作类型没变时无需重建
    if self._WorkType[index] == workType then
        return
    end
    --工作台解锁
    boxModel.gameObject:SetActiveEx(false)
    --回收工作台
    self:RecycleWorkModel(index)
    self._WorkType[index] = workType
    --未分配任务
    if workType == XMVCA.XSkyTower.WorkType.None then
        return
    end
    local modelUrl = self._OwnControl:GetWorkModelUrl(self._FloorId, workType)
    local parent = self:GetWorkBenchModel(index)
    self._WorkbenchPool:GetModelAsync(modelUrl, parent, function(model)
        --异步加载期间可能已被改分配或房间已释放
        if not self:Exist() or self._WorkType[index] ~= workType then
            self._WorkbenchPool:RecycleModel(modelUrl, model)
            return
        end
        self._WorkModel[index] = model
        self._WorkModelUrl[index] = modelUrl
        self:AddNavMeshObstacleSizeByCollider(model)
    end)
end

---回收工位上的工作台模型
---@param index number 工位下标
function XSkyTowerRoom:RecycleWorkModel(index)
    local model = self._WorkModel[index]
    if not model then
        return
    end
    local modelUrl = self._WorkModelUrl[index]
    self._WorkModel[index] = nil
    self._WorkModelUrl[index] = nil
    self._WorkbenchPool:RecycleModel(modelUrl, model)
end

function XSkyTowerRoom:UpdateWork(floorId, index)
    if self._FloorId ~= floorId or not self:Exist() then
        return
    end
    --最后一个售卖工位停工、撤下或移走后，立即清掉本层顾客
    if #self._CustomerList > 0 and not self:HasSaleWork() then
        self:ClearCustomers()
    end
    if index then
        self:LoadWorkModel(index)
    else
        self:LoadWorkModels()
    end
    self:RefreshWorkRoles()
end

---@param uiTransform UnityEngine.Transform
---@param targetTransform UnityEngine.Transform
---@param offset UnityEngine.Vector3
function XSkyTowerRoom:SetViewPosToTransformLocalPosition(uiTransform, targetTransform, offset)
    if XTool.UObjIsNil(self._SkyTowerCamera.Camera) then
        return
    end
    local offsetX = offset and offset.x or 0
    local offsetY = offset and offset.y or 0
    local offsetZ = offset and offset.z or 0
    self._SkyTowerCamera.Camera:SetViewPosToTransformLocalPosition(uiTransform, targetTransform, offsetX, offsetY, offsetZ, 0.5, 0.5)
end

---返回缓存的世界坐标，调用方只读使用
---@return UnityEngine.Vector3
function XSkyTowerRoom:GetRandomPoint(workPosIndex)
    local points = self._FreeRandomPoints
    local map = self._RandomPointUsed
    -- 保留哈希表的键和容量，避免反复删除、插入占用标记
    for hashCode in pairs(map) do
        map[hashCode] = false
    end
    for _, index in pairs(self._PointsMap) do
        map[index] = true
    end
    local count = 0
    for _, point in ipairs(self._RandomPoints) do
        if not map[point.HashCode] then
            count = count + 1
            points[count] = point
        end
    end
    -- 只从本次填入的前 count 项选择，尾部槽位保留给后续调用复用
    local index = math.random(1, count)
    local point = points[index]
    self._PointsMap[workPosIndex] = point.HashCode

    return point.Position
end

---加载订单Npc
---@param id number 角色id
function XSkyTowerRoom:LoadOrderNpc(id)
    if not self._OrderNpc then
        self._OrderNpc = self._OwnControl:AddEntity(XSkyTowerOrderNpc, self._CharacterRoot, id, self._FloorId)
    elseif self._OrderNpc:GetId() ~= id then
        self._OrderNpc:DisposeImmediately()
        self._OrderNpc = self._OwnControl:AddEntity(XSkyTowerOrderNpc, self._CharacterRoot, id, self._FloorId)
    end
    self._OrderNpc:SetGameObject(self._UiObj.IndentPoint)
    self._OrderNpc:Born()
end

--- 改变订单NPC状态
---@param state number
function XSkyTowerRoom:ChangeIndentNpcState(state)
    if not self._OrderNpc then
        return
    end

    self._OrderNpc:ChangeState(state)
end

function XSkyTowerRoom:ReleaseOrderNpc()
    if self._OrderNpc then
        self._OrderNpc:Release()
    end
    self._OrderNpc = nil

    self:TryLoadIndent()
end

function XSkyTowerRoom:GetOrderNpcModel()
    return self._OrderNpc and self._OrderNpc:GetTransform() or nil
end

function XSkyTowerRoom:LoadPerformer(performerId, floorId)
    return self._OwnControl:AddEntity(XSkyTowerPerformer, self._CharacterRoot, performerId, floorId or self._FloorId)
end

--每秒会执行一次
function XSkyTowerRoom:Simulation(timeOfNow)
    self:SimulationCustomer(timeOfNow)
end

---本层是否有已开工的售卖工作，缺货等待仍算，未确认的安排预览不算
---@return boolean
function XSkyTowerRoom:HasSaleWork()
    for index, workPos in ipairs(self._Model:GetFloorWorkPosInfos(self._FloorId) or table.empty) do
        if workPos.WorkType == XMVCA.XSkyTower.WorkType.Sale and self._OwnControl:IsRunning(self._FloorId, index) then
            return true
        end
    end
    return false
end

function XSkyTowerRoom:SimulationCustomer(timeOfNow)
    if not self:HasSaleWork() then
        if #self._CustomerList > 0 then
            self:ClearCustomers()
        end
        return
    end
    if #self._CustomerList >= self._MaxCustomerCount then
        return
    end
    if XTool.UObjIsNil(self._CharacterRoot) then
        return
    end
    if timeOfNow > self._NextLoadCustomer then
        self:LoadCustomer(timeOfNow)
    end
end

function XSkyTowerRoom:LoadCustomer(timeOfNow)
    local customerId = self:GetRandomCustomerNpcId()
    if not XTool.IsNumberValid(customerId) then
        return
    end
    ---@type XSkyTowerCustomer
    local customer = self._OwnControl:AddEntity(XSkyTowerCustomer, self._CharacterRoot, customerId, self._FloorId)
    customer:SetBornPoint(self._StartPoint, self._RedPoint, self._GreenPoint)
    table.insert(self._CustomerList, customer)
    customer:Load()
    --未达到最大值时，刷新时间在加载后刷新
    local nextLoad = math.random(self._RandomMin, self._RandomMax)
    self._NextLoadCustomer = timeOfNow + nextLoad
end

---清掉本层当前的顾客，但保留刷新上限，切楼层区间时用
function XSkyTowerRoom:ClearCustomers()
    for _, customer in ipairs(self._CustomerList) do
        customer:DisposeImmediately()
    end
    self._CustomerList = {}
end

function XSkyTowerRoom:GetRandomCustomerNpcId()
    --策划要求纯随机，不做去重：出现过的能再出现，同层也允许撞脸
    if XTool.IsTableEmpty(self._CustomerIds) then
        return 0
    end
    return self._CustomerIds[math.random(1, #self._CustomerIds)]
end

---顾客自己走完流程要下场时走这里
---同层允许出现重复角色，按npcId找会捞错人，只能认实例
---@param customer XSkyTowerCustomer
function XSkyTowerRoom:RemoveCustomerByEntity(customer)
    for idx, item in ipairs(self._CustomerList) do
        if item == customer then
            self:RemoveCustomerByIndex(idx)
            return
        end
    end
end

function XSkyTowerRoom:TryRemoveCustomer(npcId)
    local index
    for idx, customer in ipairs(self._CustomerList) do
        if customer:GetNpcId() == npcId then
            index = idx
            break
        end
    end

    if not index then
        return
    end

    self:RemoveCustomerByIndex(index)
end

function XSkyTowerRoom:RemoveCustomerByIndex(index)
    --达到最大值时，刷新时间在销毁后刷新
    if #self._CustomerList >= self._MaxCustomerCount then
        local nextLoad = math.random(self._RandomMin, self._RandomMax)
        self._NextLoadCustomer = XTime.GetServerNowTimestamp() + nextLoad
    end

    if index then
        local customer = self._CustomerList[index]
        table.remove(self._CustomerList, index)
        customer:DisposeImmediately()
    end
end

function XSkyTowerRoom:GetCustomerRandomPoint()
    local vec3 = CsVector3.zero
    vec3.x = vec3.x + CsRandom.Range(self._PointMin.x, self._PointMax.x)
    vec3.y = self._PointMin.y
    vec3.z = vec3.z + CsRandom.Range(self._PointMin.z, self._PointMax.z)
    return vec3
end

--region Camera

function XSkyTowerRoom:ResetCamera()
    self._SkyTowerCamera:ShowDefault()
end

---舞台镜头聚焦
function XSkyTowerRoom:LookAtDance()
    self._SkyTowerCamera:ShowDanceCamera(self._UiObj.NodeDance)
end

---楼层镜头聚焦
function XSkyTowerRoom:LookAtFloor()
    self._SkyTowerCamera:ShowFloorCamera(self._UiObj.NodeFloorCenter)
end

---工作台镜头聚焦
function XSkyTowerRoom:LookAtWork(index)
    local node = self:GetWorkBenchModel(index)
    self._SkyTowerCamera:ShowWorkCamera(node)
end
--endregion

--region 镜头聚焦时的场景遮挡处理
--- 聚焦舞台时收起遮挡视线的家具与在岗角色，与RestoreFocusHidden成对调用
function XSkyTowerRoom:HideForFocus()
    if self._FocusHidden then
        return
    end
    self._FocusHidden = true
    if not XTool.UObjIsNil(self._UiObj.Furniture) then
        self._UiObj.Furniture.gameObject:SetActiveEx(false)
    end
    for _, role in pairs(self._CharacterMap or table.empty) do
        role:Hide()
    end
end

--- 恢复HideForFocus收起的家具与角色，未收起过时不做任何处理
function XSkyTowerRoom:RestoreFocusHidden()
    if not self._FocusHidden then
        return
    end
    self._FocusHidden = false
    if not XTool.UObjIsNil(self._UiObj.Furniture) then
        self._UiObj.Furniture.gameObject:SetActiveEx(true)
    end
    for index, role in pairs(self._CharacterMap or table.empty) do
        if self:IsInBusinessScene() and self._WorkAssignments[index] and role:Exist() then
            role:Show()
        end
    end
end

--- 未解锁工位的Lock模型上播放呼吸光，同一时刻只保留一个
---@param index number 工位下标
function XSkyTowerRoom:PlayWorkUnlockBreath(index)
    self:StopWorkUnlockBreath()
    local model = self:GetWorkUnlockModel(index)
    if XTool.UObjIsNil(model) then
        return
    end
    local param = XMVCA.XSkyTower.BreathScale
    -- 记录原始缩放，Kill后要还原，否则模型会停在脉动的中间值上
    self._BreathTarget = model
    self._BreathOriginScale = model.localScale
    local minScale = CsVector3(param.Min, param.Min, param.Min)
    local maxScale = CsVector3(param.Max, param.Max, param.Max)
    model.localScale = minScale
    self._BreathSeq = CsTween.DOTween.Sequence()
    self._BreathSeq:Append(model:DOScale(maxScale, param.Duration):SetEase(CsTween.Ease.InOutQuad))
    self._BreathSeq:Append(model:DOScale(minScale, param.Duration):SetEase(CsTween.Ease.InOutQuad))
    self._BreathSeq:SetLoops(-1)
end

--- 停止呼吸光并还原缩放
function XSkyTowerRoom:StopWorkUnlockBreath()
    if self._BreathSeq then
        self._BreathSeq:Kill()
        self._BreathSeq = nil
    end
    if not XTool.UObjIsNil(self._BreathTarget) and self._BreathOriginScale then
        self._BreathTarget.localScale = self._BreathOriginScale
    end
    self._BreathTarget = nil
    self._BreathOriginScale = nil
end
--endregion

return XSkyTowerRoom
