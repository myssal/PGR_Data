---@class XUiGridSkyTower3DBase : XUiNode
---@field Transform UnityEngine.Transform
---@field GameObject UnityEngine.GameObject
---@field Offset UnityEngine.Vector3
---@field Target UnityEngine.Transform
---@field _Control XSkyTowerControl
local XUiGridSkyTower3DBase = XClass(XUiNode, "XUiGridSkyTower3DBase")

local LocalSize = Vector3.one

---@param container UnityEngine.Transform 挂载节点，不传就留在原地
---@param offset UnityEngine.Vector3
function XUiGridSkyTower3DBase:OnStart(container, offset)
    self:InitUi()
    self:InitCb()

    if not XTool.UObjIsNil(container) then
        self.Transform:SetParent(container)
    end
    --注意别往self.Parent上写，那是XUiNode记父节点用的，覆盖掉会让UnBindParent和Release都找不到人
    self.Offset = offset
end

function XUiGridSkyTower3DBase:SetTarget(target)
    self.Target = target
end

---@param offset UnityEngine.Vector3
function XUiGridSkyTower3DBase:SetOffset(offset)
    self.Offset = offset
end

function XUiGridSkyTower3DBase:Show(...)
    self:Open()
    self:OnRefresh(...)
end

function XUiGridSkyTower3DBase:Hide()
    self:Close()
end

function XUiGridSkyTower3DBase:IsShow()
    if XTool.UObjIsNil(self.GameObject) then
        return false
    end
    return self.GameObject.activeInHierarchy
end

function XUiGridSkyTower3DBase:SetName(name)
    self.GameObject.name = name
end

function XUiGridSkyTower3DBase:InitUi()
end

function XUiGridSkyTower3DBase:InitCb()
end

function XUiGridSkyTower3DBase:OnRefresh(...)
end

function XUiGridSkyTower3DBase:OnRecycle()
    self:Close()
end

--- 更新Ui位置
---@param room XSkyTowerRoom
---@return void
function XUiGridSkyTower3DBase:UpdateTransform(room)
    if not room or not self:IsShow() then
        self:Hide()
        return
    end

    if XTool.UObjIsNil(self.Transform) or XTool.UObjIsNil(self.Target) then
        self:Hide()
        return
    end

    room:SetViewPosToTransformLocalPosition(self.Transform, self.Target, self.Offset)
    self.Transform.localScale = LocalSize
end

return XUiGridSkyTower3DBase
