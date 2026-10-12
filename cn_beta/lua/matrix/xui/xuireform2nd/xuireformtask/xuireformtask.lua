local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XDynamicGridTask = require("XUi/XUiTask/XDynamicGridTask")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

-- ======== AUTO FIELDS BEGIN ========
---@class XUiReformTask : XLuaUi
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field PanelAsset UnityEngine.RectTransform
---@field SViewTask UnityEngine.UI.ScrollRect
---@field GridTask UnityEngine.RectTransform
---@field ImgEmpty UnityEngine.UI.Image
-- ======== AUTO FIELDS END ========
local XUiReformTask = XLuaUiManager.Register(XLuaUi, "UiReformTask")

function XUiReformTask:OnAwake()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
end

function XUiReformTask:OnStart()
    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self.GridTask.gameObject:SetActiveEx(false)

    self._DynamicTable = XDynamicTableNormal.New(self.SViewTask.transform)
    self._DynamicTable:SetProxy(XDynamicGridTask)
    self._DynamicTable:SetDelegate(self)
end

function XUiReformTask:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.OnRefresh, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_MULTI, self.OnRefresh, self)
    self:_Refresh()
end

function XUiReformTask:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.OnRefresh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_MULTI, self.OnRefresh, self)
end

function XUiReformTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)

        grid.RootUi = self
        grid:ResetData(data)
    end
end

function XUiReformTask:OnRefresh()
    self:_Refresh()
end

function XUiReformTask:_Refresh()
    if not self.GameObject:Exist() then
        return
    end

    local tasks = XDataCenter.TaskManager.GetTaskList(XDataCenter.TaskManager.TaskType.Reform)
    XDataCenter.TaskManager.SortTaskList(tasks)
    tasks = XDataCenter.TaskManager.AddReceiveDataIfAchieved(tasks)
    self._DynamicTable:SetDataSource(tasks)
    self._DynamicTable:ReloadDataASync()

    self.ImgEmpty.gameObject:SetActiveEx(#tasks == 0)
end

return XUiReformTask

-- ======== UI INFO BEGIN ========
--[[
# UiReformTask UI 信息
- GameObject: `UiReformTask`
- Hierarchy 路径: `UiReformTask`
- 基类: XLuaUi

## 节点树（被 UiObject 引用的物体会标注变量名）
```
UiReformTask
└─ Animation
  └─ AnimEnable
└─ FullScreenBackground
  └─ RImgFestivalBg
  └─ FxBgEffect
    └─ Root
      └─ guangLizi
      └─ guangLizi
└─ SafeAreaContentPane
  └─ TopControlWhite
    └─ BtnBack
      └─ Normal
        └─ ImgNormal
          └─ TextBack
        └─ ImgNormalTxt
          └─ Txt1
          └─ TextBack
        └─ ImgNormalHandle
          └─ PcHandle
          └─ TextBack
      └─ Press
        └─ ImgNormal
          └─ TextBack
        └─ ImgNormalTxt
          └─ Txt1
          └─ TextBack
        └─ ImgNormalHandle
          └─ PcHandle
          └─ TextBack
      └─ Select
      └─ Disable
    └─ BtnMainUi
      └─ Normal
        └─ ImgNormal
          └─ TextMainUi
        └─ ImgNormalTxt
          └─ Txt1
          └─ TextMainUi
        └─ ImgNormalHandle
          └─ PcHandle
          └─ TextMainUi
      └─ Press
        └─ ImgNormal
          └─ TextMainUi
        └─ ImgNormalTxt
          └─ Txt1
          └─ TextMainUi
        └─ ImgNormalHandle
          └─ PcHandle
          └─ TextMainUi
      └─ Select
      └─ Disable
  └─ PanelChallengeLevel
    └─ Bg
    └─ Text1
  └─ SViewTask (被UiObject引用: SViewTask)
    └─ Viewport
      └─ Content
        └─ GridTask
          └─ PanelAnimation
            └─ Bg
            └─ RImgTaskType
            └─ TxtTaskName
            └─ TxtTaskDescribe
            └─ TxtTaskNumQian
            └─ TxtSubTypeTip
            └─ ProgressBg
              └─ ImgProgress
            └─ TaskGridList
              └─ Viewport
                └─ Content
                  └─ GridCommon
                    └─ Bg
                    └─ Tri
                    └─ RImgIcon
                    └─ PanelSite
                      └─ TxtSite
                    └─ ImgQuality
                    └─ PanelTxt
                      └─ TxtCount
                    └─ BtnClick
                    └─ TxtName
            └─ BtnReceiveHave
              └─ Text
            └─ BtnSkip
              └─ Normal
                └─ ImgNormal
                └─ Txt
                └─ Image
                └─ Effect
              └─ Press
                └─ ImgNormal
                └─ Txt
                └─ Image
              └─ Select
              └─ Disable
                └─ Image
                └─ Txt
                └─ Lock
                └─ Image
            └─ BtnFinish
              └─ Normal
                └─ ImgNormal
                └─ Txt
                └─ Effect
              └─ Press
                └─ ImgNormal
                └─ Txt
              └─ Select
              └─ Disable
                └─ Image
                └─ Txt
            └─ ImgComplete
              └─ Text
    └─ Scrollbar
      └─ Handle
  └─ PanelAsset
    └─ PanelTool1
      └─ Bg
      └─ RImgTool1
      └─ TxtTool1
      └─ BtnBuyJump1
        └─ Normal
          └─ ImgNormal
        └─ Press
          └─ ImgNormal
        └─ Select
        └─ Disable
          └─ ImgNormal
    └─ PanelTool2
      └─ Bg
      └─ RImgTool2
      └─ TxtTool2
      └─ BtnBuyJump2
        └─ Normal
          └─ ImgNormal
        └─ Press
          └─ ImgNormal
        └─ Select
        └─ Disable
          └─ ImgNormal
    └─ PanelTool3
      └─ Bg
      └─ RImgTool3
      └─ TxtTool3
      └─ BtnBuyJump3
        └─ Normal
          └─ ImgNormal
        └─ Press
          └─ ImgNormal
        └─ Select
        └─ Disable
          └─ ImgNormal
  └─ Dark
  └─ ImgEmpty (被UiObject引用: ImgEmpty)
    └─ TxtNone
```

## UiObject 引用
| 变量名 | 组件类型 | MidPath |
|---|---|---|
| `BtnBack` | XUiButton | `SafeAreaContentPane/TopControlWhite/BtnBack` |
| `BtnMainUi` | XUiButton | `SafeAreaContentPane/TopControlWhite/BtnMainUi` |
| `PanelAsset` | RectTransform | `SafeAreaContentPane/PanelAsset` |
| `SViewTask` | XDynamicTableNormal | `SafeAreaContentPane/SViewTask` |
| `GridTask` | RectTransform | `SafeAreaContentPane/SViewTask/Viewport/Content/GridTask` |
| `ImgEmpty` | Image | `SafeAreaContentPane/ImgEmpty` |

## 子 UI 引用
| 变量名 | 目标 UI |
|---|---|
| `PanelAsset` | `PanelAsset` |
| `GridTask` | `GridTask` |
]]
-- ======== UI INFO END ========

