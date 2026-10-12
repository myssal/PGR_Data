---@type XReformBalanceControl 栏位规则分部
--- 4.9 天平栏位规则·Control 分部（state+logic 直接在分部，Rule 6.6 瞬态下沉 Control）
--- partial of XReformBalanceControl（like config 分部）；slot state 持于 Control 实例（玩法级，Rule 6.2）
--- follow 父 XReform2ndMobGroup 范式（槽位数组 + amount/max + place/remove + 固定锁 + compact）
--- 实例化/wiring（谁调 InitBalanceSlots、接砝码选择事件）deferred（同 ViewModel，待天平 UI/Control 协调）
--- 单测经 XMVCA:_GetOrRegisterControl(ModuleId.XReform).BalanceControl + LockRef/UnLockRef（同 TestReformBalanceConfig 先例）
local XReformBalanceControl = XClassPartial("XReformBalanceControl")

-- 砝码侧（caller 用 XReformBalanceControl.Side 或实例 .Side）
local Side = {
    Wish = 1, -- 愿望侧（我方角色/我方词缀）
    Cost = 2, -- 代价侧（敌方怪物/敌方词缀，固定怪占此侧）
}
XReformBalanceControl.Side = Side

-- 建当前关卡栏位（caller 进关卡时调，传 stage 配置）
---@param stage table
---@param wishSlotNum number  Stage.WishWeightSlotNum
---@param costSlotNum number  Stage.CostWeightSlotNum
---@param fixedMassIds number[]|nil  关卡固定怪的 massId（caller 由 FixedEnemyIds 转好传入）
function XReformBalanceControl:InitBalanceSlots(stage, wishSlotNum, costSlotNum, fixedMassIds)
    self._Stage = stage
    self._SlotMax = {
        [Side.Wish] = wishSlotNum or 0,
        [Side.Cost] = costSlotNum or 0,
    }
    -- 槽位（左→右编号 1..max）；每槽 { WeightId=number|false, IsFixed=bool }
    self._Slots = {
        [Side.Wish] = {},
        [Side.Cost] = {},
    }
    for side = Side.Wish, Side.Cost do
        for index = 1, self._SlotMax[side] do
            self._Slots[side][index] = { WeightId = false, IsFixed = false }
        end
    end
    self:_InitFixed(fixedMassIds)
end

-- 固定怪按配置顺序从代价侧1号起依次占槽 + 锁
function XReformBalanceControl:_InitFixed(fixedMassIds)
    if not fixedMassIds then
        return
    end
    local slots = self._Slots[Side.Cost]
    local slotMax = self._SlotMax[Side.Cost]
    local placeIndex = 1
    for index = 1, #fixedMassIds do
        local massId = fixedMassIds[index]
        if massId and placeIndex <= slotMax then
            slots[placeIndex].WeightId = massId
            slots[placeIndex].IsFixed = true
            placeIndex = placeIndex + 1
        end
    end
end

-- 顺序填该侧下一空槽（左→右编号）
-- 返回 true 成功 / false 已满（caller 飘字"…侧天平已满，无法继续添加"）
---@param side number  XReformBalanceControl.Side
---@param weightId number
---@return boolean
function XReformBalanceControl:PlaceWeight(side, weightId)
    local slots = self._Slots[side]
    if not slots then
        return false
    end
    for index = 1, #slots do
        if not slots[index].WeightId then
            slots[index].WeightId = weightId
            return true
        end
    end
    return false  -- 该侧已满
end

-- 固定槽不可卸（caller 飘字"当前怪物无法下阵"）；空槽无砝码不可卸（与 RemoveWeight 语义对齐）
---@param side number
---@param slotIndex number  1-based
---@return boolean  true 可移除（有砝码且非固定）/ false 固定锁或空槽
function XReformBalanceControl:CanRemoveWeight(side, slotIndex)
    local slot = self._Slots[side] and self._Slots[side][slotIndex]
    if not slot then
        return false
    end
    return not slot.IsFixed and slot.WeightId ~= false
end

-- 移除非固定槽；移除后后移补空（保持编号连续，符"按编号顺序填"）
-- 固定槽拒移除；空槽 no-op
---@param side number
---@param slotIndex number
---@return boolean  true 移除成功 / false 固定锁或无效
function XReformBalanceControl:RemoveWeight(side, slotIndex)
    local slots = self._Slots[side]
    if not slots then
        return false
    end
    local slot = slots[slotIndex]
    if not slot or not slot.WeightId or slot.IsFixed then
        return false
    end
    self:_CompactAfterRemove(side, slotIndex)
    return true
end

-- 移除 slotIndex 后，后续非固定槽前移补空（对齐父 MobGroup SetMob→table.remove 范式：compact 无洞）
-- 固定槽从1号起连续（_InitFixed），非固定在后；removeIndex 必为非固定（CanRemove 已挡固定）→ 后续皆非固定，简单前移
function XReformBalanceControl:_CompactAfterRemove(side, removeIndex)
    local slots = self._Slots[side]
    local slotMax = #slots
    for index = removeIndex, slotMax - 1 do
        slots[index].WeightId = slots[index + 1].WeightId
    end
    slots[slotMax].WeightId = false  -- 末槽清空
end

-- 该侧是否已满
---@param side number
---@return boolean
function XReformBalanceControl:IsSideFull(side)
    local slots = self._Slots[side]
    if not slots then
        return true
    end
    for index = 1, #slots do
        if not slots[index].WeightId then
            return false
        end
    end
    return true
end

-- 读该侧槽位状态（UI 渲染用）：[{ Index, WeightId, IsFixed }]
---@param side number
---@return table[]
function XReformBalanceControl:GetSlotState(side)
    local slots = self._Slots[side]
    if not slots then
        return table.empty
    end
    local state = {}
    for index = 1, #slots do
        state[index] = {
            Index = index,
            WeightId = slots[index].WeightId,
            IsFixed = slots[index].IsFixed,
        }
    end
    return state
end

return XReformBalanceControl
