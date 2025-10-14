local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

---@class XUiPanelRace3DCamera : XUiNode 主界面场景相机
---@field Parent XUiRaceMain
---@field _Control XRaceControl
local XUiPanelRace3DCamera = XClass(XUiNode, "XUiPanelRace3DCamera")

local NodeCount = 8
local NameToLayer = CS.UnityEngine.LayerMask.NameToLayer
local SceneType = XEnumConst.Race.SceneType
local MainCam = 1
local RoundGuessRoleCam = 2
local MatchGuessRoleCam = 3
local GuessOptionCam = 4
local SettlementCam = 5

function XUiPanelRace3DCamera:OnStart(sceneType)
    self._SceneType = sceneType
    ---@type XUiPanelRoleModel[]
    self._RoleModels = {}
    self._StateName = self._Control:GetClientConfig("RaceMainRoleStateName")
    self._Offset = CS.UnityEngine.Vector3(0, self._Control:GetIntClientConfig("HUDOffsetY"), 0)
    self._Pivot = CS.UnityEngine.Vector2(0.5, 0.5)
    self._RoleIds = {}
end

---注册角色点击事件
function XUiPanelRace3DCamera:RegisterRoleClick()
    for i = 1, NodeCount do
        local input = self[string.format("Input%s", i)]
        if not XTool.UObjIsNil(input) then
            input:AddPointerClickListener(function()
                self:OnClickRole(i)
            end)
        end
    end
end

function XUiPanelRace3DCamera:ShowRole()
    if self._SceneType == SceneType.Normal then
        self:ShowRoundRole()
    end
end

function XUiPanelRace3DCamera:ShowRoundRole()
    self._RoleIds = self._Control:GetRoleRandomSite()
    if XTool.IsTableEmpty(self._RoleIds) then
        self:RandomRoleSite()
    end
    self:InitRole()
    self:ShowCamera(MainCam)
end

function XUiPanelRace3DCamera:RefreshRole()
    self:RandomRoleSite()
    self:InitRole()
end

function XUiPanelRace3DCamera:RandomRoleSite()
    local roundId
    local championRoleId --总冠军角色有特殊显示
    if self._Control:IsAllMatchFinish() then
        roundId = self._Control:GetFinalRoundId()
        local data = self._Control:GetEliminatorData(roundId)
        championRoleId = data:GetShowRoleId(1)
    else
        roundId = self._Control:GetCurRound()
    end

    self._RoleIds = XTool.Clone(self._Control:GetRoleIdsByRoundId(roundId))
    XTool.Shuffle(self._RoleIds) --随机角色位置
    self._Control:SetRoleRandomSite(self._RoleIds)
end

function XUiPanelRace3DCamera:InitRole()
    for i = 1, NodeCount do
        local roleId = self._RoleIds[i]
        local node = self[string.format("Role%s", i)]
        if XTool.UObjIsNil(node) then
            XLog.Error(string.format("节点%s不存在", i))
            goto continue
        end

        if roleId then
            self:LoadRole(node, roleId)
        else
            node.gameObject:SetActiveEx(false)
        end
        :: continue ::
    end
end

function XUiPanelRace3DCamera:LoadRole(node, roleId)
    local characterCfg = self._Control:GetRaceCharacterById(roleId)
    local model = node:LoadPrefab(characterCfg.CharacterModel)
    model:SetLayerRecursively(NameToLayer("UiNear"))
    CS.XShadowHelper.AddShadow(model.gameObject, true)
    ---@type UnityEngine.Animator
    local anim = model:GetComponent("Animator")
    if not XTool.UObjIsNil(anim) and not string.IsNilOrEmpty(self._StateName) then
        anim:CrossFade(self._StateName, 0.2, 0)
    end
end

function XUiPanelRace3DCamera:LoadOption()
    local path = self._Control:GetClientConfig("GuessOptionModel")
    local model = self.Option:LoadPrefab(path)
    model:SetLayerRecursively(NameToLayer("UiNear"))
end

function XUiPanelRace3DCamera:LookAt(roleId)
    if not roleId then
        return
    end
    
    self.Option.gameObject:SetActiveEx(false)
    self.RoleMatch.gameObject:SetActiveEx(self._SceneType == SceneType.MatchPredict)
    self.PanelSettleRoleModel.gameObject:SetActiveEx(self._SceneType == SceneType.Settlement)
    
    if self._SceneType == SceneType.MatchPredict then
        self:LoadRole(self.RoleMatch, roleId) --直接替换角色
        self:ShowCamera(MatchGuessRoleCam)
    elseif self._SceneType == SceneType.Settlement then
        self:LoadRole(self.PanelSettleRoleModel, roleId)
        self:ShowCamera(SettlementCam)
    else
        for i = 1, NodeCount do
            local node = self[string.format("Role%s", i)]
            if not XTool.UObjIsNil(node) then
                local isShow = self._RoleIds[i] == roleId
                node.gameObject:SetActiveEx(isShow)
            end
        end
        self:ShowCamera(RoundGuessRoleCam, table.indexof(self._RoleIds, roleId)) --摄像头滑动到角色上
    end
end

function XUiPanelRace3DCamera:ShowOption()
    self.Option.gameObject:SetActiveEx(true)
    self.RoleMatch.gameObject:SetActiveEx(false)
    for i = 1, NodeCount do
        local node = self[string.format("Role%s", i)]
        if not XTool.UObjIsNil(node) then
            node.gameObject:SetActiveEx(false)
        end
    end
    self:ShowCamera(GuessOptionCam)
end

function XUiPanelRace3DCamera:ShowCamera(cameraType, camIndex)
    self.UiMainCamFar.gameObject:SetActiveEx(cameraType == MainCam)
    self.UiMainCamNear.gameObject:SetActiveEx(cameraType == MainCam)
    self.UiChangeCamNearMatch.gameObject:SetActiveEx(cameraType == MatchGuessRoleCam)
    self.UiChangeCamNearOption.gameObject:SetActiveEx(cameraType == GuessOptionCam)
    self.UiChangeCamFarFightSettlement.gameObject:SetActiveEx(cameraType == SettlementCam)
    self.UiChangeCamNearFightSettlement.gameObject:SetActiveEx(cameraType == SettlementCam)

    for i = 1, NodeCount do
        local farCam = self[string.format("UiChangeCamFar%s", i)]
        if not XTool.UObjIsNil(farCam) then
            farCam.gameObject:SetActiveEx(cameraType == RoundGuessRoleCam and i == camIndex)
        end

        local nearCam = self[string.format("UiChangeCamNear%s", i)]
        if not XTool.UObjIsNil(nearCam) then
            nearCam.gameObject:SetActiveEx(cameraType == RoundGuessRoleCam and i == camIndex)
        end
    end
end

function XUiPanelRace3DCamera:OnClickRole(index)
    local roleId = self._RoleIds[index]
    if not roleId then
        return
    end
    local info = self._Control:GetCurRoundInfo()
    if info.State ~= XEnumConst.Race.RoundState.Guess then
        return
    end
    XLuaUiManager.Open("UiRacePredict", roleId)
end

function XUiPanelRace3DCamera:SetViewPosToTransformLocalPosition(uiTransform, roleId)
    if XTool.UObjIsNil(self.UiNearCamera) then
        return
    end
    if self._SceneType == SceneType.MatchPredict then
        if not XTool.UObjIsNil(self.RoleMatch) then
            CS.XUiHelper.SetViewPosToTransformLocalPosition(self.UiNearCamera, uiTransform, self.RoleMatch, self._Offset, self._Pivot)
        end
        return
    end
    if XTool.IsTableEmpty(self._RoleIds) then
        return
    end
    local site = table.indexof(self._RoleIds, roleId)
    if site == -1 then
        return
    end
    local node = self[string.format("Role%s", site)]
    if XTool.UObjIsNil(node) then
        return
    end
    CS.XUiHelper.SetViewPosToTransformLocalPosition(self.UiNearCamera, uiTransform, node, self._Offset, self._Pivot)
end

return XUiPanelRace3DCamera
