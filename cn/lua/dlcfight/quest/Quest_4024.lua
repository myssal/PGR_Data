local QuestBase = require("Common/XQuestBase")
---@class XQuestScript4024 : XQuestBase
local XQuestScript4024 = XDlcScriptManager.RegQuestScript(4024, "XQuestScript4024", QuestBase)

---@param proxy XDlcCSharpFuncs
function XQuestScript4024:Ctor(proxy)
end

function XQuestScript4024:Init()

end

function XQuestScript4024:Terminate()
end

---@class Quest4024Objective
local ObjectiveBase = XClass(nil, "Quest4024Objective")

---@param quest XQuestScript4024
function ObjectiveBase:Ctor(quest)
    self.quest = quest
end

local emptyVector3 = { x = 0, y = 0, z = 0 }

local ObjectiveDefines = {}

--01.到达指定地点查看阿呆蛙
---@class QuestObjective40240101 : Quest4024Objective
ObjectiveDefines.Obj40240101 = {
    Id = 40240101,
    Type = EQuestObjectiveType.ReachTargetPosition,
    Args = {
        LevelId = 4024,
        TracePosArgs = {
            {
                Position = { x = 117.2, y = 143.74, z = 106.48 },                 -- 目标位置（初始为空，后续需要赋值）
                DisplayOffset = { x = 0, y = 0.5, z = 0 }, -- 显示偏移量
                ShowEffect = false,                      -- 是否显示特效
                ForceMapPinActive = false,               -- 是否强制激活地图标记
            },                                           -- 这里加上逗号，方便后续扩展
        },
        TargetPosition = { x = 117.2, y = 143.74, z = 106.48 },                   -- 后续替换为摆放点坐标
        ReachDistance = 5,                             -- 到达锚点1.5米范围内
    },
    ---@param obj QuestObjective40240101
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40240101
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

--02.播放B1级动画：阿呆蛙出场
---@class QuestObjective40240102 : Quest4024Objective
ObjectiveDefines.Obj40240102 = {
    Id = 40240102,
    Type = EQuestObjectiveType.DramaPlayFinish,
    Args = {
        LevelId = 4024,
        DramaName = "Drama_1001_024",
    },
    ---@param obj QuestObjective40240102
    ---@param proxy XDlcCSharpFuncs
    EnterFunc = function(obj, proxy)
        proxy:FinishQuestObjectiveScriptEnter()
    end,
    ---@param obj QuestObjective40240102
    ---@param proxy XDlcCSharpFuncs
    HandleEventFunc = function(obj, proxy, eventType, eventArgs)
    end,
    ---@param obj QuestObjective40240102
    ---@param proxy XDlcCSharpFuncs
    ExitFunc = function(obj, proxy)
        proxy:FinishInstLevel() --标记当前副本关卡完成
        proxy:RequestLeaveInstanceLevel(false)
        proxy:FinishQuestObjectiveScriptExit()
    end,
}

local StepDefines = {}

StepDefines.Step402401 = {
    Id = 402401,
    ExecMode = EQuestStepExecMode.Serial,
    NeedCompleteCount = 1,
}

QuestBase.InitSteps(StepDefines)
QuestBase.InitQuestObjectives(ObjectiveBase, ObjectiveDefines)