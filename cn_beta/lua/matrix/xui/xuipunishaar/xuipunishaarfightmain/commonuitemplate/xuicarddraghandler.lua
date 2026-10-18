--- 卡牌假拖拽处理器（Theatre5 范式）：XGoInputHandler 三阶段 + 阈值区分 click/drag + 跟手 +
--- reparent 到 DragRoot（经 RequestCustody 事件）+ blocksRaycasts 放行 + 保底定时器。
--- 组合到 grid（grid 持 self._DragHandler = XUiCardDragHandler.New(self)）。
--- grid 拥有 _DragCardData/_DragArea/_DragSourcePos/_Control/Transform/GameObject，handler 读这些；
--- 拖拽机制状态（_DragInputCom/_DragCanvasGroup/归位快照/保底定时器）由 handler 自管。
--- C 级塌缩：XUiGridShopCard 与 XUiComShopSubCardItem 拖拽模式字节同构（~130 行 × 2），hoist 至此。
---@class XUiCardDragHandler
local XUiCardDragHandler = XClass(nil, "XUiCardDragHandler")

local UNITY = CS.UnityEngine
local Vector2 = UNITY.Vector2
local DRAG_MOVE_LIMIT = 20
local Vector3Cache = UNITY.Vector3.zero

---@param host XUiGridShopCard|XUiComShopSubCardItem 持有者
function XUiCardDragHandler:Ctor(host)
    self._Host = host
end

--- 开启拖拽能力（幂等：init 一次）。dragArea 由 host 自管（host._DragArea，drop zone 亦读），handler 不存。
function XUiCardDragHandler:Enable()
    if self._DragInited then
        return
    end
    self._DragInited = true

    local host = self._Host
    self._DragContainerTrans = host.Transform.parent
    self._DragDefaultLocalPos = host.Transform.localPosition
    self._DragDefaultSibling = host.Transform:GetSiblingIndex()

    self._DragInputCom = host.GameObject:GetComponent(typeof(CS.XGoInputHandler))
    if XTool.UObjIsNil(self._DragInputCom) then
        self._DragInputCom = host.GameObject:AddComponent(typeof(CS.XGoInputHandler))
    end
    self._DragInputCom:AddBeginDragListener(handler(self, self.OnBeginDrag))
    self._DragInputCom:AddDragListener(handler(self, self.OnDragging))
    self._DragInputCom:AddEndDragListener(handler(self, self.OnEndDrag))

    self._DragCanvasGroup = host.GameObject:GetComponent(typeof(UNITY.CanvasGroup))
    if XTool.UObjIsNil(self._DragCanvasGroup) then
        self._DragCanvasGroup = host.GameObject:AddComponent(typeof(UNITY.CanvasGroup))
    end
    -- 常驻巡检（Enable 起 OnDestroy 停，OnEndDrag 不停，覆盖 OnEndDrag 丢失 + UI 清但逻辑层卡住终态）#拖拽保底
    self:_StartPeriodicCheck()
end

--- toggle XGoInputHandler.enabled（副卡商品禁用 grid 拖拽用）。
---@param value boolean
function XUiCardDragHandler:SetEnabled(value)
    if self._DragInputCom then
        self._DragInputCom.enabled = value
    end
end

--- 重置归位快照（host RefreshPosition 调，SetPosition 改 localPosition 后同步，防拖拽后归错位）。
function XUiCardDragHandler:UpdateSnapshot()
    local host = self._Host
    self._DragContainerTrans = host.Transform.parent
    self._DragDefaultLocalPos = host.Transform.localPosition
    self._DragDefaultSibling = host.Transform:GetSiblingIndex()
end

---@param value boolean
function XUiCardDragHandler:SetBlocksRaycasts(value)
    if self._DragCanvasGroup then
        self._DragCanvasGroup.blocksRaycasts = value
    end
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiCardDragHandler:OnBeginDrag(eventData)
    -- 方向1：源头拦非左键，右/中键不进拖拽态（不动保底守卫极性，绕开"右/中键拖拽被保底误触 _ForceReset 清会话致落位失败"坑）#拖拽按键源头
    -- 字段可达：click 回调已实证（XUiFightCaptureV217:215）；drag 回调未实证，临时 debug log 确认 button 取值后删
    if XMain.IsEditorDebug then
        XLog.Debug("[DragDiag] OnBeginDrag button=" .. tostring(eventData and eventData.button))
    end
    if eventData and eventData.button ~= CS.UnityEngine.EventSystems.PointerEventData.InputButton.Left then
        return
    end
    if self._IsOnEndDrag then
        return  -- OnEndDrag 进行中/异步 cb 未回，拒新 BeginDrag 重入 #拖拽保底
    end
    self._DragBeginScreenPos = eventData.position
    self._IsDragging = false
    -- 按住点跟手 offset：光标本地 - 卡牌本地（原 parent 空间；reparent 后通用因相对偏移与 parent 原点无关、同 canvas 同尺度）#跟手
    local parent = self._Host.Transform.parent
    local ok, point = UNITY.RectTransformUtility.ScreenPointToLocalPointInRectangle(parent, eventData.position, CS.XUiManager.Instance.UiCamera)
    if ok then
        local cardLocal = self._Host.Transform.localPosition
        self._DragOffsetX = point.x - cardLocal.x
        self._DragOffsetY = point.y - cardLocal.y
    else
        self._DragOffsetX = 0
        self._DragOffsetY = 0
    end
    -- 缓存拖拽基准偏移 K #落点重构：源栏 slot sizeDelta.x 作格周期，K=floor(_DragOffsetX/周期)。
    -- OnBeginDrag 即真拖拽起点（Unity 阈值后触发），卡牌尚在原位、指针在源栏内。
    self:_CacheDragBaseline(eventData)
end

function XUiCardDragHandler:OnDragging(eventData)
    -- 方向1续：OnBeginDrag 拦非左键不阻止 Unity 后续派发 OnDragging，须同过滤（PointerEventData.button 跨 Begin/Drag/End 同实例一致）#拖拽按键源头
    if eventData and eventData.button ~= CS.UnityEngine.EventSystems.PointerEventData.InputButton.Left then
        return
    end
    if not self:_CheckCanDrag(eventData) then
        return
    end
    self:_ScreenToLocal(eventData)  -- 填 Vector3Cache（光标在当前 parent 本地）
    Vector3Cache.x = Vector3Cache.x - (self._DragOffsetX or 0)  -- 按住点跟手：光标钉按下时相对卡牌的位置 #跟手
    Vector3Cache.y = Vector3Cache.y - (self._DragOffsetY or 0)
    self._Host.Transform.localPosition = Vector3Cache
    -- 栏级落点反算 + 防抖 + 转发栏容器
    self:_RecomputeFocus(eventData)
end

function XUiCardDragHandler:OnEndDrag(eventData)
    -- 方向1续：同过滤右/中键，免其走 no-op 路径时无条件 blocksRaycasts=true 干扰在途左拖的兄弟 grid 射线穿透 #拖拽按键源头
    -- eventData nil（保底 ①class OnEndDrag(nil) 路径）放行——`eventData and` 短路，nil 不过滤
    if eventData and eventData.button ~= CS.UnityEngine.EventSystems.PointerEventData.InputButton.Left then
        return
    end
    if self._IsOnEndDrag then
        return  -- 重入闭锁（防 Unity 双派发/保底与正常派发双触发）#拖拽保底
    end
    self._IsOnEndDrag = true
    -- 停拖拽期每帧巡检（OnEndDrag 触发即停，cb 丢包终态由常驻 1Hz _StartPeriodicCheck 兜底）
    self:_StopDragCheck()
    -- 清拖拽基准字段 #落点重构（无论是否真拖拽均清，防 OnBeginDrag 缓存残留）
    self:_ClearDragBaseline()
    if self._DragCanvasGroup then
        self._DragCanvasGroup.blocksRaycasts = true
    end
    if not self._IsDragging then
        self._IsOnEndDrag = false
        return
    end
    self._IsDragging = false
    self:_RemoveAppPauseListener()

    local host = self._Host
    local handled = host._Control.GameControl:EndDragCard(handler(self, self._OnDragEndCallback))
    if not handled then
        self:_OnDragEndCallback(false)
    end
end

function XUiCardDragHandler:_OnDragEndCallback(success)
    self:_RestorePosition()
    self._IsOnEndDrag = false
end

--region 落点反算（slot 射线 + G 基准左对齐 #落点重构） -------------------

--- 缓存拖拽基准偏移 K（OnBeginDrag 调）。K = floor(光标相对卡牌左缘位移 / slotWidth)，
--- 即按下时光标位于卡牌左缘右数第几格。OnDragging 中 focusSlot = S - K（S=光标命中 slot），
--- 实现多格卡左对齐（卡牌左缘落 focusSlot）；单格卡 K=0 → focusSlot=S。
--- slotWidth 取源栏 slot sizeDelta.x（slot RT 覆盖完整落点格子、无间隙 → sizeDelta.x=格周期）。
--- pivot.x=0：_DragOffsetX 即「光标 - 卡牌左缘」在源栏 parent 空间位移（卡牌/槽位 parent 坐标对齐，复用跟手 offset）。
--- Shop 无源栏（不在商店栏算 K）→ K=0，落点取命中 slot 直读。
---@param eventData table
function XUiCardDragHandler:_CacheDragBaseline(eventData)
    self._DragBaselineK = 0
    self._LastFocusPos = nil
    local gameControl = self._Host._Control.GameControl
    if not gameControl then
        return
    end
    -- K = floor(抓取偏移 / 卡自身格周期)。卡 sizeDelta.x = unitWidth×size（XUiGridShopCard:166），perSlot=cardWidth/cardSize。
    -- 不依赖源栏 bar slotWidth：Shop 源无注册栏（商店栏未 RegisterDragFocusBar），原 K=0 致多格卡未扣抓取偏移、
    -- focusSlot=hitSlot 卡左缘跟指针 → 3 格卡抓中间拖 slot2 占 2,3,4 越界。Fight/Bag 源 perSlot=源栏 slot.sizeDelta.x 结果不变。#3格卡点中间修复
    -- latent 假设：perSlot 取卡本地 sizeDelta（localScale==1 前提）；若未来给卡加动态缩放须改回 slot parent 宽度
    local cardData = self._Host._DragCardData
    local cardId = cardData and (cardData.CardId or cardData.TemplateId) or nil
    local cardCfg = cardId and gameControl.GetTablePunishaarCard and gameControl:GetTablePunishaarCard(cardId, true) or nil
    local cardSize = (cardCfg and cardCfg.Size) or 1
    local cardTransform = self._Host.Transform
    local cardWidth = cardTransform.sizeDelta.x or 0
    local perSlot = cardSize > 0 and cardWidth / cardSize or 0
    if perSlot > 0 and self._DragOffsetX then
        -- pivot.x 鲁棒折算：_DragOffsetX 是相对 pivot 的偏移，左缘在 pivot 左 pivotX*cardWidth 处。
        -- 折算到左缘后 floor：pivot=0（主卡）退化原式无回归；pivot=0.5（商品副卡）左半按下 _DragOffsetX<0 →
        -- 旧式 K=-1 致 focusSlot=hitSlot+1 偏右一格，折算后 K=0，副卡单格恒落 hitSlot。#副卡落点pivot修复
        local pivotX = cardTransform.pivot.x or 0
        local offsetFromLeftEdge = self._DragOffsetX + pivotX * cardWidth
        self._DragBaselineK = math.floor(offsetFromLeftEdge / perSlot)
        -- K 语义=光标落在卡的第几格(0-based)，不得越 [0, cardSize-1]：
        -- 副卡商品 icon 比格窄(Size=1 但 cardWidth<slotWidth)，抓右缘 floor 得 1 → focusSlot 左偏 1 格(误判)；
        -- 多格卡抓右缘同理得 Size → clamp 回末格(Size-1)。clamp 后单格卡(含副卡)恒 K=0。#副卡窄icon误判
        if self._DragBaselineK < 0 then
            self._DragBaselineK = 0
        elseif self._DragBaselineK >= cardSize then
            self._DragBaselineK = cardSize - 1
        end
    end
end

--- 清空拖拽基准字段（OnEndDrag/CancelDrag 调，防会话残留；OnBeginDrag 会被 _CacheDragBaseline 重置）。
function XUiCardDragHandler:_ClearDragBaseline()
    self._DragBaselineK = nil
    self._LastFocusPos = nil
    self._DragOffsetX = nil  -- 按住点跟手 offset 清理（防下次拖拽残留）#跟手
    self._DragOffsetY = nil
end

--- 落点反算：遍历注册栏，每栏逐 slot RectTransformUtility.RectangleContainsScreenPoint 几何命中，
--- 命中 slot S → focusSlot = S - K（K=OnBeginDrag 缓存基准偏移，多格卡左对齐）。
--- 间隙不命中 → 无栏命中 → 仅清栏区域焦点（不清卖出区 SellZone，其 OnExit 自管 #批次2）。
--- 注入式：handler 经 gameControl:GetDragFocusBars() 取栏遍历 slot，不直读 host.Parent（向上铁律）。
---@param eventData table
function XUiCardDragHandler:_RecomputeFocus(eventData)
    local gameControl = self._Host._Control.GameControl
    local bars = gameControl and gameControl.GetDragFocusBars and gameControl:GetDragFocusBars() or nil
    if not bars then
        return
    end
    local uiCamera = CS.XUiManager.Instance.UiCamera
    -- 逐 slot 几何命中：找光标所在 slot（S=1-based 格号）+ 栏归属
    local hitBar, hitSlot
    for i = 1, #bars do
        local bar = bars[i]
        local count = bar.GetSlotListCount and bar:GetSlotListCount() or 0
        for j = 1, count do
            local slot = bar.GetSlotByIndex and bar:GetSlotByIndex(j)
            if slot and not XTool.UObjIsNil(slot.Transform)
                and UNITY.RectTransformUtility.RectangleContainsScreenPoint(
                        slot.Transform, eventData.position, uiCamera) then
                hitBar, hitSlot = bar, j
                break
            end
        end
        if hitBar then
            break
        end
    end
    if not hitBar then
        -- 无栏命中：仅清栏区域焦点，不清 SellZone 焦点（卖出区未接入栏反算，其 OnExit 自管）
        local curArea = gameControl:GetDragFocusArea()
        if curArea == gameControl.DragArea.FightArea or curArea == gameControl.DragArea.Bag then
            gameControl:ClearDragFocusTarget()
        end
        self._LastFocusPos = nil
        return
    end
    -- G 基准左对齐：focusSlot = S - K（K=按下时光标距卡牌左缘的格数；单格 K=0 → focusSlot=S）
    local focusSlot = hitSlot - (self._DragBaselineK or 0)
    -- 左缘越界 clamp 到 pos1（pos1 解锁合法）；右缘锁定格(>gridLimit) 不 clamp 也不清焦点——透传 focusSlot 原值，
    -- 松开时 _DropAction_Buy 副卡分支 GetMasterCardByAreaPos(lockedPos) 返 nil（锁定格无卡）→ CanMountSubCardOnMaster(nil) false → BuySubCardWithInvalidTarget 弹窗；
    -- 主卡 BuyExact/Repack/CrossGap canExecute dropPos>gridLimit 拒 → _RejectBuyFail hasDropPos 分支 → PunishaarDropPosLocked 弹窗 #锁定格落点非法判定
    -- （旧 clamp focusSlot=gridLimit 致副卡误挂最右已解锁卡；clear-focus 改法致静默归位无弹窗，均非预期，故去右 clamp 走下游判定）
    local barArea = hitBar:GetDragArea()
    local cardArea = (barArea == gameControl.DragArea.FightArea)
        and XMVCA.XPunishaar.EnumConst.CardAreaType.FightArea
        or XMVCA.XPunishaar.EnumConst.CardAreaType.Bag
    local gridLimit = gameControl:_GetAreaGridLimit(cardArea) or 0
    if gridLimit > 0 then
        if focusSlot < 1 then
            focusSlot = 1
        end
    end
    -- 防抖：槽位/区域不变且焦点未被外部清空才跳过（防卖出区 OnExit 清空后误判不重设）
    if focusSlot == self._LastFocusPos and barArea == gameControl:GetDragFocusArea()
        and gameControl:GetDragFocusArea() ~= nil then
        return
    end
    -- 临时诊断日志（需要时取消注释）：K=指针在卡牌第几格(1-based) / hitSlot=指针在栏第几槽(1-based) / focusSlot=卡牌第一格落栏第几槽(1-based)
    -- if XMain.IsWindowsEditor then
    --     XLog.Debug(string.format("[DragDiag] K=%s(指针在卡牌第几格) hitSlot=%s(指针在栏第几槽) focusSlot=%s(卡牌第一格落栏第几槽) area=%s",
    --         tostring((self._DragBaselineK or 0) + 1), tostring(hitSlot), tostring(focusSlot), tostring(barArea)))
    -- end
    self._LastFocusPos = focusSlot
    gameControl:SetDragFocusTarget(barArea, focusSlot)
end

--endregion

function XUiCardDragHandler:_CheckCanDrag(eventData)
    if self._IsDragging then
        return true
    end
    local host = self._Host
    if not host._DragArea then
        return false
    end
    -- 已购商品拒拖拽：点击侧 BtnClick 已按 goods.IsBought 置灰（XUiGridShopCard:216），
    -- 拖拽侧对称补拦截，避免“点击拦、拖拽放”的不对称。非商品卡 IsBought=nil 不触发。#R7
    if host._DragCardData and host._DragCardData.IsBought then
        return false
    end
    if host._Control.GameControl:GetIsDraggingCard() then
        return false
    end
    if Vector2.Distance(self._DragBeginScreenPos, eventData.position) <= DRAG_MOVE_LIMIT then
        return false
    end

    self._IsDragging = true
    if self._DragCanvasGroup then
        self._DragCanvasGroup.blocksRaycasts = false
    end
    -- 兜底先就位再移走节点：reparent/BeginDragCard 之后若抛错，常驻巡检 + PAUSE 监听仍能把节点归位；
    -- 反序（先移走再注册）时一旦中间抛错，节点已在 DragRoot 却无任何兜底守着，将永久滞留。
    -- 拖拽期每帧巡检（对齐 Theatre5 grid 级 interval=0，OnEndDrag 丢失 1 帧内兜底）
    self:_StartDragCheck()
    -- app 切后台监听（仅活跃拖拽期间，结束/销毁即注销，对齐 Theatre5 :208）
    XEventManager.AddEventListener(XEventId.EVENT_APPLICATION_PAUSE, self.OnApplicationPause, self)
    self:_ReparentToDragRoot()
    -- 主卡拖拽时临时缩放（副卡不缩）；缩放值走 ClientConfig key PunishaarDragMainCardScale，0/缺省视为 1（不缩放）。
    -- board 主卡无 CardId（走 TemplateId）→ IsSubCard(nil 短路) false → 主卡；商品主卡 CardId 非 sub → 主卡；副卡商品 CardId sub → 不缩 #拖拽主卡scale
    local dragData = host._DragCardData
    local isSubCard = dragData and dragData.CardId and host._Control:IsSubCard(dragData.CardId) or false
    if not isSubCard then
        local scale = XMVCA.XPunishaar:GetClientNumberByKey("PunishaarDragMainCardScale") or 0
        if scale == 0 then
            scale = 1
        end
        if scale ~= 1 then
            self._DragDefaultLocalScale = host.Transform.localScale
            host.Transform.localScale = UNITY.Vector3(scale, scale, scale)
        end
    end
    host._Control.GameControl:BeginDragCard(host._DragCardData, host._DragArea, host._DragSourcePos)
    -- 通知 host 拖拽开始（host 按需覆写，如商品 grid 隐 PanelBuy）#PanelDragBuyTips
    if host.OnDragBegin then
        host:OnDragBegin()
    end
    return true
end

function XUiCardDragHandler:_ScreenToLocal(eventData)
    local parent = self._Host.Transform.parent
    local ok, point = UNITY.RectTransformUtility.ScreenPointToLocalPointInRectangle(
            parent, eventData.position, CS.XUiManager.Instance.UiCamera)
    if not ok then
        Vector3Cache.x, Vector3Cache.y, Vector3Cache.z = -99999, -99999, 0
        return Vector3Cache
    end
    Vector3Cache.x, Vector3Cache.y, Vector3Cache.z = point.x, point.y, 0
    return Vector3Cache
end

--- 请求把自己托管到高层拖拽层（依赖倒置：grid 不知顶层结构，只派发请求）。
function XUiCardDragHandler:_ReparentToDragRoot()
    local host = self._Host
    host._Control.GameControl:DispatchEvent(host._Control.GameControl.EventId.Drag.RequestCustody, host)
end

function XUiCardDragHandler:_RestorePosition()
    local host = self._Host
    if self._DragContainerTrans then
        host.Transform:SetParent(self._DragContainerTrans, false)
    end
    if self._DragDefaultLocalPos then
        host.Transform.localPosition = self._DragDefaultLocalPos
    end
    if self._DragDefaultSibling then
        host.Transform:SetSiblingIndex(self._DragDefaultSibling)
    end
    -- 恢复原 scale（_CheckCanDrag 主卡缩 0.9 的对称；副卡未缩 _DragDefaultLocalScale 为 nil 跳过）#拖拽主卡scale
    if self._DragDefaultLocalScale then
        host.Transform.localScale = self._DragDefaultLocalScale
        self._DragDefaultLocalScale = nil
    end
    -- 拖拽归位完成：派发 DragSettled。normal-end（_OnDragEndCallback）+ force-end（CancelDragIfDragging）均经此，
    -- 单点全覆盖；购买走异步 cb→_OnDragEndCallback→本方法（等 cb 展开），取消/无效走同步（松手即展开）。
    -- 非副卡拖拽商店栏未收起则 PanelShop no-op。#副卡拖拽收起展开
    local gameControl = host._Control and host._Control.GameControl
    if gameControl then
        gameControl:DispatchEvent(gameControl.EventId.Drag.DragSettled)
    end
    -- 通知 host 拖拽结束归位（host 按需覆写，如商品 grid 恢复 PanelBuy；_RestorePosition 单点全覆盖 normal+cancel）#PanelDragBuyTips
    if host.OnDragEnd then
        host:OnDragEnd()
    end
end

--- 常驻巡检定时器（Enable 起 OnDestroy 停，OnEndDrag 不停）#拖拽保底
--- 对齐 Theatre5 shop 级独立常驻保底（XUiTheatre5BattleShop:78）：不随 grid OnEndDrag 停，
--- 覆盖 OnEndDrag 丢失 + OnEndDrag 触发但异步 cb 丢包（UI _IsDragging 已清但逻辑层卡）终态。
--- 0.2s（5Hz）：TryFixDragError 左键按 return no-op（几行判定），8 grid × 5Hz 开销可忽略；cb 丢包兜底延迟≤0.2s。
function XUiCardDragHandler:_StartPeriodicCheck()
    self:_StopPeriodicCheck()
    self._PeriodicTimerId = XScheduleManager.ScheduleForever(handler(self, self._OnPeriodicCheck), 200)
end

function XUiCardDragHandler:_StopPeriodicCheck()
    if self._PeriodicTimerId then
        XScheduleManager.UnSchedule(self._PeriodicTimerId)
        self._PeriodicTimerId = nil
    end
end

function XUiCardDragHandler:_OnPeriodicCheck()
    self:TryFixDragError()
end

--- 拖拽期每帧巡检（对齐 Theatre5 grid 级 :212 interval=0）：_CheckCanDrag 起 OnEndDrag 停，
--- 拖拽期每帧调 TryFixDragError，OnEndDrag 丢失即时兜底（1 帧内归位，非常驻 1Hz 的≤1s）。
function XUiCardDragHandler:_StartDragCheck()
    self:_StopDragCheck()
    self._DragCheckTimerId = XScheduleManager.ScheduleForever(handler(self, self._OnDragCheck), 0)
end

function XUiCardDragHandler:_StopDragCheck()
    if self._DragCheckTimerId then
        XScheduleManager.UnSchedule(self._DragCheckTimerId)
        self._DragCheckTimerId = nil
    end
end

function XUiCardDragHandler:_OnDragCheck()
    self:TryFixDragError()
end

--- 状态自检修复（对齐 Theatre5 TryFixDragError :282-307）：按卡死不变量检测并强制复位，不闸于 _IsDragging。
--- 覆盖三类终态：①OnEndDrag 丢失（_IsDragging 残留 + 左键已松）；②UI 已清但逻辑层卡（_IsDragging=false 但 GetIsDraggingCard 本卡）；③UI 已清但节点滞留 DragRoot。
--- 正常拖拽（_IsDragging=true + 左键按住）不触发。
function XUiCardDragHandler:TryFixDragError()
    -- 左键按住或触屏有触点=拖拽进行中，不判卡死（避免拖拽中误触发 _ForceReset→CancelDrag 清逻辑会话 + _RestorePosition→DragSettled 展开商店栏）
    -- 松手（GetMouseButton(0)=false 且触屏无触点）才判 ①②③类卡死终态
    -- touchCount 兜底：防项目关 simulateMouseWithTouches 致触屏拖拽 GetMouseButton(0) 不模拟 #M1
    if UNITY.Input.GetMouseButton(0) or UNITY.Input.touchCount > 0 then
        return
    end
    local host = self._Host
    local gameControl = host._Control and host._Control.GameControl
    if not gameControl then
        return
    end
    local needFix = false
    if self._IsDragging then
        -- 拖拽中但左键已松（OnEndDrag 丢失）→ 走正常 OnEndDrag 路由（EndDragCard→_DropAction_Buy 含无效判定弹窗），
        -- 对齐 Theatre5 EndDragErrorCheckTimer 调 OnEndDrag(nil)（不 _ForceReset 绕过路由，否则副卡空槽松手不触发 invalid 判定）
        if not UNITY.Input.GetMouseButton(0) then
            self:OnEndDrag(nil)
            return
        end
    else
        -- UI 已清但逻辑层仍认本卡在拖 → 卡死
        if gameControl.GetIsDraggingCard and gameControl:GetIsDraggingCard() then
            local dragData = gameControl.GetDraggingCardData and gameControl:GetDraggingCardData()
            if dragData and dragData == host._DragCardData then
                needFix = true
            end
        end
        -- UI 已清且 OnEndDrag 已结束（cb 已回）但节点仍滞留 DragRoot → 卡死（_RestorePosition 未归位异常）
        -- not _IsOnEndDrag 排除正常异步操作期间（cb 未回，节点暂滞留 DragRoot）误触发中断
        if not needFix and not self._IsOnEndDrag and self._DragContainerTrans
                and host.Transform.parent ~= self._DragContainerTrans then
            needFix = true
        end
    end
    if needFix then
        if XMain.IsEditorDebug then
            XLog.Debug("[DragHandler] TryFixDragError 触发自愈：_IsDragging=" .. tostring(self._IsDragging))
        end
        self:_ForceReset()
    end
end

--- 强制复位（无条件，去 _IsDragging 守卫）：恢复射线 + 归位 + 清基准 + 清逻辑层会话 + 注销 PAUSE。
--- 与 CancelDragIfDragging 区别：不闸 _IsDragging（TryFixDragError 卡死态调，含 UI 已清但逻辑卡）。
function XUiCardDragHandler:_ForceReset()
    self._IsDragging = false
    self._IsOnEndDrag = false
    self:_StopDragCheck()
    self:SetBlocksRaycasts(true)
    self:_RestorePosition()
    -- 清拖拽基准字段 #落点重构
    self:_ClearDragBaseline()
    -- 清逻辑层拖拽会话 + 派发 DRAG_END（让 PanelBagLayoutBase._OnDragEnd 恢复 bag grids blocksRaycasts + 副卡置灰恢复）
    local gameControl = self._Host._Control and self._Host._Control.GameControl
    if gameControl and gameControl.CancelDrag then
        gameControl:CancelDrag()
    end
    self:_RemoveAppPauseListener()
end

--- app 切后台：拖拽输入事件丢失，强制结束（归位+清会话，绕过操作路由，对齐 Theatre5 OnApplicationPauseEvent :248）。
--- Layer 1 保底定时器不覆盖此场景（后台无输入 → GetMouseButtonUp 返回 false → 检查空转、拖拽卡死）。
---@param isPause boolean
function XUiCardDragHandler:OnApplicationPause(isPause)
    self:CancelDragIfDragging()
end

--- 强制中断拖拽并归位（幂等：未在拖拽时 no-op）。
--- 三处共用：app 切后台 / host 节点被隐藏（OnDisable）/ host 销毁（OnDestroy）。
--- 闸于 _IsDragging（仅拖拽态复位）；卡死态（UI 清但逻辑卡）由 TryFixDragError→_ForceReset 覆盖。
function XUiCardDragHandler:CancelDragIfDragging()
    if not self._IsDragging then
        return
    end
    self:_ForceReset()
end

function XUiCardDragHandler:_RemoveAppPauseListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_APPLICATION_PAUSE, self.OnApplicationPause, self)
end

function XUiCardDragHandler:OnDestroy()
    -- 销毁时若仍在拖拽：先归位并清逻辑层会话，防节点滞留 DragRoot + 会话残留致后续拖拽被 GetIsDraggingCard 拒
    self:CancelDragIfDragging()
    -- 卡死态（_IsDragging=false 但本卡是逻辑层拖拽卡 _DraggingCardData 残留）清逻辑层会话
    -- 仅本卡是逻辑层拖拽卡才 CancelDrag（dragData==_DragCardData），防误清其他卡格正在进行的拖拽会话 #M2修正
    local host = self._Host
    local gameControl = host and host._Control and host._Control.GameControl
    if gameControl and gameControl.CancelDrag and gameControl.GetDraggingCardData then
        local dragData = gameControl:GetDraggingCardData()
        if dragData and dragData == host._DragCardData then
            gameControl:CancelDrag()
        end
    end
    self:_StopDragCheck()
    self:_StopPeriodicCheck()
    self:_RemoveAppPauseListener()
end

return XUiCardDragHandler
