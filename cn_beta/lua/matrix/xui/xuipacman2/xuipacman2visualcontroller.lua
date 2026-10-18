local EventDefine = require("XUi/XUiPacMan2/XUiPacMan2EventDefine")
local XUiPacMan2OverlayDialogueData = require("XUi/XUiPacMan2/XUiPacMan2OverlayDialogueData")

local DialogType = EventDefine.DialogType
local OverlayUiName = "UiPacMan2EventOverlay"
---@class XUiPacMan2VisualController
---PacMan2游戏界面的事件表现控制器。
---
---职责：
---1. 显示和隐藏对话；
---2. 切换魔幻滤镜；
---3. 切换结局遮罩；
---4. 记录当前持续表现状态；
---5. 开始新关卡或销毁时清理表现。
local XUiPacMan2VisualController = XClass(nil, "XUiPacMan2VisualController")


---@param rootUi XUiPacMan2Game
function XUiPacMan2VisualController:Ctor(rootUi)
    self._RootUi = rootUi

    self._HeadUi = {}

    local headUiObject = rootUi.Head:GetComponent("UiObject")
    XTool.InitUiObjectByInstance(headUiObject, self._HeadUi)
    
    ---策划表只填写业务Key，不直接填写Prefab节点名。
    self._MagicFilterNodes = {
        Stage26Magic = rootUi.ScreenEffect,
    }

    self._EndingMaskNodes = {
        Black = rootUi.PanelEndingMaskBlack,
    }

    self._CurrentMagicFilterKey = nil
    self._CurrentEndingMaskKey = nil

    -- 本关Overlay页面会话。
    -- nil表示尚未打开或已经关闭；
    -- session存在但Ui为空表示正在异步打开；
    -- session.Ui有效表示已经打开；
    -- session.IsClosing表示正在关闭。
    self._OverlaySession = nil

    -- Overlay消息的唯一数据所有者。
    -- 页面只读取这里保存的消息，不自行保存业务历史。
    self._OverlayDialogueData = XUiPacMan2OverlayDialogueData.New()
    -- 页面打开前保存业务回调，打开完成后交给Overlay。
    self._OverlaySkipCallback = nil
    
    self:Reset()
end

---显示对话。
---@param dialogType number
---@param content string
---@param characterName string|nil
---@param headIcon string|nil
function XUiPacMan2VisualController:ShowDialogue(dialogType, content, characterName, headIcon)
    local rootUi = self._RootUi

    if not rootUi then
        return
    end

    local isCharacter = dialogType == DialogType.Character

    rootUi.PanelDialog.gameObject:SetActiveEx(true)
    rootUi.Head.gameObject:SetActiveEx(isCharacter)
    rootUi.TxtCharacterName.gameObject:SetActiveEx(isCharacter)
    rootUi.TxtDialogTips.text = content or ""

    if isCharacter then
        rootUi.TxtCharacterName.text = characterName or ""

        -- 不传头像时，保留Prefab中设置的默认头像。
        if headIcon and headIcon ~= "" then
            self._HeadUi.StandIcon:SetRawImage(headIcon)
        end
    else
        rootUi.TxtCharacterName.text = ""
    end
end

---隐藏对话。
function XUiPacMan2VisualController:HideDialogue()
    local rootUi = self._RootUi

    if not rootUi then
        return
    end

    rootUi.PanelDialog.gameObject:SetActiveEx(false)
    rootUi.Head.gameObject:SetActiveEx(false)
    rootUi.TxtCharacterName.gameObject:SetActiveEx(false)
    rootUi.TxtCharacterName.text = ""
    rootUi.TxtDialogTips.text = ""
end

---控制指定魔幻滤镜。
---滤镜使用单通道，开启新滤镜时替换当前滤镜。
---@param filterKey string
---@param enabled boolean
function XUiPacMan2VisualController:SetMagicFilterEnabled(filterKey, enabled)
    local targetNode = self._MagicFilterNodes[filterKey]

    if not targetNode or XTool.UObjIsNil(targetNode) then
        XLog.Error("[PacMan2VisualController] 未配置MagicFilter, filterKey=" .. tostring(filterKey))
        return
    end

    if enabled then
        -- 相同滤镜已经显示，不重复开关，避免闪烁。
        if self._CurrentMagicFilterKey == filterKey then
            return
        end

        local currentNode = self._MagicFilterNodes[self._CurrentMagicFilterKey]

        if currentNode and not XTool.UObjIsNil(currentNode) then
            currentNode.gameObject:SetActiveEx(false)
        end

        targetNode.gameObject:SetActiveEx(true)
        self._CurrentMagicFilterKey = filterKey

        XLog.Debug("[PacMan2VisualController] MagicFilter enabled, filterKey=" .. tostring(filterKey))
        return
    end

    -- 旧滤镜的关闭事件不能关闭后来替换上来的新滤镜。
    if self._CurrentMagicFilterKey ~= filterKey then
        return
    end

    targetNode.gameObject:SetActiveEx(false)
    self._CurrentMagicFilterKey = nil

    XLog.Debug("[PacMan2VisualController] MagicFilter disabled, filterKey=" .. tostring(filterKey))
end

---控制指定结局遮罩。
---遮罩使用单通道，开启新遮罩时替换当前遮罩。
---@param maskKey string
---@param enabled boolean
function XUiPacMan2VisualController:SetEndingMaskEnabled(maskKey, enabled)
    local targetNode = self._EndingMaskNodes[maskKey]

    if not targetNode or XTool.UObjIsNil(targetNode) then
        XLog.Error("[PacMan2VisualController] 未配置EndingMask, maskKey=" .. tostring(maskKey))
        return
    end

    if enabled then
        if self._CurrentEndingMaskKey == maskKey then
            return
        end

        local currentNode = self._EndingMaskNodes[self._CurrentEndingMaskKey]

        if currentNode and not XTool.UObjIsNil(currentNode) then
            currentNode.gameObject:SetActiveEx(false)
        end

        targetNode.gameObject:SetActiveEx(true)
        self._CurrentEndingMaskKey = maskKey

        XLog.Debug("[PacMan2VisualController] EndingMask enabled, maskKey=" .. tostring(maskKey))
        return
    end

    if self._CurrentEndingMaskKey ~= maskKey then
        return
    end

    targetNode.gameObject:SetActiveEx(false)
    self._CurrentEndingMaskKey = nil

    XLog.Debug("[PacMan2VisualController] EndingMask disabled, maskKey=" .. tostring(maskKey))
end

---打开或关闭Overlay。
---每关只允许打开和关闭一次，配置顺序必须为：
---打开Overlay → 追加消息 → 关闭Overlay。
---
---消息可以在页面异步打开期间写入Data；
---页面打开完成后会显示Data中的当前完整消息。
---@param enabled boolean
---@param onComplete function
function XUiPacMan2VisualController:SetOverlayEnabled(enabled, onComplete)
    if enabled then
        if self._OverlaySession then
            XLog.Error("[PacMan2VisualController] 本关Overlay已经开始打开，不能重复打开")
            onComplete()
            return
        end

        -- 每次开始新的Overlay前清空上一轮数据。
        self._OverlayDialogueData:Clear()

        local session = {
            Ui = nil,
            IsClosing = false,
        }

        self._OverlaySession = session

        XLuaUiManager.OpenWithCallback(OverlayUiName, function(ui)
            -- 打开期间可能已经退出关卡或重置事件系统。
            -- 旧会话回调不能继续操作新关卡。
            if self._OverlaySession ~= session then
                return
            end

            local overlay = ui and ui.UiProxy and ui.UiProxy.UiLuaTable

            if not overlay or XTool.UObjIsNil(overlay.GameObject) then
                self._OverlaySession = nil
                self._OverlayDialogueData:Clear()

                XLog.Error("[PacMan2VisualController] Overlay打开后未取得有效界面")
                onComplete()
                return
            end

            session.Ui = overlay

            -- 页面异步打开期间到达的消息已经保存在Data中。
            -- 打开完成后直接显示当前完整列表。
            overlay:SetDialogueData(self._OverlayDialogueData:GetDialogues())
            -- 打开完成后才提供跳过入口。
            overlay:SetSkipCallback(self._OverlaySkipCallback)
            onComplete()
        end)

        return
    end

    local session = self._OverlaySession
    local overlay = session and session.Ui

    if not session then
        XLog.Error("[PacMan2VisualController] Overlay尚未打开，不能关闭")
        onComplete()
        return
    end

    if session.IsClosing then
        XLog.Error("[PacMan2VisualController] Overlay正在关闭，不能重复关闭")
        return
    end

    if not overlay or XTool.UObjIsNil(overlay.GameObject) then
        XLog.Error("[PacMan2VisualController] Overlay尚未完成打开，不能关闭")
        onComplete()
        return
    end

    session.IsClosing = true
    -- 表里的关闭事件先执行时，立即停止接受跳过。
    -- 如果玩家先点击跳过，Game会先取消事件组，表里的关闭事件不会再执行。
    self:SetOverlaySkipCallback(nil)
    XLuaUiManager.CloseWithCallback(OverlayUiName, function()
        -- 关闭期间可能已经退出关卡或重置事件系统。
        if self._OverlaySession ~= session then
            return
        end

        self._OverlaySession = nil
        self._OverlayDialogueData:Clear()

        -- 页面完全关闭后通知调用方。
        -- 调用方可能是原子事件，也可能是Game的跳过响应。
        onComplete()
    end)
end

---设置当前Overlay的跳过响应。
---页面尚未打开时只保存，打开完成后再绑定。
---@param callback function|nil
function XUiPacMan2VisualController:SetOverlaySkipCallback(callback)
    self._OverlaySkipCallback = callback

    local session = self._OverlaySession
    local overlay = session and session.Ui

    if overlay and not XTool.UObjIsNil(overlay.GameObject) then
        overlay:SetSkipCallback(callback)
    end
end

---向当前Overlay追加一条消息。
---消息的唯一所有者是OverlayDialogueData。
---页面正在异步打开时只保存数据；页面打开后再统一显示。
---@param style string Left / Right / System
---@param content string
---@param headIcon string|nil
---@return boolean 是否追加成功
function XUiPacMan2VisualController:AppendOverlayDialogue(style, content, headIcon)
    local session = self._OverlaySession

    if not session then
        XLog.Error("[PacMan2VisualController] Overlay尚未开始打开，无法追加消息")
        return false
    end

    if session.IsClosing then
        XLog.Error("[PacMan2VisualController] Overlay正在关闭，无法继续追加消息")
        return false
    end

    local dialogue = self._OverlayDialogueData:Append(style, content, headIcon)

    if not dialogue then
        return false
    end

    local overlay = session.Ui

    -- 页面可能仍在异步打开。
    -- 尚未打开时只保存Data；打开完成后通过SetDialogueData完整初始化。
    -- 已经打开时只向DynamicList增量插入这一条消息。
    if overlay and not XTool.UObjIsNil(overlay.GameObject) then
        overlay:InsertDialogue(dialogue)
    end

    return true
end

---关卡清理时移除Overlay。
---不播放关闭事件，也不调用事件完成回调。
function XUiPacMan2VisualController:_ResetOverlay()
    local session = self._OverlaySession
    self._OverlaySession = nil
    self._OverlaySkipCallback = nil

    if session then
        -- Remove同时处理等待打开的请求和已经入栈的页面。
        -- 不能只检查IsUiShow，因为页面可能还在打开过程中。
        XLuaUiManager.Remove(OverlayUiName)
    end
end

---清理全部事件表现。
function XUiPacMan2VisualController:Reset()
    self:_ResetOverlay()
    if self._OverlayDialogueData then
        self._OverlayDialogueData:Clear()
    end
    self:HideDialogue()

    for _, node in pairs(self._MagicFilterNodes or {}) do
        if node and not XTool.UObjIsNil(node) then
            node.gameObject:SetActiveEx(false)
        end
    end

    for _, node in pairs(self._EndingMaskNodes or {}) do
        if node and not XTool.UObjIsNil(node) then
            node.gameObject:SetActiveEx(false)
        end
    end

    self._CurrentMagicFilterKey = nil
    self._CurrentEndingMaskKey = nil
end

function XUiPacMan2VisualController:Dispose()
    self:Reset()

    if self._OverlayDialogueData then
        self._OverlayDialogueData:Dispose()
        self._OverlayDialogueData = nil
    end

    self._MagicFilterNodes = nil
    self._EndingMaskNodes = nil
    self._RootUi = nil
end

return XUiPacMan2VisualController