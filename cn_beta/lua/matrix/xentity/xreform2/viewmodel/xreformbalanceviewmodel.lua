-- 4.9 天平配平档状态暴露 ViewModel（继承父，尊重框架上下文）
-- 继承 XViewModelReform2ndList：兼容框架创建（Model:New(model)→_Model）+ UI 用法（viewModel:Update/SetStage 等方法调用驱动）
-- 子 Ctor 在父 Data（现网压力字段 Pressure 等）基础上新增配平档状态字段（不改压力字段，caller 写入，UI 读）
-- require 父必须在 XClass 之前（继承非全局基类，见 lua-require-before-xclass）
-- 封存时本文件随 Balance 天平功能删（父 XViewModelReform2ndList 不动）
local XViewModelReform2ndList = require("XEntity/XReform2/ViewModel/XViewModelReform2ndList")
local XReformBalanceViewModel = XClass(XViewModelReform2ndList, "XReformBalanceViewModel")

-- 父 Ctor(model) 已先执行（create 链 super 先）：初始化 self.Data（Pressure 等现网压力字段）+ self._Model
-- 本 Ctor 仅追加配平档状态字段（caller 写入，UI 读取；init false/0 便于判空兜底）
function XReformBalanceViewModel:Ctor()
    self.Data.BalanceResult = false    -- 配平档（XReformBalanceLogic.BalanceResult: Unbalanced/Normal/Perfect）
    self.Data.DifficultyResult = false-- 质量难度档（XReformBalanceLogic.DifficultyResult: Normal/Hard/Nightmare）
    self.Data.WishTotal = 0            -- 愿望总质量
    self.Data.CostTotal = 0            -- 代价总质量
end

return XReformBalanceViewModel
