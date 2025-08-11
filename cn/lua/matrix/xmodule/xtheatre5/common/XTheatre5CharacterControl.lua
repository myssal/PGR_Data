---@class XTheatre5CharacterControl : XControl
---@field private _Model XTheatre5Model
---@field private _MainControl XTheatre5Control
local XTheatre5CharacterControl = XClass(XControl, "XTheatre5CharacterControl")

function XTheatre5CharacterControl:OnInit()

end

function XTheatre5CharacterControl:AddAgencyEvent()

end

function XTheatre5CharacterControl:RemoveAgencyEvent()

end

function XTheatre5CharacterControl:OnRelease()

end

--region 根据当前模式及角色数据，获取指定角色涂装配置相关接口

--- 根据指定角色Id，获取当前模式的角色应用的涂装Id
function XTheatre5CharacterControl:GetFashionIdByCharacterIdInCurMode(characterId)
    local fashionId = nil

    if self._Model:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameModel.PVP then
        fashionId = self._Model.PVPCharacterData:GetCharacterFashionId(characterId)
    else
        fashionId = self._Model.PVERougeData:GetCharacterFashionId(characterId)
    end

    if not XTool.IsNumberValid(fashionId) then
        -- 如果没有相关数据，则使用默认涂装
        local charaCfg = self._Model:GetTheatre5CharacterCfgById(characterId)

        if charaCfg then
            fashionId = charaCfg.FashionIds[XMVCA.XTheatre5.EnumConst.CharacterFashionIndexType.Default]
        end
    end
    
    return fashionId
end

--- 根据指定角色Id，获取当前模式的角色应用的涂装的配置
function XTheatre5CharacterControl:GetFashionCfgByCharacterIdInCurMode(characterId)
    local fashionId = self:GetFashionIdByCharacterIdInCurMode(characterId)

    if XTool.IsNumberValid(fashionId) then
        return self:GetTheatre5CharacterFashionCfgById(fashionId)
    end
end

--- 根据指定角色的Id获取其主线涂装Id（角色Id关联Theatre5Character表）
function XTheatre5CharacterControl:GetMainlineFashionIdByCharacterIdCurMode(characterId)
    local fashionCfg = self:GetFashionCfgByCharacterIdInCurMode(characterId)

    if fashionCfg then
        return XTool.IsNumberValid(fashionCfg.MainlineFashionId) and fashionCfg.MainlineFashionId or nil
    end
end

--- 根据指定角色的Id获取头像（角色Id关联Theatre5Character表）
function XTheatre5CharacterControl:GetPortraitByCharacterIdCurMode(characterId)
    local fashionCfg = self:GetFashionCfgByCharacterIdInCurMode(characterId)

    if fashionCfg then
        return fashionCfg.Portrait
    end
end

--- 根据指定角色的Id获取匹配立绘（角色Id关联Theatre5Character表）
function XTheatre5CharacterControl:GetMatchImgByCharacterIdCurMode(characterId)
    local fashionCfg = self:GetFashionCfgByCharacterIdInCurMode(characterId)

    if fashionCfg then
        return fashionCfg.MatchImg
    end
end

--- 根据指定角色的Id获取动画控制器（角色Id关联Theatre5Character表）
function XTheatre5CharacterControl:GetAnimatorControllerByCharacterIdCurMode(characterId)
    local fashionCfg = self:GetFashionCfgByCharacterIdInCurMode(characterId)

    if fashionCfg then
        return fashionCfg.AnimatorController
    end
end

--- 根据指定角色的Id获取切换待机动画（角色Id关联Theatre5Character表）
function XTheatre5CharacterControl:GetNormalIdleAnimaByCharacterIdCurMode(characterId)
    local fashionCfg = self:GetFashionCfgByCharacterIdInCurMode(characterId)

    if fashionCfg then
        return fashionCfg.NormalIdleAnima
    end
end

--- 根据指定角色的Id获取切换选中动画（角色Id关联Theatre5Character表）
function XTheatre5CharacterControl:GetChooseAnimaByCharacterIdCurMode(characterId)
    local fashionCfg = self:GetFashionCfgByCharacterIdInCurMode(characterId)

    if fashionCfg then
        return fashionCfg.ChooseAnima
    end
end

--- 根据指定角色的Id获取详情页待机动画（角色Id关联Theatre5Character表）
function XTheatre5CharacterControl:GetDetailIdleAnimaByCharacterIdCurMode(characterId)
    local fashionCfg = self:GetFashionCfgByCharacterIdInCurMode(characterId)

    if fashionCfg then
        return fashionCfg.DetailIdleAnima
    end
end

--endregion

--region Configs - Theatre5CharacterFashion

function XTheatre5CharacterControl:GetTheatre5CharacterFashionCfgById(id, notips)
    return self._Model:GetTheatre5CharacterFashionCfgById(id, notips)
end

function XTheatre5CharacterControl:GetMatchImgByFashionId(fashionId)
    local fashionCfg = self:GetTheatre5CharacterFashionCfgById(fashionId)

    if fashionCfg then
        return fashionCfg.MatchImg
    end
end

function XTheatre5CharacterControl:GetPortraitByFashionId(fashionId)
    local fashionCfg = self:GetTheatre5CharacterFashionCfgById(fashionId)

    if fashionCfg then
        return fashionCfg.Portrait
    end
end

function XTheatre5CharacterControl:GetAnimatorCtrlResPathByFashionId(fashionId)
    local fashionCfg = self:GetTheatre5CharacterFashionCfgById(fashionId)

    if fashionCfg then
        return fashionCfg.AnimatorController
    end
end

function XTheatre5CharacterControl:GetMainlineFashionIdByFashionId(fashionId)
    local fashionCfg = self:GetTheatre5CharacterFashionCfgById(fashionId)

    if fashionCfg then
        return fashionCfg.MainlineFashionId
    end
end

function XTheatre5CharacterControl:GetNormalIdleAnimaByFashionId(fashionId)
    local fashionCfg = self:GetTheatre5CharacterFashionCfgById(fashionId)

    if fashionCfg then
        return fashionCfg.NormalIdleAnima
    end
end

function XTheatre5CharacterControl:GetChooseAnimaByFashionId(fashionId)
    local fashionCfg = self:GetTheatre5CharacterFashionCfgById(fashionId)

    if fashionCfg then
        return fashionCfg.ChooseAnima
    end
end

function XTheatre5CharacterControl:GetDetailIdleAnimaByFashionId(fashionId)
    local fashionCfg = self:GetTheatre5CharacterFashionCfgById(fashionId)

    if fashionCfg then
        return fashionCfg.DetailIdleAnima
    end
end

--- 获取玩家默认涂装Id
function XTheatre5CharacterControl:GetDefaultFashionIdByCharacterId(characterId)
    local charaCfg = self._Model:GetTheatre5CharacterCfgById(characterId)

    if charaCfg then
        return charaCfg.FashionIds[XMVCA.XTheatre5.EnumConst.CharacterFashionIndexType.Default]
    end
end
--endregion

return XTheatre5CharacterControl