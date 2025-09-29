XPayConfigs = XPayConfigs or {}

local TABLE_PAY_PATH = "Share/Pay/Pay.tab"
local TABLE_FIRST_PAY_PATH = "Share/Pay/FirstPayReward.tab"

local Application = CS.UnityEngine.Application
local Platform = Application.platform
local RuntimePlatform = CS.UnityEngine.RuntimePlatform

local PayTemplates = {}
local FirstPayTemplates = {}
local PayListDataConfig = nil

XPayConfigs.PayTemplateType = {
    PC = 0,
    Android = 1,
    IOS = 2,
}

function XPayConfigs.Init()
    PayTemplates = XTableManager.ReadByStringKey(TABLE_PAY_PATH, XTable.XTablePay, "Key")
    FirstPayTemplates = XTableManager.ReadByIntKey(TABLE_FIRST_PAY_PATH, XTable.XTableFirstPayReward, "NeedPayMoney")
end

function XPayConfigs.GetPayTemplate(key)
    local template = PayTemplates[key]
    if not template then
        XLog.ErrorTableDataNotFound("XPayConfigs.GetPayTemplate", "template", TABLE_PAY_PATH, "key", tostring(key))
        return
    end

    return template
end

function XPayConfigs.GetPayConfig()
    if not PayListDataConfig then
        PayListDataConfig = {}
        if XOverseaManager.IsENRegion() then
            for _,v in pairs(PayTemplates)do
                if v.ShowUIType == 1 then
                    if v.Platform == XPayConfigs.PayTemplateType.Android and Platform == RuntimePlatform.Android then
                        table.insert(PayListDataConfig,v)
                    elseif v.Platform == XPayConfigs.PayTemplateType.IOS and Platform == RuntimePlatform.IPhonePlayer then
                        table.insert(PayListDataConfig,v)
                    elseif v.Platform == XPayConfigs.PayTemplateType.PC and (Platform == RuntimePlatform.WindowsPlayer 
                    or Platform == RuntimePlatform.WindowsEditor) then
                        table.insert(PayListDataConfig,v)
                    end
                end
            end
        else
            for _,v in pairs(PayTemplates)do
                if v then
                    table.insert(PayListDataConfig,v)
                end
            end
        end
    end
    return PayListDataConfig
end

function XPayConfigs.CheckFirstPay(totalPayMoney)
    for _, v in pairs(FirstPayTemplates) do
        return totalPayMoney >= v.NeedPayMoney
    end
end

function XPayConfigs.GetSmallRewards()
    for _, v in pairs(FirstPayTemplates) do
        return v.SmallRewardId
    end
end

function XPayConfigs.GetBigRewards()
    for _, v in pairs(FirstPayTemplates) do
        return v.BigRewardId
    end
end