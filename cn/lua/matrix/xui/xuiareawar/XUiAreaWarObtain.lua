local XUiObtain = require("XUi/XUiObtain/XUiObtain")
local XUiGridAreaWarItem = require("XUi/XUiAreaWar/XUiGridAreaWarItem")
local XUiAreaWarObtain =  XLuaUiManager.Register(XUiObtain, "UiAreaWarObtain")

function XUiAreaWarObtain:OnStart(rewardGoodsList,areaWarItemList, title, closeCb, sureCb, horizontalNormalizedPosition, customParams)

    if not self.GridAreawarItem then
        self.GridAreawarItem = self.Transform:Find("SafeAreaContentPane/ScrView/Viewport/PanelContent/GridItem")
        self.GridAreawarItem.gameObject:SetActiveEx(false)
    end
    self.CustomParams = customParams or {}
    self.Items = {}
    self.GridCommon.gameObject:SetActive(false)
    self.CancelBtnPosX = self.BtnCancel.transform.localPosition.x
    self.SureBtnPosX = self.BtnSure.transform.localPosition.x
    if title then
        self.TxtTitle.text = title
    end
    self.OkCallback = sureCb
    self.CancelCallback = closeCb
    if not XTool.IsTableEmpty(rewardGoodsList) then
        self:Refresh(rewardGoodsList, horizontalNormalizedPosition)
        self:Layout()
        self:CheckIsTimelimitGood(rewardGoodsList)
    end

    if not XTool.IsTableEmpty(areaWarItemList) then
        self:RefreshAreaWarItem(areaWarItemList, horizontalNormalizedPosition)
        self:Layout()
    end


    self:PlayAnimationAniObtain()
   
end

function XUiAreaWarObtain:RefreshAreaWarItem(areaWarItemList,horizontalNormalizedPosition)
    for _, itemData in pairs(areaWarItemList) do
        local go = XUiHelper.Instantiate(self.GridAreawarItem, self.PanelContent)
        local grid = XUiGridAreaWarItem.New(go, self)
        grid:RefreshItem(itemData.ItemId,itemData.Num)
        grid.GameObject:SetActiveEx(true)
    end

    if horizontalNormalizedPosition then
        self.ScrView.horizontalNormalizedPosition = horizontalNormalizedPosition
    end
end
return XUiAreaWarObtain