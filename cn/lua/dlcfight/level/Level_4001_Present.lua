local XLevel4001Present = XDlcScriptManager.RegLevelPresentScript(4001)

---@param proxy XDlcCSharpFuncs
function XLevel4001Present:Ctor(proxy) --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy

    self._assistMachineId = 6030               --辅助机npc单位表Id

    self._streetMall2F_ElevatorCallerPlaceId = 100066
    self._streetMall3F_ElevatorCallerPlaceId = 100067
    self._streetMall1F_ElevatorCallerPlaceId = 100068
    self._streetMall4F_ElevatorCallerPlaceId = 100123
    self._streetMall2F_ElevatorPortSpotId = 100002
    self._streetMall3F_ElevatorPortSpotId = 100001
    self._streetMall1F_ElevatorPortSpotId = 100014
    self._streetMall4F_ElevatorPortSpotId = 100015
    self._streetCE_ElevatorPortSpotId = 100010
    self._CoffeeNpcUUID = 100093
    self._WeComeBackID = 100010

    self._deathZoneId = 100009                 --死区的triggerID
    self._reviveRotation = { 0, 0, 0 }         --复活时的旋转
    self._transportNPCPlazaId = 100020
    self._cafeObj = 100076
    -- 隐藏跳跳乐相关
    self._jumperTouchObj = 100043
    self._jumperLightObj = {100044,100045,100046}
end

function XLevel4001Present:Init() --初始化逻辑
    self._streetMall2F_ElevatorCallerUUID = self._proxy:GetSceneObjectUUID(self._streetMall2F_ElevatorCallerPlaceId)
    self._streetMall3F_ElevatorCallerUUID = self._proxy:GetSceneObjectUUID(self._streetMall3F_ElevatorCallerPlaceId)
    self._streetMall1F_ElevatorCallerUUID = self._proxy:GetSceneObjectUUID(self._streetMall1F_ElevatorCallerPlaceId)
    self._streetMall4F_ElevatorCallerUUID = self._proxy:GetSceneObjectUUID(self._streetMall4F_ElevatorCallerPlaceId)
    self._streetMall3F_ElevatorPortPos = self._proxy:GetSpot(self._streetMall3F_ElevatorPortSpotId)
    self._streetMall2F_ElevatorPortPos = self._proxy:GetSpot(self._streetMall2F_ElevatorPortSpotId)
    self._streetMall1F_ElevatorPortPos = self._proxy:GetSpot(self._streetMall1F_ElevatorPortSpotId)
    self._streetMall4F_ElevatorPortPos = self._proxy:GetSpot(self._streetMall4F_ElevatorPortSpotId)
    self._tempLevelSwitcherBackUUID = self._proxy:GetSceneObjectUUID(self._WeComeBackID)
    self._questNpcUUID = self._proxy:GetNpcUUID(self._CoffeeNpcUUID)
    self._PlazaLevelSwitchUUID = self._proxy:GetNpcUUID(self._transportNPCPlazaId)         --传送去商业街玩法
    self._storyInstLevelEntranceNpcPID = 100234            --测试版剧情副本入口NPC
    self._storyInstLevelEntranceNpc2PID = 600003
    self._storyInstLevelEntranceNpc3PID = 600021
    self._storyInstLevelEntranceNpc4PID = 600022
    self._storyInstLevelEntranceNpc5PID = 500026           --支线D跳跳乐备用入口
    self._cafeObjSwitchUUID = self._proxy:GetSceneObjectUUID(self._cafeObj)                        --切换去咖啡厅玩法
    self._lxyObjSwitchUUID = 900001                   --进入剧情副本入口1
    self._lxyObjSwitch1UUID = 900002                   --进入剧情副本入口1
    self._revivePoint = self._proxy:GetSpot(100003)                                --复活点坐标
    self._proxy:RegisterEvent(EWorldEvent.NpcInteractStart)
    self._proxy:RegisterEvent(EWorldEvent.ActorTrigger)
    self._proxy:RegisterEvent(EWorldEvent.DramaFinish)
end

---@param dt number @ delta time
function XLevel4001Present:Update(dt) --每帧更新逻辑

end

---@param eventType number
---@param eventArgs userdata
function XLevel4001Present:HandleEvent(eventType, eventArgs) --事件响应逻辑
    if eventType == EWorldEvent.NpcInteractStart then
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) then --是玩家发起的交互
            if eventArgs.TargetId == self._streetMall2F_ElevatorCallerUUID then
                --传送到露天广场
                self._proxy:TeleportWithBlackUi(eventArgs.LauncherId, self._streetMall3F_ElevatorPortPos)
            elseif eventArgs.TargetId == self._streetMall3F_ElevatorCallerUUID then
                --传送到时序广场
                self._proxy:TeleportWithBlackUi(eventArgs.LauncherId, self._streetMall2F_ElevatorPortPos)
            elseif eventArgs.TargetId == self._streetMall1F_ElevatorCallerUUID then
                --从商业街传送回时序广场
                self._proxy:TeleportWithBlackUi(eventArgs.LauncherId, self._streetMall1F_ElevatorPortPos)
            elseif eventArgs.TargetId == self._streetMall4F_ElevatorCallerUUID then
                --从时序广场传送到商业街
                self._proxy:TeleportWithBlackUi(eventArgs.LauncherId, self._streetMall4F_ElevatorPortPos)
            elseif eventArgs.TargetId == self._tempLevelSwitcherBackUUID then
                local pos = { x = 18.43, y = 1.14, z = 17.55 }
                self._proxy:SwitchLevel(4003, pos)
            --elseif eventArgs.TargetId == self._cafeObjSwitchUUID then
            --    self._proxy:OpenGameplayMainEntrance(1, { 555.03, 169.44, 1174.21 })
            elseif eventArgs.TargetPlaceId == self._storyInstLevelEntranceNpc2PID then
                local pos = { x = 76.383, y = 7.865, z = 55.2803 }
                self._proxy:RequestEnterInstLevel(4013, pos)
            elseif eventArgs.TargetPlaceId == self._lxyObjSwitchUUID then
                local pos = { x = 20.9339, y = 56.59, z = 40.44 }
                self._proxy:RequestEnterInstLevel(4011, pos)
            elseif eventArgs.TargetPlaceId == self._lxyObjSwitch1UUID then
                local pos = { x = 20.9339, y = 56.59, z = 40.44 }
                self._proxy:RequestEnterInstLevel(4023, pos)
            elseif eventArgs.TargetPlaceId == self._storyInstLevelEntranceNpc3PID then
                local pos = { x = 605.746094, y = 189.338181, z = 1146.83838 }
                self._proxy:RequestEnterInstLevel(4021, pos)
            elseif eventArgs.TargetPlaceId == self._storyInstLevelEntranceNpc4PID then
                local pos = { x = 605.746094, y = 189.338181, z = 1146.83838 }
                self._proxy:RequestEnterInstLevel(4022, pos)
            elseif eventArgs.TargetPlaceId == self._storyInstLevelEntranceNpc5PID then
                local pos = { x = 243.7, y = 36.6, z = 322.7 }
                self._proxy:RequestEnterInstLevel(4025, pos)
            elseif eventArgs.TargetPlaceId == self._jumperTouchObj then                     --随机生成场景物件特殊物件生成跳跳乐
                for _, HideObj in pairs(self._jumperLightObj ) do                       --隐藏所有场景物件并随机加载一个
                    self._proxy:UnloadSceneObject(HideObj)
                end
                self._proxy:LoadSceneObject(self._jumperLightObj[self._proxy:Random(1, #self._jumperLightObj)])
            end
        end
    elseif eventType == EWorldEvent.ActorTrigger then
        --XLog.Error("有npc触发器触发")
        if (eventArgs.HostSceneObjectPlaceId == self._deathZoneId and eventArgs.TriggerState == ETriggerState.Enter) then
            self._proxy:SetNpcPosAndRot(eventArgs.EnteredActorUUID, self._revivePoint,
                self._reviveRotation, true)
        end
    elseif eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "Drama_5001_001" then                               --跳跳乐对话跳转
            local dramaOptions = self._proxy:GetDramaDialogFirstDecisionId(1)
            if dramaOptions == 1001 then --选择了对话选项1
                self._proxy:RequestEnterInstLevel(4008, { x = 243.7, y = 37, z = 322.7 })
            elseif dramaOptions == 1002 then --选择了对话选项2
                self._proxy:RequestEnterInstLevel(4009,  { x = 252.58, y = 38.92, z = 241.96 })
            elseif dramaOptions == 1003 then --选择了对话选项3
                self._proxy:RequestEnterInstLevel(4010,{ x = 250.82, y = 55.46, z = 270.79 })
            end
        elseif eventArgs.DramaName == "Drama_5002_001" then                               --跳跳乐对话跳转
            local dramaOptions = self._proxy:GetDramaDialogFirstDecisionId(2)
            if dramaOptions == 1001 then                --选择了对话选项1
                self._proxy:RequestEnterInstLevel(4018, { x = 266.72, y = 52.77, z = 327.83 })
            elseif dramaOptions == 1002 then            --选择了对话选项2
                self._proxy:RequestEnterInstLevel(4019, { x = 378.57, y = 54.64, z = 290.85 })
            elseif dramaOptions == 1003 then            --选择了对话选项3
                self._proxy:RequestEnterInstLevel(4020, { x = 271, y = 54.11, z = 237.4 })
            end
        end
    end

end

function XLevel4001Present:Terminate() --脚本结束逻辑（脚本被卸载、Npc死亡、关卡结束......）

end

return XLevel4001Present