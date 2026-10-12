---@class XReformBalanceControl : XControl
---@field private _Model XReformModel
---@field private _MainControl XReformControl
--- 4.9 天平质点子 Control（一次性封存功能）
--- config 分部（XReformBalanceConfigControl.lua，XClassPartial）注册 7 张 Balance 表，方法直接 patch 到本 Control 实例。
--- 封存时：删本夹 + 去 XReformControl 中本子 Control 的 wiring（AddSubControl 行）。
local XReformBalanceControl = XClass(XControl, "XReformBalanceControl", true)
-- config 分部（7 表 TableKey 注册 + accessor）
XClassPartialRequire("XModule/XReform/SubModules/Balance/XReformBalanceConfigControl", "XReformBalanceControl")
-- 栏位规则分部（双侧栏位 + 固定锁 + 接口供 UI）
XClassPartialRequire("XModule/XReform/SubModules/Balance/XReformBalanceSlotControl", "XReformBalanceControl")
-- 选择态分部（已选砝码集合 + 上限校验 + 汇出算法入参）
XClassPartialRequire("XModule/XReform/SubModules/Balance/XReformBalanceSelectControl", "XReformBalanceControl")
-- 配平计算分部（调 Logic 算配平档/难度档 + 写 ViewModel）
XClassPartialRequire("XModule/XReform/SubModules/Balance/XReformBalanceCalcControl", "XReformBalanceControl")

function XReformBalanceControl:OnInit()
    -- config 分部加载 7 张 Balance 表到本 Control 实例（InitBalanceConfig 由 config 分部定义）
    self:InitBalanceConfig()
end

function XReformBalanceControl:AddAgencyEvent()
end

function XReformBalanceControl:RemoveAgencyEvent()
end

function XReformBalanceControl:OnRelease()
end

--region 对外接口

--- 进入天平质点主界面（配平环节），由上一个主界面带关卡唯一id调用
--- 建立本次配平的槽位与选择态（页面态，ExitMainUI 清理）
---@param stageId number 关卡id（XReform 模块内唯一键）
function XReformBalanceControl:EnterMainUI(stageId)
    self._StageId = stageId
    local stageConfig = self:_GetStageConfig()
    self:InitBalanceSlots(self._Model:GetStage(stageId), stageConfig.WishWeightSlotNum, stageConfig.CostWeightSlotNum, self:GetFixedEnemyMassIds())
    self:InitBalanceSelect()
    self:ApplySelectedWeightsCache()
    self:RefreshBalanceResult()
end

--- 退出天平质点主界面（UI 栈自动回退到上一个主界面）
function XReformBalanceControl:ExitMainUI()
    self._StageId = nil
end

---@return number
function XReformBalanceControl:GetStageId()
    return self._StageId
end

--endregion

--region 分部共用

---@return XReformBalanceLogic
function XReformBalanceControl:GetBalanceLogic()
    if not self._BalanceLogic then
        self._BalanceLogic = require("XModule/XReform/SubModules/Balance/XReformBalanceLogic").New()
    end
    return self._BalanceLogic
end

---@return XReformBalanceViewModel
function XReformBalanceControl:GetBalanceViewModel()
    return self._Model:GetBalanceViewModel()
end

--- 提交砝码选择并进入编队出战界面
function XReformBalanceControl:EnterBattleRoleRoom()
    local stageId = self._StageId
    self:SaveSelectedWeightsCache()
    self._Model:SetBalancePreFightData(stageId,
        self:GetSelectedMassIds(self.Side.Wish),
        self:GetSelectedMassIds(self.Side.Cost))
    self._Model:SetBalanceEntityIds(self:GetSelectedEntityIds())
    self._Model:SetBalanceAutoEntityIds(self:GetAutoDeployEntityIds())
    self:RecordEnterBattle()
    self._MainControl:OpenBattleRoleRoom(stageId)
end

function XReformBalanceControl:RecordEnterBattle()
    local dict = {}
    dict["stage_id"] = self._StageId
    dict["difficulty"] = self:GetStageDifficulty()
    dict["is_one_key"] = self:IsRecommendUsed() and 1 or 0
    CS.XRecord.Record(dict, "1000053", "ReformStageAutoChoose")
end

--- 当前关卡的 ReformStage 配置
---@return XTableReformStage
function XReformBalanceControl:_GetStageConfig()
    return self._Model:GetStageConfigById(self._StageId)
end

--- 当前关卡难度（普通/困难）
---@return number XEnumConst.REFORM.DIFFICULTY
function XReformBalanceControl:GetStageDifficulty()
    return self:_GetStageConfig().Difficulty
end

--- 莱亚成长质量的已满足条件集合（UnlockStageIds 配的是已通关关卡id）
--- 遍历当前活动所有 stage，收集已通关 stageId，供 ResolveMass 按 UnlockStageIds 取 MassValues 成长档
--- 通关数据流已落地（SetData→_Stage 实体 + GetIsPassed），不再兜底 nil
---@return table<number, boolean>
function XReformBalanceControl:GetSatisfiedMassConditions()
    local stageDic = self._Model:GetStageDic()
    local satisfiedConditions = {}
    for stageId, stage in pairs(stageDic) do
        if stage:GetIsPassed() then
            satisfiedConditions[stageId] = true
        end
    end
    return satisfiedConditions
end

--endregion



return XReformBalanceControl
