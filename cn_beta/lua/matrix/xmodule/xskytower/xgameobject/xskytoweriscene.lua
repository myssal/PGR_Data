
local CsVector3 = CS.UnityEngine.Vector3

---@class XSkyTowerIScene : XEntity 通天塔场景接口
---@field _GameObject UnityEngine.GameObject 模型
---@field _Transform UnityEngine.Transform 模型变换
---@field _Root UnityEngine.Transform 父节点，可能为空
---@field _IsLoading boolean
---@field _Model XSkyTowerModel
---@field _OwnControl XSkyTowerControl
local XSkyTowerIScene = XClass(XEntity, "XSkyTowerIScene")

function XSkyTowerIScene:OnInit(root, ...)
    self._Root = root
    self._IsLoading = false
    self:Init()
    self:AddEvent()
end

--- 创建对象时初始化
function XSkyTowerIScene:Init()
end

function XSkyTowerIScene:AddEvent()
end

function XSkyTowerIScene:RemoveEvent()
end

--- 加载资源
---@param onLoadCb function 加载成功回调
---@return void
function XSkyTowerIScene:Load(onLoadCb)
    if not self:CheckBeforeLoad() then
        return
    end
    local assetPath = self:GetAssetPath()
    local loader = self._OwnControl:GetLoader()
    self._IsLoading = true
    loader:LoadAsync(assetPath, function(asset)
        -- 场景退出后实体可能已释放，晚到的资源由本次加载器延后回收
        if not self._OwnControl then
            if asset then
                self:UnloadAssetNextFrame(loader, assetPath)
            end
            self._IsLoading = false
            return
        end
        if not asset then
            self._IsLoading = false
            XLog.Error("skyTower load resource error: asset path = " .. assetPath)
            return
        end

        self._ResPath = assetPath
        if not self:CheckAfterLoad() then
            self:Release()
            self._IsLoading = false
            return
        end
        self._GameObject = XUiHelper.Instantiate(asset)
        if not XTool.UObjIsNil(self._GameObject) then
            self._Transform = self._GameObject.transform
            self:ResetTransform()
            self._GameObject.name = self:GetObjName()
        end
        self:OnLoadSuccess()

        if onLoadCb then onLoadCb() end

        self._IsLoading = false
    end)
end

function XSkyTowerIScene:OnRelease()
    self:DoRelease()
    self:RemoveEvent()
end

--- 释放资源, Release 会执行 RemoveEntity
---@return void
function XSkyTowerIScene:Release()
   self:DoRelease()
    if self._OwnControl then
        self._OwnControl:RemoveEntity(self)
    end
    self._OwnControl = nil
end

function XSkyTowerIScene:DoRelease()
    self:TryDestroy(self._GameObject)
    self._GameObject = nil
    self._Transform = nil
    
    if not string.IsNilOrEmpty(self._ResPath) then
        local loader = self._OwnControl:GetLoader()
        local assetPath = self._ResPath
        self._ResPath = nil
        self:UnloadAssetNextFrame(loader, assetPath)
    end
end

--- 加载成功回调
function XSkyTowerIScene:OnLoadSuccess()
end

--- 加载前检查
---@return boolean
function XSkyTowerIScene:CheckBeforeLoad()
    return true
end

function XSkyTowerIScene:CheckAfterLoad()
    return true
end

--- 获取资源路径
---@return string
function XSkyTowerIScene:GetAssetPath()
    XLog.Error("XSkyTowerIScene:GetAssetPath: subclass must override this function")
end

--- 重置场景变换
function XSkyTowerIScene:ResetTransform()
    if not XTool.UObjIsNil(self._Root) then
        self._Transform:SetParent(self._Root.transform)
    end
    self:TryResetTransform(self._Transform)
end

--- 加载物体名
---@return string
function XSkyTowerIScene:GetObjName()
    return "DefaultSkyTowerScene"
end

--- 删除游戏物体
---@param obj UnityEngine.GameObject 物体
---@return boolean 是否销毁成功
function XSkyTowerIScene:TryDestroy(obj)
    if XTool.UObjIsNil(obj) then
        return false
    end
    XUiHelper.Destroy(obj)
    obj = nil
    return true
end

function XSkyTowerIScene:TryResetTransform(transform)
    if XTool.UObjIsNil(transform) then
        return false
    end
    transform.localPosition       = CsVector3.zero
    transform.localEulerAngles    = CsVector3.zero
    transform.localScale          = CsVector3.one
    return true
end

function XSkyTowerIScene:Exist()
    return not XTool.UObjIsNil(self._GameObject)
end

function XSkyTowerIScene:IsLoading()
    return self._IsLoading
end

function XSkyTowerIScene:Hide()
    if not self:Exist() then
        return
    end
    self._GameObject:SetActiveEx(false)
end

function XSkyTowerIScene:Show()
    if not self:Exist() then
        return
    end

    self._GameObject:SetActiveEx(true)
end

function XSkyTowerIScene:GetTransform()
    return self._Transform
end

function XSkyTowerIScene:IsHide()
    return not self._GameObject.activeInHierarchy
end

---加载回调里卸载最后一份引用会清空C#正在遍历的回调列表，统一延后一帧释放。
function XSkyTowerIScene:UnloadAssetNextFrame(loader, assetPath)
    XScheduleManager.ScheduleNextFrame(function()
        --使用本次加载器；退出玩法后可能已被整体销毁，此时无需重复卸载。
        if not XTool.UObjIsNil(loader) then
            loader:Unload(assetPath)
        end
    end)
end

return XSkyTowerIScene