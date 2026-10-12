require("XCommon/XDynamicList")
local XUiPacMan2OverlayDialogueItem = require("XUi/XUiPacMan2/XUiPacMan2OverlayDialogueItem")

local EmptyDialogues = {}

---@class XUiPacMan2EventOverlay : XLuaUi
---PacMan2事件Overlay界面。
---
---本界面只负责显示外部传入的消息列表，
---不保存业务消息、不决定消息何时追加。
local XUiPacMan2EventOverlay = XLuaUiManager.Register(XLuaUi, "UiPacMan2EventOverlay")

function XUiPacMan2EventOverlay:OnAwake()
    -- 页面只持有当前用于显示的列表引用。
    -- 消息的真正所有者是OverlayDialogueData。
    self._DialogueData = EmptyDialogues

    -- 使用当前UiObject中已经绑定好的三个模板。
    self._DialogueTemplates = {
        Left = self.PanelTxtLayout1,
        Right = self.PanelTxtLayout2,
        System = self.PanelTxtLayout3,
    }

    -- 模板留在原位置，但不作为实际消息显示。
    for _, template in pairs(self._DialogueTemplates) do
        template.gameObject:SetActiveEx(false)
    end

    self._DynamicList = XDynamicList.New(self.PanelChatView)

    -- 数据按“最新在前”保存，界面按时间顺序从上到下显示。
    self._DynamicList:SetReverse(true)

    -- 不同样式使用独立对象池，避免左、右、蓝底模板相互混用。
    for style, template in pairs(self._DialogueTemplates) do
        self._DynamicList:AddObjectPools(style, template.gameObject)
    end

    -- 页面只转发跳过请求，具体业务由Game负责。
    self._OnSkip = nil

    if self.BtnSkip then
        XUiHelper.RegisterClickEvent(self, self.BtnSkip, self.RequestSkip)
        self.BtnSkip.gameObject:SetActiveEx(false)
    end

    self._RefreshDialogueCallback = function(data, getItem)
        local item = getItem(data.Style, XUiPacMan2OverlayDialogueItem.New)
        item:Refresh(data)
    end
end

function XUiPacMan2EventOverlay:OnEnable()
    -- 重新显示时根据当前数据重新构建可视节点。
    self._DynamicList:SetViewSize(self.PanelChatView.rect.size, false)
    self:_RefreshDialogues()
end

function XUiPacMan2EventOverlay:OnDisable()
    -- 隐藏Overlay只影响页面显示。
    -- 消息数据由外部OverlayDialogueData管理。
end

function XUiPacMan2EventOverlay:OnDestroy()
    -- 解除C#动态列表对Lua回调的引用。
    if self._DynamicList then
        local dynamicList = self._DynamicList.DynamicList

        if not XTool.UObjIsNil(dynamicList) then
            dynamicList.tableViewGridDelegate = nil
        end
    end

    -- 对象池中的显示节点属于Overlay层级，随界面一起销毁。
    self._DynamicList = nil
    self._DialogueData = nil
    self._DialogueTemplates = nil
    self._RefreshDialogueCallback = nil
    self._OnSkip = nil
end


---设置当前需要显示的完整消息列表。
---本界面不修改该列表，只读取并交给DynamicList。
---@param dialogues table[]|nil
function XUiPacMan2EventOverlay:SetDialogueData(dialogues)
    self._DialogueData = dialogues or EmptyDialogues

    if self.GameObject.activeInHierarchy then
        self:_RefreshDialogues()
    end
end

---增量显示一条新消息。
---业务数据已经由OverlayDialogueData保存，
---本接口只把新增消息加入DynamicList显示数据。
---@param dialogue table
function XUiPacMan2EventOverlay:InsertDialogue(dialogue)
    if not dialogue then
        return
    end

    -- DialogueData将最新消息放在数组头部，
    -- DynamicList同样从Head插入，保持两边顺序一致。
    self._DynamicList:InsertData({ dialogue, }, DLInsertDataDir.Head, true)

    self:_ScrollToLatestDialogue()
end

---设置跳过响应；传nil时隐藏按钮并停止接受跳过请求。
---@param callback function|nil
function XUiPacMan2EventOverlay:SetSkipCallback(callback)
    self._OnSkip = callback

    if self.BtnSkip then
        self.BtnSkip.gameObject:SetActiveEx(callback ~= nil)
    end
end


---按钮和调试入口共用此方法。
---@return boolean 是否受理
function XUiPacMan2EventOverlay:RequestSkip()
    if not self._OnSkip then
        return false
    end
    return self._OnSkip()
end


---根据外部传入的数据完整刷新页面。
---只在页面首次取得数据或重新启用时使用。
function XUiPacMan2EventOverlay:_RefreshDialogues()
    self._DynamicList:SetData(self._DialogueData, self._RefreshDialogueCallback)
    self:_ScrollToLatestDialogue()
end

---停止原有惯性并定位到最新消息。
function XUiPacMan2EventOverlay:_ScrollToLatestDialogue()
    local dynamicList = self._DynamicList.DynamicList
    dynamicList:StopMovement()
    dynamicList.verticalNormalizedPosition = 0
end

return XUiPacMan2EventOverlay