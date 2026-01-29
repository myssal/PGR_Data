---@class XUiGridLuosaitaBlock : XUiNode
---@field Parent XUiPanelLuosaitaSection
---@field _Control XMainLineLuosaitaControl
local XUiGridLuosaitaBlock = XClass(XUiNode, "XUiGridLuosaitaBlock")

function XUiGridLuosaitaBlock:OnStart()
    self.RImgRed = self.Transform:FindTransform("RImgRed").parent
    self.RImgBlue = self.Transform:FindTransform("RImgBlue").parent
    self.AnimEnableBlue = self.Transform:FindTransform("AnimEnableBlue")
    self.BlueLoop = self.Transform:FindTransform("BlueLoop")
    self.RedLoop = self.Transform:FindTransform("RedLoop")
end

function XUiGridLuosaitaBlock:Refresh(blockData)
    if not blockData then
        self:Close()
        return
    end

    local isOccupied = blockData:IsOccupied()
    if self.IsOccupied == isOccupied then return end

    self.RImgRed.gameObject:SetActiveEx(not isOccupied)
    self.RImgBlue.gameObject:SetActiveEx(isOccupied)
    
    -- 只有从未占领切换到占领的时候才播切换特效，其他时候播常驻特效
    if self.IsOccupied == false and isOccupied then
        self.AnimEnableBlue:PlayTimelineAnimation()
    else
        if isOccupied then
            self.BlueLoop:PlayTimelineAnimation()
        else
            self.RedLoop:PlayTimelineAnimation()
        end
    end
    self.IsOccupied = isOccupied
end

return XUiGridLuosaitaBlock
