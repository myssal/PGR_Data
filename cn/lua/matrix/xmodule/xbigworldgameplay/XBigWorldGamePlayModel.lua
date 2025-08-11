---@class XBigWorldGamePlayModel : XModel
local XBigWorldGamePlayModel = XClass(XModel, "XBigWorldGamePlayModel")

local TableKey = {
    BigWorldActivity = {
        DirPath = XConfigUtil.DirectoryType.Client,
        ReadFunc = XConfigUtil.ReadType.IntAll,
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BigWorldGoods = {
        DirPath = XConfigUtil.DirectoryType.Client,
        ReadFunc = XConfigUtil.ReadType.IntAll,
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BigWorldGoodsGroup = {
        DirPath = XConfigUtil.DirectoryType.Client,
        ReadFunc = XConfigUtil.ReadType.IntAll,
        CacheType = XConfigUtil.CacheType.Normal,
    },
}

local ModuleKey = {
    BigWorldSysModule = {
        Identifier = "WorldId",
        CacheType = XConfigUtil.CacheType.Normal,
    },
    BigWorldOpenGuide = {
        ReadFunc = XConfigUtil.ReadType.IntAll,
        CacheType = XConfigUtil.CacheType.Normal,
    }
}

local SysModuleId2ModuleId = {
    [1] = ModuleId.XSkyGarden,
}

local SystemModuleId = {
    XSkyGarden = 1,
}

function XBigWorldGamePlayModel:OnInit()
    -- 初始化内部变量ModuleKey
    -- 这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._CurrentWorldId = 0
    self._CurrentLevelId = 0

    self._EntranceRedDict = {}
    self._OpenGuideIdDict = {}
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common/Activity", TableKey)
    self._ConfigUtil:InitConfigByTableKey("BigWorld/Common", ModuleKey)
end

function XBigWorldGamePlayModel:OnClear()
end

function XBigWorldGamePlayModel:ClearPrivate()
end

function XBigWorldGamePlayModel:ResetAll()
end

-- region Config

function XBigWorldGamePlayModel:GetModuleIdByWorldId(worldId)
    ---@type XTableBigWorldSysModule
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(ModuleKey.BigWorldSysModule, worldId)
    local sysModuleId = config and config.SysModuleId or 0
    if not sysModuleId or sysModuleId <= 0 then
        XLog.Error(string.format("世界Id = %s, 不存在对应系统模块，请检查配置", worldId))
        return ModuleId.XBigWorld
    end

    local moduleId = SysModuleId2ModuleId[sysModuleId]
    if not moduleId then
        XLog.Error(string.format("世界Id = %s, 系统Id = %s，不存在对应模块，请联系程序添加！", worldId, sysModuleId))
    end
    return moduleId
end

function XBigWorldGamePlayModel:GetSystemModuleId(worldId)
    ---@type XTableBigWorldSysModule
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(ModuleKey.BigWorldSysModule, worldId)
    local sysModuleId = config and config.SysModuleId or 0
    return sysModuleId
end

-- endregion

function XBigWorldGamePlayModel:SetCurrentWorldId(worldId)
    self._CurrentWorldId = worldId
end

function XBigWorldGamePlayModel:GetCurrentWorldId()
    return self._CurrentWorldId
end

function XBigWorldGamePlayModel:SetCurrentLevelId(levelId)
    self._CurrentLevelId = levelId
end

function XBigWorldGamePlayModel:GetCurrentLevelId()
    return self._CurrentLevelId
end

---@return table<number, XTableBigWorldActivity>
function XBigWorldGamePlayModel:GetAllActivityTemplates()
    return self._ConfigUtil:GetByTableKey(TableKey.BigWorldActivity)
end

---@param activityId number
---@return table<number, table> -- XUiGridBWItem
function XBigWorldGamePlayModel:GetBigWorldActivityGoodsByActivityId(activityId)
    local activityCfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BigWorldActivity, activityId)
    if not activityCfg then return end

    return self:GetBigWorldGoodsByGroupId(activityCfg.GoodsGroupId)
end

---@param groupId number
---@return table<number, table> -- XUiGridBWItem
function XBigWorldGamePlayModel:GetBigWorldGoodsByGroupId(groupId)
    local groupCfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BigWorldGoodsGroup, groupId)
    if not groupCfg then return end

    local datas = {}
    local itemCount = 0
    local isIgnoreCount = groupCfg.IsIgnoreCount
    for _, goodsId in ipairs(groupCfg.GoodIds) do
        local data = {}
        local goodCfg = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.BigWorldGoods, goodsId)
        data.TemplateId = goodCfg.TemplateId
        if not isIgnoreCount then
            data.Count = goodCfg.Count
        end
        itemCount = itemCount + 1
        datas[itemCount] = data
    end
    return datas
end

function XBigWorldGamePlayModel:GetOpenGuideIdList(sysModuleId)
    local idList = self._OpenGuideIdDict[sysModuleId]
    if idList then
        return idList
    end
    ---@type table<number, XTableBigWorldOpenGuide>
    local templates = self._ConfigUtil:GetByTableKey(ModuleKey.BigWorldOpenGuide)
    local dict = {}
    if XTool.IsTableEmpty(templates) then
        return dict
    end
    for _, template in pairs(templates) do
        local list = dict[template.SysModuleId]
        if not list then
            list = {}
            dict[template.SysModuleId] = list
        end
        list[#list + 1] = template
    end

    for _, list in pairs(dict) do
        ---@param a XTableBigWorldOpenGuide
        ---@param b XTableBigWorldOpenGuide
        table.sort(list, function(a, b) 
            local indexA = a.StepIndex
            local indexB = b.StepIndex
            if indexA ~= indexB then
                return indexA < indexB
            end
            return a.Id < b.Id
        end)
    end
    self._OpenGuideIdDict = dict
    
    return dict[sysModuleId]
end

function XBigWorldGamePlayModel:Clear()
    self._CurrentWorldId = 0
    self._CurrentLevelId = 0
end


--region 入口红点

function XBigWorldGamePlayModel:UpdateEntranceRedPoint(data)
    if not data then
        return
    end
    self._EntranceRedDict = data.RedPoints
end

--- 检查空花入口红点
---@return boolean
function XBigWorldGamePlayModel:CheckSkyGardenEntranceRedPoint()
    return self._EntranceRedDict[SystemModuleId.XSkyGarden]
end

function XBigWorldGamePlayModel:GetSkyGardenOpenGuideIdList()
    return self:GetOpenGuideIdList(SystemModuleId.XSkyGarden)
end

--endregion



return XBigWorldGamePlayModel
