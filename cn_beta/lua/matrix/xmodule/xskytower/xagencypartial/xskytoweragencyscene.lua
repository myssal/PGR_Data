---Agency部分类，此处用于场景管理
---@type XSkyTowerAgency
local XSkyTowerAgency = XClassPartial('XSkyTowerAgency')

function XSkyTowerAgency:InitScene()
    self._SceneObj = nil
    -- 已完成的加载步骤数（包含最后的资源回收）
    self.LoadCount = 0
    -- 本次加载需要的总步骤数
    self.LoadTotalCount = 0
    ---@type UnityEngine.AsyncOperation
    self._SceneUnloadOperation = nil
    ---@type table<number,UnityEngine.Object>
    self._FloorPreLoadAssetHash = {}
    ---@type table<number,UnityEngine.GameObject>
    self._FloorObjHash = {}
    ---楼层在BaseFloorPoint局部空间下的高度（盖楼用）
    self._FloorBuildHeight = nil
    ---楼层在世界空间下的高度（摄像机移动用）
    self._FloorTotalHeight = nil
    ---@type table<string,boolean> 已加载的资源路径集合
    self._LoadedAssetUrls = {}
end

function XSkyTowerAgency:LoadAsync(url, loadSuccess, loadFail)
    ---@type XLoaderUtil
    local loader = CS.XLoaderUtil.GetModuleLoader(ModuleId.XSkyTower)
    loader:LoadAsync(url, function(asset)
        if not asset then
            XLog.Error("通天塔资源加载失败：" .. url)
            if loadFail then
                loadFail()
            end
            return
        end
        self._LoadedAssetUrls[url] = true
        if loadSuccess then
            loadSuccess(asset)
        end
    end)
end

function XSkyTowerAgency:Load(url)
    ---@type XLoaderUtil
    local loader = CS.XLoaderUtil.GetModuleLoader(ModuleId.XSkyTower)
    local asset = loader:Load(url)
    if asset then
        self._LoadedAssetUrls[url] = true
    else
        XLog.Error("通天塔资源加载失败：" .. url)
    end
    return asset
end

---创建场景、预加载楼层
function XSkyTowerAgency:LoadSceneResources()
    local sceneUrl = self._Model:GetClientConfigValue("ScenePrefab")
    --实例化最高楼层附近一定范围的楼层，其他楼层预加载
    --local instantiateFloorRange = self._Model:GetIntClientConfigValue("InstantiateFloorRange")
    local maxFloorId = self._Model:GetMaxFloorId()
    self.LoadCount = 0
    self._SceneUnloadOperation = nil
    --场景本体 + 全部楼层 + 最后的资源回收，进度条按这个总数算比例
    self.LoadTotalCount = self.MaxFloorId + 2
    local checkLoadEnd = function()
        self.LoadCount = self.LoadCount + 1
    end

    self:LoadAsync(sceneUrl, function(asset)
        self._SceneObj = {}
        local go = XUiHelper.Instantiate(asset)
        XUiHelper.InitUiClass(self._SceneObj, go)
        self:InitFloorHeight()
        checkLoadEnd()
    end, function()
        self:OnLoadSceneFail(sceneUrl)
    end)

    for i = 1, self.MaxFloorId do
        local floorCfg = self._Model:GetFloorConfig(i)
        self:LoadAsync(floorCfg.ResLut, function(asset)
            self._FloorPreLoadAssetHash[i] = asset
            if i <= maxFloorId then
                self:LoadFloor(i)
            end
            checkLoadEnd()
        end, function()
            self:OnLoadSceneFail(sceneUrl)
        end)
    end
end

--- 推进最后的资源回收步骤并获取场景加载进度（0~1）
function XSkyTowerAgency:GetSceneLoadProgress()
    if not XTool.IsNumberValid(self.LoadTotalCount) then
        return 0
    end
    local progress = math.min(self.LoadCount / self.LoadTotalCount, 1)
    --回收完成在下次轮询才体现到进度，避免 GC 与打开入口界面发生在同一帧
    self:_TryUnloadUnusedAssets()
    return progress
end

--- 资源加载完毕后，推进最后的资源回收步骤
function XSkyTowerAgency:_TryUnloadUnusedAssets()
    if self.LoadCount ~= self.LoadTotalCount - 1 then
        return
    end
    if not self._SceneUnloadOperation then
        self._SceneUnloadOperation = CS.UnityEngine.Resources.UnloadUnusedAssets()
    elseif self._SceneUnloadOperation.isDone then
        LuaGC()
        self._SceneUnloadOperation = nil
        self.LoadCount = self.LoadCount + 1
    end
end

---加载场景资源失败
function XSkyTowerAgency:OnLoadSceneFail(url)
    CS.XLoaderUtil.ClearModuleLoader(ModuleId.XSkyTower)
    XLuaUiManager.Remove("UiSkyTowerLoading")
    XLog.Error(string.format("通天塔场景资源加载失败！%s", url))
end

---加载场景资源成功
function XSkyTowerAgency:OnLoadSceneSuccess()
    --进入玩法界面
    XLuaUiManager.OpenWithCallback("UiSkyTowerEntrance", function()
        XLuaUiManager.Remove("UiSkyTowerLoading")
    end)
    XEventManager.DispatchEvent(XEventId.EVENT_SKY_TOWER_ENTER_ROOM)
end

---创建楼层（不会重复创建）
---@return UnityEngine.GameObject
function XSkyTowerAgency:LoadFloor(floorId)
    if self._FloorObjHash[floorId] then
        return nil
    end

    local asset = self._FloorPreLoadAssetHash[floorId]
    if not asset then
        local floorCfg = self._Model:GetFloorConfig(floorId)
        ---@type XLoaderUtil
        local loader = CS.XLoaderUtil.GetModuleLoader(ModuleId.XSkyTower)
        asset = loader:Load(floorCfg.ResLut)
    end

    local floorObj = XUiHelper.Instantiate(asset, self._SceneObj.BaseFloorPoint)
    self._FloorObjHash[floorId] = floorObj
    return floorObj
end

function XSkyTowerAgency:InitFloorHeight()
    self._FloorTotalHeight = self._Model:GetIntClientConfigValue("FloorHeight")
    self._FloorBuildHeight = self._SceneObj.BaseFloorPoint:InverseTransformVector(0, self._FloorTotalHeight, 0).magnitude
end

function XSkyTowerAgency:InitSceneSetting()
    local sceneSetting = self._SceneObj.SceneSetting
    if XTool.UObjIsNil(sceneSetting) then
        return
    end
    sceneSetting.enabled = true
    CS.XGraphicManager.BindScene(sceneSetting)
    -- Dormitory 下 BindScene 不会应用全局光照，需显式使用主场景的配置。
    sceneSetting:UpdateGlobalIllumination()
end

---获取楼层实际高度
function XSkyTowerAgency:GetFloorTotalHeight()
    if not self._FloorTotalHeight then
        XLog.Error("场景初始化未完成，无法获取楼层高度.")
        return 0
    end
    return self._FloorTotalHeight
end

---获取楼层盖楼用高度
function XSkyTowerAgency:GetFloorBuildHeight()
    if not self._FloorBuildHeight then
        XLog.Error("场景初始化未完成，无法获取楼层高度.")
        return 0
    end
    return self._FloorBuildHeight
end

function XSkyTowerAgency:GetSceneObj()
    return self._SceneObj
end

function XSkyTowerAgency:GetLoadedAssetUrls()
    return self._LoadedAssetUrls
end

function XSkyTowerAgency:GetFloorObjHash()
    return self._FloorObjHash
end

function XSkyTowerAgency:ResetSceneObj()
    XUiHelper.Destroy(self._SceneObj.GameObject)
    self._SceneObj = nil
    self._FloorPreLoadAssetHash = {}
    self._FloorObjHash = {}
    self._FloorTotalHeight = nil
    self._FloorBuildHeight = nil
end

return XSkyTowerAgency
