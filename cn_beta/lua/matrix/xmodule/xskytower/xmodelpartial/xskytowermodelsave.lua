---Model部分类，此处用于定义和本地缓存相关的读写逻辑
---@type XSkyTowerModel
local XSkyTowerModel = XClassPartial('XSkyTowerModel')

local SAVE_KEY_ACTIVITY = "SAVE_KEY_ACTIVITY" --跟随活动期数变化

function XSkyTowerModel:OnInitSave()
    self._SaveUtil:SetCustomVersionGetFunc(handler(self, self.GetActivityVersion), SAVE_KEY_ACTIVITY)
end

function XSkyTowerModel:GetActivityVersion()
    return self._ActivityId
end

--region 首次进入活动
--- 是否首次进入活动
---@return boolean
function XSkyTowerModel:IsFirstEnterActivity()
    return self._SaveUtil:GetDataByBlockKey(SAVE_KEY_ACTIVITY, "EnterActivity") ~= true
end

--- 标记已经进入过活动
function XSkyTowerModel:MarkFirstEnterActivity()
    self._SaveUtil:SaveDataByBlockKey(SAVE_KEY_ACTIVITY, "EnterActivity", true)
end

--endregion

--region 菜单红点
--- 获取菜单页签红点已记录的数量
---@param tabId number
---@return number
function XSkyTowerModel:GetMenuRedPointMarkCount(tabId)
    local key = string.format("MenuTab_%s", tabId)
    return self._SaveUtil:GetDataByBlockKey(SAVE_KEY_ACTIVITY, key) or 0
end

--- 记录菜单页签红点的数量
---@param tabId number
---@param count number
function XSkyTowerModel:SaveMenuRedPointMarkCount(tabId, count)
    local key = string.format("MenuTab_%s", tabId)
    self._SaveUtil:SaveDataByBlockKey(SAVE_KEY_ACTIVITY, key, count)
end

--endregion

--region 演出红点
--- 演出红点是否已经标记
---@param performId number
---@return boolean
function XSkyTowerModel:IsPerformRedPointMarked(performId)
    local key = string.format("Perform_%s", performId)
    return self._SaveUtil:GetDataByBlockKey(SAVE_KEY_ACTIVITY, key) == true
end

--- 标记演出红点
---@param performId number
function XSkyTowerModel:MarkPerformRedPoint(performId)
    local key = string.format("Perform_%s", performId)
    self._SaveUtil:SaveDataByBlockKey(SAVE_KEY_ACTIVITY, key, true)
end

--endregion

---@return boolean
function XSkyTowerModel:GetSetting(key)
    local value = self._SaveUtil:GetDataByBlockKey(SAVE_KEY_ACTIVITY, key)
    --没有存过时按默认开启处理
    if value == nil then
        return true
    end
    return value
end

function XSkyTowerModel:SaveSetting(key, value)
    self._SaveUtil:SaveDataByBlockKey(SAVE_KEY_ACTIVITY, key, value)
end

---获取最近一次点击开始游戏的时间
function XSkyTowerModel:GetEntranceTime()
    if not self._EntranceTime then
        self._EntranceTime = self._SaveUtil:GetDataByBlockKey(SAVE_KEY_ACTIVITY, "EntranceTime") or 0
    end
    return self._EntranceTime
end

--更新点击开始游戏的时间
function XSkyTowerModel:UpdateEntranceTime()
    self._EntranceTime = XTime.GetServerNowTimestamp()
    self._SaveUtil:SaveDataByBlockKey(SAVE_KEY_ACTIVITY, "EntranceTime", self._EntranceTime)
end

return XSkyTowerModel
