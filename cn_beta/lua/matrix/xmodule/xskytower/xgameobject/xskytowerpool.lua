---@class XSkyTowerPool:XEntity
local XSkyTowerPool = XClass(XEntity, "XSkyTowerPool")

local MaxCount = 3

function XSkyTowerPool:OnInit(key)
    ---@type table<string, UnityEngine.Transform[]> 资源路径索引空闲模型
    self._Pool = {}
    self._PoolRoot = nil
    self._Key = key or "Pool"
end

function XSkyTowerPool:OnRelease()
    self._Pool = {}
    self._PoolRoot = nil
end

---池子的挂载点，回收的模型统一挂到这里并隐藏，跟着场景根节点一起销毁
---@return UnityEngine.Transform
function XSkyTowerPool:GetPoolRoot()
    if not XTool.UObjIsNil(self._PoolRoot) then
        return self._PoolRoot
    end
    local sceneObj = XMVCA.XSkyTower:GetSceneObj()
    local go = CS.UnityEngine.GameObject(self._Key)
    go.transform:SetParent(sceneObj.Transform, false)
    go:SetActiveEx(false)
    self._PoolRoot = go.transform
    return self._PoolRoot
end

---取一个模型，池里有就复用，没有就异步加载
---@param modelUrl string 模型资源路径
---@param parent UnityEngine.Transform 挂载的工位节点
---@param cb function 拿到模型后的回调，参数为模型Transform
function XSkyTowerPool:GetModelAsync(modelUrl, parent, cb)
    local model = self:PopModel(modelUrl)
    if model then
        self:AttachModel(model, parent)
        if cb then
            cb(model)
        end
        return
    end
    XMVCA.XSkyTower:LoadAsync(modelUrl, function(asset)
        if XTool.UObjIsNil(parent) then
            return
        end
        local newModel = XUiHelper.Instantiate(asset, parent)
        self:AttachModel(newModel.transform, parent)
        if cb then
            cb(newModel)
        end
    end)
end

---从池里取一个模型
---@return UnityEngine.Transform
function XSkyTowerPool:PopModel(modelUrl)
    local list = self._Pool[modelUrl]
    if XTool.IsTableEmpty(list) then
        return nil
    end
    local model = table.remove(list)
    if not XTool.UObjIsNil(model) then
        return model
    end
    return nil
end

---把模型挂到节点上
function XSkyTowerPool:AttachModel(model, parent)
    if XTool.UObjIsNil(model) then
        return
    end
    model.transform:SetParent(parent, false)
    model.transform.localPosition = Vector3.zero
    model.transform.localEulerAngles = Vector3.zero
    model.transform.localScale = Vector3.one
    model.gameObject:SetActiveEx(true)
end

---回收模型，挂回池根节点等待复用
---@param modelUrl string 模型资源路径，为空时直接销毁
function XSkyTowerPool:RecycleModel(modelUrl, model)
    if XTool.UObjIsNil(model) then
        return
    end
    local root = self:GetPoolRoot()
    local list = self._Pool[modelUrl]
    local capacity = list and #list or 0
    if XTool.UObjIsNil(root) or capacity >= MaxCount then
        XUiHelper.Destroy(model.gameObject)
        return
    end
    model.gameObject:SetActiveEx(false)
    model.transform:SetParent(root, false)
    if not list then
        list = {}
        self._Pool[modelUrl] = list
    end
    table.insert(list, model)
end

return XSkyTowerPool