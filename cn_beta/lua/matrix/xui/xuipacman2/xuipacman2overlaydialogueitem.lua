---@class XUiPacMan2OverlayDialogueItem
---Overlay动态列表中的一条消息表现。
---实例会被对象池复用，因此Refresh必须覆盖本条消息需要的显示内容。
local XUiPacMan2OverlayDialogueItem = XClass(nil, "XUiPacMan2OverlayDialogueItem")

function XUiPacMan2OverlayDialogueItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    -- 保存模板中的默认头像。
    -- 复用节点时，如果新消息没有指定头像，需要恢复默认值，不能沿用上一条消息的头像。
    if self.StandIcon then
        self._DefaultHeadTexture = self.StandIcon.texture
    end
end

---@param data table 消息数据：Style、Content、HeadIcon。
function XUiPacMan2OverlayDialogueItem:Refresh(data)
    self.TxtDialogTips.text = data.Content or ""

    -- 蓝底模板没有头像组件。
    if self.StandIcon then
        if data.HeadIcon and data.HeadIcon ~= "" then
            self.StandIcon:SetRawImage(data.HeadIcon)
        else
            self.StandIcon.texture = self._DefaultHeadTexture
        end
    end

    -- 回调返回后，DynamicList会调用XDynamicGrid，按配置顺序刷新布局。
end

return XUiPacMan2OverlayDialogueItem