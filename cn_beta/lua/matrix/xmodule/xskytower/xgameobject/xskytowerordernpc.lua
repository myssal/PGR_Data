local XSkyTowerChar = require("XModule/XSkyTower/XGameObject/XSkyTowerChar")

---@class XSkyTowerOrderNpc : XSkyTowerChar
local XSkyTowerOrderNpc = XClass(XSkyTowerChar, "XSkyTowerOrderNpc")

function XSkyTowerOrderNpc:Init()

end

function XSkyTowerOrderNpc:SetGameObject(basePoint)
    self._BasePoint = basePoint
end

function XSkyTowerOrderNpc:Born(bornCb)
    XSkyTowerChar.Born(self, bornCb)
    self:GetRoom():TryRemoveCustomer(self:GetNpcId())
end

function XSkyTowerOrderNpc:Show()
    XSkyTowerChar.Show(self)
    --处理旋转/位移/缩放
    self:InitCharTransform()
end

--跟角色Id绑定属性初始化
function XSkyTowerOrderNpc:InitData()
    local template = self._Model:GetOrderModelConfig(self._Id)
    self._AnimationList = template.Anim
end

function XSkyTowerOrderNpc:GetAssetPath()
    local npcId = self:GetNpcId()
    if not XTool.IsNumberValid(npcId) then
        return
    end
    return self._Model:GetNpcModelUrl(npcId)
end

function XSkyTowerOrderNpc:GetNpcId()
    local template = self._Model:GetOrderModelConfig(self._Id)
    return template and template.NpcId or 0
end

function XSkyTowerOrderNpc:GetControllerPath()
    local npcId = self:GetNpcId()
    if not XTool.IsNumberValid(npcId) then
        return
    end
    return self._Model:GetNpcControllerUrl(npcId)
end

function XSkyTowerOrderNpc:GetObjName()
    return string.format("@OrderNpc-%s", self._Id)
end

function XSkyTowerOrderNpc:GetCharTypeDesc()
    return CS.XTextManager.GetLuaText("XSkyTowerOrderNpc.lua_61")
end

function XSkyTowerOrderNpc:OnClick()
end

function XSkyTowerOrderNpc:InitCharTransform()
    self._Transform.position = self._BasePoint.position
    self._Transform.rotation = self._BasePoint.rotation
end

--加载进入时播放
function XSkyTowerOrderNpc:PlayBehaviour()
    local behaviorId = self:GetOrderNpcBehaviourId(XMVCA.XSkyTower.PerformState.NotStart)
    XLuaBehaviorManager.PlayId(behaviorId, self._Agent)
end

function XSkyTowerOrderNpc:GetOrderNpcBehaviourId(state)
    -- state 下标从0开始
    state = state + 1
    return self._OwnControl:GetPerformConfig(self._Id).OrderBehaviourIds[state]
end

function XSkyTowerOrderNpc:GetActionId(index)
    return self._AnimationList[index]
end

function XSkyTowerOrderNpc:ChangeState(state)
    XLuaBehaviorManager.PlayId(self:GetOrderNpcBehaviourId(state), self._Agent)
end

function XSkyTowerOrderNpc:IsNeedClick()
    return true
end

function XSkyTowerOrderNpc:Dispose()
    self:GetRoom():ReleaseOrderNpc()
end

function XSkyTowerOrderNpc:GetRandomBubbleText()
    local template = self._Model:GetOrderModelConfig(self._Id)
    return template and XUiHelper.ReplaceTextNewLine(template.RePlay) or ""
end

function XSkyTowerOrderNpc:IsHideWhenStopBusiness()
    return true
end

return XSkyTowerOrderNpc