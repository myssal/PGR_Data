local XDlcRelinkFriend = require("XModule/XDlcRelink/XEntity/XDlcRelinkFriend")
---@class XDlcRelinkControl : XControl
---@field private _Model XDlcRelinkModel
local XDlcRelinkControl = XClass(XControl, "XDlcRelinkControl")
function XDlcRelinkControl:OnInit()
    --初始化内部变量
    self.RequestName = {}

    self.FriendCache = nil
    ---@type XDlcRelinkFriend[]
    self.FriendMap = {}
    self.FriendInfoSyncTime = 20
    self.LastFriendInfoSyncTime = 0
end

function XDlcRelinkControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XDlcRelinkControl:RemoveAgencyEvent()

end

function XDlcRelinkControl:OnRelease()
    --XLog.Error("这里执行Control的释放")
    self.FriendCache = nil
    self.FriendMap = {}
    self.LastFriendInfoSyncTime = 0
end

--region 通用

function XDlcRelinkControl:GetCurrentWorldIdAndLevelId()
    return self._Model:GetCurrentWorldIdAndLevelId()
end

function XDlcRelinkControl:OpenFriendInviteUi()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.SocialFriend) then
        return
    end

    local nowTime = XTime.GetServerNowTimestamp()
    if not self.FriendCache or self.LastFriendInfoSyncTime + self.FriendInfoSyncTime <= nowTime then
        local friendList = XDataCenter.SocialManager.GetFriendList()
        if XTool.IsTableEmpty(friendList) then
            self.FriendCache = {}
            self.FriendMap = {}
            XLuaUiManager.Open("UiRelinkPopupPlayerInvite", self.FriendCache)
            return
        end

        local playerIds = {}
        for _, friend in ipairs(friendList) do
            table.insert(playerIds, friend.FriendId)
        end

        XDataCenter.SocialManager.GetPlayerInfoListByServer(playerIds, function(friendInfoList)
            self.FriendCache = {}
            self.LastFriendInfoSyncTime = XTime.GetServerNowTimestamp()
            self:SortFriendList(friendInfoList)
            for i, friendInfo in ipairs(friendInfoList) do
                local cache = self.FriendMap[friendInfo.Id]
                if not cache then
                    cache = XDlcRelinkFriend.New()
                end
                cache:UpdateFriendData(friendInfo)
                self.FriendCache[i] = cache
                self.FriendMap[friendInfo.Id] = cache
            end
            XLuaUiManager.Open("UiRelinkPopupPlayerInvite", self.FriendCache)
        end)
    else
        XLuaUiManager.Open("UiRelinkPopupPlayerInvite", self.FriendCache)
    end
end

function XDlcRelinkControl:SortFriendList(friendInfoList)
    if not friendInfoList or #friendInfoList <= 1 then
        return friendInfoList or {}
    end
    table.sort(friendInfoList, Handler(self, self.SortFriendListHandler))
    return friendInfoList
end

function XDlcRelinkControl:SortFriendListHandler(friendA, friendB)
    if friendA.IsOnline ~= friendB.IsOnline then
        return friendA.IsOnline
    end

    if friendA.IsOnline then
        -- 都在线，按亲密度、等级降序
        if friendA.FriendExp ~= friendB.FriendExp then
            return friendA.FriendExp > friendB.FriendExp
        end
        return friendA.Level > friendB.Level
    else
        -- 都不在线，按最后登录时间、亲密度、等级降序
        if friendA.LastLoginTime ~= friendB.LastLoginTime then
            return friendA.LastLoginTime > friendB.LastLoginTime
        end
        if friendA.FriendExp ~= friendB.FriendExp then
            return friendA.FriendExp > friendB.FriendExp
        end
        return friendA.Level > friendB.Level
    end
end

function XDlcRelinkControl:CheckPlayerInRoom(playerId)
    if not XTool.IsNumberValid(playerId) then
        return false
    end
    if XMVCA.XDlcRoom:IsInRoom() then
        local team = XMVCA.XDlcRoom:GetTeam()
        return team and team:IsPlayerInTeam(playerId) or false
    end
    return false
end

function XDlcRelinkControl:GetLoadingTips()
    local tips = self._Model:GetClientConfigParams("LoadingTips")
    return XTool.RandomArray(tips, os.time())
end

--endregion

--region 角色表相关

function XDlcRelinkControl:GetCharacterIdList()
    -- TODO 临时读取全表 后期在改
    local characterIdList = {}
    local characterConfigs = self._Model:GetDlcRelinkCharacterConfigs()
    for _, config in pairs(characterConfigs) do
        if XTool.IsNumberValid(config.Id) then
            table.insert(characterIdList, config.Id)
        end
    end
    return characterIdList
end

function XDlcRelinkControl:GetCharacterSquareHeadImage(characterId)
    if not XTool.IsNumberValid(characterId) then
        return ""
    end
    return self._Model:GetDlcRelinkCharacterSquareHeadImage(characterId)
end

function XDlcRelinkControl:GetCharacterName(characterId)
    if not XTool.IsNumberValid(characterId) then
        return ""
    end
    return self._Model:GetDlcRelinkCharacterName(characterId)
end

function XDlcRelinkControl:GetCharacterTradeName(characterId)
    if not XTool.IsNumberValid(characterId) then
        return ""
    end
    return self._Model:GetDlcRelinkCharacterTradeName(characterId)
end

--endregion

--region World表相关

function XDlcRelinkControl:GetDlcRelinkWorldId()
    local worldId, levelId = self:GetCurrentWorldIdAndLevelId()
    if not XTool.IsNumberValid(worldId) or not XTool.IsNumberValid(levelId) then
        return nil
    end
    return string.format("%s%s", worldId, levelId)
end

function XDlcRelinkControl:GetCurrentWorldScene(worldId, levelId)
    local id
    if XTool.IsNumberValid(worldId) and XTool.IsNumberValid(levelId) then
        id = string.format("%s%s", worldId, levelId)
    else
        id = self:GetDlcRelinkWorldId()
    end
    if not id then
        return ""
    end
    return self._Model:GetDlcRelinkWorldSceneUrl(id)
end

function XDlcRelinkControl:GetCurrentWorldSceneModel(worldId, levelId)
    local id
    if XTool.IsNumberValid(worldId) and XTool.IsNumberValid(levelId) then
        id = string.format("%s%s", worldId, levelId)
    else
        id = self:GetDlcRelinkWorldId()
    end
    if not id then
        return ""
    end
    return self._Model:GetDlcRelinkWorldSceneModelUrl(id)
end

function XDlcRelinkControl:GetCurrentMaskLoadingType(worldId, levelId)
    local id
    if XTool.IsNumberValid(worldId) and XTool.IsNumberValid(levelId) then
        id = string.format("%s%s", worldId, levelId)
    else
        id = self:GetDlcRelinkWorldId()
    end
    if not id then
        return ""
    end
    return self._Model:GetDlcRelinkWorldMaskLoadingType(id)
end

function XDlcRelinkControl:GetCurrentWorldArtName()
    local id = self:GetDlcRelinkWorldId()
    if not id then
        return ""
    end
    return self._Model:GetDlcRelinkWorldArtName(id)
end

function XDlcRelinkControl:GetCurrentWorldLoadingBackground()
    local id = self:GetDlcRelinkWorldId()
    if not id then
        return ""
    end
    return self._Model:GetDlcRelinkWorldLoadingBackground(id)
end

--endregion

--region 客户端配置表相关

function XDlcRelinkControl:GetClientConfig(key, index)
    if not index then
        index = 1
    end
    return self._Model:GetClientConfig(key, index)
end

--endregion

--region 模型相关

function XDlcRelinkControl:GetCharacterModelId(characterId)
    local fashionId = self._Model:GetDlcRelinkCharacterDefaultNpcFashionId(characterId)
    local resourcesId = XDataCenter.FashionManager.GetResourcesId(fashionId)
    local modelId = XMVCA.XCharacter:GetCharResModel(resourcesId)
    return modelId
end

---@param roleModel XUiPanelRoleModel
function XDlcRelinkControl:UpdateCharacterModel(roleModel, characterId, targetPanelRole, targetUiName, callBack)
    if not roleModel or not XTool.IsNumberValid(characterId) then
        return
    end
    local modelId = self:GetCharacterModelId(characterId)
    --local fashionId = nil
    local weaponId = self._Model:GetDlcRelinkCharacterEquipId(characterId)
    local weaponFashionId = nil
    roleModel:UpdateRoleModel(modelId, targetPanelRole, targetUiName, function(model)
        if not XTool.IsNumberValid(weaponId) then
            if callBack then
                callBack()
            end
            return
        end
        roleModel:UpdateCharacterWeaponModels(characterId, modelId, callBack, true, weaponId, weaponFashionId)
    end)
    --roleModel:LoadResCharacterUiEffect(characterId, fashionId, weaponFashionId)
end

--endregion

return XDlcRelinkControl
