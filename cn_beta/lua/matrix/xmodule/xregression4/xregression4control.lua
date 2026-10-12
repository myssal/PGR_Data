
---@class XRegression4Control : XControl
---@field private _Model XRegression4Model
local XRegression4Control = XClass(XControl, "XRegression4Control", true)
-- 配置查询部分类
XClassPartialRequire("XModule/XRegression4/XRegression4ControlConfig", "XRegression4Control")

function XRegression4Control:OnInit()
    -- 初始化内部变量
end

function XRegression4Control:AddAgencyEvent()
    -- control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XRegression4Control:RemoveAgencyEvent()
end

function XRegression4Control:OnRelease()
end

---@return XRegression4
function XRegression4Control:GetMainViewModel()
    return self._Model:GetMainViewModel()
end

---@return XRegression4Passport
function XRegression4Control:GetPassportViewModel()
    return self._Model:GetMainViewModel():GetProperty("_PassportViewModel")
end

--region   ------------------Request start-------------------

--- 签到请求
---@param signId 签到Id
---@param cb 协议返回回调
function XRegression4Control:RequestSignIn(signId, cb)
    local signVideModel = self._Model:GetMainViewModel():GetProperty("_SignViewModel")
    if signVideModel:CheckIsReceive(signId) then
        XUiManager.TipMsg(self:GetClientConfigValue("RepeatSignTips", 1))
        return
    end
    XNetwork.Call("Regression4SignInGetRewardRequest", { SignInId = signId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        signVideModel:ReceiveSign(signId)
        XUiManager.OpenUiObtain(res.RewardGoods)

        XEventManager.DispatchEvent(XEventId.EVENT_REGRESSION4_SIGN_STATUS_CHANGE)

        if cb then cb() end
    end)
end

--- 购买战令
---@param passportTypeId 战令类型Id
---@param cb 协议返回回调
function XRegression4Control:RequestBuyPassport(passportTypeId, cb)
    local viewModel = self._Model:GetMainViewModel():GetProperty("_PassportViewModel")

    XNetwork.Call("Regression4PassportBuyPassportRequest", { Id = passportTypeId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        viewModel:BuyPassport(passportTypeId)
        viewModel:ReceiveAvailable( { res.PassportInfo } )
        local rewardList = res.RewardList
        if not XTool.IsTableEmpty(rewardList) then
            XUiManager.OpenUiObtain(rewardList)
        end

        XEventManager.DispatchEvent(XEventId.EVENT_REGRESSION4_PASSPORT_STATUS_CHANGE)

        if cb then cb() end
    end)
end

--- 领取单个战令奖励
---@param rewardId 奖励Id
---@param cb 协议返回回调
function XRegression4Control:RequestSinglePassportReward(rewardId, cb)
    local viewModel = self._Model:GetMainViewModel():GetProperty("_PassportViewModel")
    XNetwork.Call("Regression4PassportRecvRewardRequest", { Id = rewardId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        local template = self:GetPassportRewardInfoById(rewardId)
        viewModel:ReceiveSingleReward(rewardId, template.PassportId)

        XUiManager.OpenUiObtain(res.RewardList)
        XEventManager.DispatchEvent(XEventId.EVENT_REGRESSION4_PASSPORT_STATUS_CHANGE)

        if cb then cb() end
    end)
end

--- 一键领取战令奖励
---@param cb 协议返回回调
function XRegression4Control:RequestAvailablePassportReward(cb)
    local viewModel = self._Model:GetMainViewModel():GetProperty("_PassportViewModel")
    if not viewModel:IsRewardsAvailable() then
        XUiManager.TipMsg(self:GetClientConfigValue("NoRewardAvailableTips", 1))
        return
    end

    XNetwork.Call("Regression4PassportRecvAllRewardRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        viewModel:ReceiveAvailable(res.PassportInfos)

        XUiManager.OpenUiObtain(res.RewardList)
        XEventManager.DispatchEvent(XEventId.EVENT_REGRESSION4_PASSPORT_STATUS_CHANGE)

        if cb then cb() end
    end)
end

--endregion------------------Request finish------------------

--region   ------------------转发 Agency start-------------------

function XRegression4Control:IsOpen()
    return self:GetAgency():IsOpen()
end

function XRegression4Control:EnterUiMain()
    return self:GetAgency():EnterUiMain()
end

function XRegression4Control:PlayStory(cb)
    return self:GetAgency():PlayStory(cb)
end

function XRegression4Control:OnActivityEnd()
    return self:GetAgency():OnActivityEnd()
end

function XRegression4Control:MarkSignLocalRedPointData()
    return self:GetAgency():MarkSignLocalRedPointData()
end

function XRegression4Control:MarkTaskLocalRedPointData()
    return self:GetAgency():MarkTaskLocalRedPointData()
end

function XRegression4Control:MarkPassportLocalRedPointData()
    return self:GetAgency():MarkPassportLocalRedPointData()
end

function XRegression4Control:MarkShopLocalRedPointData()
    return self:GetAgency():MarkShopLocalRedPointData()
end

function XRegression4Control:MarkGiftShopRedPointData()
    return self:GetAgency():MarkGiftShopRedPointData()
end

function XRegression4Control:CheckSignLocalRedPointData()
    return self:GetAgency():CheckSignLocalRedPointData()
end

function XRegression4Control:CheckTaskLocalRedPointData()
    return self:GetAgency():CheckTaskLocalRedPointData()
end

function XRegression4Control:CheckPassportLocalRedPointData()
    return self:GetAgency():CheckPassportLocalRedPointData()
end

function XRegression4Control:CheckShopLocalRedPointData()
    return self:GetAgency():CheckShopLocalRedPointData()
end

function XRegression4Control:CheckGiftShopRedPointData()
    return self:GetAgency():CheckGiftShopRedPointData()
end

--endregion------------------转发 Agency finish------------------

return XRegression4Control
