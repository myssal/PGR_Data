---@class XUiBigWorldSetPanelVoice : XBigWorldUi
---@field TogControl UnityEngine.UI.Toggle
---@field SliderMusic UnityEngine.UI.Slider
---@field SliderSound UnityEngine.UI.Slider
---@field SliderVoice UnityEngine.UI.Slider
---@field TLanguageGroup UnityEngine.UI.ToggleGroup
---@field TogJP UnityEngine.UI.Toggle
---@field TogCN UnityEngine.UI.Toggle
---@field TogHK UnityEngine.UI.Toggle
---@field TogEN UnityEngine.UI.Toggle
---@field TFashionGroup UnityEngine.UI.ToggleGroup
---@field TogFashionClose UnityEngine.UI.Toggle
---@field TogFashionOpen UnityEngine.UI.Toggle
---@field PanelMute UnityEngine.RectTransform
---@field TogMute UnityEngine.UI.Toggle
---@field ImgVoiceFill UnityEngine.UI.Image
---@field TxtVoice UnityEngine.UI.Text
---@field ImgVoiceOFF UnityEngine.UI.Image
---@field ImgVoiceON UnityEngine.UI.Image
---@field ImgSoundON UnityEngine.UI.Image
---@field ImgSoundOFF UnityEngine.UI.Image
---@field TxtSound UnityEngine.UI.Text
---@field ImgSoundFill UnityEngine.UI.Image
---@field ImgMusicON UnityEngine.UI.Image
---@field ImgMusicOFF UnityEngine.UI.Image
---@field ImgMusicFill UnityEngine.UI.Image
---@field TxtMusic UnityEngine.UI.Text
---@field SafeAreaContentPanel XUiSafeAreaAdapter
---@field ParentUi XUiBigWorldSet
---@field _Control XBigWorldSetControl
local XUiBigWorldSetPanelVoice = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldSetPanelVoice")

function XUiBigWorldSetPanelVoice:OnAwake()
    self:_RegisterButtonClicks()
    ---@type XBWAudioSetting
    self._Setting = false

    self._OffColor = self.ImgMusicOFF.color
    self._OnColor = self.ImgMusicON.color
    self._FillColor = self.ImgMusicFill.color
    self._VoiceTextColor = self.TxtMusic.color

    self:_InitUi()
end

function XUiBigWorldSetPanelVoice:OnStart()
    self._Setting = self._Control:GetSettingBySetType(XEnumConst.BWSetting.SetType.Voice)
end

function XUiBigWorldSetPanelVoice:OnEnable()
    self._Control:RefreshSpecialScreenOff(self.SafeAreaContentPanel)
    self:_Refresh()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldSetPanelVoice:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldSetPanelVoice:OnDestroy()
end

function XUiBigWorldSetPanelVoice:OnSliderMusicValueChanged(value)
    self._Setting:SetMusicVolumeValue(value)
end

function XUiBigWorldSetPanelVoice:OnSliderSoundValueChanged(value)
    self._Setting:SetSoundVolumeValue(value)
end

function XUiBigWorldSetPanelVoice:OnSliderVoiceValueChanged(value)
    self._Setting:SetVoiceVolumeValue(value)
end

function XUiBigWorldSetPanelVoice:OnTogControlClick(value)
    if value == 1 then
        self._Setting:SetVolumeControlValue(XEnumConst.BWSetting.VolumeControl.ON)
    else
        self._Setting:SetVolumeControlValue(XEnumConst.BWSetting.VolumeControl.OFF)
    end

    self:_RefreshVolumeControl(value == 1)
end

function XUiBigWorldSetPanelVoice:OnTLanguageGroupClick(index)
    --- 英语和粤语语音资源暂未实装
    if index == XEnumConst.CV_TYPE.EN or index == XEnumConst.CV_TYPE.HK then
        XMVCA.XBigWorldUI:TipText("LanguageSetTips")
    end
    self._Setting:SetCvTypeValue(index)
end

function XUiBigWorldSetPanelVoice:OnTFashionGroupClick(index)
    self._Setting:SetFashionVoiceValue(index)
end

function XUiBigWorldSetPanelVoice:OnTogJPClick(value)
    if value then
        self._Setting:SetCvTypeValue(XEnumConst.CV_TYPE.JPN)
    end
end

function XUiBigWorldSetPanelVoice:OnTogCNClick(value)
    if value then
        self._Setting:SetCvTypeValue(XEnumConst.CV_TYPE.CN)
    end
end

function XUiBigWorldSetPanelVoice:OnTogHKClick(value)
    if value then
        self._Setting:SetCvTypeValue(XEnumConst.CV_TYPE.HK)
    end
end

function XUiBigWorldSetPanelVoice:OnTogENClick(value)
    if value then
        self._Setting:SetCvTypeValue(XEnumConst.CV_TYPE.EN)
    end
end

function XUiBigWorldSetPanelVoice:OnTogFashionCloseClick(value)
    if value then
        self._Setting:SetFashionVoiceValue(XEnumConst.BWSetting.FashionVoice.Close)
    end
end

function XUiBigWorldSetPanelVoice:OnTogFashionOpenClick(value)
    if value then
        self._Setting:SetFashionVoiceValue(XEnumConst.BWSetting.FashionVoice.Open)
    end
end

function XUiBigWorldSetPanelVoice:OnTogMuteClick(value)
    self._Setting:SetMuteInBackgroundValue(value == 1)
end

function XUiBigWorldSetPanelVoice:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    XUiHelper.RegisterSliderChangeEvent(self, self.SliderMusic, self.OnSliderMusicValueChanged, false)
    XUiHelper.RegisterSliderChangeEvent(self, self.SliderSound, self.OnSliderSoundValueChanged, false)
    XUiHelper.RegisterSliderChangeEvent(self, self.SliderVoice, self.OnSliderVoiceValueChanged, false)
    self.TogControl.CallBack = Handler(self, self.OnTogControlClick)

    self.TLanguageGroup:Init({
        self.TogJP,
        self.TogCN,
        self.TogHK,
        self.TogEN,
    }, Handler(self, self.OnTLanguageGroupClick))
    self.TFashionGroup:Init({
        self.TogFashionClose,
        self.TogFashionOpen,
    }, Handler(self, self.OnTFashionGroupClick))

    self.TogMute.CallBack = Handler(self, self.OnTogMuteClick)
end

function XUiBigWorldSetPanelVoice:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SETTING_RESET, self._Refresh, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SETTING_RESTORE, self._Refresh, self)
end

function XUiBigWorldSetPanelVoice:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SETTING_RESET, self._Refresh, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_SETTING_RESTORE, self._Refresh, self)
end

function XUiBigWorldSetPanelVoice:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldSetPanelVoice:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldSetPanelVoice:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldSetPanelVoice:_InitUi()
    local isShowMute = false
    if XDataCenter.UiPcManager.GetUiPcMode() == XDataCenter.UiPcManager.XUiPcMode.Pc then
        isShowMute = true
    end
    self.PanelMute.gameObject:SetActiveEx(isShowMute)
end

function XUiBigWorldSetPanelVoice:_Refresh()
    if self._Setting:GetVolumeControlValue() == XEnumConst.BWSetting.VolumeControl.ON then
        self.TogControl:SetButtonState(CS.UiButtonState.Select)
        self:_RefreshVolumeControl(true)
    else
        self.TogControl:SetButtonState(CS.UiButtonState.Normal)
        self:_RefreshVolumeControl(false)
    end
    if self._Setting:GetMuteInBackgroundValue() then
        self.TogMute:SetButtonState(CS.UiButtonState.Select)
    else
        self.TogMute:SetButtonState(CS.UiButtonState.Normal)
    end

    self.TLanguageGroup:SelectIndex(self._Setting:GetCvTypeValue(), false)
    self.TFashionGroup:SelectIndex(self._Setting:GetFashionVoiceValue(), false)
    self.SliderMusic.value = self._Setting:GetMusicVolumeValue()
    self.SliderSound.value = self._Setting:GetSoundVolumeValue()
    self.SliderVoice.value = self._Setting:GetVoiceVolumeValue()
end

function XUiBigWorldSetPanelVoice:_RefreshVolumeControl(isOn)
    self:_ChangeVolumeTansparent(isOn and 1 or 0.5)
    self.SliderMusic.interactable = isOn
    self.SliderSound.interactable = isOn
    self.SliderVoice.interactable = isOn
end

function XUiBigWorldSetPanelVoice:_ChangeVolumeTansparent(alpha)
    self._VoiceTextColor.a = alpha
    self._FillColor.a = alpha
    self._OnColor.a = alpha
    self._OffColor.a = alpha

    self.TxtMusic.color = self._VoiceTextColor
    self.TxtSound.color = self._VoiceTextColor
    self.TxtVoice.color = self._VoiceTextColor

    self.ImgMusicFill.color = self._FillColor
    self.ImgSoundFill.color = self._FillColor
    self.ImgVoiceFill.color = self._FillColor

    self.ImgMusicOFF.color = self._OffColor
    self.ImgSoundOFF.color = self._OffColor
    self.ImgVoiceOFF.color = self._OffColor

    self.ImgMusicON.color = self._OnColor
    self.ImgSoundON.color = self._OnColor
    self.ImgVoiceON.color = self._OnColor
end

return XUiBigWorldSetPanelVoice
