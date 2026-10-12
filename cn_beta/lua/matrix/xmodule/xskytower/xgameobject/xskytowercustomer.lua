

local XSkyTowerChar = require("XModule/XSkyTower/XGameObject/XSkyTowerChar")

---@class XSkyTowerCustomer : XSkyTowerChar
---@field
local XSkyTowerCustomer = XClass(XSkyTowerChar, "XSkyTowerCustomer")

function XSkyTowerCustomer:GetAssetPath()
    local npcId = self:GetNpcId()
    if not XTool.IsNumberValid(npcId) then
        return
    end
    return self._Model:GetNpcModelUrl(npcId)
end

function XSkyTowerCustomer:GetControllerPath()
    local npcId = self:GetNpcId()
    if not XTool.IsNumberValid(npcId) then
        return
    end 
    return self._Model:GetNpcControllerUrl(npcId)
end

function XSkyTowerCustomer:GetNpcId()
    return self._Model:GetCustomerNpcId(self._Id)
end

function XSkyTowerCustomer:GetObjName()
    return string.format("@Customer-%s", tostring(self._Id))
end

function XSkyTowerCustomer:GetCharTypeDesc()
    return CS.XTextManager.GetLuaText("XSkyTowerCustomer.lua_34")
end

function XSkyTowerCustomer:GetBehaviourId()
    local template = self._Model:GetCustomerConfig(self._Id)
    return template and template.BehaviourId or ""
end

function XSkyTowerCustomer:SetBornPoint(point, redPoint, greenPoint)
    self._BornPoint = point
    self._RedPoint = redPoint
    self._GreedPoint = greenPoint
end

--立即释放
function XSkyTowerCustomer:Dispose()
    self:GetRoom():RemoveCustomerByEntity(self)
end

function XSkyTowerCustomer:InitCharTransform()
    if self._BornPoint then
        self._Transform.position = self._BornPoint
    end

    --改变朝向
    local target = CS.UnityEngine.Quaternion.LookRotation(CS.UnityEngine.Vector3.back)
    self._Transform.rotation = target
    self:TryAddNavMeshAgent()
end

function XSkyTowerCustomer:PlayBehaviour()
    XLuaBehaviorManager.PlayId(self:GetBehaviourId(), self._Agent)
end

function XSkyTowerCustomer:DoSetGreenPoint()
    self._Agent:SetVarDicByKey("TargetPosition", self._GreedPoint)
end

function XSkyTowerCustomer:DoSetRedPoint()
    self._Agent:SetVarDicByKey("TargetPosition", self._RedPoint)
end

function XSkyTowerCustomer:DoSetStartPoint()
    self._Agent:SetVarDicByKey("TargetPosition", self._BornPoint)
end

function XSkyTowerCustomer:GetRandomPoint()
    return self:GetRoom():GetCustomerRandomPoint()
end

function XSkyTowerCustomer:GetRandomBubbleText()
    local text = self._Model:GetCustomerTextList(self._Id)
    if XTool.IsTableEmpty(text) then
        return
    end
    local index = math.random(1, #text)
    return text[index]
end

function XSkyTowerCustomer:GetBubbleText(index)
    local text = self._Model:GetCustomerTextList(self._Id)
    if XTool.IsTableEmpty(text) then
        return
    end
    return text[index] or "? ? ?"
end

return XSkyTowerCustomer