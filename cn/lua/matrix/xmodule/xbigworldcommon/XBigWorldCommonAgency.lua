---@class XBigWorldCommonAgency : XAgency
---@field private _Model XBigWorldCommonModel
---@field private KeyCode XBigWorldInputKeyCode
local XBigWorldCommonAgency = XClass(XAgency, "XBigWorldCommonAgency")

function XBigWorldCommonAgency:OnInit()
    -- 初始化一些变量
    ---@type XBWPopupConfirmData
    self._ConfirmPopupData = false
    ---@type XBWPopupQuitConfirmData
    self._QuitConfirmPopupData = false

    self.LevelSubType = {
        StoryInst = 1, -- 剧情副本
        LevelPlayInst = 2 -- 玩法副本
    }

    self.LevelSaveOption = {
        None = 0, -- 不保存
        SaveExit = 1, -- 保存
        NoSaveExit = 2 -- 不保存
    }
    
    self.CoolTimeFormat = {
        -- 显示为 00:00:01
        Clock = 1,
    }
    
    self.KeyCode = require("XModule/XBigWorldCommon/XInput/XInputKeyCode")
end

function XBigWorldCommonAgency:InitRpc()
    -- 实现服务器事件注册
    -- XRpc.XXX
end

function XBigWorldCommonAgency:InitEvent()
    -- 实现跨Agency事件注册
    -- self:AddAgencyEvent()
end

---@return XBWPopupConfirmData
function XBigWorldCommonAgency:GetPopupConfirmData()
    if not self._ConfirmPopupData then
        local XBWPopupConfirmData = require("XModule/XBigWorldCommon/XData/XConfirmData/XBWPopupConfirmData")

        self._ConfirmPopupData = XBWPopupConfirmData.New()
    end

    self._ConfirmPopupData:Clear()

    return self._ConfirmPopupData
end

---@return XBWPopupQuitConfirmData
function XBigWorldCommonAgency:GetPopupQuitConfirmData()
    if not self._QuitConfirmPopupData then
        local XBWPopupQuitConfirmData = require("XModule/XBigWorldCommon/XData/XConfirmData/XBWPopupQuitConfirmData")

        self._QuitConfirmPopupData = XBWPopupQuitConfirmData.New()
    end

    self._QuitConfirmPopupData:Clear()

    return self._QuitConfirmPopupData
end

function XBigWorldCommonAgency:CreateShadyController(uiTransform, isAutoOpen)
    local transform = uiTransform:FindTransform("SafeAreaContentPane")

    if not transform then
        transform = uiTransform
    end

    local shadyUrl = XMVCA.XBigWorldResource:GetAssetUrl("Shady")
    local shady = transform:LoadPrefab(shadyUrl)
    local controller = shady.gameObject:GetComponent(typeof(CS.XUiShadyController))

    if XTool.UObjIsNil(controller) then
        controller = shady.gameObject:AddComponent(typeof(CS.XUiShadyController))
    end

    controller:SetTarget(shady.transform, "DarkEnable")

    if isAutoOpen then
        controller:Open()
    end

    return controller
end

-- region X3C

function XBigWorldCommonAgency:OnOpenLeaveInstLevelPopup(data)
    local confrimData = XMVCA.XBigWorldCommon:GetPopupQuitConfirmData()

    if data.LevelSubType == self.LevelSubType.StoryInst then
        local title = XMVCA.XBigWorldService:GetText("StoryLevelTipExitTitle")
        local tips = XMVCA.XBigWorldService:GetText("StoryLevelTipExitText")
        local sureText = XMVCA.XBigWorldService:GetText("StoryLevelTipExitSureText")
        local cancelText = XMVCA.XBigWorldService:GetText("StoryLevelTipExitCancelText")

        confrimData:InitInfo(title, tips, true)
        confrimData:InitCancelClick(cancelText, function()
            XMVCA.XBigWorldGamePlay:RequestLeaveInstLevel(self.LevelSaveOption.NoSaveExit)
        end)
        confrimData:InitSureClick(sureText, function()
            XMVCA.XBigWorldGamePlay:RequestLeaveInstLevel(self.LevelSaveOption.SaveExit)
        end)
    elseif data.LevelSubType == self.LevelSubType.LevelPlayInst then
        local title = XMVCA.XBigWorldService:GetText("InstLevelTipExitTitle")
        local tips = XMVCA.XBigWorldService:GetText("InstLevelTipExitText")
        local sureText = XMVCA.XBigWorldService:GetText("InstLevelTipExitSureText")
        local cancelText = XMVCA.XBigWorldService:GetText("InstLevelTipExitCancelText")

        confrimData:InitInfo(title, tips, true)
        confrimData:InitCancelClick(cancelText, function()
            XMVCA.XBigWorldGamePlay:RequestLeaveInstLevel()
        end)
        confrimData:InitSureClick(sureText, function()
            XMVCA.XBigWorldGamePlay:RequestAgainChallengeInst()
        end)
    else
        XLog.Error("找不到对应的子关卡类型， SubLevelType = " .. tostring(data.LevelSubType))

        return
    end

    XMVCA.XBigWorldUI:OpenQuitConfirmPopup(confrimData)
end

-- endregion

---@return XCoolTime
function XBigWorldCommonAgency:GetCoolTime()
    if not self._CoolTime then
        self._CoolTime  = require("XModule/XBigWorldCommon/XCoolTime/XCoolTime").New()
    end
    return self._CoolTime
end

function XBigWorldCommonAgency:GetCoolTimeStr(second)
    return self:GetCoolTime():GetClockTimeStr(second)
end

return XBigWorldCommonAgency
