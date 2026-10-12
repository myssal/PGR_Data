
local XRedPointConditionRegression4All = {}
local SubConditions = nil

function XRedPointConditionRegression4All.GetSubConditions()
    SubConditions = SubConditions or {
        XRedPointConditions.Types.CONDITION_REGRESSION4_SIGN,
        XRedPointConditions.Types.CONDITION_REGRESSION4_PASSPORT,
        XRedPointConditions.Types.CONDITION_REGRESSION4_TASK,
        XRedPointConditions.Types.CONDITION_REGRESSION4_SHOP,
        XRedPointConditions.Types.CONDITION_REGRESSION4_MAIN,
        XRedPointConditions.Types.CONDITION_REGRESSION4_SURVEY,
    }
    return SubConditions
end 

function XRedPointConditionRegression4All.Check()
    if XMVCA.XRegression4:CheckTaskRedPoint() then
        return true
    end

    if XMVCA.XRegression4:CheckSignRedPoint() then
        return true
    end

    if XMVCA.XRegression4:CheckPassportRedPoint() then
        return true
    end

    if XMVCA.XRegression4:CheckShopRedPoint() then
         return true
    end

    if XMVCA.XRegression4:CheckMainRedPoint() then
        return true
    end

    if XMVCA.XRegression4:CheckSurveyRedPoint() then
        return true
    end
    
    return false
end

return XRedPointConditionRegression4All

