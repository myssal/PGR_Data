

---@class XUiPanelDownloadTips
local XUiPanelDownloadTips = {}

function XUiPanelDownloadTips.New(gameObj, parentProxy)
    local class = {}
    setmetatable(class, { __index = XUiPanelDownloadTips })
    class:Init(gameObj, parentProxy)
    return class
end

function XUiPanelDownloadTips:Init(gameObj, parentProxy)
    self.GameObject = gameObj
    self.Parent = parentProxy
    self:InitDynamicTable()
    self:RefreshDynamicTable()
end

function XUiPanelDownloadTips:InitDynamicTable()
    local XGridDownloadTipSubpackage = require("XLaunchUi/XGridDownloadTipSubpackage")
    local XDynamicTableNormal = require("XLaunchUi/XDynamicTableNormalLaunch")
    self.DynamicTable = XDynamicTableNormal.New(self.Parent.SubpackageList)
    self.DynamicTable:SetProxy(XGridDownloadTipSubpackage, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelDownloadTips:IsAllGridDownloadFlag()
    for k, grid in pairs(self.DynamicTable:GetGrids()) do
        if not grid:GetDownFlag() then
            return false
        end
    end
    return true
end

function XUiPanelDownloadTips:SetAllGridDownloadFlag(flag)
    for k, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:SetDownFlag(flag)
        grid:RefreshWithCb()
    end
end

function XUiPanelDownloadTips:SetAllGridClickLock(flag)
    for k, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:SetClickLock(flag)
    end
end

function XUiPanelDownloadTips:GetRemoveResIdList()
    local res = {}
    for k, grid in pairs(self.DynamicTable:GetGrids()) do
        -- print("SP/DN GetRemoveResIdList ", k, grid, grid:GetDownFlag())
        if not grid:GetDownFlag() then
            local resIdlist = grid.ResIdList
            for i = 1, #resIdlist do
                local resId = resIdlist[i]
                table.insert(res, resId)
            end
        end
    end
    return res
end

function XUiPanelDownloadTips:GetRemoveSize()
    local resSize = 0
    for k, grid in pairs(self.DynamicTable:GetGrids()) do
        if not grid:GetDownFlag() then
            resSize = resSize + grid:GetTotalSize()
        end
    end
    return resSize
end

function XUiPanelDownloadTips:RegisterGridClickCb(cb)
    self.GridClickCb = cb
end

function XUiPanelDownloadTips:RefreshDynamicTable()
    local dataString = CS.XLaunchManager.LaunchConfig:GetString("LaunchDownloadResIdList")
    
    local t = {}
    -- 提取每个双引号包裹的内容
    for content in string.gmatch(dataString, '"(.-)"') do
        -- 提取名称、描述和资源ID部分
        local name, desc, rest = string.match(content, "([^|]+)|([^|]+)|(.*)")
        if not name or not desc then
            error("无效格式: " .. content)
        end

        local resIds = {}
        -- 在 rest 后添加一个竖线，确保最后的数字也能被正确提取
        local restWithDelimiter = rest .. "|"
        -- 使用 gmatch 正确分割每个数字部分
        for numStr in string.gmatch(restWithDelimiter, "([^|]*)|") do
            if numStr ~= "" then
                local num = tonumber(numStr)
                if num then
                    table.insert(resIds, num)
                else
                    error("无效数字格式: " .. numStr)
                end
            end
        end

        -- 构建最终表结构
        table.insert(t, {
            Name = name,
            Desc = desc,
            ResIdList = resIds
        })
    end

    self.DynamicTable:SetDataSource(t)
    self.DynamicTable:ReloadDataSync()
end

function XUiPanelDownloadTips:OnDynamicTableEvent(event, index, grid)
    if event == self.DynamicTable.DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        local data = self.DynamicTable.DataSource[index]
        grid:Init(data)
        grid:RegisterClickCb(function ()
            if self.GridClickCb then
                self.GridClickCb(self:GetRemoveSize())
            end
        end)
    elseif event == self.DynamicTable.DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh()
    end
end

function XUiPanelDownloadTips:SetActiveEx(flag)
    self.GameObject:SetActiveEx(flag)
end

function XUiPanelDownloadTips:OnDestroy()
    if self.DynamicTable then
        self.DynamicTable:Clear()
        self.DynamicTable = nil
    end
end

return XUiPanelDownloadTips