local UnityPlayerPrefs = CS.UnityEngine.PlayerPrefs
local KEY_GAME_DOWNLOAD_RECORD = "KEY_GAME_DOWNLOAD_RECORD"
local KEY_LAUNCH_DOWNLOAD_RECORD = "KEY_LAUNCH_DOWNLOAD_RECORD"
local KEY_REMOVE_RESID_LIST = "KEY_REMOVE_RESID_LIST"
local KEY_DOWNLOADED = "KEY_DOWNLOADED"

local DLC_NEED_DOWNLOAD_KEY = "DLC_NEED_DOWNLOAD_KEY"
local HAS_SELECT_DOWNLOAD_PART_KEY = "HAS_SELECT_DOWNLOAD_PART_KEY"
local HAS_SELECT_ALL_DOWNLOAD_KEY = "HAS_SELECT_ALL_DOWNLOAD_KEY"
local IS_SELECT_WIFI_AUTO_DOWNLOAD = "IS_SELECT_WIFI_AUTO_DOWNLOAD" --是否选中wifi自动下载
local KEY_UNINSTALLED_RESID_LIST = "KEY_UNINSTALLED_RESID_LIST" -- 新增Key
local KEY_SUBPACKAGE_FINISHED = "KEY_SUBPACKAGE_FINISHED_" -- 分包下载完成状态
local KEY_SUBPACKAGE_ACTIVE = "KEY_SUBPACKAGE_ACTIVE_" -- 分包激活状态（用户意图）
local CsLog = CS.XLog

---@class XLaunchDlcManager 分包资源-启动管理类
local M = {}
local XLaunchDlcManager = M

local DlcIdList = {}
local ApplicationIndexTable = {}

local LaunchDownloadRecord = {} -- 热更时已选择的下载
local DownloadedDic = {} -- 已下载

local DlcIndexInfo = {}
local DlcIgnoreDownloadIfNotDownload --未下载过的ResId在热更时进行忽略

local NeedLaunchTest = CS.XResourceManager.NeedLaunchTest
local IsInGame = false

local DLC_BASE_INDEX = 0 -- 基础资源包索引
local DLC_COMMON_INDEX = -1 -- 通用资源包索引

local STATE_DEFAULT = 0 -- 未开始下载
local STATE_START = 1 -- 已开始（选择）下载

local DownloadedMap = {}
local PathModule = nil
local FileModule = nil
local VersionModule = nil

local IsInit = false
local IsRecordAllDlcId = true --所有的DlcId均被标记已经下载了

local Split = function(str)
    local arr = {}
    for v in string.gmatch(str, "[^,]*") do
        table.insert(arr, v)
    end
    return arr
end

--====启动逻辑接口 begin=====
M.Init = function(dlcIndexTable)
    if IsInit then
        return
    end
    IsInit = true

    for dlcId, info in pairs(dlcIndexTable) do
        table.insert(DlcIdList, dlcId)
    end
    
    
    for i, dlcId in pairs(DlcIdList) do
        local value = UnityPlayerPrefs.GetInt(KEY_LAUNCH_DOWNLOAD_RECORD .. dlcId, STATE_DEFAULT)
        LaunchDownloadRecord[dlcId] = value
        if IsRecordAllDlcId and value == STATE_DEFAULT then
            IsRecordAllDlcId = false
        end
        
        local downloadState = UnityPlayerPrefs.GetInt(KEY_DOWNLOADED .. dlcId, STATE_DEFAULT)
        DownloadedDic[dlcId] = downloadState
    end
    CsLog.Debug("[DLC] dlc is all record = " .. tostring(IsRecordAllDlcId))
end

M.SetDownloadedMap = function(downloadedMap)
    -- local logTab = {}
    -- local count = 0
    -- for dlcId, need in pairs(downloadedMap) do
    --     count = count + 1
    --     table.insert(logTab, dlcId .. ":" .. tostring(need))
    -- end
    -- CsLog.Debug("[DLC] downloadedMap: count:" .. count ..", " .. tostring(table.concat(logTab, ";")))
    CsLog.Debug("[DLC] downloadedMap next:" .. tostring((next(downloadedMap))))
    DownloadedMap = downloadedMap
end

M.AddDownloadedMap = function(updateTable)
    local count = 0
    for name, info in pairs(updateTable) do
        if not DownloadedMap[name] then
            count = count + 1
        end
        DownloadedMap[name] = true
    end
    CsLog.Debug("[DLC] AddDownloadedMap, Count: " .. count)
end

-- 目前仅游戏内以Traditional下载方式时调用
M.SetDownloadedFile = function(name, downloaded)
    DownloadedMap[name] = downloaded
    -- CsLog.Debug("[DLC] SetDownloadedFile, downloaded:"..tostring(downloaded) .. ", file name " .. name)
end

M.SetDlcIndexInfo = function(dlcId, dlcIndexInfo) -- 记录size后即可丢弃
    DlcIndexInfo[dlcId] = dlcIndexInfo
end

M.IsNameDownloaded = function(name)
    return DownloadedMap[name]
end

-- 是否需要下载
M.CheckNeedDownload = function(dlcId, needShowSelect)
    if LaunchDownloadRecord[dlcId] == STATE_START then
        if needShowSelect then
            return false
        end
        return true
    end
    return false
end

-- 修正下载记录
M.SetDlcDownloadedRecord = function(dlcId, downloaded)
    DownloadedDic[dlcId] = downloaded and STATE_START or STATE_DEFAULT
    UnityPlayerPrefs.SetInt(KEY_DOWNLOADED .. dlcId, downloaded and STATE_START or STATE_DEFAULT)
end

-- 修正下载记录(仅本次)
M.FixDownloadedDlc = function(dlcId, downloaded)
    -- print(".. FixDownloadedDlc dlcId:" .. dlcId .. ", downloaded:" .. tostring(downloaded) .. "\n" .. debug.traceback())
    DownloadedDic[dlcId] = downloaded and STATE_START or STATE_DEFAULT
end

M.DoneDownloadInLaunch = function(dlcIds)
    for dlcId, v in pairs(LaunchDownloadRecord) do
        if v == STATE_START then
            DownloadedDic[dlcId] = STATE_START
            UnityPlayerPrefs.SetInt(KEY_DOWNLOADED .. dlcId, STATE_START)
        end
    end
end

M.HasDownloadedDlc = function(id)
    -- print("?? HasDownloadedDlc id:" .. id .. ", DownloadedDic[id]:" .. tostring(DownloadedDic[id]) .. "\n" .. debug.traceback())
    return DownloadedDic[id] == STATE_START
end

M.SetAllLaunchDownloadRecord = function()
    for i, dlcId in pairs(DlcIdList) do
        M.SetLaunchDownloadRecord(dlcId)
    end
end

-- 热更时选择下载策略
M.NeedShowSelect = function(appVer)
    if NeedLaunchTest then
        return true
    end

    if not M.CheckSubpackageOpen() then
        return false
    end

    --全部分包已经被标记下载完成过
    if IsRecordAllDlcId then
        return false
    end
    --调整为只有新包才会弹
    return UnityPlayerPrefs.GetInt(HAS_SELECT_DOWNLOAD_PART_KEY, STATE_DEFAULT) == STATE_DEFAULT
end

M.DoneSelect = function(appVer)
    --调整为只有新包才会弹
    UnityPlayerPrefs.SetInt(HAS_SELECT_DOWNLOAD_PART_KEY, STATE_START)
    UnityPlayerPrefs.Save()
end

--- 是否是整包下载， 只记录玩家的选择选项
---@return boolean
--------------------------
M.IsFullDownload = function()
    local state = UnityPlayerPrefs.GetInt(HAS_SELECT_ALL_DOWNLOAD_KEY, STATE_DEFAULT)
    return state == STATE_START
end

M.SetIsFullDownload = function(isFullDownload) 
    UnityPlayerPrefs.SetInt(HAS_SELECT_ALL_DOWNLOAD_KEY, isFullDownload and STATE_START or STATE_DEFAULT)
end

M.IsAllDlcIdRecord = function() 
    return IsRecordAllDlcId
end

-- 新增：记录已卸载的ResId
M.AddUninstalledResId = function(resId)
    if not resId then return end
    
    local str = UnityPlayerPrefs.GetString(KEY_UNINSTALLED_RESID_LIST, "")
    local dict = {}
    
    -- 解析旧数据防止重复
    for id in string.gmatch(str, "[^,]+") do
        dict[tonumber(id)] = true
    end
    
    if not dict[resId] then
        if str == "" then
            str = tostring(resId)
        else
            str = str .. "," .. tostring(resId)
        end
        UnityPlayerPrefs.SetString(KEY_UNINSTALLED_RESID_LIST, str)
        -- 立即保存，确保状态落地
        UnityPlayerPrefs.Save()
    end
end

-- 判断是否已经记录了该已卸载的 ResId
M.HasUninstalledResId = function(resId)
    if not resId then return false end
    
    local str = UnityPlayerPrefs.GetString(KEY_UNINSTALLED_RESID_LIST, "")
    if str == "" then return false end

    local targetId = tonumber(resId)
    for idStr in string.gmatch(str, "[^,]+") do
        if tonumber(idStr) == targetId then
            return true
        end
    end
    
    return false
end

-- 清除特定的已卸载 ResId 记录
M.RemoveUninstalledResId = function(resId)
    if not resId then return end
    
    local str = UnityPlayerPrefs.GetString(KEY_UNINSTALLED_RESID_LIST, "")
    if str == "" then return end

    local targetId = tonumber(resId)
    local idList = {}
    local isChanged = false

    -- 遍历并剔除目标 ID
    for idStr in string.gmatch(str, "[^,]+") do
        if tonumber(idStr) ~= targetId then
            table.insert(idList, idStr)
        else
            isChanged = true
        end
    end

    -- 如果发生了变化，重新拼接字符串并保存
    if isChanged then
        local newStr = table.concat(idList, ",")
        UnityPlayerPrefs.SetString(KEY_UNINSTALLED_RESID_LIST, newStr)
        UnityPlayerPrefs.Save()
        CsLog.Debug("[XLaunchDlcManager] RemoveUninstalledResId: " .. tostring(resId))
    end
end

M.ClearDownloadRecord = function(resId)
    if not resId or resId <= 0 then
        CsLog.Error("[XLaunchDlcManager] ClearDownloadRecord: resId 无效 -> " .. tostring(resId))
        return
    end

    -- 1. 清除：KEY_DOWNLOADED..resId
    UnityPlayerPrefs.SetInt(KEY_DOWNLOADED .. resId, STATE_DEFAULT)
    DownloadedDic[resId] = STATE_DEFAULT

    -- 2. 清除：KEY_LAUNCH_DOWNLOAD_RECORD..resId
    UnityPlayerPrefs.SetInt(KEY_LAUNCH_DOWNLOAD_RECORD .. resId, STATE_DEFAULT)
    LaunchDownloadRecord[resId] = STATE_DEFAULT

    -- 3. 按文件名删除 DownloadedMap 记录
    --（要求调用方提供 indexInfo，这里只删 ResId 对应的所有文件）
    local indexInfo = XMVCA.XSubPackage:GetSubIndexInfo()[resId]
    if indexInfo then
        for _, info in pairs(indexInfo) do
            local fileName = info[1]  -- fileName
            DownloadedMap[fileName] = nil
        end
    end

    UnityPlayerPrefs.Save()

    CsLog.Debug("[XLaunchDlcManager] ClearDownloadRecord 完成, resId = " .. tostring(resId))
end

M.SetLaunchDownloadRecord = function (id)
    local state = STATE_START
    CsLog.Debug("SetLaunchDownloadRecord:" .. tostring(id))
    LaunchDownloadRecord[id] = state
    UnityPlayerPrefs.SetInt(KEY_LAUNCH_DOWNLOAD_RECORD .. id, state)
end

M.SetRemoveResIdsRecord = function (resIdList)
    -- print("SP/DN SetRemoveResIdsRecord",resIdList,resIdList and resIdList[1], debug.traceback())
    if type(resIdList) == "table" then
        resIdList = table.concat(resIdList, ",")
    else
        resIdList = ""    
    end
    UnityPlayerPrefs.SetString(KEY_REMOVE_RESID_LIST, resIdList)
end

M.GetRemoveResIdsRecord = function()
    local resIdString = UnityPlayerPrefs.GetString(KEY_REMOVE_RESID_LIST)
    local resIdDic = {} -- key = resId, value = true
    if resIdString and resIdString ~= "" then
        for resIdStr in string.gmatch(resIdString, "[^,]+") do
            -- 过滤空字段
            if resIdStr ~= "" then
                local resId = tonumber(resIdStr)
                if resId then
                    resIdDic[resId] = true
                end
            end
        end
    end

    return resIdDic
end

M.IsSubPackageFinished = function(subPackageId)
    local key = KEY_SUBPACKAGE_FINISHED .. tostring(subPackageId)
    local val = UnityPlayerPrefs.GetInt(key, 0)
    return val == 1
end

M.SetSubPackageFinished = function(subPackageId, isFinished)
    local key = KEY_SUBPACKAGE_FINISHED .. tostring(subPackageId)
    local val = isFinished and 1 or 0
    UnityPlayerPrefs.SetInt(key, val)
    UnityPlayerPrefs.Save()
    CsLog.Debug("[XLaunchDlcManager] SetSubPackageFinished: " .. tostring(subPackageId) .. " -> " .. tostring(isFinished))
end

-- 检查分包是否处于激活状态（用户点过下载且没卸载）
M.IsSubPackageActive = function(subPackageId)
    if not subPackageId then return false end
    local key = KEY_SUBPACKAGE_ACTIVE .. tostring(subPackageId)
    local val = UnityPlayerPrefs.GetInt(key, 0)
    return val == 1
end

-- 设置分包激活状态
M.SetSubPackageActive = function(subPackageId, isActive)
    if not subPackageId then return end
    local key = KEY_SUBPACKAGE_ACTIVE .. tostring(subPackageId)
    local val = isActive and 1 or 0
    UnityPlayerPrefs.SetInt(key, val)
    UnityPlayerPrefs.Save()
    CsLog.Debug("[XLaunchDlcManager] SetSubPackageActive: " .. tostring(subPackageId) .. " -> " .. tostring(isActive))
end
--====启动逻辑接口 end=====


--======== 游戏业务层接口 begin ====

--- 清除需要下载的DlcId标记(仅仅本次）
--------------------------

M.CheckGameNeedDownload = function(dlcId)
    return not M.HasDownloadedDlc(dlcId)
end

M.GetPathModule = function()
    if not PathModule then
        PathModule = require("XLaunchAppPathModule")
    end
    return PathModule
end


---@return XLaunchFileModule
--------------------------
M.GetFileModule = function()
    if not FileModule then
        local FileModuleCreator = require("XLaunchFileModule")
        FileModule = FileModuleCreator()
    end
    return FileModule
end

M.GetVersionModule = function()
    if not VersionModule then
        VersionModule = require("XLaunchAppVersionModule")
    end
    return VersionModule
end

M.DoDownloadDlc = function(progressCb, doneCb, exitCb)
    CsLog.Error("此函数已经废弃，如果还有调用请联系牟文检查！")
    --local PathModule = M.GetPathModule()
    --local DocFileModule = M.GetFileModule()
    --local VersionModule = M.GetVersionModule()
    --DocFileModule.SetIsInGame(IsInGame)
    --XMVCA.XSubPackage:SetFileModule(DocFileModule)
    --DocFileModule.Check(RES_FILE_TYPE.MATRIX_FILE, PathModule, VersionModule, doneCb, progressCb, exitCb)
end

-- 游戏内调用下载
M.DownloadDlc = function (ids, processCb, doneCb, exitCb)
    CsLog.Error("此函数已经废弃，如果还有调用请联系牟文检查！")
   -- IsInGame = true
   -- --清除一下记录
   -- M.ClearGameDownloadRecord()
   -- --标记本次需要下载DLCId
   -- for _, id in pairs(ids) do
   --     M.SetGameDownloadRecord(id)
   -- end
   -- --CsLog.Error("Prepare Download" .. table.concat(ids, ", "))
   ---- todo 下载模块，无需界面
   ---- CS.XUiManager.Instance:OpenWithCallback("UiLaunch", function()
   --     M.DoDownloadDlc(processCb, 
   --         function(isPause)
   --             XLuaUiManager.Close("UiLaunch")
   --             if doneCb then
   --                 doneCb(isPause)
   --             end
   --         end, 
   --         function()
   --             XLuaUiManager.Close("UiLaunch")
   --             if exitCb then exitCb() end
   --         end)
   -- -- end)
end

M.GetIndexInfo = function()
    return DlcIndexInfo
end

--是否选中wifi自动下载
M.IsSelectWifiAutoDownload = function()
    --默认选中
    return UnityPlayerPrefs.GetInt(IS_SELECT_WIFI_AUTO_DOWNLOAD, STATE_START) == STATE_START
end

M.SetSelectWifiAutoDownloadValue = function(isSelect)
    local value = isSelect and STATE_START or STATE_DEFAULT
    UnityPlayerPrefs.SetInt(IS_SELECT_WIFI_AUTO_DOWNLOAD, value)
end

M.CheckSubpackageChannel = function()
    local channels = CS.XRemoteConfig.SubPackAppChannel --字符串，直接判断是否包含对应Id
    if channels == nil or #channels == 0 then
        return true
    end
    local channelId = tostring(CS.XHeroSdkAgent.GetChannelId())
    if channels == nil or channels == "nil" or channels == "0" then
        return false
    end
    local channelList = Split(channels)
    for _, channel in ipairs(channelList) do
        if string.find(channel, channelId) then
            return true
        end
    end
    return false
end

M.CheckSubpackageOpen = function()
    if CS.XResourceManager.NeedLaunchTest then
        return true
    end
    if CS.XUiPc.XUiPcManager.IsPcMode() then
        return false
    end

    --选择类型
    if CS.XRemoteConfig.LaunchSelectType == nil or CS.XRemoteConfig.LaunchSelectType == 0 then
        return false
    end

    --构建
    if not CS.XInfo.IsDlcBuild then
        return false
    end

    --提审模式
    if CS.XRemoteConfig.IsHideFunc then
        return false
    end
    
    return M.CheckSubpackageChannel()
end

--- 切割ResIds resId|resId|resId.... , 如果
---@return number[]
M.SplitResIds = function(value, isMap, cache, separator) 
    local resIds = cache or {}
    if value == nil or value == "" then
        return resIds
    end
    -- 兼容逗号和竖线分隔符
    local pattern = separator and ("[^" .. separator .. "]+") or "[^,|]+"
    for numStr in string.gmatch(tostring(value), pattern) do
        if numStr ~= "" then
            local num = tonumber(numStr)
            if num then
                if isMap then
                    resIds[num] = true
                else
                    resIds[#resIds + 1] = num
                end
            else
                error("无效数字格式: " .. numStr .. ", value: " .. tostring(value))
            end
        end
    end
    return resIds
end

M.CheckResIsIgnoreDownload = function(resId, needShowSelect, isOpen)
    --分包不开启，则不忽略
    if not isOpen then
        return false
    end
    --如果展示选择框，则不忽略，在玩家选择完之后剔除
    if needShowSelect then
        return false
    end
    --如果已经下载，则不忽略
    if XLaunchDlcManager.CheckNeedDownload(resId, needShowSelect) then
        return false
    end
    if not DlcIgnoreDownloadIfNotDownload then
        DlcIgnoreDownloadIfNotDownload = {}
        local keyStr = CS.XLaunchManager.LaunchConfig:GetString("LaunchIgnoreSelectResKey")
        local storage = CS.XLaunchManager.LaunchRemoveSelectSubPackageIds
        --为空则不忽略
        if storage == nil then
            return false
        end

        local subPackageMap = {}
        local subPackageStorage = CS.XLaunchManager.SubPackageTab
        if subPackageStorage then
            local spPairs = subPackageStorage.keyValuePairs
            for i = 0, spPairs.Length - 1 do
                local kv = spPairs[i]
                subPackageMap[kv.Key] = kv.Value
            end
        end

        if keyStr and keyStr ~= "" then
            local split = keyStr .. "|"
            local map = {}
            for key in string.gmatch(split, "([^|]*)|") do
                if key ~= "" then
                    map[key] = true
                end
            end
            for i = 0, storage.keyValuePairs.Length - 1 do
                local kv = storage.keyValuePairs[i]
                local k = kv.Key
                if map[k] then
                    for subId in string.gmatch(tostring(kv.Value), "[^,|]+") do
                        local resIdsStr = subPackageMap[subId]
                        if resIdsStr then
                            XLaunchDlcManager.SplitResIds(resIdsStr, true, DlcIgnoreDownloadIfNotDownload)
                        end
                    end
                end
            end
        end
    end
    --存在则不忽略
    return DlcIgnoreDownloadIfNotDownload[resId] ~= nil
end

--- 清理在热更阶段产生的local变量
M.ClearLaunchCache = function()
    DlcIgnoreDownloadIfNotDownload = nil
end

--======== 业务层接口 end ====

return XLaunchDlcManager