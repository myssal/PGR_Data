
local XSkyTowerChar = require("XModule/XSkyTower/XGameObject/XSkyTowerChar")

---@class XSkyTowerPerformer : XSkyTowerChar 演员
---@field _Model XSkyTowerModel
---@field _OwnControl XSkyTowerControl
local XSkyTowerPerformer = XClass(XSkyTowerChar, "XSkyTowerPerformer")

function XSkyTowerPerformer:SetPerform(perform)
    ---@type XSkyTowerPerform
    self._Perform = perform
end

function XSkyTowerPerformer:GetAssetPath()
    return self._Model:GetNpcModelUrl(self:GetNpcId())
end

function XSkyTowerPerformer:GetControllerPath()
    return self._Model:GetNpcControllerUrl(self:GetNpcId())
end

function XSkyTowerPerformer:GetNpcId()
    return self._Model:GetPerformerNpcId(self._Id)
end

function XSkyTowerPerformer:GetObjName()
    local key = self._Perform:IsFloorGroupPerform() and "@FloorGroupPerformer-%s" or "@Performer-%s"
    return string.format(key, tostring(self._Id))
end

function XSkyTowerPerformer:GetCharTypeDesc()
    return CS.XTextManager.GetLuaText("XSkyTowerPerformer.lua_26")
end

function XSkyTowerPerformer:GetBehaviourId(state)
    local template = self._Model:GetPerformerConfig(self._Id)
    return template and template.PerformBehaviorIds[state] or ""
end

function XSkyTowerPerformer:ChangeState(state)
    if self._State == state then
        return
    end
    if XTool.UObjIsNil(self._GameObject) then
        return
    end
    self._State = state
    XLuaBehaviorManager.PlayId(self:GetBehaviourId(state), self._Agent)
end

function XSkyTowerPerformer:SetTransform(x, y, z, rX, rY, rZ)
    self._PosX, self._PosY, self._PosZ = x, y, z
    self._RotX, self._RotY, self._RotZ = rX, rY, rZ
end

function XSkyTowerPerformer:InitCharTransform()
    self._Transform:SetPosition(self._PosX, self._PosY, self._PosZ)
    self._Transform:SetEulerRotation(self._RotX, self._RotY, self._RotZ)
end

function XSkyTowerPerformer:PlayBehaviour()
    self:ChangeState(1)
end

function XSkyTowerPerformer:Born(bornCb)
    XSkyTowerChar.Born(self, bornCb)

    self:GetRoom():TryRemoveCustomer(self:GetNpcId())
end

function XSkyTowerPerformer:Dispose()
    if not self._OwnControl or not self._Perform then
        return
    end
    self._Perform:RemoveActor(self:GetId())
end

function XSkyTowerPerformer:SetBubbleTextList(dialogId)
    self._DialogTxtList = self._Model:GetDialogTextList(dialogId)
end

function XSkyTowerPerformer:GetBubbleText(index)
    if index and index <= 0 then
        index = 1
    end
    return self._DialogTxtList and self._DialogTxtList[index] or ""
end

return XSkyTowerPerformer