local XUiCommonRollingNumber = require("XUi/XUiCommon/XUiCommonRollingNumber")

-- 滚动放大倍数
local ROLL_SCALE = 10

---@class XUiGridSkyTowerSkillItem : XUiNode
---@field private _Control XSkyTowerControl
local XUiGridSkyTowerSkillItem = XClass(XUiNode, "XUiGridSkyTowerSkillItem")

--region 生命周期
function XUiGridSkyTowerSkillItem:OnDisable()
    self:StopRoll()
end

function XUiGridSkyTowerSkillItem:OnDestroy()
    self.NumberRoll = nil
end
--endregion

--region 界面刷新
---@param data {Id:number, Addition:number, WorkType:number, AdditionType:number}
---@param isAura boolean 所属技能是否光环（光环不对角色本体生效）
---@param previewAddition number 目标等级加成，非预览态传nil
---@param isRoll boolean 是否播放预览滚动，长按累计时直接显示目标值
function XUiGridSkyTowerSkillItem:Refresh(data, isAura, previewAddition, isRoll)
    local workType = data.WorkType -- 工作类型
    local productId = data.Id  -- 加成内容
    local addition = data.Addition or 0 -- 当前加成
    local additionType = data.AdditionType -- 加成类型，决定加成值的单位

    local isLock = not self._Control:IsProductUnlock(workType, productId)
    self:RefreshVisible(isLock, isAura)
    if isLock then
        self:RefreshUnknown()
        return
    end

    self:RefreshInfo(workType, productId)
    self:RefreshAddition(workType, addition, previewAddition, additionType, isRoll)
end

-- 未解锁与已解锁的节点显隐
function XUiGridSkyTowerSkillItem:RefreshVisible(isLock, isAura)
    self.PanelLock.gameObject:SetActiveEx(isLock)
    self.RImgIcon.gameObject:SetActiveEx(not isLock)
    if isLock then
        self.PanelTxtUp.gameObject:SetActiveEx(false)
        self.PanelTxtDown.gameObject:SetActiveEx(false)
    end
    self.PanelAura.gameObject:SetActiveEx(not isLock and isAura == true)
end

-- 未解锁态
function XUiGridSkyTowerSkillItem:RefreshUnknown()
    self.TxtName.text = self._Control:GetClientConfigValue("SkillUnknownName")
    self.PanelUrgent.gameObject:SetActiveEx(false)
    self:StopRoll()
    self.TxtAddition = nil
end

-- 名称、图标与加急角标
function XUiGridSkyTowerSkillItem:RefreshInfo(workType, productId)
    self.TxtName.text = self._Control:GetProductName(workType, productId)
    self.RImgIcon:SetRawImage(self._Control:GetProductIcon(workType, productId))
    self.ImgQualityBg:SetSprite(self._Control:GetProductQualityIcon(workType, productId))
    local isUrgent = self._Control:IsUrgentProduct(workType, productId) -- 是否加急物品
    self.PanelUrgent.gameObject:SetActiveEx(isUrgent)
end

-- 按目标加成决定正负面板；零加成全部隐藏，预览变化时高亮并滚动
function XUiGridSkyTowerSkillItem:RefreshAddition(workType, addition, previewAddition, additionType, isRoll)
    -- 切换目标文本前打断旧滚动
    self:StopRoll()
    self.TxtAddition = nil
    local targetAddition = addition
    if previewAddition ~= nil then
        targetAddition = previewAddition
    end
    local isUp = targetAddition > 0
    self.PanelTxtUp.gameObject:SetActiveEx(isUp)
    self.PanelTxtDown.gameObject:SetActiveEx(targetAddition < 0)
    if targetAddition == 0 then
        return
    end

    local panel = isUp and self.PanelTxtUp or self.PanelTxtDown
    self.TxtAddition = panel:GetObject("Txt")
    panel:GetObject("Img"):SetSprite(self._Control:GetUpOrDownArrowIcon(isUp and 1 or 2))
    local isPreview = previewAddition ~= nil and previewAddition ~= addition
    if isPreview and isRoll then
        self:RollAddition(workType, addition, targetAddition, additionType)
    else
        self.TxtAddition.text = self._Control:GetSkillAdditionDescText(targetAddition, workType, additionType)
    end
end
--endregion

--region 数值滚动
-- 加成数值滚动到下一级
function XUiGridSkyTowerSkillItem:RollAddition(workType, from, to, additionType)
    self.RollWorkType = workType
    self.RollAdditionType = additionType
    self.RollFrom = from
    self.RollTo = to
    -- 整数加成不必保留小数位
    self.RollIsInteger = math.floor(from) == from and math.floor(to) == to

    if not self.NumberRoll then
        self.NumberRoll = XUiCommonRollingNumber.New(function()
            self:SetAdditionText(self.RollFrom)
        end, function(value)
            self:SetAdditionText(self:RoundValue(value / ROLL_SCALE))
        end, function()
            -- Kill与Play都会触发OnFinish，主动打断时不能再写终值
            if self.RollSuppressFinish then
                return
            end
            self:SetAdditionText(self.RollTo)
        end)
    end

    -- Play内部先Kill，这次Kill带出的OnFinish要抑制掉
    self.RollSuppressFinish = true
    self.NumberRoll:Play(from * ROLL_SCALE, to * ROLL_SCALE, XMVCA.XSkyTower.StaffRollDuration)
    self.RollSuppressFinish = false
end

-- 写加成文本，滚动回调可能在节点销毁后到达
function XUiGridSkyTowerSkillItem:SetAdditionText(addition)
    if XTool.UObjIsNil(self.TxtAddition) then
        return
    end
    self.TxtAddition.text = self._Control:GetSkillAdditionDescText(addition, self.RollWorkType, self.RollAdditionType)
end

-- 按加成是否整数决定保留位数
function XUiGridSkyTowerSkillItem:RoundValue(value)
    if self.RollIsInteger then
        return math.floor(value + 0.5)
    end
    return math.floor(value * 10 + 0.5) / 10
end

-- 主动打断滚动，不写终值
function XUiGridSkyTowerSkillItem:StopRoll()
    if self.NumberRoll then
        self.RollSuppressFinish = true
        self.NumberRoll:Kill()
        self.RollSuppressFinish = false
    end
end
--endregion

return XUiGridSkyTowerSkillItem
