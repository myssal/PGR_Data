---@class XUiPanelSkyTowerWorkOrder : XUiNode 安排工作弹窗的事件/订单信息
---@field _Control XSkyTowerControl
---@field Parent XUiSkyTowerWork
local XUiPanelSkyTowerWorkOrder = XClass(XUiNode, "XUiPanelSkyTowerWorkOrder")

--region 生命周期
function XUiPanelSkyTowerWorkOrder:OnStart()
    -- 进度文本里的道具图标要走模块自己的富文本图源
    self._GridList = {}
    self._RequestImage = XMVCA.XSkyTower.RichTextImageCallBack
end
--endregion

--region 界面刷新
function XUiPanelSkyTowerWorkOrder:RefreshView()
    local descList = self._Control:GetWorkOrderDescList(XMVCA.XSkyTower.WorkOrderMaxCount, self.Parent:GetFloorId())
    -- 没有进行中的事件与订单时整块隐藏
    if XTool.IsTableEmpty(descList) then
        self:Close()
        return
    end
    self:Open()
    XUiHelper.RefreshUiObjectList(self._GridList, self.GridOrder.parent, self.GridOrder, #descList, function(index, grid)
        grid.TxtOrderInfo.requestImage = self._RequestImage
        grid.TxtOrderInfo.text = descList[index]
    end)
end
--endregion

return XUiPanelSkyTowerWorkOrder
