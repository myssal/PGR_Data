local ActionType = {
    PlayCG = 1,
    OpenDIY = 2,
}

local ActionTypeClass = {
    
}

local ActionTypePath = {
    [ActionType.PlayCG] = "XModule/XBigWorldGamePlay/OpeningGuide/GuideAction/XPlayCgAction",
    [ActionType.OpenDIY] = "XModule/XBigWorldGamePlay/OpeningGuide/GuideAction/XOpenDIYAction",
}

---@class XBigWorldOpenGuide 开场引导
---@field _ActionDict table<number, XGuideAction>
---@field _Queue XQueue
local XBigWorldOpenGuide = XClass(nil, "XBigWorldOpenGuide")

function XBigWorldOpenGuide:Ctor()
    self._Queue = XQueue.New()
    self._IsUpdateEnterData = false
end

--- 添加动作
---@param template XTableBigWorldOpenGuide
function XBigWorldOpenGuide:AddAction(template)
    if not template then
        XLog.Error("添加行为失败! 行为配置为空" )
        return
    end
    local action = self:__CreateAction(template)
    if not action then
        return
    end
    self._Queue:Enqueue(action)
end

--- 开场引导开始
function XBigWorldOpenGuide:Start()
    -- 打开按键检测冲突
    CS.XInputManager.InputMapper:SetIsOpenInputMapSectionCheck(true)
    self:PreLaunch()
    XMVCA.XBigWorldUI:OpenWithCallback("UiBigWorldBlackMaskNormal", function()
        --没有引导需要跑了
        if self._Queue:IsEmpty() then
            return self:Finish()
        end
        local action = self._Queue:Dequeue()
        action:Begin()
    end)
end

--- 开场引导完成
function XBigWorldOpenGuide:Finish()
    -- 关闭按键检测冲突
    CS.XInputManager.InputMapper:SetIsOpenInputMapSectionCheck(false)
    self._Queue:Clear()
    self._Queue = nil
    if self._IsUpdateEnterData then
        XMVCA.XBigWorldGamePlay:RequestGetEnterBigWorldData(function()
            self:OnFinish()
        end)
    else
        self:OnFinish()
    end
    self:PreExit()
end

function XBigWorldOpenGuide:OnFinish()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_OPEN_GUIDE_FINISH)

    XMVCA.XBigWorldUI:Close("UiBigWorldBlackMaskNormal")
end

function XBigWorldOpenGuide:PreLaunch()
    if self.IsPreLaunch then
        return
    end
    --预先初始化开场需要的系统
    CS.XWorldEngine.PreLaunch()
    --初始化输入后系统
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():InitInputMapStack()
    --设置大世界状态
    XMVCA.XBigWorldGamePlay:InitCurrentBigWorldType()
    self.IsPreLaunch = true
end

function XBigWorldOpenGuide:PreExit()
    if not self.IsPreLaunch then
        return
    end
    --移除掉开场的系统，交由正式流程去控制
    CS.XWorldEngine.PreExit()
    --设置大世界状态
    XMVCA.XBigWorldGamePlay:DeinitCurrentBigWorldType()
    self.IsPreLaunch = false
end

function XBigWorldOpenGuide:SetUpdateEnterData(value)
    self._IsUpdateEnterData = value
end

function XBigWorldOpenGuide:RunNext()
    local action = self._Queue:Dequeue()
    if not action then
        return self:Finish()
    end
    action:Begin()
end

---@param template XTableBigWorldOpenGuide
---@return XGuideAction 
function XBigWorldOpenGuide:__CreateAction(template)
    local actionType = template.ActionType
    local cls = ActionTypeClass[actionType]
    if not cls then
        local path = ActionTypePath[actionType]
        if not path then
            XLog.Error("不存在行为，行为类型 = " .. actionType)
            return
        end
        cls = require(path)
        ActionTypeClass[actionType] = cls
    end
    return cls.New(template, self)
end

return XBigWorldOpenGuide