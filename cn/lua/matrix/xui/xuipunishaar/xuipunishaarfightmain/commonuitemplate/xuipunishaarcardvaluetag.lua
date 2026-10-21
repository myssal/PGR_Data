--- 卡牌数值标签（TagDamage/TagCD 通用 XUiNode）。
--- 挂卡牌根节点（grid 层，非 CardShow 子树）：atk/cd 数据由父 grid 算好喂入，避免子→父上行访问（UI-Rule）。
--- 含 normal/up 两文本对称显隐：current≈config（浮点 eps）→ 显 normal（TxtDamage/TxtCD）；
---   current≠config → 显 up（TxtDamageUp/TxtCDUp）。
--- 变更检测：first（首次）或 current/config 与上次不同才赋值/切显隐/播动效；值不变跳过（每帧调省开销）。
---@class XUiPunishaarCardValueTag: XUiNode
---@field protected _Control XPunishaarControl
---@field Parent
---@field TxtDamage UnityEngine.UI.Text @TagDamage 实例绑（normal）
---@field TxtDamageUp UnityEngine.UI.Text @TagDamage 实例绑（up）
---@field TxtCD UnityEngine.UI.Text @TagCD 实例绑（normal）
---@field TxtCDUp UnityEngine.UI.Text @TagCD 实例绑（up）
---@field Animator UnityEngine.Animator
local XUiPunishaarCardValueTag = XClass(XUiNode, "XUiPunishaarCardValueTag")

local EPS = 1e-4

function XUiPunishaarCardValueTag:OnStart()
    -- 默认全隐，由 Refresh 决定显哪个
    if self.TxtDamage then self.TxtDamage.gameObject:SetActiveEx(false) end
    if self.TxtDamageUp then self.TxtDamageUp.gameObject:SetActiveEx(false) end
    if self.TxtCD then self.TxtCD.gameObject:SetActiveEx(false) end
    if self.TxtCDUp then self.TxtCDUp.gameObject:SetActiveEx(false) end
end

--- 按 current vs config 判等显 normal/up + 变更检测驱动 Refresh 动效。
--- 战斗内（changedOverride=nil）：first 或 changed 才处理；值不变跳过（每帧调省开销）。
--- 战斗外（changedOverride≠nil）：always 设值+切显隐（grid 切卡 Tag 需更新），changedOverride 时播动效。
---@param currentValue number 运行时值（base+delta / reader 最终值）
---@param configValue number 配置基础值
---@param formattedText string 已格式化展示文本
---@param changedOverride boolean|nil true/false=调用方已判（战斗外逻辑层 cardId 历史）；nil=自身 _LastCurrent 算（战斗内现状）
function XUiPunishaarCardValueTag:Refresh(currentValue, configValue, formattedText, changedOverride)
    local normalTxt = self.TxtDamage or self.TxtCD
    local upTxt = self.TxtDamageUp or self.TxtCDUp
    if not normalTxt or not upTxt then
        return
    end
    local equal = math.abs(currentValue - configValue) < EPS
    local showTxt, hideTxt
    if equal then
        showTxt, hideTxt = normalTxt, upTxt
    else
        showTxt, hideTxt = upTxt, normalTxt
    end

    if changedOverride ~= nil then
        -- 战斗外路径：调用方传 changed（逻辑层 cardId 历史），always 设值+切显隐
        self._LastCurrent = currentValue
        self._LastConfig = configValue
        showTxt.text = formattedText
        if not showTxt.gameObject.activeSelf then
            showTxt.gameObject:SetActiveEx(true)
        end
        if hideTxt.gameObject.activeSelf then
            hideTxt.gameObject:SetActiveEx(false)
        end
        if changedOverride then
            self:_PlayRefreshAnim()
        end
    else
        -- 战斗内路径：first/changed 自身 _LastCurrent 算，值不变跳过（每帧调省 .text/SetActiveEx 开销）
        local first = self._LastCurrent == nil
        local changed = not first
                and (self._LastCurrent ~= currentValue or self._LastConfig ~= configValue)
        self._LastCurrent = currentValue
        self._LastConfig = configValue
        if not (first or changed) then
            return
        end
        showTxt.text = formattedText
        if not showTxt.gameObject.activeSelf then
            showTxt.gameObject:SetActiveEx(true)
        end
        if hideTxt.gameObject.activeSelf then
            hideTxt.gameObject:SetActiveEx(false)
        end
        if changed then
            self:_PlayRefreshAnim()
        end
    end
end

--- 清空（grid 切空槽/副卡态时隐标签 + 清缓存，下次 Refresh 视作首次不播动效）。
function XUiPunishaarCardValueTag:Clear()
    if self.TxtDamage then self.TxtDamage.gameObject:SetActiveEx(false) end
    if self.TxtDamageUp then self.TxtDamageUp.gameObject:SetActiveEx(false) end
    if self.TxtCD then self.TxtCD.gameObject:SetActiveEx(false) end
    if self.TxtCDUp then self.TxtCDUp.gameObject:SetActiveEx(false) end
    self._LastCurrent = nil
    self._LastConfig = nil
end

--- Refresh 动效钩子：数值变更时播 XUiNode:PlayAnimation("Refresh")。
--- prefab 上 Tag 根节点（TagDamage/TagCD）需挂 Animation 组件 + "Refresh" state。#79
function XUiPunishaarCardValueTag:_PlayRefreshAnim()
    if self.Animator then
        self.Animator:Play("TagCDRefresh")
    else
        self:PlayAnimation("Refresh")
    end
end

return XUiPunishaarCardValueTag
