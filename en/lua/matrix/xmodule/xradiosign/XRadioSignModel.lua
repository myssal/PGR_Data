local TableKey = {
    RadioSignClientConfig = { DirPath = XConfigUtil.DirectoryType.Client },
    RadioSignActivity = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
    RadioSignContent = { DirPath = XConfigUtil.DirectoryType.Share, CacheType = XConfigUtil.CacheType.Normal },
}

---@class XRadioSignModel : XModel
local XRadioSignModel = XClass(XModel, "XRadioSignModel")
function XRadioSignModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ConfigUtil:InitConfigByTableKey("RadioSign", TableKey)

    self._ActivityId = 0
    self._ContentRecords = false
end

function XRadioSignModel:ClearPrivate()
end

function XRadioSignModel:ResetAll()
    --这里执行重登数据清理
    self._ActivityId = 0
    self._ContentRecords = false
end

----------public start----------

function XRadioSignModel:SetDataFromServer(data)
    self._ActivityId = data.ActivityId
    self._ContentRecords = data.SignContentIds
end

function XRadioSignModel:GetClientConfig()
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RadioSignClientConfig, "ClientConfig", true)
    return config
end

---@return XTableRadioSignActivity
function XRadioSignModel:GetActivityConfig()
    local activityId = self._ActivityId
    if not activityId or activityId == 0 then
        return nil
    end
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RadioSignActivity, activityId, true)
    return config
end

---@return XTableRadioSignContent[]
function XRadioSignModel:GetContentConfigs()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.RadioSignContent)
    return configs
end

function XRadioSignModel:GetContentConfig(contentId)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.RadioSignContent, contentId, true)
    return config
end

function XRadioSignModel:IsContentReceived(contentId)
    if self._ContentRecords then
        for i, signedId in pairs(self._ContentRecords) do
            if signedId == contentId then
                return true
            end
        end
    end
    return false
end

-- 添加已领取的contentId到缓存
---@param contentId number
function XRadioSignModel:AddContentReceived(contentId)
    if not contentId or contentId == 0 then
        return
    end
    
    -- 如果已经存在，不重复添加
    if self:IsContentReceived(contentId) then
        return
    end
    
    -- 初始化_ContentRecords（如果为false或nil）
    if not self._ContentRecords then
        self._ContentRecords = {}
    end
    
    -- 添加到数组中
    table.insert(self._ContentRecords, contentId)
    XLog.Debug("[XRadioSignModel] AddContentReceived: 添加contentId到缓存, contentId =", contentId)
end

---@return XTableRadioSignClientConfig[]
function XRadioSignModel:GetClientConfigs()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.RadioSignClientConfig)
    return configs
end

return XRadioSignModel