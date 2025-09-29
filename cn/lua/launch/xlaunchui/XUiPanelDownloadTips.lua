

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
    local t = {}

    -- 遍历 LaunchRemoveSelectResIds 的所有键值对
    local storage = CS.XLaunchManager.LaunchRemoveSelectResIds
    if storage == nil then
        error("LaunchRemoveSelectResIds is nil")
        return
    end

    -- keyValuePairs 是 List<KeyValueData>
    local pairs = storage.keyValuePairs
    for i = 0, pairs.Length - 1 do
        local kv = pairs[i]
        local k = kv.Key
        local v = kv.Value

        -- 通过 XBuiltinText 解析真实key
        local realKey = CS.XApplication.GetText(k)
        if not realKey or realKey == "" then
            error("无效 realKey, key = " .. tostring(k))
        end

        local name, desc = string.match(realKey, "([^|]+)|([^|]+)")
        if not name or not desc then
            error("realKey 格式错误: " .. tostring(realKey))
        end

        -- 解析 value，转成数字数组
        local resIds = {}
        local vWithDelimiter = v .. "|"
        for numStr in string.gmatch(vWithDelimiter, "([^|]*)|") do
            if numStr ~= "" then
                local num = tonumber(numStr)
                if num then
                    table.insert(resIds, num)
                else
                    error("无效数字格式: " .. numStr .. ", key=" .. tostring(k))
                end
            end
        end

        -- 构建表结构
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