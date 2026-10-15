local XSkyTowerIScene = require("XModule/XSkyTower/XGameObject/XSkyTowerIScene")
local CsTime = CS.UnityEngine.Time
local CsInput = CS.UnityEngine.Input
local CsMathf = CS.UnityEngine.Mathf
local CsVector2 = CS.UnityEngine.Vector2
local CsPointerEventData = CS.UnityEngine.EventSystems.PointerEventData
local CsEventSystem = CS.UnityEngine.EventSystems.EventSystem
local CsRaycastResultList = CS.System.Collections.Generic.List(CS.UnityEngine.EventSystems.RaycastResult)

local CheckInterval = 0.05

---@class XSkyTowerCamera : XSkyTowerIScene 通天塔摄像机
---@field SceneTransform UnityEngine.Transform 场景根节点
---@field GameObject UnityEngine.GameObject
---@field Camera UnityEngine.Camera
---@field _WorkType number
---@field CameraMain Cinemachine.CinemachineVirtualCamera 入口界面展示的虚拟相机
---@field CameraMoveTran UnityEngine.Transform
---@field CameraMove Cinemachine.CinemachineVirtualCamera 负责移动的虚拟相机
---@field CameraDance Cinemachine.CinemachineVirtualCamera 负责播放聚焦到舞台动画的虚拟相机
---@field CameraWork Cinemachine.CinemachineVirtualCamera 负责播放聚焦到工作台动画的虚拟相机
---@field CameraFloor Cinemachine.CinemachineVirtualCamera 负责播放聚焦到楼层动画的虚拟相机
---@field _AreaType number
---@field _LevelUpEffect UnityEngine.GameObject
---@field _TouchHandler XBlackRockChess.XTouchHandler
---@field _CameraParam XSkyTowerCameraParam
---@field _InputArea UnityEngine.GameObject
local XSkyTowerCamera = XClass(XSkyTowerIScene, "XSkyTowerCamera")

--射线方向分量小于该值时视为与楼层竖直线平行，不做求交
local MinRayDirection = 0.0001

function XSkyTowerCamera:Init()
    self._WorkType = self._Model:GetEnterWorkType()
    self._PosInfo = {}
    self._RaycastResults = CsRaycastResultList()
    self._UnscaledDeltaTime = CsTime.unscaledDeltaTime
    self:SetGameObject(XMVCA.XSkyTower:GetSceneObj())
end

function XSkyTowerCamera:AddEvent()
    XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_LEVEL_CHANGE, self.RefreshMoveRange, self)
end

function XSkyTowerCamera:RemoveEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_LEVEL_CHANGE, self.RefreshMoveRange, self)
end

function XSkyTowerCamera:SetGameObject(obj)
    self.SceneTransform = obj.Transform
    self.Camera = obj.Camera
    self.Camera.depth = 5
    self.CameraMain = obj.CameraMain
    self.CameraMove = obj.CameraMove
    self.CameraMoveTran = self.CameraMove.transform
    self.CameraDance = obj.CameraDance
    self.CameraWork = obj.CameraWork
    self.CameraFloor = obj.CameraFloor
    self.GameObject = self.Camera.gameObject
    --Brain挂在真实摄像机上，播放镜头动画时用它判断blend是否结束
    self._Brain = self.GameObject:GetComponent(typeof(CS.Cinemachine.CinemachineBrain))

    self:ShowDefault()
    self:RefreshCameraParam(obj.CameraParam)
    self:ShowEntranceCamera(true)

    local physicsRaycaster = self.GameObject:GetComponent(typeof(CS.UnityEngine.EventSystems.PhysicsRaycaster))
    if not physicsRaycaster then
        physicsRaycaster = self.GameObject:AddComponent(typeof(CS.UnityEngine.EventSystems.PhysicsRaycaster))
    end
    self._PhysicsRaycaster = physicsRaycaster
    --设置响应事件遮罩
    physicsRaycaster:SetEventMask(CS.UnityEngine.LayerMask.GetMask(LayerMaskName.Npc) | CS.UnityEngine.LayerMask.GetMask(LayerMaskName.Room))
    CS.XGraphicManager.BindCamera(self.Camera)
end

function XSkyTowerCamera:Release()
    self:ReleaseMainInput()
    XSkyTowerIScene.Release(self)
    self.Camera = nil
    self.CameraMain = nil
    self.CameraMoveTran = nil
    self.CameraDance = nil
    self.CameraWork = nil
    self.CameraFloor = nil
    self.SceneTransform = nil
    self.CameraMove = nil
    self._MoveTanHalfFov = nil
    self._PhysicsRaycaster = nil
    self._Brain = nil
    self._HasEnteredMainCamera = nil
    self._EntranceFloorId = nil
end

---刷新镜头参数配置，并按新参数重新计算移动范围、修正当前位置
---@param cameraParam XSkyTowerCameraParam
function XSkyTowerCamera:RefreshCameraParam(cameraParam)
    if XTool.UObjIsNil(cameraParam) then
        XLog.Error("通天塔场景摄像机缺少 XSkyTowerCameraParam 组件")
        return
    end
    self._CameraParam = cameraParam
    self:RefreshMoveCameraLens()
    self:RefreshMoveRange()
    self:ClampCameraPosition()
    self:NotifyGameplayUiState()
end

---缓存移动相机的视场角，缩放靠改localZ实现、不动镜头参数，
---所以只在参数刷新时算一次，避免每帧都去读m_Lens这个结构体
function XSkyTowerCamera:RefreshMoveCameraLens()
    if XTool.UObjIsNil(self.CameraMove) then
        return
    end
    self._MoveTanHalfFov = CsMathf.Tan(self.CameraMove.m_Lens.FieldOfView * 0.5 * CsMathf.Deg2Rad)
end

---统一缓存镜头配置，并按当前已解锁楼层数计算移动范围，配置变更或楼层解锁后需重新调用
function XSkyTowerCamera:RefreshMoveRange()
    local cameraParam = self._CameraParam
    if not cameraParam then
        return
    end
    local heightParam = cameraParam.Height
    local zoomParam = cameraParam.Zoom
    local detectionParam = cameraParam.FloorDetection
    local scrollParam = cameraParam.DragEdgeScroll
    local floorCount = math.max(self._Model:GetMaxFloorId(), 1)
    local floorHeight = XMVCA.XSkyTower:GetFloorTotalHeight()
    self._MinLocalY = heightParam.MinLocalY
    self._MaxLocalY = floorCount * floorHeight + heightParam.MaxHeightOffset
    self._MaxLocalY = math.max(self._MinLocalY, self._MaxLocalY)
    self._NearestLocalZ = zoomParam.NearestLocalZ
    self._FarthestLocalZ = zoomParam.BaseFarthestLocalZ - zoomParam.FloorCountToExtraPullBack:Evaluate(floorCount)
    self._FarthestLocalZ = math.min(self._FarthestLocalZ, self._NearestLocalZ)
    self._TopDistanceThreshold = detectionParam.TopDistanceThreshold
    self._DragDistancePerPixel = heightParam.DragDistancePerPixel
    self._DefaultLocalOffsetY = heightParam.DefaultLocalOffsetY
    self._LocateFloorDuration = heightParam.LocateFloorDuration
    self._InertiaDuration = heightParam.InertiaDuration
    self._InertiaVelocityScale = heightParam.InertiaVelocityScale
    self._MaxInertiaSpeed = heightParam.MaxInertiaSpeed
    self._InertiaStopSpeed = heightParam.InertiaStopSpeed
    self._InertiaSpeedCurve = heightParam.InertiaSpeedCurve
    self._DefaultLocalZ = zoomParam.DefaultLocalZ
    self._PinchSensitivity = zoomParam.PinchSensitivity
    self._MouseWheelSensitivity = zoomParam.MouseWheelSensitivity
    self._HideUiBelowLocalZ = zoomParam.HideUiBelowLocalZ
    self._HideUiAboveLocalZ = zoomParam.HideUiAboveLocalZ
    self._ScreenEdgePixels = scrollParam.ScreenEdgePixels
    self._AutoMoveSpeed = scrollParam.AutoMoveSpeed
    self._CrossGroupAllowedDistance = scrollParam.CrossGroupAllowedDistance
end

---把镜头当前位置夹回合法的高度与缩放范围内
function XSkyTowerCamera:ClampCameraPosition()
    if not self._CameraParam or XTool.UObjIsNil(self.CameraMoveTran) then
        return
    end
    local localX, localY, localZ = self.CameraMoveTran:GetLocalPosition()
    localY = CsMathf.Clamp(localY, self._MinLocalY, self._MaxLocalY)
    localZ = CsMathf.Clamp(localZ, self._FarthestLocalZ, self._NearestLocalZ)
    self.CameraMoveTran:SetLocalPosition(localX, localY, localZ)
end

---绑定主界面的镜头操作（拖动改高度、双指/滚轮缩放），并重置镜头到默认缩放
---@param inputHandler XGoInputHandler 镜头操作区域
---@param curFloorChangeCb function 当前楼层变化回调，参数：楼层Id
function XSkyTowerCamera:BindMainInput(inputHandler, curFloorChangeCb)
    self:ReleaseMainInput()
    if XTool.UObjIsNil(inputHandler) then
        return
    end
    self._InputHandler = inputHandler
    self._InputArea = inputHandler.gameObject
    self._CurFloorChangeCb = curFloorChangeCb
    self._BeginDragCb = handler(self, self.OnMainBeginDrag)
    self._DragCb = handler(self, self.OnMainDrag)
    self._EndDragCb = handler(self, self.OnMainEndDrag)
    inputHandler:AddBeginDragListener(self._BeginDragCb)
    inputHandler:AddDragListener(self._DragCb)
    inputHandler:AddEndDragListener(self._EndDragCb)

    if XTool.UObjIsNil(self._TouchHandler) then
        self._TouchHandler = self.CameraMoveTran.gameObject:AddComponent(typeof(CS.XBlackRockChess.XTouchHandler))
    end
    self._MainZoomCb = handler(self, self.OnMainZoom)
    self._TouchHandler:AddZoomAction(self._MainZoomCb)
    self:SetMainInputEnabled(true)
    self:ResetMainCameraPosition()
    self._HasEnteredMainCamera = true
end

---解除主界面的镜头操作绑定，并停掉所有正在进行的镜头运动
function XSkyTowerCamera:ReleaseMainInput()
    self:StopInertia()
    self:StopLocate()
    self._IsHeightDragging = false
    if not XTool.UObjIsNil(self._InputHandler) then
        self._InputHandler:RemoveAllListeners()
    end
    if self._MainZoomCb and not XTool.UObjIsNil(self._TouchHandler) then
        self._TouchHandler:DelZoomAction(self._MainZoomCb)
    end
    self._InputHandler = nil
    self._InputArea = nil
    self._MainZoomCb = nil
    self._CurFloorChangeCb = nil
    self._LastFloorCheckTime = nil
    self._DetectedFloorId = nil
    --楼层世界坐标在场景重建后会变，下次绑定时重新读取
    self._FloorWorldYList = nil
    self._FloorWorldYMaxId = nil
end

---开关镜头操作响应，关闭时会中断当前的拖动、惯性与定位（如打开子界面、长按升级时）
---@param value boolean
function XSkyTowerCamera:SetMainInputEnabled(value)
    self._MainInputEnabled = value
    if not XTool.UObjIsNil(self._InputHandler) then
        self._InputHandler.enabled = value
    end
    if not XTool.UObjIsNil(self._TouchHandler) then
        self._TouchHandler.enabled = value
    end
    if value then
        --子界面期间可能解锁楼层，恢复操作时按最新数据同步高度和缩放范围
        self:RefreshMoveRange()
    else
        self._IsHeightDragging = false
        self:StopInertia()
        self:StopLocate()
    end
    self:NotifyGameplayUiState()
end

---把镜头横向位置和缩放重置为默认值，高度保持不变
function XSkyTowerCamera:ResetMainCameraPosition()
    if not self._CameraParam or XTool.UObjIsNil(self.CameraMoveTran) then
        return
    end
    self:RefreshMoveRange()
    local localX, localY = self.CameraMoveTran:GetLocalPosition()
    localY = CsMathf.Clamp(localY, self._MinLocalY, self._MaxLocalY)
    local localZ = CsMathf.Clamp(self._DefaultLocalZ, self._FarthestLocalZ, self._NearestLocalZ)
    self.CameraMoveTran:SetLocalPosition(localX, localY, localZ)
    self:NotifyGameplayUiState()
end

---摄像机定位到指定楼层
---@param floorId number 楼层Id
---@param immediate boolean 是否瞬移，为false时播放快速移动
---@param onFinish function 定位完成回调
---@return boolean 是否成功发起定位
function XSkyTowerCamera:LocateFloor(floorId, immediate, onFinish, offsetY)
    if not XTool.IsNumberValid(floorId) or not self._CameraParam or XTool.UObjIsNil(self.CameraMoveTran) then
        return false
    end
    offsetY = offsetY or 0
    self:RefreshMoveRange()
    return self:LocatePosition(self:GetFloorLocalY(floorId, true) + offsetY, floorId, immediate, onFinish)
end

---保持镜头朝向和缩放，将场景挂点定位到画面中心，高度受镜头行程限制
---@param node UnityEngine.Transform 场景挂点
---@param floorId number 挂点所在楼层
---@param immediate boolean 是否瞬移
---@param onFinish function 定位完成回调
---@return boolean 是否成功发起定位
function XSkyTowerCamera:LocateNode(node, floorId, immediate, onFinish)
    if XTool.UObjIsNil(node) or not XTool.IsNumberValid(floorId) or not self._CameraParam or XTool.UObjIsNil(self.CameraMoveTran) then
        return false
    end
    --挂点和镜头不一定在同一个父节点下，统一转换到移动镜头的父节点空间
    local positionX, positionY, positionZ = node:GetPosition()
    local directionX, directionY, directionZ = self.CameraMoveTran:GetForward()
    local parent = self.CameraMoveTran.parent
    if not XTool.UObjIsNil(parent) then
        positionX, positionY, positionZ = parent:InverseTransformPointEx(positionX, positionY, positionZ)
        directionX, directionY, directionZ = parent:InverseTransformVectorEx(directionX, directionY, directionZ)
    end
    if math.abs(directionZ) <= MinRayDirection then
        return false
    end
    local _, _, localZ = self.CameraMoveTran:GetLocalPosition()
    local distance = (positionZ - localZ) / directionZ
    if distance <= 0 then
        return false
    end
    local targetY = positionY - directionY * distance
    return self:LocatePosition(targetY, floorId, immediate, onFinish)
end

---移动镜头到指定局部坐标，楼层定位和演出定位共用
---@private
function XSkyTowerCamera:LocatePosition(targetY, floorId, immediate, onFinish)
    self:StopInertia()
    self:StopLocate()
    self:RefreshMoveRange()

    local localX, localY, localZ = self.CameraMoveTran:GetLocalPosition()
    targetY = CsMathf.Clamp(targetY, self._MinLocalY, self._MaxLocalY)
    --主动定位的落点楼层已知，直接同步判定基准，避免结束后又被检测结果覆盖
    self._DetectedFloorId = floorId
    if immediate or targetY == localY then
        self.CameraMoveTran:SetLocalPosition(localX, targetY, localZ)
        self:NotifyGameplayUiState()
        if onFinish then
            onFinish(self:CalcCurFloorId())
        end
        return true
    end

    local beginY = localY
    self._LocateTimer = XUiHelper.Tween(self._LocateFloorDuration, function(progress)
        if XTool.UObjIsNil(self.CameraMoveTran) then
            return true
        end
        self.CameraMoveTran:SetLocalPosition(localX, beginY + (targetY - beginY) * progress, localZ)
    end, function()
        self._LocateTimer = nil
        if XTool.UObjIsNil(self.CameraMoveTran) then
            return
        end
        self:NotifyGameplayUiState()
        if onFinish then
            onFinish()
        end
    end)
    return true
end

---楼层对应的摄像机localPosition.y
---楼层在场景中按 FloorHeight * (FloorId - 1) 摆放（见XSkyTowerRoom），
---未居中时以MinLocalY作为1层的取景高度；居中时按当前镜头计算，仍受高度范围限制
---@param floorId number
---@param isCenter boolean 是否定位到楼层中间点
---@return number
function XSkyTowerCamera:GetFloorLocalY(floorId, isCenter)
    local floorHeight = XMVCA.XSkyTower:GetFloorTotalHeight()
    local targetY = self._MinLocalY + floorHeight * (floorId - 1)
    if isCenter then
        local floorObj = XMVCA.XSkyTower:GetFloorObjHash()[floorId]
        if not XTool.UObjIsNil(floorObj) and not XTool.UObjIsNil(self.CameraMoveTran) then
            --地板上方半层高作为楼层中心，镜头空间的y为0时处于屏幕纵向中线
            local positionX, positionY, positionZ = floorObj.transform:GetPosition()
            local _, centerY, centerZ = self.CameraMoveTran:InverseTransformPointEx(positionX, positionY + floorHeight * 0.5, positionZ)
            --镜头沿父节点的局部y轴移动，换算到镜头空间后求出让centerY归零的位移
            local moveX, moveY, moveZ = 0, 1, 0
            local parent = self.CameraMoveTran.parent
            if not XTool.UObjIsNil(parent) then
                local direction = parent:TransformVector(0, 1, 0)
                moveX, moveY, moveZ = direction.x, direction.y, direction.z
            end
            local _, directionY, directionZ = self.CameraMoveTran:InverseTransformVectorEx(moveX, moveY, moveZ)
            if math.abs(directionY) > MinRayDirection then
                local offsetY = centerY / directionY
                if centerZ - directionZ * offsetY > MinRayDirection then
                    local _, localY = self.CameraMoveTran:GetLocalPosition()
                    targetY = localY + offsetY
                end
            end
        end
    end
    return CsMathf.Clamp(targetY, self._MinLocalY, self._MaxLocalY)
end

---楼层天花板对应的摄像机localPosition.y
---@param floorId number
---@return number
function XSkyTowerCamera:GetFloorCeilingLocalY(floorId)
    local floorHeight = XMVCA.XSkyTower:GetFloorTotalHeight()
    local targetY = self._MinLocalY + floorHeight * floorId
    return CsMathf.Clamp(targetY, self._MinLocalY, self._MaxLocalY)
end

---打断正在进行的楼层或演出定位
function XSkyTowerCamera:StopLocate()
    if self._LocateTimer then
        XScheduleManager.UnSchedule(self._LocateTimer)
        self._LocateTimer = nil
    end
end

---楼层地板的世界高度，下标为楼层Id
---楼层由XSkyTowerRoom挂在BaseFloorPoint下摆放，而摄像机不在该节点内，
---直接读世界坐标可以免去BaseFloorPoint的偏移与缩放换算，也不依赖“每层等高”的假设
---@return number[]
function XSkyTowerCamera:GetFloorWorldYList()
    local maxFloorId = self._Model:GetMaxFloorId()
    if self._FloorWorldYList and self._FloorWorldYMaxId == maxFloorId then
        return self._FloorWorldYList
    end

    local list = {}
    for floorId, floorObj in pairs(XMVCA.XSkyTower:GetFloorObjHash()) do
        if not XTool.UObjIsNil(floorObj) then
            local position = floorObj.transform.position
            list[floorId] = position.y
            --所有楼层的localPosition只有y不同，共用一条竖直线，记下这条线的x/z供求交使用
            self._FloorLineX = position.x
            self._FloorLineZ = position.z
        end
    end
    self._FloorWorldYList = list
    self._FloorWorldYMaxId = maxFloorId
    return list
end

---反算“距屏幕顶部TopDistanceThreshold处”对应的世界高度
---@param anchorY number 竖直线上任意一点的高度，用于确定视线的屏幕水平位置
---@return number 世界高度，求交失败时返回nil
function XSkyTowerCamera:CalcTopLimitWorldY(anchorY)
    --锚点在镜头局部空间下的位置，z即沿视线方向的深度
    local anchorLocalX, _, anchorLocalZ = self.CameraMoveTran:InverseTransformPointEx(self._FloorLineX, anchorY, self._FloorLineZ)
    if anchorLocalZ <= MinRayDirection then
        --锚点落在镜头平面上或背后，当前朝向取不到楼层
        return nil
    end
    --视口y从下往上为0~1，换算成-1~1的归一化坐标
    local ndcY = 1 - 2 * self._TopDistanceThreshold
    --局部空间下视线方向为(横向偏移, 纵向偏移, 1)，纵向偏移由视场角得出；
    --而锚点方向的x/z之比就是所需的横向偏移，取楼层所在的水平位置可保证视线与竖直线共面、必定相交
    local directionX, directionY, directionZ = self.CameraMoveTran:TransformDirectionEx(anchorLocalX / anchorLocalZ, ndcY * self._MoveTanHalfFov, 1)
    local originX, originY, originZ = self.CameraMoveTran:GetPosition()

    --用x/z中方向分量较大的一轴解出视线走过的距离，避免除以接近0的值
    local distance
    if math.abs(directionZ) >= math.abs(directionX) then
        if math.abs(directionZ) <= MinRayDirection then
            return nil
        end
        distance = (self._FloorLineZ - originZ) / directionZ
    else
        if math.abs(directionX) <= MinRayDirection then
            return nil
        end
        distance = (self._FloorLineX - originX) / directionX
    end
    --交点落在镜头背后，说明当前朝向取不到楼层
    if distance <= 0 then
        return nil
    end
    return originY + directionY * distance
end

---按当前镜头位置判定所处楼层：取地板落在“距屏幕顶部TopDistanceThreshold”以下的最高楼层
---@return number 楼层Id，判定失败时返回0
function XSkyTowerCamera:CalcCurFloorId()
    if not self._CameraParam or XTool.UObjIsNil(self.CameraMoveTran) or not self._MoveTanHalfFov then
        return 0
    end
    local floorYList = self:GetFloorWorldYList()
    local anchorY = floorYList[1]
    if not anchorY then
        return 0
    end

    local limitY = self:CalcTopLimitWorldY(anchorY)
    if not limitY then
        return 0
    end

    local result = 0
    for floorId = 1, self._Model:GetMaxFloorId() do
        local floorY = floorYList[floorId]
        if floorY and floorY <= limitY then
            result = floorId
        end
    end
    return result > 0 and result or 1
end

---镜头移动后按CheckInterval节流地重算当前楼层，变化时回调
function XSkyTowerCamera:CheckCurFloor()
    if not self._CurFloorChangeCb or not self._CameraParam then
        return
    end
    local now = CsTime.unscaledTime
    if self._LastFloorCheckTime and now - self._LastFloorCheckTime < CheckInterval then
        return
    end
    self._LastFloorCheckTime = now

    local floorId = self:CalcCurFloorId()
    if not XTool.IsNumberValid(floorId) or floorId == self._DetectedFloorId then
        return
    end
    self._DetectedFloorId = floorId
    self._CurFloorChangeCb(floorId)
end

---强制重算当前楼层，忽略节流与上一次结果（定位结束、参数变更时使用）
function XSkyTowerCamera:ForceCheckCurFloor()
    self._LastFloorCheckTime = nil
    self._DetectedFloorId = nil
    self:CheckCurFloor()
end

---开始拖动，打断定位与惯性并进入拖动态
function XSkyTowerCamera:OnMainBeginDrag()
    if not self._MainInputEnabled or not self._CameraParam then
        return
    end
    self:StopLocate()
    self:StopInertia()
    self._IsHeightDragging = true
    self._LastHeightVelocity = 0
    self:NotifyGameplayUiState()
end

---拖动中，按手指位移改变镜头高度并记录瞬时速度供惯性使用
---@param eventData UnityEngine.EventSystems.PointerEventData
function XSkyTowerCamera:OnMainDrag(eventData)
    if not self._IsHeightDragging or not eventData then
        return
    end
    local _, deltaY = eventData:GetDelta()
    deltaY = -deltaY * self._DragDistancePerPixel
    local actualDelta = self:MoveHeight(deltaY)
    self._LastHeightVelocity = self._UnscaledDeltaTime > 0 and actualDelta / self._UnscaledDeltaTime or 0
end

---结束拖动，按松手速度进入惯性滑动
function XSkyTowerCamera:OnMainEndDrag()
    if not self._IsHeightDragging then
        return
    end
    self._IsHeightDragging = false
    if not self:StartInertia(self._LastHeightVelocity or 0) then
        self:NotifyGameplayUiState()
        self:ForceCheckCurFloor()
    end
end

---按增量移动镜头高度，超出范围时截断
---@param deltaY number 期望的高度增量
---@return number 实际生效的高度增量
function XSkyTowerCamera:MoveHeight(deltaY)
    if deltaY == 0 or not self._CameraParam then
        return 0
    end
    local localX, localY, localZ = self.CameraMoveTran:GetLocalPosition()
    local minY, maxY = self:GetHeightRange()
    local targetY = CsMathf.Clamp(localY + deltaY, minY, maxY)
    local actualDelta = targetY - localY
    if actualDelta == 0 then
        return 0
    end
    self.CameraMoveTran:SetLocalPosition(localX, targetY, localZ)
    --拖动、惯性与屏幕边缘滚动都经过此处，楼层检测统一在这里处理
    self:CheckCurFloor()
    return actualDelta
end

--- 按指针到屏幕上下边缘的距离滚动镜头，拖动期间每帧调用
---@param pointerScreenY number 指针屏幕纵坐标
---@param screenHeight number 屏幕高度（像素）
---@return number 实际生效的高度增量
function XSkyTowerCamera:MoveHeightByScreenEdge(pointerScreenY, screenHeight)
    if not self._CameraParam or not pointerScreenY or not screenHeight or screenHeight <= 0 then
        return 0
    end
    -- 边缘区最多各占半屏，否则上下两侧会重叠
    local range = math.min(self._ScreenEdgePixels, screenHeight * 0.5)
    if range <= 0 then
        return 0
    end
    -- 越贴近边缘系数越大，上边缘为正（镜头升高）、下边缘为负
    local ratio = 0
    if pointerScreenY > screenHeight - range then
        ratio = (pointerScreenY - (screenHeight - range)) / range
    elseif pointerScreenY < range then
        ratio = (pointerScreenY - range) / range
    end
    if ratio == 0 then
        return 0
    end
    ratio = CsMathf.Clamp(ratio, -1, 1)
    -- 拖动属UI交互，不应被战斗/演出的timeScale影响
    return self:MoveHeight(ratio * self._AutoMoveSpeed * self._UnscaledDeltaTime)
end

--- 限制镜头只能在指定高度区间内移动，允许越出的位移取自镜头参数
---@param minLocalY number 区间下界
---@param maxLocalY number 区间上界
function XSkyTowerCamera:SetHeightLimit(minLocalY, maxLocalY)
    self._LimitMinLocalY = minLocalY
    self._LimitMaxLocalY = math.max(minLocalY, maxLocalY)
    self._LimitOverflow = self._CrossGroupAllowedDistance or 0
end

function XSkyTowerCamera:ClearHeightLimit()
    self._LimitMinLocalY = nil
    self._LimitMaxLocalY = nil
    self._LimitOverflow = nil
end

--- 当前允许到达的高度上下限，未设区间限制时即镜头本身的行程范围
---@return number, number
function XSkyTowerCamera:GetHeightRange()
    if not self._LimitMinLocalY then
        return self._MinLocalY, self._MaxLocalY
    end
    --塔底和塔顶不参与越界放宽，保留镜头的全局端点
    local minY = self._LimitMinLocalY <= self._MinLocalY and self._MinLocalY or self._LimitMinLocalY - self._LimitOverflow
    local maxY = self._LimitMaxLocalY >= self._MaxLocalY and self._MaxLocalY or self._LimitMaxLocalY + self._LimitOverflow
    --镜头已越出区间时放宽到当前位置，避免被瞬间拉回
    local _, localY = self.CameraMoveTran:GetLocalPosition()
    return math.min(minY, localY), math.max(maxY, localY)
end

---松手后按初速度开启惯性滑动，速度过小或时长非正时不启动
---@param velocity number 松手瞬间的高度速度
---@return boolean 是否进入惯性
function XSkyTowerCamera:StartInertia(velocity)
    if self._InertiaDuration <= 0 then
        return false
    end
    velocity = CsMathf.Clamp(velocity * self._InertiaVelocityScale, -self._MaxInertiaSpeed, self._MaxInertiaSpeed)
    if math.abs(velocity) <= self._InertiaStopSpeed then
        return false
    end
    self._InertiaVelocity = velocity
    self._InertiaElapsed = 0
    self._InertiaTimer = XScheduleManager.ScheduleForever(handler(self, self.UpdateInertia), 0)
    self:NotifyGameplayUiState()
    return true
end

---惯性滑动的每帧驱动，按速度曲线衰减，时长耗尽或速度过小时结束
function XSkyTowerCamera:UpdateInertia()
    if not self._CameraParam or not self._MainInputEnabled then
        self:StopInertia()
        self:NotifyGameplayUiState()
        self:ForceCheckCurFloor()
        return
    end
    self._InertiaElapsed = self._InertiaElapsed + self._UnscaledDeltaTime
    local progress = CsMathf.Clamp01(self._InertiaElapsed / self._InertiaDuration)
    local speed = self._InertiaVelocity * self._InertiaSpeedCurve:Evaluate(progress)
    local actualDelta = self:MoveHeight(speed * self._UnscaledDeltaTime)
    local actualSpeed = self._UnscaledDeltaTime > 0 and math.abs(actualDelta / self._UnscaledDeltaTime) or 0
    if progress >= 1 or actualSpeed <= self._InertiaStopSpeed then
        self:StopInertia()
        self:NotifyGameplayUiState()
        self:ForceCheckCurFloor()
    end
end

---打断惯性滑动
function XSkyTowerCamera:StopInertia()
    if self._InertiaTimer then
        XScheduleManager.UnSchedule(self._InertiaTimer)
        self._InertiaTimer = nil
    end
end

---双指捏合/滚轮缩放回调，改变镜头与楼层的距离
---@param value number 缩放输入量，正数为拉近
function XSkyTowerCamera:OnMainZoom(value)
    if not self._MainInputEnabled or not self._CameraParam or not self:IsZoomInputAllowed() then
        return
    end
    local sensitivity = CsInput.touchCount >= 2 and self._PinchSensitivity or self._MouseWheelSensitivity
    local localX, localY, localZ = self.CameraMoveTran:GetLocalPosition()
    local targetZ = CsMathf.Clamp(localZ - value * sensitivity, self._FarthestLocalZ, self._NearestLocalZ)
    if targetZ == localZ then
        return
    end
    --演出定位的目标位置按当前缩放计算，主动缩放时取消定位
    self:StopLocate()
    self.CameraMoveTran:SetLocalPosition(localX, localY, targetZ)
    --缩放只刷新玩法UI显隐，保持当前楼层和分区选中状态
    self:NotifyGameplayUiState()
end

---缩放输入是否落在镜头操作区域内（避免在UI上捏合时误缩放）
---@return boolean
function XSkyTowerCamera:IsZoomInputAllowed()
    local eventSystem = CsEventSystem.current
    if XTool.UObjIsNil(eventSystem) or XTool.UObjIsNil(self._InputArea) then
        return false
    end
    local mousePosition = CsInput.mousePosition
    local position = CsVector2(mousePosition.x, mousePosition.y)
    if CsInput.touchCount >= 2 then
        position = (CsInput.GetTouch(0).position + CsInput.GetTouch(1).position) * 0.5
    end
    local eventData = CsPointerEventData(eventSystem)
    eventData.position = position
    self._RaycastResults:Clear()
    eventSystem:RaycastAll(eventData, self._RaycastResults)
    if self._RaycastResults.Count <= 0 then
        return false
    end
    local raycastTransform = self._RaycastResults[0].gameObject.transform
    return raycastTransform == self._InputArea.transform or raycastTransform:IsChildOf(self._InputArea.transform)
end

---通知外部玩法UI的显隐：缩放超出可视区间时隐藏，其余情况都显示
function XSkyTowerCamera:NotifyGameplayUiState()
    if not self._CameraParam or XTool.UObjIsNil(self.CameraMoveTran) then
        return
    end
    local _, _, localZ = self.CameraMoveTran:GetLocalPosition()
    local hideByZoomRange = localZ < self._HideUiBelowLocalZ or localZ > self._HideUiAboveLocalZ
    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_HIDE_GAMEPLAY_UI, hideByZoomRange)
end

function XSkyTowerCamera:ShowDefault()
    self:ShowCamera(self.CameraMove)
end

---返回入口时注视玩法镜头内的最高楼层，首次进入活动时默认注视已解锁最高层。
function XSkyTowerCamera:ShowEntranceCamera(immediate)
    self:SetMainInputEnabled(false)
    self:RefreshMoveRange()
    local floorId = self._Model:GetMaxFloorId()
    if self._HasEnteredMainCamera then
        --即时判定，避免使用被输入解绑清除、或仍处于节流间隔内的楼层缓存
        local curFloorId = self:CalcCurFloorId()
        if XTool.IsNumberValid(curFloorId) then
            floorId = curFloorId
        end
    end
    self._EntranceFloorId = floorId
    local transform = self.CameraMain.transform
    local localX, _, localZ = transform:GetLocalPosition()
    transform:SetLocalPosition(localX, self:GetFloorLocalY(floorId), localZ)
    self:ShowCamera(self.CameraMain, immediate)
end

---入口当前注视的楼层，供再次进入玩法时恢复定位
---@return number
function XSkyTowerCamera:GetEntranceFloorId()
    return self._EntranceFloorId or self._Model:GetMaxFloorId()
end

---跟随舞台
function XSkyTowerCamera:ShowDanceCamera(node)
    self.CameraDance.Follow = node
    self:ShowCamera(self.CameraDance)
end

---跟随最新解锁的楼层
function XSkyTowerCamera:ShowFloorCamera(node)
    self.CameraFloor.Follow = node
    self:ShowCamera(self.CameraFloor)
end

---跟随最新解锁的工作台
function XSkyTowerCamera:ShowWorkCamera(node)
    self.CameraWork.Follow = node
    self:ShowCamera(self.CameraWork)
end

function XSkyTowerCamera:ShowCamera(camera, immediate)
    self.CameraMain.gameObject:SetActiveEx(camera == self.CameraMain)
    self.CameraMove.gameObject:SetActiveEx(camera == self.CameraMove)
    self.CameraDance.gameObject:SetActiveEx(camera == self.CameraDance)
    self.CameraWork.gameObject:SetActiveEx(camera == self.CameraWork)
    self.CameraFloor.gameObject:SetActiveEx(camera == self.CameraFloor)

    if not immediate or XTool.UObjIsNil(self._Brain) then
        return
    end

    camera.PreviousStateIsValid = false
    self._Brain.enabled = false
    self._Brain.enabled = true
end

---混合镜头的Brain，挂在真实摄像机上
---@return Cinemachine.CinemachineBrain
function XSkyTowerCamera:GetBrain()
    return self._Brain
end

---场景点击响应的开关，播放镜头动画期间需要关闭
---@param value boolean
function XSkyTowerCamera:SetScenePickEnabled(value)
    if XTool.UObjIsNil(self._PhysicsRaycaster) then
        return
    end
    self._PhysicsRaycaster.enabled = value
end

function XSkyTowerCamera:GetDefaultLocalOffsetY()
    return self._DefaultLocalOffsetY
end

return XSkyTowerCamera
