--=============
--配置表枚举
--ReadFunc : 读取表格的方法，默认为XConfigUtil.ReadType.Int
--DirPath : 读取的文件夹类型XConfigUtil.DirectoryType，默认是Share
--Identifier : 读取表格的主键名，默认为Id
--TableDefinedName : 表定于名，默认同表名
--CacheType : 配置表缓存方式，默认XConfigUtil.CacheType.Private
--=============
local DlcRelinkTableKey = {
    DlcRelinkActivity = { CacheType = XConfigUtil.CacheType.Normal },
    DlcRelinkCharacter = {},
    DlcRelinkWorld = {
        ReadFunc = XConfigUtil.ReadType.String,
        DirPath = XConfigUtil.DirectoryType.Client,
    },
    DlcRelinkClientConfig = {
        CacheType = XConfigUtil.CacheType.Normal,
        ReadFunc = XConfigUtil.ReadType.String,
        DirPath = XConfigUtil.DirectoryType.Client,
        Identifier = "Key",
    }
}

---@class XDlcRelinkModel : XModel
---@field ActivityData XDlcRelinkActivity
local XDlcRelinkModel = XClass(XModel, "XDlcRelinkModel")
function XDlcRelinkModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ConfigUtil:InitConfigByTableKey("DlcWorld/DlcRelink", DlcRelinkTableKey)
end

function XDlcRelinkModel:ClearPrivate()
    --这里执行内部数据清理
end

function XDlcRelinkModel:ResetAll()
    --这里执行重登数据清理
    self.ActivityData = nil
end

--region 服务端信息更新和获取

function XDlcRelinkModel:NotifyActivityData(data)
    if not self.ActivityData then
        self.ActivityData = require("XModule/XDlcRelink/XEntity/XDlcRelinkActivity").New()
    end
    self.ActivityData:NotifyActivityData(data)
end

--endregion

--region 活动表相关

---@return XTableDlcRelinkActivity
function XDlcRelinkModel:GetActivityConfig()
    if not self.ActivityData then
        return nil
    end
    local curActivityId = self.ActivityData:GetActivityId()
    if not XTool.IsNumberValid(curActivityId) then
        return nil
    end
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkActivity, curActivityId)
end

-- 获取活动时间Id
function XDlcRelinkModel:GetActivityTimeId()
    local config = self:GetActivityConfig()
    return config and config.TimeId or 0
end

-- 获取世界Id
function XDlcRelinkModel:GetWorldId()
    local config = self:GetActivityConfig()
    return config and config.WorldId or 0
end

function XDlcRelinkModel:GetCurrentWorldIdAndLevelId()
    local worldId = self:GetWorldId()
    local levelId = 90002
    return worldId, levelId
end

--endregion

--region 角色表相关

---@return XTableDlcRelinkCharacter[]
function XDlcRelinkModel:GetDlcRelinkCharacterConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkCharacter)
end

---@return XTableDlcRelinkCharacter
function XDlcRelinkModel:GetDlcRelinkCharacterConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkCharacter, id)
end

function XDlcRelinkModel:GetDlcRelinkCharacterNpcId(id)
    local config = self:GetDlcRelinkCharacterConfig(id)
    return config and config.NpcId or 0
end

function XDlcRelinkModel:GetDlcRelinkCharacterName(id)
    local config = self:GetDlcRelinkCharacterConfig(id)
    return config and config.Name or ""
end

function XDlcRelinkModel:GetDlcRelinkCharacterTradeName(id)
    local config = self:GetDlcRelinkCharacterConfig(id)
    return config and config.TradeName or ""
end

function XDlcRelinkModel:GetDlcRelinkCharacterEquipId(id)
    local config = self:GetDlcRelinkCharacterConfig(id)
    return config and config.EquipId or 0
end

function XDlcRelinkModel:GetDlcRelinkCharacterDefaultNpcFashionId(id)
    local config = self:GetDlcRelinkCharacterConfig(id)
    return config and config.DefaultNpcFashionId or 0
end

function XDlcRelinkModel:GetDlcRelinkCharacterSquareHeadImage(id)
    local config = self:GetDlcRelinkCharacterConfig(id)
    return config and config.SquareHeadImage or ""
end

--endregion

--region World表相关

---@return XTableDlcRelinkWorld[]
function XDlcRelinkModel:GetDlcRelinkWorldConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkWorld)
end

---@return XTableDlcRelinkWorld
function XDlcRelinkModel:GetDlcRelinkWorldConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkWorld, id)
end

function XDlcRelinkModel:GetDlcRelinkWorldIcon(id)
    local config = self:GetDlcRelinkWorldConfig(id)
    return config and config.Icon or ""
end

function XDlcRelinkModel:GetDlcRelinkWorldSceneUrl(id)
    local config = self:GetDlcRelinkWorldConfig(id)
    return config and config.SceneUrl or ""
end

function XDlcRelinkModel:GetDlcRelinkWorldSceneModelUrl(id)
    local config = self:GetDlcRelinkWorldConfig(id)
    return config and config.SceneModelUrl or ""
end

function XDlcRelinkModel:GetDlcRelinkWorldLoadingBackground(id)
    local config = self:GetDlcRelinkWorldConfig(id)
    return config and config.LoadingBackground or ""
end

function XDlcRelinkModel:GetDlcRelinkWorldArtName(id)
    local config = self:GetDlcRelinkWorldConfig(id)
    return config and config.ArtName or ""
end

function XDlcRelinkModel:GetDlcRelinkWorldMaskLoadingType(id)
    local config = self:GetDlcRelinkWorldConfig(id)
    return config and config.MaskLoadingType or ""
end

function XDlcRelinkModel:GetDlcRelinkWorldSettlementUiName(id)
    local config = self:GetDlcRelinkWorldConfig(id)
    return config and config.SettlementUiName or ""
end

--endregion

--region 客户端配置表相关

function XDlcRelinkModel:GetClientConfig(key, index)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkClientConfig, key)
    if not config then
        return nil
    end
    return config.Params and config.Params[index] or ""
end

function XDlcRelinkModel:GetClientConfigParams(key)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkClientConfig, key)
    if not config then
        return nil
    end
    return config.Params
end

--endregion

return XDlcRelinkModel
