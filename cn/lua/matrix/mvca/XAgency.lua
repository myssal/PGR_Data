---
--- Created by Jaylin.
--- DateTime: 2023-03-06-006 11:29
---
local IsWindowsEditor = XMain.IsWindowsEditor

---@class XAgency : XMVCAEvent
XAgency = XClass(XMVCAEvent, "XAgency")

function XAgency:Ctor(id)
    self._Id = id
    if id == "XFashionStory" then
        XLog.Debug("hello")
    end
    self._Model = XMVCA:_GetOrRegisterModel(self._Id)
    self._RpcNameDict = {}
    --self:OnInit()
end

function XAgency:GetId()
    return self._Id
end

---初始化接口, 提供给子类重写
function XAgency:OnInit()

end

---实现服务器事件注册, 提供给子类重写
function XAgency:InitRpc()
end

function XAgency:AddRpc(name, handler)
    self._RpcNameDict[name] = true
    XRpc[name] = handler
end

---实现跨模块Agency事件注册
function XAgency:InitEvent()
    --跨模块监听统一在xmvca
    --XMVCA:AddEventListener()
end

---为了兼容老的manager
function XAgency:AfterInitManager()

end

--动态注册后的添加
function XAgency:InitDynamicRegister()
    self:InitRpc()
    self:InitEvent()
end

---移除rpc
function XAgency:RemoveRpc()
    for name, _ in pairs(self._RpcNameDict) do
        XRpc.RemoveRpc(name)
        self._RpcNameDict[name] = nil
    end
end

---移除跨模块事件
function XAgency:RemoveEvent()

end

function XAgency:_CallResetAll()
    self:ResetAll()
    self._Model:CallResetAll()
end

---与model一致, 重登账号来一个resetAll
function XAgency:ResetAll()

end

function XAgency:OnRelease()

end

function XAgency:Release()
    self:RemoveRpc()
    self:RemoveEvent()
    self:Clear()
    self:OnRelease()
    if IsWindowsEditor then
        WeakRefCollector.AddRef(WeakRefCollector.Type.Agency, self)
    end
end

---保留函数, 热重载model
---@param model XModel
function XAgency:_HotReloadModel(model)
    if self._Model then
        self._Model = model
    end
end

---发送当前Agency事件,基于XEventManager
function XAgency:SendAgencyEvent(eventId, ...)
    --XMVCA:DispatchEvent(eventId, ...)
    XEventManager.DispatchEvent(eventId, ...) --先使用原来的接口
end

---添加监听其他Agency事件,基于XEventManager
function XAgency:AddAgencyEvent(eventId, func, obj)
    --XMVCA:AddEventListener(eventId, func, obj)
    XEventManager.AddEventListener(eventId, func, obj) --先使用原来的接口
end

---移除监听其他Agency事件,基于XEventManager
function XAgency:RemoveAgencyEvent(eventId, func, obj)
    --XMVCA:RemoveEventListener(eventId, func, obj)
    XEventManager.RemoveEventListener(eventId, func, obj) --先使用原来的接口
end
