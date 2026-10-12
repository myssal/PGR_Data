
---@class XNetworkCallCd 带CD的请求
---@field _Request string 协议名
---@field _Cd number 冷却时间
---@field _LastCall number 上次请求时间
local XNetworkCallCd = XClass(nil, "XNetworkCallCd")

---@param tipHandler table|nil 提示处理对象，提供 TipMsg/TipCode 方法；不传则使用通用提示
function XNetworkCallCd:Ctor(request, cd, tipHandler)
    self._Request = request
    self._Cd = cd or 0
    self._LastCall = 0
    self._GetTipFunc = nil
    self._TipHandler = tipHandler
end

--- 请求
---@param req table 请求的数据
---@param responseCb function 协议成功返回回调
---@param cb function 协议成功返回在responseCb之后执行或者在Cd未结束执行（可屏蔽不执行）
---@param errorCb function 协议失败执行
---@param ignoreTip boolean Cd未结束是否弹提示
---@param ignoreWaitCb boolean Cd未结束是否执行cb
---@return void
--------------------------
function XNetworkCallCd:Call(req, responseCb, cb, errorCb, ignoreTip, ignoreWaitCb)
    --由于XNetwork是在Update里进行更新， 这里保持同步
    local timeOfNow = CS.UnityEngine.Time.time
    local subSecond = timeOfNow - self._LastCall
    --Cd时间未到
    if subSecond < self._Cd then
        if not ignoreTip then
            local leftCd = math.ceil(math.max(0, self._Cd - subSecond))
            if self._TipHandler then
                self._TipHandler:TipMsg(self:GetNotCdTip(leftCd))
            else
                XUiManager.TipMsg(self:GetNotCdTip(leftCd))
            end
        end
        if cb and not ignoreWaitCb then cb() end
        return
    end
    
    XNetwork.Call(self._Request, req, function(res)
        if res.Code ~= XCode.Success then
            if self._TipHandler then
                self._TipHandler:TipCode(res.Code)
            else
                XUiManager.TipCode(res.Code)
            end
            if errorCb then errorCb(res) end
            return
        end
        self._LastCall = timeOfNow

        if responseCb then responseCb(res) end

        if cb then cb() end
    end)
end

--- 重置上次请求时间
--------------------------
function XNetworkCallCd:ResetLastCall()
    self._LastCall = 0
end

-- 修改提示内容可以设置回调
function XNetworkCallCd:GetNotCdTip(leftCd)
    if self._GetTipFunc then
        self._GetTipFunc(leftCd)
        return
    end
    return XUiHelper.GetText("RequestFrequentlyText", tostring(leftCd))
end

function XNetworkCallCd:SetNotCdTipCb(func)
    self._GetTipFunc = func
end

return XNetworkCallCd
