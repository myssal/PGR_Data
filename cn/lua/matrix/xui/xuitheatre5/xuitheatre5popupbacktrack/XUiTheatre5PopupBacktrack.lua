--- pve剧情节点确认回溯界面
---@class XUiTheatre5PopupBacktrack: XLuaUi
---@field _Control XTheatre5Control
local XUiTheatre5PopupBacktrack = XLuaUiManager.Register(XLuaUi, 'UiTheatre5PopupBacktrack')

function XUiTheatre5PopupBacktrack:OnAwake()
    self.BtnSure:AddEventListener(handler(self, self.OnSubmit))
end

function XUiTheatre5PopupBacktrack:OnStart(cfg)
    ---@type XTableTheatre5PveStoryLineContent
    self.Cfg = cfg

    if not self.Cfg then
        XLog.Error('没有有效的节点配置')
        self:Close()
        return
    end
    
    self:InitShow()
end

function XUiTheatre5PopupBacktrack:InitShow()
    self.TxtDescription.text = self.Cfg.CharacterStoryDesc
end

function XUiTheatre5PopupBacktrack:OnSubmit()
    XMVCA.XTheatre5.PVEAgency:RequestPveStoryLinePromote(self.Cfg.StoryLineId, self.Cfg.Id, function()
        self._Control.FlowControl:EnterStroryLineContent(self.Cfg.StoryLineId)
        -- 因为不确定其他节点是否会处理该界面，因此使用安全接口进行关闭
        XLuaUiManager.SafeClose('UiTheatre5PopupBacktrack')
    end)
end

return XUiTheatre5PopupBacktrack