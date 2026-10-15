
local XSkyTowerIScene = require("XModule/XSkyTower/XGameObject/XSkyTowerIScene")

---@class XSkyTowerChar : XSkyTowerIScene
---@field _Id
---@field _Animator UnityEngine.Animator
---@field _Input XGoInputHandler
---@field _BubbleOffset UnityEngine.Vector3 气泡偏移
---@field _Agent BehaviorTree.XAgent
---@field _ReferenceCount number 引用计数
---@field _EffectLoader XUiLoadPrefab
---@field _IsShowDelayBubble boolean
---@field _IsDoLoadBehaviour boolean
---@field _MoveSpeed number 移动速度
---@field _MoveAgent XMoveAgent
---@field _FloorId number 所在楼层
local XSkyTowerChar = XClass(XSkyTowerIScene, "XSkyTowerChar")

local ResourceUnloadTime = 10000 --延时销毁

---@param root UnityEngine.Transform 父节点
---@param id number 对象Id
---@param floorId number 所在楼层，由创建者（房间）传入
function XSkyTowerChar:OnInit(root, id, floorId)
    self._FloorId = floorId or 0
    XSkyTowerIScene.OnInit(self, root, id)
    self._Id = id
    self._ReferenceCount = 0
    self._BubbleOffset = XMVCA.XSkyTower:StrPos2Vector3(self._Model:GetClientConfigValue("CharacterProperty", 2))
    self:InitData()
end

function XSkyTowerChar:Init()
    self._MoveSpeed = tonumber(self._Model:GetClientConfigValue("CharacterProperty", 1))
    self._BubbleDuration = self._OwnControl:GetBubbleProperty()
end

function XSkyTowerChar:InitData()
    
end

function XSkyTowerChar:Born(bornCb)
    local exist = self:Exist()
    --存在 且 显示
    if exist and not self:IsHide() then
        if bornCb then bornCb() end
        return
    end
    self._ReferenceCount = self._ReferenceCount + 1
    if exist then
        self:Show()
        if bornCb then bornCb() end
        return
    end

    if self:IsLoading() then
        return
    end
    
    self:Load(bornCb)
end

function XSkyTowerChar:CheckAfterLoad()
    if XTool.UObjIsNil(self._Root) then
        return false
    end
    return true
end

function XSkyTowerChar:Dispose()
    if not self:Exist() then
        self._ReferenceCount = 0
        return
    end
    self._ReferenceCount = self._ReferenceCount - 1
    self:Hide()
    self:StopDelayTimer()
    self.DelayTimer = XScheduleManager.ScheduleOnce(self._DelayReleaseCb, ResourceUnloadTime)
end

function XSkyTowerChar:StopDelayTimer()
    if not self.DelayTimer then
        return
    end
    XScheduleManager.UnSchedule(self.DelayTimer)
    self.DelayTimer = nil
end

function XSkyTowerChar:DisposeImmediately()
    self:Release()
end

function XSkyTowerChar:OnLoadSuccess()
    --动画
    self._Animator = self._GameObject:GetComponent(typeof(CS.UnityEngine.Animator))
    if not self._Model or not self:CheckAfterLoad() then
        self:Release()
        return
    end
    -- 加载自定义状态机
    local path = self:GetControllerPath()
    if not string.IsNilOrEmpty(path) then
        local loader = self._OwnControl:GetLoader()
        local asset = loader:Load(path)
        if not asset then
            XLog.Error(string.format("%s:角色状态机加载失败, 路径: %s", self:GetCharTypeDesc(), path))
            return
        end
        
        self._CtrlPath = path
        self._Animator.runtimeAnimatorController = asset
    end
    self._ActionDurationCache = nil
    --取消动画自带的位移
    self._Animator.applyRootMotion = false
    --不可见时跳过重定向、IK 和骨骼 Transform 写入，状态机仍更新
    self._Animator.cullingMode = CS.UnityEngine.AnimatorCullingMode.CullUpdateTransforms
    self._EffectLoader = self._GameObject:GetComponent(typeof(CS.XUiLoadPrefab))
    --行为树代理
    self._Agent = self._GameObject:GetComponent(typeof(CS.BehaviorTree.XAgent))
    if not self._Agent then
        self._Agent = self._GameObject:AddComponent(typeof(CS.BehaviorTree.XAgent))
        self._Agent.ProxyType = "SkyTowerChar"
        self._Agent:InitProxy()
    end
    self._Agent.Proxy.LuaAgentProxy:SetRole(self)
    --是否需要点击
    if self:IsNeedClick() then
        --设置层级，点击生效
        self._GameObject:SetLayerRecursively(CS.UnityEngine.LayerMask.NameToLayer(LayerMaskName.Npc))
        self._Input = self._GameObject:GetComponent(typeof(CS.XGoInputHandler))
        if not self._Input then
            self._Input = self._GameObject:AddComponent(typeof(CS.XGoInputHandler))
        end
        self._Input:AddPointerClickListener(handler(self, self.OnClick))
    end
    --处理旋转/位移/缩放
    self:InitCharTransform()
    --订单NPC、演员等可能直接使用预制体自带的移动组件，也要统一关闭角色碰撞。
    self:TryAddNavMeshAgent(true)
    --处理阴影
    --CS.XMaterialContainerHelper.SetCharacterShadowVolumeEnable(self._GameObject, false)
    --CS.XShadowHelper.AddShadow(self._GameObject, true)

    self._DelayReleaseCb = handler(self, self.DelayRelease)

    self:PlayBehaviour()

    if self:IsHideWhenStopBusiness() and not self:GetRoom():IsInBusinessScene() then
        self:Hide()
    end
end

function XSkyTowerChar:IsHideWhenStopBusiness()
    return false
end

function XSkyTowerChar:Release()
    if not string.IsNilOrEmpty(self._CtrlPath) then
        local loader = self._OwnControl:GetLoader()
        loader:Unload(self._CtrlPath)
        self._CtrlPath = nil
    end
    XSkyTowerIScene.Release(self)
    
    self._Animator = nil
    self._ActionDurationCache = nil
    self._Input = nil
    self._Agent = nil
    self._EffectLoader = nil
    self._Effect = nil
    self._EffectPath = nil
    self._EffectTransform = nil
    self._MoveAgent = nil

    self._ReferenceCount = 0
    self._IsShowDelayBubble = false
    
    self:StopDelayTimer()
end

function XSkyTowerChar:Hide()
    XSkyTowerIScene.Hide(self)
    self:DoHideBubble()
    self._IsDoLoadBehaviour = false
end

function XSkyTowerChar:DelayRelease()
    if not self:Exist() then
        return
    end
    --还有引用，不销毁
    if self._ReferenceCount > 0 then
        return
    end
    
    self:Release()
end

function XSkyTowerChar:GetControllerPath()
    return ""
end

--Debug 输出, 不用于实际业务
function XSkyTowerChar:GetCharTypeDesc()
    return ""
end

function XSkyTowerChar:IsNeedClick()
    return false
end

function XSkyTowerChar:OnClick()
    XLog.Warning("未实现点击方法！")
end

function XSkyTowerChar:InitCharTransform()
end

function XSkyTowerChar:PlayBehaviour()
    XLog.Error("子类未实现该方法")
end

function XSkyTowerChar:ChangeState(state)
end

--播放动画
function XSkyTowerChar:DoAction(actionId, needFadeCross, crossDuration)
    if not self:Exist() then
        return
    end
    if needFadeCross then
        self._Animator:CrossFade(actionId, crossDuration, -1, 0)
    else
        self._Animator:Play(actionId, -1, 0)
    end
end

--根据下标播放动画
function XSkyTowerChar:DoActionIndex(index, needFadeCross, crossDuration)
    self:DoAction(self:GetActionId(index), needFadeCross, crossDuration)
end

function XSkyTowerChar:CheckPlayRepeat(index, isRequireRepeat)
    if isRequireRepeat then
        return true
    end

    local stateInfo = self._Animator:GetCurrentAnimatorStateInfo(0)
    local nextInfo = self._Animator:GetNextAnimatorStateInfo(0)
    
    local actionId = self:GetActionId(index)
    
    local newHash = CS.UnityEngine.Animator.StringToHash(actionId)

    if newHash == stateInfo.shortNameHash 
            or nextInfo.shortNameHash == newHash then
        return false
    end
    return true
end

function XSkyTowerChar:GetActionId(index)
    XLog.Error("子类调用，但未实现该方法")
    return "Error"
end

function XSkyTowerChar:GetActionDuration(index)
    local actionId = self:GetActionId(index)
    if string.IsNilOrEmpty(actionId) then
        return 0
    end
    local cache = self._ActionDurationCache
    if not cache then
        local controller = self._Animator.runtimeAnimatorController
        if XTool.UObjIsNil(controller) then
            return 0
        end

        cache = {}
        local animationClips = controller.animationClips
        for i = 0, animationClips.Length - 1 do
            local clip = animationClips[i]
            if clip then
                local name = clip.name
                -- 同名动画保留第一个，保持原有查找行为
                if cache[name] == nil then
                    cache[name] = clip.length
                end
            end
        end
        self._ActionDurationCache = cache
    end

    return cache[actionId] or 0
end

--弹出聊天气泡
function XSkyTowerChar:DoRandomBubble()
    if XTool.UObjIsNil(self._GameObject) or self:IsHide() then
        return
    end
    local text = self:GetRandomBubbleText()
    if string.IsNilOrEmpty(text) then
        return
    end
    
    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_SHOW_3D_DIALOG, self:GetBubbleKey(), text, nil, self._Transform, self._BubbleOffset)
end

function XSkyTowerChar:DoBubble(index)
    if XTool.UObjIsNil(self._GameObject) or self:IsHide() then
        return
    end
    local text = self:GetBubbleText(index)
    if string.IsNilOrEmpty(text) then
        return
    end
    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_SHOW_3D_DIALOG, self:GetBubbleKey(), text, nil, self._Transform, self._BubbleOffset)
end

--- 延时弹出气泡
---@param delay number 毫秒
function XSkyTowerChar:DoRandomBubbleDelay(delay)
    --上次的正在展示
    if self:IsShowDelayBubble() then
        return
    end
    
    if not self._RandomBubbleHandler then
        self._RandomBubbleHandler = function()
            if not self:Exist() then
                return
            end
            
            self:DoRandomBubble()
            XScheduleManager.ScheduleOnce(function() 
                self:DoHideBubble()
                self._IsShowDelayBubble = false
            end, self._BubbleDuration * XScheduleManager.SECOND)
        end
    end
    self._IsShowDelayBubble = true
    XScheduleManager.ScheduleOnce(self._RandomBubbleHandler, delay)
end

function XSkyTowerChar:IsShowDelayBubble()
    return self._IsShowDelayBubble
end

--隐藏气泡
function XSkyTowerChar:DoHideBubble()
    if XTool.UObjIsNil(self._GameObject) then
        return
    end
    
    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_HIDE_3D_DIALOG, self:GetBubbleKey())
end

--获取随机聊天气泡
function XSkyTowerChar:GetRandomBubbleText()
    XLog.Error("子类调用，但未实现该方法")
    return "Error"
end

--通过下标获取冒泡
function XSkyTowerChar:GetBubbleText(index)
    XLog.Error("子类调用，但未实现该方法")
    return "Error"
end

--获取气泡Id
function XSkyTowerChar:GetBubbleKey()
    return self:GetUid()
end

--随机寻路
function XSkyTowerChar:DoFindRandomPoint()
    local point = self:GetRandomPoint()
    self._Agent:SetVarDicByKey("TargetPosition", point)
end

--随机点位方法
function XSkyTowerChar:GetRandomPoint()
    XLog.Error("子类调用，但未实现该方法")
    return CS.UnityEngine.Vector3.zero
end

function XSkyTowerChar:DoStopMove()
    if not self:Exist() then
        return
    end
    if not self._MoveAgent then
        return
    end
    
    self._MoveAgent:Stop()
end

function XSkyTowerChar:GetId()
    return self._Id
end

--加载特效
function XSkyTowerChar:DoLoadEffect(effectId, x, y, z)
    if XTool.UObjIsNil(self._GameObject) then
        return
    end
    local path = self._Model:GetEffectUrl(effectId)
    if string.IsNilOrEmpty(path) then
        return
    end
    if self._EffectPath == path and not XTool.UObjIsNil(self._Effect) then
        self._Effect:SetActiveEx(true)
        self._EffectTransform:SetLocalPosition(x, y, z)
        return
    end

    if not XTool.UObjIsNil(self._EffectLoader)
            and XTool.UObjIsNil(self._EffectLoader.PrefabGameObject) then
        self:DoDestroyEffect()
    end
    if XTool.UObjIsNil(self._EffectLoader) then
        -- 直接使用新组件，避免同帧 GetComponent 取回待销毁的旧 loader
        self._EffectLoader = self._GameObject:AddComponent(typeof(CS.XUiLoadPrefab))
    end
    -- 由 Lua 主动加载，避免克隆组件的 Start 再次增加资源引用
    self._EffectLoader.enabled = false
    ---@type UnityEngine.GameObject
    local effect = self._EffectLoader:LoadPrefab(path)
    if XTool.UObjIsNil(effect) then
        self:DoDestroyEffect()
        return
    end

    self._Effect = effect
    self._EffectPath = path
    ---@type UnityEngine.Transform
    self._EffectTransform = effect.transform
    self._Effect:SetActiveEx(true)
    self._EffectTransform:SetLocalPosition(x, y, z)
end

--隐藏特效
function XSkyTowerChar:DoHideEffect()
    if XTool.UObjIsNil(self._GameObject) 
            or XTool.UObjIsNil(self._Effect) then
        return
    end
    self._Effect:SetActiveEx(false)
end

--销毁
function XSkyTowerChar:DoDestroyEffect()
    local effect = self._Effect
    local loader = self._EffectLoader
    self._Effect = nil
    self._EffectPath = nil
    self._EffectTransform = nil
    self._EffectLoader = nil
    if not XTool.UObjIsNil(effect) then
        effect:SetActiveEx(false)
        XUiHelper.Destroy(effect)
    end
    if not XTool.UObjIsNil(loader) then
        -- 重建组件以重置私有路径缓存，OnDestroy 负责释放资源引用
        loader.enabled = false
        XUiHelper.Destroy(loader)
    end
end

--是否在工作
function XSkyTowerChar:DoIsWorking()
    return false
end

function XSkyTowerChar:DoCheckInt(intValue)
    return false
end

function XSkyTowerChar:DoLoadComplete()
    self:OnLoadBehaviourComplete()
end

--加载行为完成
function XSkyTowerChar:OnLoadBehaviourComplete()
    self._IsDoLoadBehaviour = true
end

-- 添加移动控件
---@param onlyIfExists boolean 为true时只初始化已有组件，不给静态角色额外添加移动组件
function XSkyTowerChar:TryAddNavMeshAgent(onlyIfExists)
    if XTool.UObjIsNil(self._GameObject) then
        return
    end
    local agent = self._GameObject:GetComponent(typeof(CS.XMoveAgent))
    if not agent then
        if onlyIfExists then
            return
        end
        agent = CS.XNavMeshUtility.AddMoveAgent(self._GameObject)
        agent.Radius = 0.35
        agent.CeilSize = 0.3
        agent.Speed = self._MoveSpeed
    end
    --通天塔所有角色都允许相互穿过，新建和预制体自带的组件保持一致。
    agent.IsObstacle = false
    agent.IsIgnoreCollide = true
    --只在通天塔设置楼层隔离，预制体已有移动组件时也要更新。
    local floorHeight = XMVCA.XSkyTower:GetFloorTotalHeight()
    agent.MovementGroup = self:GetRoom():GetTransform()
    --采样距离小于半层高；只容忍本层地板附近的烘焙高度误差。
    agent.NavMeshSampleDistance = math.min(1, floorHeight * 0.45)
    agent.MaxGroundHeightDifference = math.min(0.5, floorHeight * 0.25)
    self._MoveAgent = agent
end

---获取对象所在楼层
function XSkyTowerChar:GetFloorId()
    return self._FloorId or 0
end

function XSkyTowerChar:GetRoom()
    local floorId = self:GetFloorId()
    return self._OwnControl:GetRoom(floorId)
end

return XSkyTowerChar