---@class XBigWorldModel : XModel
local XBigWorldModel = XClass(XModel, "XBigWorldModel")

local GuideTableKey = {
    BigWorldGuideGroup = "Share/BigWorld/Common/Guide/BigWorldGuideGroup.tab",
    BigWorldGuideComplete = "Share/BigWorld/Common/Guide/BigWorldGuideComplete.tab",
}

function XBigWorldModel:OnInit()
    local identifier = "Id"
    local readInt = XConfigUtil.ReadType.Int
    local config = {
        [GuideTableKey.BigWorldGuideGroup] = {
            readInt,
            XTable.XTableGuideGroup,
            identifier,
            XConfigUtil.CacheType.Normal,
        },
        [GuideTableKey.BigWorldGuideComplete] = {
            readInt,
            XTable.XTableGuideComplete,
            identifier,
            XConfigUtil.CacheType.Normal,
        }
    }
    self._ConfigUtil:InitConfig(config)
    
    self._FinishOpenGuideIdDict = {}
end

function XBigWorldModel:ClearPrivate()
end

function XBigWorldModel:ResetAll()
end

function XBigWorldModel:GetCookieKey(key)
    return string.format("BIG_WORLD_%s_%s_%s", self._Id, XPlayer.Id, key)
end

---@return table<number, XTableGuideGroup>
function XBigWorldModel:GetBigWorldGuideGroupTemplates()
    return self._ConfigUtil:Get(GuideTableKey.BigWorldGuideGroup)
end

---@return XTableGuideGroup
function XBigWorldModel:GetBigWorldGuideGroupTemplateById(guideId)
    return self._ConfigUtil:GetCfgByPathAndIdKey(GuideTableKey.BigWorldGuideGroup, guideId)
end

---@return table<number, XTableGuideComplete>
function XBigWorldModel:GetBigWorldGuideCompleteTemplates()
    return self._ConfigUtil:Get(GuideTableKey.BigWorldGuideComplete)
end

---@return XTableGuideComplete
function XBigWorldModel:GetBigWorldGuideCompleteTemplateById(completeId)
    return self._ConfigUtil:GetCfgByPathAndIdKey(GuideTableKey.BigWorldGuideComplete, completeId)
end

function XBigWorldModel:UpdateFinishGuideDict(idList)
    if not idList then
        return
    end
    for _, guideId in pairs(idList) do
        self._FinishOpenGuideIdDict[guideId] = true
    end
end

function XBigWorldModel:AddFinishGuideDict(guideId)
    self._FinishOpenGuideIdDict[guideId] = true
end

function XBigWorldModel:CheckOpenGuideFinish(guideId)
    return self._FinishOpenGuideIdDict[guideId] ~= nil
end

return XBigWorldModel