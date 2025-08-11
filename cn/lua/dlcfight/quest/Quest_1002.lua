local QuestBase = require("Common/XQuestBase")
---@class XQuestScript1002 : XQuestBase
local XQuestScript1002 = XDlcScriptManager.RegQuestScript(1002, "XQuestScript1002", QuestBase)

---@param proxy XDlcCSharpFuncs
function XQuestScript1002:Ctor(proxy)
    --self._id = 1002
    --self._dramaRot = { x = 0, y = 0, z = 0 }
    --self._playerNpcUUID = 0
    --self._item1PlaceId = 100001
    --self._item1UUID = 0
    --self._questNpc1PlaceId = 100016
    --self._questNpc2PlaceId = 100011
    --self._sceneObject_4003_3_PlaceId = 100010
    --self._questNpc4PlaceId = 100002
    --self._actor4003_1 = 3
    --self._actor4003_2 = 4
    --self._actor4003_3 = 2
    --self._tempLevelSwitcherBackUUID = 0 --初始化为0，大于0时才是有效的UUID
    --self._tempLevelSwitcherBack1UUID = 0 --初始化为0，大于0时才是有效的UUID
    --self._questLevelId = 4001
    --self._questLevel2Id = 4003
    --self._emptyVector3 = { x = 0, y = 0, z = 0 }
end

function XQuestScript1002:Init()
    --self._proxy:RegisterEvent(EWorldEvent.DramaFinish)
    --self._proxy:RegisterEvent(EWorldEvent.ActorTrigger)
    --self._proxy:RegisterEvent(EWorldEvent.NpcInteractStart)
    --self._proxy:RegisterEvent(EWorldEvent.ShortMessageReadComplete)
    --self._proxy:RegisterEvent(EWorldEvent.EnterLevel)
    --self._proxy:RegisterEvent(EWorldEvent.LeaveLevel)
    --self._playerNpcUUID = self._proxy:GetLocalPlayerNpcId()
    --XLog.Debug("quest 1002 init, player npc uuid:" .. tostring(self._playerNpcUUID))
    --self._questNpc4UUID = self._proxy:GetNpcUUID(self._questNpc4PlaceId)
    --self._sceneObject_4003_3_UUID = self._proxy:GetSceneObjectUUID(self._actor4003_3)
end

function XQuestScript1002:Terminate()
end

--================================================
--DLC-任务目标类型：https://kurogame.feishu.cn/docx/TR7AdBehwoWUrrxpV0cc0Wp1nxf

---@class Quest1002Objective
local Quest1002Objective = XClass(nil, "Quest1002Objective")

---@param quest XQuestScript1002
function Quest1002Objective:Ctor(quest)
    self.quest = quest
end

local emptyVector3 = { x = 0, y = 0, z = 0 }

local ObjectiveDefines = {}
--不用数字key，是为了能在IDEA的structure视图中识别这里的table结构，方便快速跳转

--阅读露西亚发来的短信
---@class QuestObjective100211 : Quest1002Objective
ObjectiveDefines.Obj100211 = {
    Id = 100211,
    Type = EQuestObjectiveType.ReadShortMessageComplete,
    Args = {
        LevelId = 4001,
        ShortMessageId = 1002,
        AutoSend = true, --enter时，自动发送短信
    },
    ---@param obj QuestObjective100211
    InitFunc = function(obj)
        obj.dramaName = "Drama_1001_003"
    end,
    ---@param obj QuestObjective100211
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:RegisterEvent(EWorldEvent.QuestPopupClosed)
        proxy:RegisterEvent(EWorldEvent.DramaFinish)
        --用于测试固定保存模式的还原效果--
        local intVar = proxy:TryGetVarInt("test1")
        if intVar then
            XLog.Debug("int var:", intVar)
        end
        proxy:SetVarInt("test1", 931206)
        -----------------------------
    end,
    ---@param obj QuestObjective100211
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
        if eventType == EWorldEvent.QuestPopupClosed then
            if eventArgs.QuestId == 1002 and eventArgs.PopupType == EQuestPopupType.Undertake then
                --这里的播剧情，也可以单独做一个objective，放到前面
                proxy:PlayDrama(1002, nil, obj.dramaName, emptyVector3, emptyVector3)
                XLog.Debug("任务目标100211，播放剧情")
            end
        elseif eventType == EWorldEvent.DramaFinish then
            if eventArgs.DramaName == obj.dramaName then--播放完小露邀约指挥官短信对话
                proxy:FinishQuestObjectiveScriptEnter(100211)
                XLog.Debug("任务目标100211，结束enter")
            end
        end
    end,
    ---@param obj QuestObjective100211
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnregisterEvent(EWorldEvent.QuestPopupClosed)
        proxy:UnregisterEvent(EWorldEvent.DramaFinish)
        proxy:FinishQuestObjectiveScriptExit(100211)
    end,
}

--回忆与露西亚的经历
---@class QuestObjective100212 : Quest1002Objective
ObjectiveDefines.Obj100212 = {
    Id = 100212,
    --Type = EQuestObjectiveType.DramaPlayFinish,
    Type = EQuestObjectiveType.InstanceComplete,
    Args = {
        LevelId = 4001,
        --DramaName = "CE_Dialog01",
        InstLevelId = 4011,
        Count = 1,
    },
}

--回宿舍
---@class QuestObjective100213 : Quest1002Objective
ObjectiveDefines.Obj100213 = {
    Id = 100213,
    Type = EQuestObjectiveType.EnterLevel,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 100010, --进宿舍的交互传送物件
                DisplayOffset = {x = 0, y = 1.3, z = 0},
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetLevelId = 4003,
    },
}

--从吧台上拿走兔子点心
---@class QuestObjective100214 : Quest1002Objective
ObjectiveDefines.Obj100214 = {
    Id = 100214,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4003,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 100001, --进宿舍的交互传送物件
                DisplayOffset = { x = 0, y = 0.5, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [100001] = 0,--兔子点心物件
            },
        },
    },
    ---@param obj QuestObjective100214
    InitFunc = function(obj)
        obj.soRabbitCakePID = 100001
    end,
    ---@param obj QuestObjective100214
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:LoadSceneObject(obj.soRabbitCakePID)
        --原策划逻辑，这里还会播个剧情CE_Dialog02，但没有监听剧情完成事件，暂时认定为不规范写法，
        --应当用单独的任务目标实现，放在此任务目标前面
        proxy:FinishQuestObjectiveScriptEnter(100214)
    end,
    ---@param obj QuestObjective100214
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:UnloadSceneObject(obj.soRabbitCakePID)
        local uuid = proxy:GetSceneObjectUUID(obj.soRabbitCakePID)
        proxy:DestroySceneObject(uuid)
        proxy:FinishQuestObjectiveScriptExit(100214)
        --原策划逻辑，这里还会播个剧情CE_Dialog03，但没有监听剧情完成事件，暂时认定为不规范写法，
        --应当用单独的任务目标实现，放在此任务目标后面
    end,
}

--阅读休闲桌上的新闻
---@class QuestObjective100215 : Quest1002Objective
ObjectiveDefines.Obj100215 = {
    Id = 100215,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4003,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 3, --休闲桌上的新闻
                DisplayOffset = emptyVector3,
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [3] = 0,--休闲桌上的新闻
            },
        },
    },

    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:SetVarInt("test1", 578076)
        proxy:FinishQuestObjectiveScriptEnter()
    end
}

--阅读吧台上的新闻周刊
---@class QuestObjective100216 : Quest1002Objective
ObjectiveDefines.Obj100216 = {
    Id = 100216,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4003,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 4, --吧台上的新闻周刊
                DisplayOffset = emptyVector3,
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.SceneObject] = {
                [4] = 0,--吧台上的新闻周刊
            },
        },
    },
}

--前往时序广场
---@class QuestObjective100217 : Quest1002Objective
ObjectiveDefines.Obj100217 = {
    Id = 100217,
    Type = EQuestObjectiveType.EnterLevel,
    Args = {
        LevelId = 4003,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.SceneObject,
                PlaceId = 2, --离开宿舍的传送交互台
                DisplayOffset = { x = 0, y = 1.3, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetLevelId = 4001,
    },
}

--前往咖啡厅与引导员交谈
--这里也是，按新架构，应当拆分成两个objective来做，一个交互完成，一个剧情播放完成
---@class QuestObjective100218 : Quest1002Objective
ObjectiveDefines.Obj100218 = {
    Id = 100218,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 100016, --咖啡厅引导员
                DisplayOffset = { x = 0, y = 2.2, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [100016] = 0,--咖啡厅引导员
            },
        },
    },
    ---@param obj QuestObjective100218
    InitFunc = function(obj)
        obj.npcCafeGuiderPID = 100016
        obj.dramaName = "CE_Dialog04"
    end,
    ---@param obj QuestObjective100218
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        --proxy:SetActorDefaultInteractReactionEnable(obj.npcCafeGuiderPID, false)
        proxy:FinishQuestObjectiveScriptEnter(100218)
    end,
    ---@param obj QuestObjective100218
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
        if eventType == EWorldEvent.DramaFinish then
            if eventArgs.DramaName == obj.dramaName then
                --这里立即注销事件可能会报错
                proxy:AddTimerTask(0.1, function()
                    proxy:UnregisterEvent(EWorldEvent.DramaFinish)
                end)
                proxy:FinishQuestObjectiveScriptExit(100218)
            end
        end
    end,
    ---@param obj QuestObjective100218
    ExitFunc = function(obj, proxy)
        proxy:RegisterEvent(EWorldEvent.DramaFinish)
        --proxy:SetActorDefaultInteractReactionEnable(obj.npcCafeGuiderPID, true)
        proxy:PlayDrama(1002, {obj.npcCafeGuiderPID}, obj.dramaName, emptyVector3, emptyVector3)
    end,
}

--在咖啡厅寻找露西亚
---@class QuestObjective100219 : Quest1002Objective
ObjectiveDefines.Obj100219 = {
    Id = 100219,
    Type = EQuestObjectiveType.InteractComplete,
    Args = {
        LevelId = 4001,
        TraceActorArgs = {
            {
                TargetType = ETargetActorType.Npc,
                PlaceId = 100011, --咖啡厅里的露西亚
                DisplayOffset = { x = 0, y = 2.2, z = 0 },
                ShowEffect = false,
                ForceMapPinActive = false,
            },
        },
        TargetArgs = {
            [ETargetActorType.Npc] = {
                [100011] = 0,--咖啡厅里的露西亚
            },
        },
    },
    ---@param obj QuestObjective100219
    InitFunc = function(obj)
        obj.npcLuciaPID = 100011
        obj.dramaName = "StoryDrama05"
    end,
    ---@param obj QuestObjective100219
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        --proxy:SetActorDefaultInteractReactionEnable(obj.npcLuciaPID, false)
        proxy:FinishQuestObjectiveScriptEnter(100219)
    end,
    ---@param obj QuestObjective100218
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
        if eventType == EWorldEvent.DramaFinish then
            if eventArgs.DramaName == obj.dramaName then
                --这里立即注销事件可能会报错
                proxy:AddTimerTask(0.1, function()
                    proxy:UnregisterEvent(EWorldEvent.DramaFinish)
                end)
                proxy:FinishQuestObjectiveScriptExit(100219)
            end
        end
    end,
    ---@param obj QuestObjective100219
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:RegisterEvent(EWorldEvent.DramaFinish)
        --proxy:SetActorDefaultInteractReactionEnable(obj.npcLuciaPID, true)
        proxy:PlayDrama(1002, {obj.npcLuciaPID}, obj.dramaName, emptyVector3, emptyVector3)
    end,
}


local StepDefines = {}

StepDefines.Step10021 = {
    Id = 10021,
    ExecMode = EQuestStepExecMode.Serial,
}

StepDefines.Step10022 = {
    Id = 10022,
    ExecMode = EQuestStepExecMode.Serial,
    IsFixedSaveBegin = true,
    IsFixedSaveEnd = true,
}

QuestBase.InitSteps(StepDefines)
QuestBase.InitQuestObjectives(Quest1002Objective, ObjectiveDefines)


--===================[[ 任务步骤]]-===================

--========================[[ 步骤1]]=============================>>
---@param self XQuestScript1002
XQuestScript1002.StepEnterFuncs[10021] = function(self)
    self._proxy:PushQuestStepProcess(self._id, 10021, 100211, 1)--推进任务1002中的步骤1中的进度1
end

---@param self XQuestScript1002
XQuestScript1002.StepHandleEventFuncs[10021] = function(self, eventType, eventArgs)
end
---@param self XQuestScript1002
XQuestScript1002.StepExitFuncs[10021] = function(self)
end
--==============================================================<<

--========================[[ 步骤2]]=============================<< 
---@param self XQuestScript1002
XQuestScript1002.StepEnterFuncs[10022] = function(self)
    self._proxy:RegisterEvent(EWorldEvent.QuestPopupClosed)
end
---@param self XQuestScript1002
XQuestScript1002.StepHandleEventFuncs[10022] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.QuestPopupClosed then
        if eventArgs.QuestId == self._id and eventArgs.PopupType == EQuestPopupType.Undertake then
            self._proxy:PlayDrama(self._id, nil, "Drama_1001_003", self._emptyVector3, self._dramaRot)
        end
    elseif eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "Drama_1001_003" then--播放完小露邀约指挥官短信对话
            self._proxy:SendChatMessage(1002)
            XLog.Debug("任务1002，发送短信1002")
        end
    elseif eventType == EWorldEvent.ShortMessageReadComplete then
        if eventArgs.MessageId == 1002 then --播放完小露邀约指挥官短信对话
            XLog.Debug("任务1002，短信1002阅读完毕")
            self._proxy:PushQuestStepProcess(self._id, 10022, 100221, 1)--推进任务1002中的步骤1中的进度1
        end
    end
end
---@param self XQuestScript1002
XQuestScript1002.StepExitFuncs[10022] = function(self)
    self._proxy:UnregisterEvent(EWorldEvent.QuestPopupClosed)
end
--==============================================================<<

--========================[[ 步骤3]]=============================<<
---@param self XQuestScript1002
XQuestScript1002.StepEnterFuncs[10023] = function(self)
    self._step1Item2NavPointId = self._proxy:AddQuestNavPointForLevelSceneObject(self._questLevelId, self._id, 1, self._sceneObject_4003_3_PlaceId, { x = 0,y = 1.3,z = 0 }, false, false)
    self._proxy:PlayDrama(self._id, nil,"CE_Dialog01", self._emptyVector3, self._dramaRot)
end

---@param self XQuestScript1002
XQuestScript1002.StepHandleEventFuncs[10023] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.EnterLevel then
        XLog.Error("quest step 10023 handle event EnterLevel")
        --有关卡切换
        if eventArgs.LevelId == 4003 then --切换到宿舍关卡
            self._proxy:PushQuestStepProcess(self._id, 10023, 100231, 1)--推进任务1002中的步骤2中的进度1
            self._proxy:RemoveQuestNavPoint(self._id, self._step1Item2NavPointId)
            XLog.Error("quest push 4003 100231")
        end
    end
end
---@param self XQuestScript1002
XQuestScript1002.StepExitFuncs[10023] = function(self)
end

--==============================================================>>
--========================[[ 步骤4]]=============================<<
---@param self XQuestScript1002
XQuestScript1002.StepEnterFuncs[10024] = function(self)  
    self._proxy:LoadSceneObject(self._item1PlaceId)--加载兔子物件
    self._proxy:SetActorInQuest(self._id, self._item1UUID, true)
    self._step2Item2NavPointId = self._proxy:AddQuestNavPointForLevelSceneObject(self._questLevel2Id, self._id, 1, self._item1PlaceId, { x = 0, y = 0.5, z = 0 }, false, false)
    self._proxy:PlayDrama(self._id, nil,"CE_Dialog02", self._emptyVector3, self._dramaRot)
end

---@param self XQuestScript1002
XQuestScript1002.StepHandleEventFuncs[10024] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart then
        --[[
            放在这里获取uuid，因为正常来说，第一次做该任务时，
            不可能在enter里load该物件后立刻就能拿到uuid，因为load创建行为是在客户端进行，有物理网络延迟。
        ]]
        self._item1UUID = self._proxy:GetSceneObjectUUID(self._item1PlaceId)--获取兔子物件UUID
        XLog.Debug("任务1002, 10024, 兔子点心UUID：" .. tostring(self._item1UUID))
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._item1UUID and eventArgs.Type == 1 then
            self._proxy:PushQuestStepProcess(self._id, 10024, 100241, 1)--推进任务1002中的步骤3中的进度1
            self._proxy:RemoveQuestNavPoint(self._id, self._step2Item2NavPointId)
        end
    end
end
---@param self XQuestScript1002
XQuestScript1002.StepExitFuncs[10024] = function(self)
    self._proxy:DestroySceneObject(self._item1UUID)
    self._proxy:PlayDrama(self._id, nil,"CE_Dialog03", self._emptyVector3, self._dramaRot)
end

--==============================================================>>
--========================[[ 步骤5]]=============================<<
---@param self XQuestScript1002
XQuestScript1002.StepEnterFuncs[10025] = function(self)
    self._proxy:SetActorInQuest(self._id, self._tempLevelSwitcherBackUUID, true)
    if self._proxy:GetCurrentLevelId() == 4003 then 
        self._tempLevelSwitcherBackUUID = self._proxy:GetSceneObjectUUID(self._actor4003_1) 
        self._step3ItemNavPointId = self._proxy:AddQuestNavPointForLevelSceneObject(self._questLevel2Id, self._id, 1, self._actor4003_1, self._emptyVector3, false, false)       
    end
end
---@param self XQuestScript1002
XQuestScript1002.StepHandleEventFuncs[10025] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart then
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._tempLevelSwitcherBackUUID and eventArgs.Type == 1 then
            self._proxy:RemoveQuestNavPoint(self._id, self._step3ItemNavPointId)
            self._proxy:PushQuestStepProcess(self._id, 10025, 100251, 1)--推进任务1002中的步骤3中的进度1
        end
    elseif eventType == EWorldEvent.EnterLevel then
        if eventArgs.IsPlayer and eventArgs.LevelId == 4003 and self._tempLevelSwitcherBackUUID <= 0 then 
            if not self._proxy:CheckQuestStepProcessIsFinish(self._id, 10025, 100251) then
                self._tempLevelSwitcherBackUUID = self._proxy:GetSceneObjectUUID(self._actor4003_1)
            end
        end
    elseif eventType == EWorldEvent.LeaveLevel then
        if eventArgs.IsPlayer and eventArgs.LevelId == 4003 and self._tempLevelSwitcherBackUUID <= 0 then 
            if not self._proxy:CheckQuestStepProcessIsFinish(self._id, 10025, 100251) then
                self._tempLevelSwitcherBackUUID = 0
            end
        end
    end
end
---@param self XQuestScript1002
XQuestScript1002.StepExitFuncs[10025] = function(self)
end
--==============================================================>>
--========================[[ 步骤6]]=============================<<
---@param self XQuestScript1002
XQuestScript1002.StepEnterFuncs[10026] = function(self)
    self._proxy:SetActorInQuest(self._id, self._tempLevelSwitcherBack1UUID, true)
    if self._proxy:GetCurrentLevelId() == 4003 then 
        self._tempLevelSwitcherBack1UUID = self._proxy:GetSceneObjectUUID(self._actor4003_2) 
        self._step4ItemNavPointId = self._proxy:AddQuestNavPointForLevelSceneObject(self._questLevel2Id, self._id, 1, self._actor4003_2, self._emptyVector3, false, false)           
    end
end
---@param self XQuestScript1002
XQuestScript1002.StepHandleEventFuncs[10026] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart then
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._tempLevelSwitcherBack1UUID and eventArgs.Type == 1 then
            self._proxy:PushQuestStepProcess(self._id, 10026, 100261, 1)--推进任务1002中的步骤3中的进度1
            self._proxy:RemoveQuestNavPoint(self._id, self._step4ItemNavPointId)
        end
    elseif eventType == EWorldEvent.EnterLevel then
        if eventArgs.IsPlayer and eventArgs.LevelId == 4003 and self._tempLevelSwitcherBackUUID <= 0 then 
            if not self._proxy:CheckQuestStepProcessIsFinish(self._id, 10026, 100261) then
                self._tempLevelSwitcherBack1UUID = self._proxy:GetSceneObjectUUID(self._actor4003_2)
            end
        end
    elseif eventType == EWorldEvent.LeaveLevel then
        if eventArgs.IsPlayer and eventArgs.LevelId == 4003 and self._tempLevelSwitcherBackUUID <= 0 then 
            if not self._proxy:CheckQuestStepProcessIsFinish(self._id, 10026, 100261) then
                self._tempLevelSwitcherBack1UUID = 0
            end
        end
    end
end
---@param self XQuestScript1002
XQuestScript1002.StepExitFuncs[10026] = function(self)
end
--==============================================================>>
--========================[[ 步骤7]]=============================<<
---@param self XQuestScript1002
XQuestScript1002.StepEnterFuncs[10027] = function(self)  
    self._proxy:SetActorInQuest(self._id, self._sceneObject_4003_3_UUID, true)
    self._step5ItemNavPointId = self._proxy:AddQuestNavPointForLevelSceneObject(self._questLevel2Id, self._id, 1, self._actor4003_3, { x = 0, y = 1.3, z = 0 }, false, false)        
end

---@param self XQuestScript1002
XQuestScript1002.StepHandleEventFuncs[10027] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.LeaveLevel then
        XLog.Debug("quest step 10027 handle event LeaveLevel")
        --有关卡切换
        if eventArgs.LevelId == 4003 then --退出宿舍关卡
            self._proxy:PushQuestStepProcess(self._id, 10027, 100271, 1)--推进任务1002中的步骤4中的进度1
            self._proxy:RemoveQuestNavPoint(self._id, self._step5ItemNavPointId)
            XLog.Debug("quest push 4003 100271")
        end
    end
end
---@param self XQuestScript1002
XQuestScript1002.StepExitFuncs[10027] = function(self) 
end

--==============================================================>>
--========================[[ 步骤8]]=============================<<

---@param self XQuestScript1002
XQuestScript1002.StepEnterFuncs[10028] = function(self)
    self._questNpc1UUID = self._proxy:GetNpcUUID(self._questNpc1PlaceId)
    XLog.Debug("任务1002，10028，获取咖啡npc：".. tostring(self._questNpc1UUID) .. " 关卡：".. self._proxy:GetCurrentLevelId())
    self._proxy:SetActorInQuest(self._id, self._questNpc1UUID, true)
    self._step6ItemNavPointId = self._proxy:AddQuestNavPointForLevelNpc(self._questLevelId, self._id, 1, self._questNpc1PlaceId, { x = 0, y = 2.2, z = 0 }, false, false)        
end
---@param self XQuestScript1002
XQuestScript1002.StepHandleEventFuncs[10028] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart then
        XLog.Debug("任务1002，10028，Npc交互事件，target：" .. tostring(eventArgs.TargetId) .. "，cafeWaiter：" .. tostring(self._questNpc1UUID))
        if self._proxy:IsPlayerNpc(eventArgs.LauncherId) and eventArgs.TargetId == self._questNpc1UUID and eventArgs.Type == 1 then
            self._proxy:PlayDrama(self._id, { self._questNpc1UUID }, "CE_Dialog04", self._emptyVector3, self._dramaRot)--和咖啡厅引导员对话剧情
        end
    elseif eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "CE_Dialog04" then
            self._proxy:PushQuestStepProcess(self._id, 10028, 100281, 1)--推进任务1002中的步骤5中的进度1
            self._proxy:RemoveQuestNavPoint(self._id, self._step6ItemNavPointId)
        end
    end
end
---@param self XQuestScript1002
XQuestScript1002.StepExitFuncs[10028] = function(self)
end
--==============================================================>>
--========================[[ 步骤9]]=============================<<
---@param self XQuestScript1002
XQuestScript1002.StepEnterFuncs[10029] = function(self)
    self._questNpc2UUID = self._proxy:GetNpcUUID(self._questNpc2PlaceId)
    self._proxy:SetActorInQuest(self._id, self._questNpc2UUID, true)
    self._step7ItemNavPointId = self._proxy:AddQuestNavPointForLevelNpc(self._questLevelId, self._id, 1, self._questNpc2PlaceId, { x = 0, y = 1.5, z = 0 }, false, false)       
end
---@param self XQuestScript1002
XQuestScript1002.StepHandleEventFuncs[10029] = function(self, eventType, eventArgs)
    if eventType == EWorldEvent.NpcInteractStart then
        if XScriptTool.CheckNpcInteractStart(self._proxy, eventArgs, self._questNpc2UUID) then
            self._proxy:PlayDrama(self._id, nil, "StoryDrama05", self._emptyVector3, self._dramaRot)--和小露聊天对话剧情
        end
    elseif eventType == EWorldEvent.DramaFinish then
        if eventArgs.DramaName == "StoryDrama05" then
            self._proxy:PushQuestStepProcess(self._id, 10029, 100291, 1)--推进任务1002中的步骤5中的进度1
            self._proxy:RemoveQuestNavPoint(self._id, self._step7ItemNavPointId)
        end
    end
end
---@param self XQuestScript1002
XQuestScript1002.StepExitFuncs[10029] = function(self)
end
