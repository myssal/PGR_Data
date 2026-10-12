
---@class XUiGridRegression4Tab : XUiNode
---@field Parent XUiRegression4Activity
---@field Btn XUiComponent.XUiButton
local XUiGridRegression4Tab = XClass(XUiNode, "XUiGridRegression4Tab")

function XUiGridRegression4Tab:OnStart()
    self.Btn = self.GameObject:GetComponent(typeof(CS.XUiComponent.XUiButton))
    self.Btn:AddEventListener(handler(self, self.OnClick))
end

function XUiGridRegression4Tab:Update(tabData, index)
    self.TabData = tabData
    self.Index = index

    local open = self.Parent.ViewModel:CheckOpenByActivityType(tabData.ActivityType)
    self.Btn:SetDisable(not open)
    self.Btn:SetNameByGroup(0, tabData.Name)

    if tabData.RedPointEvent then
        self:AddRedPointEvent(self.Btn, handler(self, self.OnRedPoint), self, { tabData.RedPointEvent })
    end
end

function XUiGridRegression4Tab:OnRedPoint(_, count)
    self.Btn:ShowReddot(count >= 0)
end

function XUiGridRegression4Tab:OnClick()
    self.Parent:OnSelectTab(self.Index)
end

function XUiGridRegression4Tab:RefreshRedPoint()
    local redPointId = self.RedEventDic and self.RedEventDic[self.Btn]
    if XTool.IsNumberValid(redPointId) then
        XRedPointManager.Check(redPointId)
    end
end

return XUiGridRegression4Tab
