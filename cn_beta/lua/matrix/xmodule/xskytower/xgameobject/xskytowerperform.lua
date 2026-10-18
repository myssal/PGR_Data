---@class XSkyTowerPerform : XEntity 演出管理
---@field _Model XSkyTowerModel
---@field _OwnControl XSkyTowerControl
---@field _GameObject UnityEngine.GameObject
---@field _Actors table<number, XSkyTowerPerformer>
local XSkyTowerPerform = XClass(XEntity, "XSkyTowerPerform")

local BehaviorState = {
    None = 0,
    Load = 1,
    FirstTrigger = 2,
    MultipleTrigger = 3,
    Exit = 4,
}

local PerformState2BehaviorState = {
    [XMVCA.XSkyTower.PerformState.NotStart] = BehaviorState.FirstTrigger,
    [XMVCA.XSkyTower.PerformState.OnGoing] = BehaviorState.MultipleTrigger,
    [XMVCA.XSkyTower.PerformState.Finish] = BehaviorState.Exit,
}

function XSkyTowerPerform:OnInit()
    --处于演出中
    self._IsInPerform = false
    --舞台的演员
    self._Actors = {}
    --舞台的物品
    self._Furniture = {}

    self._FurniturePath = {}
end

function XSkyTowerPerform:SetGameObject(obj)
    if XTool.UObjIsNil(obj) then
        XLog.Error("演出舞台为空!!!")
        return
    end
    self._GameObject = obj
    self._Transform = obj.transform
    --添加行为树代理
    local typeStr = typeof(CS.BehaviorTree.XAgent)
    local agent = self._GameObject:GetComponent(typeStr)
    if not agent then
        agent = self._GameObject:AddComponent(typeStr)
        agent.ProxyType = "SkyTowerPerform"
        agent:InitProxy()
    end
    agent.Proxy.LuaAgentProxy:SetPerform(self)
    ---@type BehaviorTree.XAgent
    self._Agent = agent
end

---是否楼层区间事件
function XSkyTowerPerform:SetFloorGroupPerform(isGroup)
    self._IsFloorGroup = isGroup
end

function XSkyTowerPerform:IsFloorGroupPerform()
    return self._IsFloorGroup
end

--演出开始
function XSkyTowerPerform:StartPerformance(performanceId)
    --演出中，不能打断上次的演出
    if self._IsInPerform then
        return
    end
    self._IsInPerform = true
    self._PerformanceId = performanceId
    self._FloorId = self._OwnControl:GetFloorId(performanceId)
    self:SetAgentFloorId()
    self:ChangeState(BehaviorState.Load)
end

--演出谢幕
function XSkyTowerPerform:StopPerformance()
    --演出未开始
    if not self._IsInPerform then
        return
    end
    self:RemovePerformStateListener()
    self:ChangeState(BehaviorState.Exit)
end

-- 所有道具加载完毕，开始演出
function XSkyTowerPerform:DoBegin()
    if not XTool.IsNumberValid(self._PerformanceId) then
        return
    end
    if not self._IsAddEvent then
        self._IsAddEvent = true
        XEventManager.AddEventListener(XEventId.EVENT_SKY_TOWER_PERFORM_STATE_CHANGE, self.OnPerformStateChanged, self)
    end
end

function XSkyTowerPerform:RemovePerformStateListener()
    if not self._IsAddEvent then
        return
    end
    self._IsAddEvent = false
    XEventManager.RemoveEventListener(XEventId.EVENT_SKY_TOWER_PERFORM_STATE_CHANGE, self.OnPerformStateChanged, self)
end

--- 加载演员
---@param performerId number
---@param floorId number 所在楼层
---@param position UnityEngine.Vector3 位置
---@param rotation UnityEngine.Vector3 旋转
function XSkyTowerPerform:LoadActor(performerId, floorId, position, rotation, loadCb)
    local performer = self._Actors[performerId]
    if not performer then
        performer = self._OwnControl:GetRoom(floorId):LoadPerformer(performerId, floorId)
        self._Actors[performerId] = performer
    end
    local basePoint = self._Transform.position
    local targetX = basePoint.x + position.x
    local targetY = basePoint.y + position.y
    local targetZ = basePoint.z + position.z
    performer:SetPerform(self)
    performer:SetTransform(targetX, targetY, targetZ, rotation.x, rotation.y, rotation.z)
    performer:Born(loadCb)
end

--- 加载演出道具
---@param performerId number
---@param floorId number 所在楼层
---@param position UnityEngine.Vector3 位置
---@param rotation UnityEngine.Vector3 旋转
function XSkyTowerPerform:LoadFurniture(performerId, floorId, position, rotation, loadCb)
    local url = self._Model:GetNpcModelUrl(self._Model:GetPerformerNpcId(performerId))
    local loader = self._OwnControl:GetLoader()
    local asset = loader:Load(url)
    if not asset then
        XLog.Error("加载演出道具异常! 路径 = " .. url)
        return
    end
    if not self._FurniturePath[performerId] then
        self._FurniturePath[performerId] = {}
    end

    local obj = XUiHelper.Instantiate(asset, self:GetTransform())
    if not obj then
        return
    end
    local key = self._IsFloorGroup and "@FloorGroupFurniture-%s" or "@Furniture-%s"
    local basePoint = self._Transform.position
    obj.name = string.format(key, performerId)
    obj.transform:SetPosition(basePoint.x + position.x, basePoint.y + position.y, basePoint.z + position.z)
    obj.transform:SetEulerRotation(rotation.x, rotation.y, rotation.z)

    if not self._Furniture[performerId] then
        self._Furniture[performerId] = {}
    end
    local insId = obj.gameObject:GetInstanceID()
    self._Furniture[performerId][insId] = obj
    self._FurniturePath[performerId][insId] = url
    if loadCb then
        loadCb()
    end
end

function XSkyTowerPerform:OnPerformStateChanged(floorId)
    if self._FloorId ~= floorId then
        return
    end
    if not XTool.IsNumberValid(self._PerformanceId) then
        return
    end
    local state = self._OwnControl:GetState(self._PerformanceId)
    local behaviorState = PerformState2BehaviorState[state]
    if not behaviorState then
        return
    end

    --推出状态由协议调用
    if behaviorState == BehaviorState.Exit then
        return
    end
    --ChangeState内部会再次派发状态变化事件，状态相同直接返回避免自激
    if behaviorState == self._State then
        return
    end
    self:ChangeState(behaviorState)
end

function XSkyTowerPerform:ChangeState(state)
    if state == BehaviorState.None then
        return
    end
    self._State = state
    local behaviorId = self._Model:GetPerformBehaviourId(self._PerformanceId, state)
    if not string.IsNilOrEmpty(behaviorId) then
        XLuaBehaviorManager.PlayId(behaviorId, self._Agent)
    end
    for _, actor in pairs(self._Actors) do
        actor:ChangeState(state)
    end
    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_PERFORM_STATE_CHANGE, self._FloorId)
end

function XSkyTowerPerform:DoBubble(npcId, dialogId, index)
    local performer = self._Actors[npcId]
    if not performer then
        XLog.Error("不存在NpcId = " .. npcId .. "的演出角色")
        return
    end
    performer:SetBubbleTextList(dialogId)
    performer:DoBubble(index)
end

function XSkyTowerPerform:DoHideBubble(npcId)
    local performer = self._Actors[npcId]
    if not performer then
        XLog.Error("不存在NpcId = " .. npcId .. "的演出角色")
        return
    end
    performer:DoHideBubble()
end

function XSkyTowerPerform:DoDestroyProps(npcId)
    --移除演员
    self:RemoveActor(npcId)
    --移除家具
    local furnitureDict = self._Furniture[npcId] or {}
    for _, furniture in pairs(furnitureDict) do
        if furniture and not XTool.UObjIsNil(furniture.gameObject) then
            CS.UnityEngine.Object.Destroy(furniture.gameObject)
        end
    end
    local urlList = self._FurniturePath[npcId]
    if not XTool.IsTableEmpty(urlList) then
        local loader = self._OwnControl:GetLoader()
        for _, url in pairs(urlList) do
            loader:Unload(url)
        end
    end
end

function XSkyTowerPerform:IsEqualState(state)
    if not XTool.IsNumberValid(self._PerformanceId) then
        return false
    end

    local performState = self._OwnControl:GetState(self._PerformanceId)
    local behaviorState = PerformState2BehaviorState[performState]
    return behaviorState == state
end

function XSkyTowerPerform:DestroyAllProps(isBehavior)
    for _, actor in pairs(self._Actors) do
        actor:Release()
    end
    for _, furnitureDict in pairs(self._Furniture) do
        for _, furniture in pairs(furnitureDict) do
            if furniture and not XTool.UObjIsNil(furniture.gameObject) then
                CS.UnityEngine.Object.Destroy(furniture.gameObject)
            end
        end
    end
    local loader = self._OwnControl:GetLoader()
    for _, urlList in pairs(self._FurniturePath) do
        for _, url in pairs(urlList) do
            loader:Unload(url)
        end
    end
    self._IsInPerform = false
    self._Actors = {}
    self._Furniture = {}
    self._FurniturePath = {}
    self:RemovePerformStateListener()
    if isBehavior then
        if self._IsFloorGroup then
            self._OwnControl:GetRoom(self._FloorId):PlayFloorGroupPerformance()
        else
            self._OwnControl:GetRoom(self._FloorId):PlayPerformance()
        end
    end
end

function XSkyTowerPerform:OnRelease()
    self:DestroyAllProps(false)
end

function XSkyTowerPerform:Release()
    --Release不销毁道具（沿用旧逻辑，由OnRelease处理），但事件监听必须摘掉，否则场景销毁后仍会被回调
    self:RemovePerformStateListener()
end

function XSkyTowerPerform:GetTransform()
    return self._Transform
end

function XSkyTowerPerform:RemoveActor(performerId)
    local performer = self._Actors[performerId]
    if not performer then
        return
    end
    self._Actors[performerId] = nil
    performer:DisposeImmediately()
end

function XSkyTowerPerform:SetAgentFloorId()
    self._Agent:SetVarDicByKey("FloorId", self._FloorId)
end

return XSkyTowerPerform