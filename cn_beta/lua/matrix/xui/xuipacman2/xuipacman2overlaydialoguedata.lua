---@class XUiPacMan2OverlayDialogueData
---PacMan2事件Overlay的消息数据。
---
---职责：
---1. 保存本轮Overlay的完整消息历史；
---2. 校验消息样式；
---3. 追加和清空消息；
---4. 向显示层提供只读使用的消息列表。
local XUiPacMan2OverlayDialogueData = XClass(nil, "XUiPacMan2OverlayDialogueData")

local SupportedStyles = {
    Left = true,
    Right = true,
    System = true,
}

function XUiPacMan2OverlayDialogueData:Ctor()
    -- 与DynamicList的Reverse模式保持一致：
    -- 最新消息放在数组前面，页面最终仍按时间从上到下显示。
    self._Dialogues = {}
end

---追加一条Overlay消息。
---@param style string Left / Right / System
---@param content string|nil
---@param headIcon string|nil
---@return table|nil dialogue 追加成功时返回新消息，失败时返回nil
function XUiPacMan2OverlayDialogueData:Append(style, content, headIcon)
    if not SupportedStyles[style] then
        XLog.Error("[PacMan2OverlayDialogueData] 未支持的对话样式：" .. tostring(style))
        return nil
    end

    local dialogue = {
        Style = style,
        Content = content or "",
        HeadIcon = headIcon,
    }

    -- Reverse模式下，最新消息保存在数组头部。
    table.insert(self._Dialogues, 1, dialogue)
    return dialogue
end

---清空本轮Overlay消息。
---原地清空数组，避免已经持有列表引用的显示层拿到旧对象。
function XUiPacMan2OverlayDialogueData:Clear()
    for index = #self._Dialogues, 1, -1 do
        self._Dialogues[index] = nil
    end
end

---取得当前完整消息列表。
---调用方只读取或传给显示层，不应修改返回值。
---@return table[]
function XUiPacMan2OverlayDialogueData:GetDialogues()
    return self._Dialogues
end

function XUiPacMan2OverlayDialogueData:Dispose()
    self._Dialogues = nil
end

return XUiPacMan2OverlayDialogueData