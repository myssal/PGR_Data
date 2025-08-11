---@class XUiModelTheatre5PVPCharacter3D: XUiNode
local XUiModelTheatre5PVPCharacter3D = XClass(XUiNode, 'XUiModelTheatre5PVPCharacter3D')
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

function XUiModelTheatre5PVPCharacter3D:OnStart()
    if self.PanelRoleModel then
        ---@type XUiPanelRoleModel
        self.UiPanelRoleModel = XUiPanelRoleModel.New(self.PanelRoleModel, self.Parent.GameObject.name, true)
        self.UiPanelRoleModel:ShowRoleModel()
    end
end

function XUiModelTheatre5PVPCharacter3D:OnEnable()
    self:PlayAnimation('Enable')
end

function XUiModelTheatre5PVPCharacter3D:UpdateRoleModelByHand(characterId, fashionId, runtimeControllerName)
    if not self.UiPanelRoleModel then
        return
    end
    
    --获取时装ModelName
    local resourcesId
    if fashionId then
        resourcesId = XDataCenter.FashionManager.GetResourcesId(fashionId)
    else
        resourcesId = XDataCenter.FashionManager.GetFashionResourceIdByCharId(characterId)
    end

    local fashionModelName

    if resourcesId then
        fashionModelName = XMVCA.XCharacter:GetCharResModel(resourcesId)
    else
        fashionModelName = XDisplayManager.GetModelName(characterId)
    end

    local isSpecialModel, isMultiModel = XModelManager.CheckModelIsSpecial(fashionModelName, self.UiPanelRoleModel.RefName)
    -- 特殊模型 && 非多重模型
    if isSpecialModel and not isMultiModel then
        fashionModelName = XModelManager.GetSpecialModelId(fashionModelName, self.UiPanelRoleModel.RefName)
    end

    self.UiPanelRoleModel:UpdateCharacterModel(characterId, nil, self.UiPanelRoleModel.RefName, nil, nil, fashionId, nil, nil, nil, true)
    -- 加载animationController
    local runtimeController = CS.LoadHelper.LoadUiController(runtimeControllerName, self.UiPanelRoleModel.RefName)

    if runtimeController == nil or not runtimeController:Exist() then
        XLog.Error("XUiPanelDisplay RefreshSelf 错误: 展示角色的动画状态机加载失败: 状态机名称 " .. runtimeControllerName .. " Ui名称：" .. self.UiPanelRoleModel.RefName)
        return
    end

    local animator = self.UiPanelRoleModel:GetAnimator()

    if animator then
        animator.runtimeAnimatorController = runtimeController
        ---@type UnityEngine.GameObject
        local loadAnimatioClip = animator.gameObject:GetComponent(typeof(CS.XLoadAnimationClip))

        if loadAnimatioClip then
            CS.UnityEngine.Component.Destroy(loadAnimatioClip)
        end

        -- 重新加载特效
        local actionId = self.UiPanelRoleModel:GetPlayingStateName(0) -- 0:只展示身体

        local weaponFashionId
        if XRobotManager.CheckIsRobotId(characterId) then
            local robotId = characterId
            characterId = XRobotManager.GetCharacterId(robotId)
            weaponFashionId = XRobotManager.GetRobotWeaponFashionId(robotId)
        end
        self.UiPanelRoleModel:LoadCharacterUiEffect(characterId, actionId, nil, weaponFashionId, nil)
    end
end


return XUiModelTheatre5PVPCharacter3D