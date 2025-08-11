--- 专门管理场景模型的类
---@class XUiModelTheatre5ChooseCharacter3D: XUiNode
---@field private _Control XTheatre5Control
local XUiModelTheatre5ChooseCharacter3D = XClass(XUiNode, 'XUiModelTheatre5ChooseCharacter3D')
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XTheatre5CharacterAnimatorFSM = require('XModule/XTheatre5/XTheatre5CharacterAnimatorFSM')

local DefaultRoleAnimaName = "StandAct0101"

function XUiModelTheatre5ChooseCharacter3D:OnEnable()
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_CHARACTER_FASHION_CHANGED, self.RefreshCharacterShow, self)
end

function XUiModelTheatre5ChooseCharacter3D:OnDisable()
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_CHARACTER_FASHION_CHANGED, self.RefreshCharacterShow, self)
end

function XUiModelTheatre5ChooseCharacter3D:OnDestroy()
    self.CharacterCfgs = nil
end

function XUiModelTheatre5ChooseCharacter3D:LoadCharacters(characterCfgs)
    ---@type XUiPanelRoleModel[]
    self.UiPanelRoleModels = {}
    ---@type XTableTheatre5Character[]
    self.CharacterCfgs = characterCfgs
    ---@type XTheatre5CharacterAnimatorFSM[]
    self.CharacterAnimFSM = {}
    
    self.CharaId2UiModelMap = {}
    self.CharaId2AnimFSMMap = {}
    
    for i = 1, #characterCfgs do
        local root = self['PanelRoleModel'..i]

        if root then
            local cfg = self.CharacterCfgs[i]
            local mainlineFashionId = self._Control.CharacterControl:GetMainlineFashionIdByCharacterIdCurMode(cfg.Id)
            local animatorController = self._Control.CharacterControl:GetAnimatorControllerByCharacterIdCurMode(cfg.Id)
            
            self.UiPanelRoleModels[i] = XUiPanelRoleModel.New(root, 'UiTheatre5ChooseCharacter', true, true)
            self:UpdateRoleModelByHand(self.UiPanelRoleModels[i], cfg.CharacterId, mainlineFashionId, animatorController)
            self.UiPanelRoleModels[i]:ShowRoleModel()
            
            self.CharacterAnimFSM[i] = XTheatre5CharacterAnimatorFSM.New(i, self, XMVCA.XTheatre5.EnumConst.CharacterAnimaState.FullView)

            self.CharaId2UiModelMap[cfg.Id] = self.UiPanelRoleModels[i]
            self.CharaId2AnimFSMMap[cfg.Id] = self.CharacterAnimFSM[i]
        else
            break
        end
        
    end
end

function XUiModelTheatre5ChooseCharacter3D:RefreshCharacterShow(charaCfg)
    if not charaCfg then
        return
    end
    
    local uiModel = self.CharaId2UiModelMap[charaCfg.Id]

    if uiModel then
        local mainlineFashionId = self._Control.CharacterControl:GetMainlineFashionIdByCharacterIdCurMode(charaCfg.Id)
        local animatorController = self._Control.CharacterControl:GetAnimatorControllerByCharacterIdCurMode(charaCfg.Id)

        self:UpdateRoleModelByHand(uiModel, charaCfg.CharacterId, mainlineFashionId, animatorController)
        
        -- 显示刷新特效
        local posPoint = self['ModelChangedEffectRoot'..self._CurFocusIndex]

        if posPoint then
            if self.FxUiHuanRen then
                self.FxUiHuanRen.transform.position = posPoint.transform.position
                self.FxUiHuanRen:PlayWithEnable()
            end
        end
    end
    
    local fsm = self.CharaId2AnimFSMMap[charaCfg.Id]

    if fsm then
        fsm:RefreshState()
    end
end

function XUiModelTheatre5ChooseCharacter3D:RefreshAllCharacterAnimation()
    if not XTool.IsTableEmpty(self.CharaId2AnimFSMMap) then
        for i, fsm in pairs(self.CharaId2AnimFSMMap) do
            fsm:RefreshState()
        end
    end
end

function XUiModelTheatre5ChooseCharacter3D:SetCharactersVisible(characters, enable)
    if XTool.IsTableEmpty(characters) then
        return
    end
    for _, characterId in pairs(characters) do
        local root = self['PanelRoleModel'..characterId]
        if root then
            root.gameObject:SetActiveEx(enable)
        end    
    end    
end

---@param panelRoleModel XUiPanelRoleModel
function XUiModelTheatre5ChooseCharacter3D:UpdateRoleModelByHand(panelRoleModel, characterId, fashionId, runtimeControllerName)
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

    local isSpecialModel, isMultiModel = XModelManager.CheckModelIsSpecial(fashionModelName, panelRoleModel.RefName)
    -- 特殊模型 && 非多重模型
    if isSpecialModel and not isMultiModel then
        fashionModelName = XModelManager.GetSpecialModelId(fashionModelName, panelRoleModel.RefName)
    end
    
    panelRoleModel:UpdateCharacterModel(characterId, nil, panelRoleModel.RefName, nil, nil, fashionId, nil, nil, nil, true)
    -- 加载animationController
    local runtimeController = CS.LoadHelper.LoadUiController(runtimeControllerName, panelRoleModel.RefName)

    if runtimeController == nil or not runtimeController:Exist() then
        XLog.Error("XUiPanelDisplay RefreshSelf 错误: 展示角色的动画状态机加载失败: 状态机名称 " .. runtimeControllerName .. " Ui名称：" .. panelRoleModel.RefName)
        return
    end
    
    local animator = panelRoleModel:GetAnimator()
    
    if animator then
        XModelManager.HandleUiModelNodeActive(DefaultRoleAnimaName, panelRoleModel.CurRoleName, panelRoleModel:GetCurRoleModel(), false)
        animator.runtimeAnimatorController = runtimeController
        ---@type UnityEngine.GameObject
        local loadAnimatioClip = animator.gameObject:GetComponent(typeof(CS.XLoadAnimationClip))

        if loadAnimatioClip then
            CS.UnityEngine.Component.Destroy(loadAnimatioClip)
        end
        
        -- 重新加载特效
        local actionId = panelRoleModel:GetPlayingStateName(0) -- 0:只展示身体

        local weaponFashionId
        if XRobotManager.CheckIsRobotId(characterId) then
            local robotId = characterId
            characterId = XRobotManager.GetCharacterId(robotId)
            weaponFashionId = XRobotManager.GetRobotWeaponFashionId(robotId)
        end
        panelRoleModel:LoadCharacterUiEffect(characterId, actionId, nil, weaponFashionId, nil)

    end
end

function XUiModelTheatre5ChooseCharacter3D:SetCharacterFocus(index)
    if self._CurFocusIndex == index then
        return
    end

    if XTool.IsNumberValid(self._CurFocusIndex) then
        -- 取消动画
        local animaFsm = self.CharacterAnimFSM[self._CurFocusIndex]
        
        if animaFsm then
            animaFsm:SetState(XMVCA.XTheatre5.EnumConst.CharacterAnimaState.FullView)
        end
    end

    self._CurFocusIndex = index
    
    -- 切换相机
    for i = 1, 100 do
        local farCam = self['UiCamFarCharacter'..i]
        local nearCam = self['UiCamNearCharacter'..i]

        if not farCam and not nearCam then
            break
        end

        farCam.gameObject:SetActiveEx(i == index)
        nearCam.gameObject:SetActiveEx(i == index)
    end

    -- 播放选中动画
    local animaFsm = self.CharacterAnimFSM[index]

    if animaFsm then
        animaFsm:SetState(XMVCA.XTheatre5.EnumConst.CharacterAnimaState.Choose)
    end
end

--- 由状态机内部传参调用
function XUiModelTheatre5ChooseCharacter3D:PlayAnimaCross(index, type, noCross)
    local roleModel = self.UiPanelRoleModels[index]
    local charaCfg = self.CharacterCfgs[index]
    
    if roleModel and charaCfg then
        local anima = nil
        
        ---@type XTableTheatre5CharacterFashion
        local curFashionCfg = self._Control.CharacterControl:GetFashionCfgByCharacterIdInCurMode(charaCfg.Id)
        
        if type == XMVCA.XTheatre5.EnumConst.CharacterAnimaType.FullView then
            anima = curFashionCfg.NoChooseAnima
        elseif type == XMVCA.XTheatre5.EnumConst.CharacterAnimaType.FullViewSwitch then
            anima = curFashionCfg.NoChooseSwitchAnima
        elseif type == XMVCA.XTheatre5.EnumConst.CharacterAnimaType.Choose then
            anima = curFashionCfg.ChooseAnima
        elseif type == XMVCA.XTheatre5.EnumConst.CharacterAnimaType.ChooseSwitch then
            anima = curFashionCfg.ChooseSwitchAnima
        elseif type == XMVCA.XTheatre5.EnumConst.CharacterAnimaType.Detail then
            anima = curFashionCfg.DetailIdleAnima
        end

        if not string.IsNilOrEmpty(anima) then
            if noCross then
                roleModel:PlayAnima(anima)
            else
                roleModel:PlayAnimaCross(anima)
            end
        end
    end
end

return XUiModelTheatre5ChooseCharacter3D