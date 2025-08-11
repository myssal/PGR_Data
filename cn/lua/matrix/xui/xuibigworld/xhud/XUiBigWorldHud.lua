---@class XUiBigWorldHud : XBigWorldUi
local XUiBigWorldHud = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldHud")

local BtnIndex = {
    BtnQuit = 1,
    BtnQuitInst = 2,
    BtnMenu = 3,
    BtnPhoto = 4,
    BtnMessage = 5,
    BtnMessageNew = 6,
    BtnSetting = 7,
    BtnTeach = 8,
    BtnTeam = 9,
    BtnBag = 10,
    BtnExplore = 11,
    BtnLittleMap = 12,
    BtnQuest = 13,
}

function XUiBigWorldHud:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBigWorldHud:OnStart()
    self:InitView()
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SET_UI_HUD_ACTIVE, self.OnSetActive, self)
end

function XUiBigWorldHud:OnEnable()
    self:RefreshBtnQuit()
    self:RefreshRedPoint()
    self:RefreshShield()
    self:AddEventHandler()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_FIGHT_UI_HUD_ENABLE)
end

function XUiBigWorldHud:OnDisable()
    self:RemoveEventHandler()
end

function XUiBigWorldHud:OnDestroy()
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SET_UI_HUD_ACTIVE, self.OnSetActive, self)
end

function XUiBigWorldHud:InitUi()
    self._IsShowConfirm = false
    self._IsShowMenu = false
    ---@type XUiBigWorldPanelQuest
    self.PanelQuest = require("XUi/XUiBigWorld/XHud/Panel/XUiBigWorldPanelQuest").New(self.PanelTask, self)
    ---@type XUiBigWorldPanelLittleMap
    self.LittleMap = require("XUi/XUiBigWorld/XHud/Panel/XUiBigWorldPanelLittleMap").New(self.PanelLittleMap, self)
end

function XUiBigWorldHud:InitCb()
    self._RefreshMenuAnimationCb = function()
        if XTool.UObjIsNil(self.ListMenu) then
            return
        end
        self.ListMenu.gameObject:SetActiveEx(self._IsShowMenu)
    end
    self.BtnQuit.CallBack = function()
        self:OnBtnQuitClick()
    end

    self.BtnQuitDoor2.CallBack = function()
        self:OnBtnQuitClick()
    end

    self.BtnTask.CallBack = function()
        self:OnBtnTaskClick()
    end

    self.BtnMessage.CallBack = function()
        self:OnBtnMessageClick()
    end

    self.BtnMessageList.CallBack = function()
        self:OnBtnMessageListClick()
    end

    self.BtnTeam.CallBack = function()
        self:OnBtnTeamClick()
    end

    self.BtnBag.CallBack = function()
        self:OnBtnBagClick()
    end

    self.BtnHandBook.CallBack = function()
        self:OnBtnHandBookClick()
    end

    self.BtnPhoto.CallBack = function()
        self:OnBtnPhotoClick()
    end

    self.BtnSet.CallBack = function()
        self:OnBtnSetClick()
    end

    self.BtnTeach.CallBack = function()
        self:OnBtnTeachClick()
    end

    self.BtnMenu.CallBack = function()
        self:OnBtnMenuClick()
    end
    
    self._OnEnableAnimCb = handler(self, self.OnEnableAnimEnd)
    self._OnDisableAnimCb = handler(self, self.OnDisableAnimEnd)
end

function XUiBigWorldHud:InitView()
    self:RefreshMenu()
end

function XUiBigWorldHud:AddEventHandler()
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_TEACH_UNLOCK, self.OnRefreshTeachRedPoint, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_TEACH_READ, self.OnRefreshTeachRedPoint, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_RED_POINT_REFRESH, self.RefreshQuestRedPoint, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_FUNCTION_SHIELD_CHANEG, self.OnShieldChange, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_FUNCTION_SHIELD_CONTROL, self.OnShieldControl, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_FINISH_NOTIFY, self.OnMessageChange, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_RECORD_MESSAGE_NOTIFY, self.OnMessageChange, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_RECEIVE_MESSAGE_NOTIFY, self.OnMessageChange, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_HUD_RED_POINT_REFRESH, self.OnRefreshRedPoint, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_FUNCTION_EVENT_BEGIN, self.RefreshFunction, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_FIGHT_LEVEL_BEGIN_UPDATE, self.RefreshBtnQuit, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_BOX_DATA_UPDATE, self.OnRefreshCourseRedPoint, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.OnRefreshCourseRedPoint, self)
end

function XUiBigWorldHud:RemoveEventHandler()
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_TEACH_UNLOCK, self.OnRefreshTeachRedPoint, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_TEACH_READ, self.OnRefreshTeachRedPoint, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_RED_POINT_REFRESH, self.RefreshQuestRedPoint, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_FUNCTION_SHIELD_CHANEG, self.OnShieldChange, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_FUNCTION_SHIELD_CONTROL, self.OnShieldControl, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_FINISH_NOTIFY, self.OnMessageChange, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_RECORD_MESSAGE_NOTIFY, self.OnMessageChange, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_RECEIVE_MESSAGE_NOTIFY, self.OnMessageChange, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_HUD_RED_POINT_REFRESH, self.OnRefreshRedPoint, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_FUNCTION_EVENT_BEGIN, self.RefreshFunction, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_FIGHT_LEVEL_BEGIN_UPDATE, self.RefreshBtnQuit, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_BOX_DATA_UPDATE, self.OnRefreshCourseRedPoint, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.OnRefreshCourseRedPoint, self)
end


--region 按钮交互

function XUiBigWorldHud:OnBtnQuitClick()
    if XMVCA.XBigWorldGamePlay:IsInstLevel() then
        self:RecordHudClick(BtnIndex.BtnQuitInst)
        local t = CS.StatusSyncFight.XLevelConfig.GetTemplate(XMVCA.XBigWorldGamePlay:GetCurrentLevelId())
        XMVCA.XBigWorldCommon:OnOpenLeaveInstLevelPopup({
            LevelSubType = t.LevelSubType
        })
    else
        self:RecordHudClick(BtnIndex.BtnQuit)
        if self:IsShowConfirm() then
            local data = XMVCA.XBigWorldCommon:GetPopupConfirmData()
            local toggleTip = XMVCA.XBigWorldService:GetText("NoTipToday")
            local tip = XMVCA.XBigWorldService:GetText("WordTipExit")
            local exitCb = function()
                self:SaveConfirm()
                XMVCA.XBigWorldGamePlay:ExitGame()
            end
            local toggleCb = handler(self, self.UpdateConfirm)
            data:InitInfo(nil, tip):InitSureClick(nil, exitCb):InitToggle(toggleTip, toggleCb)
            --打开界面失败，直接退出空花
            if not XMVCA.XBigWorldUI:OpenConfirmPopup(data) then
                XMVCA.XBigWorldGamePlay:ExitGame()
            end
        else
            XMVCA.XBigWorldGamePlay:ExitGame()
        end
    end
end

function XUiBigWorldHud:OnBtnTaskClick()
    if XMVCA.XBigWorldGamePlay:IsInstLevel() then
        return
    end
    self:RecordHudClick(BtnIndex.BtnQuest)
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenQuest()
end

function XUiBigWorldHud:OnBtnMessageClick()
    self:RecordHudClick(BtnIndex.BtnMessageNew)
    XMVCA.XBigWorldMessage:OpenUnReadMessageUi()
end

function XUiBigWorldHud:OnBtnMessageListClick()
    self:RecordHudClick(BtnIndex.BtnMessage)
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenMessage()
end

function XUiBigWorldHud:OnBtnTeamClick()
    self:RecordHudClick(BtnIndex.BtnTeam)
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenTeam()
end

function XUiBigWorldHud:OnBtnBagClick()
    self:RecordHudClick(BtnIndex.BtnBag)
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenBackpack()
end

function XUiBigWorldHud:OnBtnHandBookClick()
    self:RecordHudClick(BtnIndex.BtnExplore)
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenExplore()
end

function XUiBigWorldHud:OnBtnPhotoClick()
    self:RecordHudClick(BtnIndex.BtnPhoto)
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenPhoto()
end

function XUiBigWorldHud:OnBtnSetClick()
    self:RecordHudClick(BtnIndex.BtnSetting)
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenSetting()
end

function XUiBigWorldHud:OnBtnTeachClick()
    self:RecordHudClick(BtnIndex.BtnTeach)
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():OpenTeaching()
end

function XUiBigWorldHud:OnBtnMenuClick()
    self._IsShowMenu = not self._IsShowMenu
    local cueId = self._IsShowMenu and 5600053 or 5600054
    XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, cueId)
    self:RefreshMenu()
    self:RecordHudClick(BtnIndex.BtnMenu)
end

function XUiBigWorldHud:RefreshMenu()
    local anim
    if self._IsShowMenu then
        anim = "ListMenuEnable"
    else
        anim = "ListMenuDisable"
    end
    self.ListMenu.gameObject:SetActiveEx(true)
    self:PlayAnimation(anim, self._RefreshMenuAnimationCb)
end

--endregion



--region 红点
function XUiBigWorldHud:RefreshFunction()
    local checkAlbum = XMVCA.XBigWorldFunction:CheckFunctionOpen(XMVCA.XBigWorldFunction.FunctionId.BigWorldAlbum) 
            and not XMVCA.XBigWorldFunction:CheckFunctionShield(XMVCA.XBigWorldFunction.FunctionType.Photo)
    
    self.BtnPhoto.gameObject:SetActiveEx(checkAlbum)
    
    local checkCourse = XMVCA.XBigWorldFunction:CheckFunctionOpen(XMVCA.XBigWorldFunction.FunctionId.BigWorldCourse) 
            and not XMVCA.XBigWorldFunction:CheckFunctionShield(XMVCA.XBigWorldFunction.FunctionType.Process)
    
    self.BtnHandBook.gameObject:SetActiveEx(checkCourse)
    self:RefreshMessage()
end

function XUiBigWorldHud:RefreshShield()
    XMVCA.XBigWorldFunction:GetSystemFunctionState()
    self:OnShieldChange()
end

function XUiBigWorldHud:RefreshBtnQuit()
    local isInstLevel = XMVCA.XBigWorldGamePlay:IsInstLevel()
    self.BtnQuitDoor2.gameObject:SetActiveEx(isInstLevel)
    self.BtnQuit.gameObject:SetActiveEx(not isInstLevel)
end

function XUiBigWorldHud:RefreshRedPoint()
    self:RefreshQuestRedPoint()
    self:RefreshButtonHelpRedPoint()
    self:RefreshCourseRedPoint()
    self:RefreshMessageRedPoint()
    self:RefreshMainMenuRedPoint()
end

function XUiBigWorldHud:RefreshQuestRedPoint()
    self.BtnTask:ShowReddot(XMVCA.XBigWorldQuest:CheckQuestRed())
end

function XUiBigWorldHud:RefreshButtonHelpRedPoint()
    self.BtnTeach:ShowReddot(XMVCA.XBigWorldTeach:CheckHasUnReadTeach())
end

function XUiBigWorldHud:RefreshCourseRedPoint()
    self.BtnHandBook:ShowReddot(XMVCA.XBigWorldCourse:CheckAllAchieved())
end

function XUiBigWorldHud:RefreshMessageRedPoint()
    self.BtnMessageList:ShowReddot(XMVCA.XBigWorldMessage:CheckUnReadMessage())
end

function XUiBigWorldHud:RefreshMainMenuRedPoint()
    if XMVCA.XBigWorldTeach:CheckHasUnReadTeach() or XMVCA.XBigWorldMessage:CheckUnReadMessage() then
        self.BtnMenu:ShowReddot(true)
        return
    end
    
    self.BtnMenu:ShowReddot(false)
end

--endregion

-- region 事件

function XUiBigWorldHud:OnShieldChange()
    self:RefreshFunction()
    if XMVCA.XBigWorldFunction:CheckFunctionShield(XMVCA.XBigWorldFunction.FunctionType.Task) then
        self.PanelQuest:Close()
    else
        self.PanelQuest:Open()
    end
    if XMVCA.XBigWorldFunction:CheckFunctionShield(XMVCA.XBigWorldFunction.FunctionType.Map) then
        self.LittleMap:Close()
    else
        self.LittleMap:Open()
    end
    if XMVCA.XBigWorldFunction:CheckFunctionShield(XMVCA.XBigWorldFunction.FunctionType.Team) then
        self.BtnTeam.gameObject:SetActiveEx(false)
    else
        self.BtnTeam.gameObject:SetActiveEx(true)
    end
    if XMVCA.XBigWorldFunction:CheckFunctionShield(XMVCA.XBigWorldFunction.FunctionType.TaskEntry) then
        self.BtnTask.gameObject:SetActiveEx(false)
    else
        self.BtnTask.gameObject:SetActiveEx(true)
    end
    if XMVCA.XBigWorldFunction:CheckFunctionShield(XMVCA.XBigWorldFunction.FunctionType.Bag) then
        self.BtnBag.gameObject:SetActiveEx(false)
    else
        self.BtnBag.gameObject:SetActiveEx(true)
    end
    if XMVCA.XBigWorldFunction:CheckFunctionShield(XMVCA.XBigWorldFunction.FunctionType.MainMenu) then
        self.BtnMenu.gameObject:SetActiveEx(false)
        self.ListMenu.gameObject:SetActiveEx(false)
    else
        self.BtnMenu.gameObject:SetActiveEx(true)
        self.ListMenu.gameObject:SetActiveEx(self._IsShowMenu)
    end
    if XMVCA.XBigWorldFunction:CheckFunctionShield(XMVCA.XBigWorldFunction.FunctionType.Set) then
        self.BtnSet.gameObject:SetActiveEx(false)
    else
        self.BtnSet.gameObject:SetActiveEx(true)
    end
    if XMVCA.XBigWorldFunction:CheckFunctionShield(XMVCA.XBigWorldFunction.FunctionType.Teach) then
        self.BtnTeach.gameObject:SetActiveEx(false)
    else
        self.BtnTeach.gameObject:SetActiveEx(true)
    end
end

function XUiBigWorldHud:OnShieldControl()
    self:RefreshMessage()
end

function XUiBigWorldHud:OnMessageChange()
    self:RefreshMessage()
    self:RefreshMessageRedPoint()
    self:RefreshMainMenuRedPoint()
end

-- endregion

function XUiBigWorldHud:IsShowConfirm()
    local timeStamp = XTime.GetSeverNextRefreshTime()
    local key = XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetCookieKey(string.format("EXIT_CONFIRM_%s", timeStamp))
    local data = XSaveTool.GetData(key)
    if not data then
        return true
    end
    return false
end

function XUiBigWorldHud:UpdateConfirm(isOn)
    self._IsShowConfirm = isOn
end

function XUiBigWorldHud:SaveConfirm()
    if not self._IsShowConfirm then
        return
    end
    local timeStamp = XTime.GetSeverNextRefreshTime()
    local key = XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetCookieKey(string.format("EXIT_CONFIRM_%s", timeStamp))
    XSaveTool.SaveData(key, true)
end

function XUiBigWorldHud:RefreshMessage()
    local isShowList = XMVCA.XBigWorldFunction:CheckFunctionOpen(XMVCA.XBigWorldFunction.FunctionId.BigWorldMessage)
            and not XMVCA.XBigWorldFunction:CheckFunctionShield(XMVCA.XBigWorldFunction.FunctionType.Message)
    
    local isShow = XMVCA.XBigWorldMessage:CheckUnReadMessage() and not XMVCA.XBigWorldMessage:CheckUnReadMessageShield() 
            and isShowList

    self.BtnMessage.gameObject:SetActiveEx(isShow)
    self.BtnMessageList.gameObject:SetActiveEx(isShowList)
    if isShow then
        self.BtnMessage:ShowTag(XMVCA.XBigWorldMessage:CheckMessageUnRecord())
    end
end

function XUiBigWorldHud:OnSetActive(value)
    if self._Active == value then
        return
    end
    self._Active = value
    
    --当前帧
    local frameCount = CS.UnityEngine.Time.frameCount
    --同一帧内，设置多次，直接取最新结果，不再播放动画
    if frameCount == self._SetFrameCount then
        if self._PlayingAnima then
            self:StopAnimation(self._PlayingAnima, true, true)
        end
        self._PlayingAnima = false
        self:SetActive(value)
        
        return
    end
    self._SetFrameCount = frameCount
    --有动画正在播放，立即停掉动画
    if self._PlayingAnima then
        self:StopAnimation(self._PlayingAnima, false, true)
    end
    if value then
        self:DoPlayEnable()
    else
        self:DoPlayDisable()
    end
end

function XUiBigWorldHud:DoPlayEnable()
    local name = "Enable"
    self._PlayingAnima = name
    --先显示节点
    self:SetActive(true)
    --再播放动画
    self:PlayAnimation(name, self._OnEnableAnimCb)
end

function XUiBigWorldHud:OnEnableAnimEnd()
    self._PlayingAnima = false
end

function XUiBigWorldHud:DoPlayDisable()
    local name = "Disable"
    self._PlayingAnima = name
    --先播放动画。播放完成后再隐藏节点
    self:PlayAnimation(name, self._OnDisableAnimCb)
end

function XUiBigWorldHud:OnDisableAnimEnd()
    self._PlayingAnima = false
    --隐藏节点
    self:SetActive(false)
end

function XUiBigWorldHud:OnRefreshRedPoint()
    self:RefreshRedPoint()
end

function XUiBigWorldHud:OnRefreshCourseRedPoint()
    self:RefreshCourseRedPoint()
end

function XUiBigWorldHud:OnRefreshTeachRedPoint()
    self:RefreshMainMenuRedPoint()
    self:RefreshButtonHelpRedPoint()
end

function XUiBigWorldHud:RecordHudClick(btnIndex)
    XMVCA.XBigWorldGamePlay:GetCurrentAgency():RecordHudClick(btnIndex)
end

function XUiBigWorldHud:RecordLittleMapClick()
    self:RecordHudClick(BtnIndex.BtnLittleMap)
end

function XUiBigWorldHud:RecordQuestClick()
    self:RecordHudClick(BtnIndex.BtnQuest)
end

return XUiBigWorldHud