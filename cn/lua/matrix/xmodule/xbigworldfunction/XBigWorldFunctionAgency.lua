---@class XBigWorldFunctionAgency : XAgency
---@field private _Model XBigWorldFunctionModel
---@field private FunctionId XBWFunctionId
local XBigWorldFunctionAgency = XClass(XAgency, "XBigWorldFunctionAgency")

local tableInsert = table.insert

local FunctionState = {
    --空状态
    None = 1,
    --繁忙
    Busy = 1 << 1,
    --冻结
    Freeze = 1 << 2,
}

local DlcEventId = XMVCA.XBigWorldService.DlcEventId

function XBigWorldFunctionAgency:OnInit()
    ---@type BigWorldFunctionType
    self.FunctionType = require("XModule/XBigWorldFunction/XFunction/XBWFunctionType")
    
    self.FunctionId = require("XModule/XBigWorldFunction/XFunction/XBWFunctionId")
    
    self._OpenHint = {}
    self._FunctionState = FunctionState.None
    --除了通知给战斗其他地方禁止使用
    self._NotifyFightFunction = {
        FunctionId = 0
    }
    --除了通知给战斗其他地方禁止使用
    self._ReturnFightFunction = {
        IsEnable = false
    }
end

function XBigWorldFunctionAgency:InitRpc()
    
end

function XBigWorldFunctionAgency:InitEvent()
    self:InitFunctionEvent()
end

function XBigWorldFunctionAgency:OnRelease()
    self:RemoveFunctionEvent()
end

function XBigWorldFunctionAgency:CheckFunctionShield(functionType, isTips)
    if functionType == self.FunctionType.None then
        return false
    end

    if self._Model:IsSetShield(functionType) then
        local shield = self._Model:CheckCurrentShield(functionType)
        if shield and isTips then
            self:SuggestFunctionShield()
        end
        
        return shield
    end

    local isShield = XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_CHECK_SYSTEM_FUNCTION_ENABLE, {
        FunctionType = functionType
    })

    if not isShield.IsEnable and isTips then
        self:SuggestFunctionShield()
    end
    self._Model:SetShieldState(functionType, not isShield.IsEnable)
    return not isShield.IsEnable
end

---@param functionType number
---@param controller XBWFunctionController
function XBigWorldFunctionAgency:RegisterFunctionController(functionType, controller)
    self._Model:RegisterFunctionController(functionType, controller)
end

function XBigWorldFunctionAgency:RegisterFunctionControllerByMethod(functionType, target, method)
    self._Model:RegisterFunctionControllerByMethod(functionType, target, method)
end

---@param functionType number
---@param controller XBWFunctionController
function XBigWorldFunctionAgency:RemoveFunctionController(functionType, controller)
    self._Model:RemoveFunctionController(functionType, controller)
end

function XBigWorldFunctionAgency:RemoveFunctionControllerByMethod(functionType, target, method)
    self._Model:RemoveFunctionControllerByMethod(functionType, target, method)
end

function XBigWorldFunctionAgency:SuggestFunctionShield()
    XMVCA.XBigWorldUI:TipText("FunctionShieldTips")
end

function XBigWorldFunctionAgency:OnFunctionsShieldChanged(data)
    local shieldTypes = data.DisabledFunctionTypes

    self._Model:ClearCurrentShield()
    if not XTool.IsTableEmpty(shieldTypes) then
        for functionType, _ in pairs(shieldTypes) do
            self._Model:AddCurrentShield(functionType)
        end
    end
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_FUNCTION_SHIELD_CHANEG)
end

function XBigWorldFunctionAgency:OnControlFunctionShield(data)
    if data.FunctionType then
        local functionType = data.FunctionType
        local controllerGroup = self._Model:GetFunctionControllerGroup(functionType)

        if controllerGroup then
            controllerGroup:Control(data.Args)
        end
    end
end

function XBigWorldFunctionAgency:GetSystemFunctionState()
    local data = XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_GET_SYSTEM_FUNCTION_DISABLED_TYPES)
    local dict = data and data.DisabledFunctionTypesDic or nil
    if not XTool.IsTableEmpty(dict) then
        for functionType, _ in pairs(dict) do
            self._Model:AddCurrentShield(functionType)
        end
    end
end

function XBigWorldFunctionAgency:OnSkipInterface(data)
    if data.SkipFunctionalId then
        XMVCA.XBigWorldSkipFunction:SkipTo(data.SkipFunctionalId)
    end
end

function XBigWorldFunctionAgency:InitFunctionEvent()
    XEventManager.AddEventListener(DlcEventId.EVENT_ENTER_GAME, self.DoWaitLoading, self)
    XEventManager.AddEventListener(DlcEventId.EVENT_FIGHT_UI_HUD_ENABLE, self.DoBackToMain, self)
    XEventManager.AddEventListener(DlcEventId.EVENT_BIG_WORLD_SETTLEMENT, self.DoSettlement, self)
    XEventManager.AddEventListener(DlcEventId.EVENT_QUEST_FINISH, self.DoQuestFinish, self)
    XEventManager.AddEventListener(DlcEventId.EVENT_FIGHT_ENTER_LEVEL, self.DoWaitLoading, self)
    XEventManager.AddEventListener(DlcEventId.EVENT_FIGHT_LEAVE_LEVEL, self.DoWaitLoading, self)
    XEventManager.AddEventListener(DlcEventId.EVENT_FIGHT_LEVEL_BEGIN_UPDATE, self.DoLevelUpdate, self)
    XEventManager.AddEventListener(DlcEventId.EVENT_BIG_WORLD_FUNCTION_EVENT_COMPLETE, self.OnFunctionEventCompleted, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUNCTION_EVENT_COMPLETE, self.OnFunctionEventCompleted, self)
end

function XBigWorldFunctionAgency:RemoveFunctionEvent()
    XEventManager.RemoveEventListener(DlcEventId.EVENT_ENTER_GAME, self.DoWaitLoading, self)
    XEventManager.RemoveEventListener(DlcEventId.EVENT_FIGHT_UI_HUD_ENABLE, self.DoBackToMain, self)
    XEventManager.RemoveEventListener(DlcEventId.EVENT_BIG_WORLD_SETTLEMENT, self.DoSettlement, self)
    XEventManager.RemoveEventListener(DlcEventId.EVENT_QUEST_FINISH, self.DoQuestFinish, self)
    XEventManager.RemoveEventListener(DlcEventId.EVENT_FIGHT_ENTER_LEVEL, self.DoWaitLoading, self)
    XEventManager.RemoveEventListener(DlcEventId.EVENT_FIGHT_LEAVE_LEVEL, self.DoWaitLoading, self)
    XEventManager.RemoveEventListener(DlcEventId.EVENT_FIGHT_LEVEL_BEGIN_UPDATE, self.DoLevelUpdate, self)
    XEventManager.RemoveEventListener(DlcEventId.EVENT_BIG_WORLD_FUNCTION_EVENT_COMPLETE, self.OnFunctionEventCompleted, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUNCTION_EVENT_COMPLETE, self.OnFunctionEventCompleted, self)
end

function XBigWorldFunctionAgency:OnFunctionEventChanged()
    --尝试开启新功能
    self:TryOpenFunction()

    if not self:IsFunctionEventFree() then
        return
    end
    XEventManager.DispatchEvent(DlcEventId.EVENT_BIG_WORLD_FUNCTION_EVENT_BEGIN)
    if self:OpenFuncOpenHint() then --系统开放
        self:_AddState(FunctionState.Busy)
    elseif XDataCenter.GuideManager.CheckGuideOpen() then --引导
        self:_AddState(FunctionState.Busy)
    elseif XMVCA.XBigWorldMessage:TryOpenMessageTipUi() then --强制短信
        self:_AddState(FunctionState.Busy)
    elseif XMVCA.XBigWorldTeach:TryShowTeach() then --教学
        self:_AddState(FunctionState.Busy)
    end
    if self:IsFunctionEventFree() then
        XEventManager.DispatchEvent(DlcEventId.EVENT_BIG_WORLD_FUNCTION_EVENT_END)
    end
end

--- 尝试开启新功能
function XBigWorldFunctionAgency:TryOpenFunction()
    for _, id in pairs(XFunctionConfig.GetOpenList(XFunctionConfig.FunctionType.BigWorld)) do
        --还未开放
        if not self:IsPlayerMark(id) then
            --检测条件
            if self:CheckFunctionCondition(id) then
                self:__UnlockFunction(id)
                if XFunctionConfig.GetOpenHint(id) == 1 then
                    tableInsert(self._OpenHint, id)
                end
            end
        end
    end
end

function XBigWorldFunctionAgency:__UnlockFunction(id)
    XPlayer.ChangeMarks(id)
    --发消息给战斗
    self._NotifyFightFunction.FunctionId = id
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_NOTIFY_FUNCTION_UNLOCK, self._NotifyFightFunction)
end

--- 检测功能条件是否通过
---@param id number
---@return boolean
function XBigWorldFunctionAgency:CheckFunctionCondition(id)
    local template = XFunctionConfig.GetFuncOpenCfg(id)
    -- 如果没有配置应该返回true
    if not template then
        return true
    end
    -- 没有条件
    if XTool.IsTableEmpty(template.Condition) then
        return true
    end
    local open, desc = true, ""
    for _, conditionId in pairs(template.Condition) do
        if conditionId and conditionId > 0 then
            open, desc = XMVCA.XBigWorldService:CheckCondition(conditionId)
            if not open then
                break
            end
        end
    end
    return open, desc
end

--- 判断功能是否已经开启
---@param id number 
---@return boolean
function XBigWorldFunctionAgency:CheckFunctionOpen(id)
    if self:CheckFunctionFitter(id) then
        return false
    end
    if not self:CheckFunctionInTime(id) then
        return false
    end
    --判断是否开启功能
    if not XFunctionConfig.GetFuncOpenCfg(id) then
        return true
    end
    return self:IsPlayerMark(id)
end

function XBigWorldFunctionAgency:IsPlayerMark(id)
    return XPlayer.IsMark(id)
end

function XBigWorldFunctionAgency:CheckFunctionOpenWithCmd(data)
    local enable = false
    if not data then
        enable = false
    else
        enable = self:CheckFunctionOpen(data.FunctionId)
    end
    self._ReturnFightFunction.IsEnable = enable
    
    return self._ReturnFightFunction
end

--- 检测并标记功能状态
---@param id number functionId
---@param needMark boolean 是否需要通知后端标记功能开放
---@param noTips:是否要弹出错误提示
---@return boolean
function XBigWorldFunctionAgency:DetectionFunction(id, needMark, noTips)
    if self:CheckFunctionFitter(id) then
        if not noTips then
            XUiManager.TipMsg(CS.XTextManager.GetText("FunctionalMaintain"))
        end
        return false
    end

    if not self:CheckFunctionInTime(id) then
        if not noTips then
            XUiManager.TipMsg(CS.XTextManager.GetText("FunctionNotDuringOpening"))
        end
        return false
    end
    
    local conditionOpen, desc = self:CheckFunctionCondition(id)
    if not conditionOpen then
        if not noTips then
            XUiManager.TipError(desc)
        end
        return false
    end
    
    if needMark then
        if not self:IsPlayerMark(id) then
            XPlayer.ChangeMarks(id)
        end
    end
    return true
end

--- 检测是否可以过滤该功能
---@param id number functionId
---@return boolean
function XBigWorldFunctionAgency:CheckFunctionFitter(id)
    return XFunctionManager.CheckFunctionFitter(id)
end

function XBigWorldFunctionAgency:CheckFunctionInTime(id)
    return XFunctionManager.CheckFunctionInTime(id)
end

--- 功能开放提示
function XBigWorldFunctionAgency:OpenFuncOpenHint()
    if XTool.IsTableEmpty(self._OpenHint) then
        return false
    end
    XMVCA.XBigWorldUI:Open("UiHintFunctional", self._OpenHint)
    self._OpenHint = {}
    return true
end

--region Function State Changed

function XBigWorldFunctionAgency:DoBackToMain()
    self:OnFunctionEventChanged()
end

function XBigWorldFunctionAgency:DoSettlement()
    self:OnFunctionEventChanged()
end

function XBigWorldFunctionAgency:DoQuestFinish()
    self:OnFunctionEventChanged()
end

function XBigWorldFunctionAgency:DoLevelUpdate()
    self:UnFreezeFunctionEvent()
    self:OnFunctionEventChanged()
end

function XBigWorldFunctionAgency:DoWaitLoading()
    self:FreezeFunctionEvent()
end

function XBigWorldFunctionAgency:OnFunctionEventCompleted()
    self:_RemoveState(FunctionState.Busy)
    self:OnFunctionEventChanged()
end

--冻结状态
function XBigWorldFunctionAgency:FreezeFunctionEvent()
    self:_AddState(FunctionState.Freeze)
end

--解冻
function XBigWorldFunctionAgency:UnFreezeFunctionEvent()
    self:_RemoveState(FunctionState.Freeze)
end

--endregion

function XBigWorldFunctionAgency:IsFunctionEventBusy()
    return self:_ContainState(FunctionState.Busy)
end

function XBigWorldFunctionAgency:IsFunctionEventFree()
    return not (self:_ContainState(FunctionState.Busy) or self:_ContainState(FunctionState.Freeze))
end

function XBigWorldFunctionAgency:_AddState(state)
    self._FunctionState = self._FunctionState | state
end

function XBigWorldFunctionAgency:_RemoveState(state)
    self._FunctionState = self._FunctionState & (~state)
end

function XBigWorldFunctionAgency:_ContainState(state)
    return (self._FunctionState & state) ~= 0
end


return XBigWorldFunctionAgency
