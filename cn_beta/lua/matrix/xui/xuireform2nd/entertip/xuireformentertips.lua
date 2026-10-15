-- ======== AUTO FIELDS BEGIN ========
---@class XUiReformEnterTips : XLuaUi
---@field private _Control XReformControl
---@field GoLock UnityEngine.RectTransform
---@field TxtTip UnityEngine.UI.Text
---@field TxtWeight UnityEngine.UI.Text
-- ======== AUTO FIELDS END ========
local XUiReformEnterTips = XLuaUiManager.Register(XLuaUi, "UiReformEnterTips")

-- 横条自动关闭延迟（UE：N秒后横条消失，恢复点击；N 值待 UE/策划确认，暂定 2 秒）
local AUTO_CLOSE_DELAY = XScheduleManagerPro.SECOND * 2

-- 4.9 天平质点：进入关卡配平环节的横条提示
function XUiReformEnterTips:OnStart(onClosed)
    self._OnClosed = onClosed
    self.TxtWeight.text = self._Control:GetBalanceControl():GetMinQuality()
end

function XUiReformEnterTips:OnEnable()
    XScheduleManagerPro.ScheduleOnce(XUiReformEnterTips._OnAutoCloseScheduleCb, self, AUTO_CLOSE_DELAY)
end

function XUiReformEnterTips:OnDisable()
    XScheduleManagerPro.UnSchedule(XUiReformEnterTips._OnAutoCloseScheduleCb, self)
end

function XUiReformEnterTips:OnDestroy()
    if self._OnClosed then
        self._OnClosed()
        self._OnClosed = nil
    end
end

function XUiReformEnterTips:_OnAutoCloseScheduleCb()
    self:Close()
end

return XUiReformEnterTips

-- ======== UI INFO BEGIN ========
--[[
# UiReformEnterTips UI 信息
- GameObject: `UiReformEnterTips`
- Hierarchy 路径: `UiReformEnterTips`
- 基类: XLuaUi

## 节点树（被 UiObject 引用的物体会标注变量名）
```
UiReformEnterTips
└─ Animation
└─ FullScreenBackground
  └─ BgMask
└─ SafeAreaContentPane
  └─ PanelWeightTip
    └─ RawImage
    └─ PanelTipLayout
      └─ GoLock (被UiObject引用: GoLock)
      └─ TxtTip (被UiObject引用: TxtTip)
      └─ TxtWeight (被UiObject引用: TxtWeight)
```

## UiObject 引用
| 变量名 | 组件类型 | MidPath |
|---|---|---|
| `GoLock` | RectTransform | `SafeAreaContentPane/PanelWeightTip/PanelTipLayout/GoLock` |
| `TxtTip` | Text | `SafeAreaContentPane/PanelWeightTip/PanelTipLayout/TxtTip` |
| `TxtWeight` | Text | `SafeAreaContentPane/PanelWeightTip/PanelTipLayout/TxtWeight` |
]]
-- ======== UI INFO END ========
