

local XRegression4Sign = XClass(XDataEntityBase, "XRegression4Sign")

local default = {
    _Id = 0, --活动id
    _SignDay = 0,   --签到天数
    _SignIdDict = {},  --已领取奖励Id
}

function XRegression4Sign:Ctor(id)
    self:Init(default, id)
end 

function XRegression4Sign:InitData(id)
    self:SetProperty("_Id", id)
end

--- 服务端数据更新
---@param notifyData Server.XRegression4SignInData
---@return nil
--------------------------
function XRegression4Sign:UpdateData(notifyData)
    if not notifyData then
        return
    end
    local signList = self:GetSignInfos()
    self:SetProperty("_SignDay", math.min(notifyData.SigninTimes, #signList))
    self:ReceiveMultiSign(notifyData.Rewards)
end

function XRegression4Sign:GetSignInfos()
    return XMVCA.XRegression4:GetSignInList(self._Id)
end

-- 是否有奖励可以领取
function XRegression4Sign:CheckHasReward()
    for _, signData in ipairs(self:GetSignInfos()) do
        if self:CheckIsSign(signData.Days) and not self:CheckIsReceive(signData.Id) then
            return true
        end
    end
    return false
end

-- 检查该天是否签到
function XRegression4Sign:CheckIsSign(signDay)
    return self._SignDay >= signDay
end

-- 检查该天的签到奖励是否领取
function XRegression4Sign:CheckIsReceive(signId)
    return self._SignIdDict[signId]
end

-- 领取签到奖励
function XRegression4Sign:ReceiveSign(signId)
    self._SignIdDict[signId] = true
    self:SetProperty("_SignIdDict", self._SignIdDict)
end

function XRegression4Sign:ReceiveMultiSign(signIds)
    for _, signId in ipairs(signIds) do
        self._SignIdDict[signId] = true
    end
    self:SetProperty("_SignIdDict", self._SignIdDict)
end

function XRegression4Sign:SetSignTimes(signTimes)
    local signList = self:GetSignInfos()
    self:SetProperty("_SignDay", math.min(signTimes, #signList))
end

return XRegression4Sign