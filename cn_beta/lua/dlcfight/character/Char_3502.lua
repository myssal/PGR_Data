local Base = require("Character/FightCharBase/XSGMonsterBase")
local SkillConfig = require("TempSkillConfigs/SkillConfig_8052")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")
--local SkillForMonster = require("TempSkillConfigs/SkillConfigsForMonster")

---Deporter-R无人机
---@class XChar3502 : XSGMonsterBase
local XChar3502 = XDlcScriptManager.RegCharScript(3502, "XChar3502", Base)

--region 怪物配置

---技能释放配置
function XChar3502:SkillCastConfig()
    self.selectSkillType = Base.SelectSkillType.CastGroup -- 按照技能释放组释放技能
    self.isOverDriveActive = false -- 关闭OD
    self.isBreakGaugeActive = true -- 开启韧性，用于验证破韧相关事件链路
    self.basicDistanceReference = {5,15,20}

    ---------游荡配置---------
    self.haveWander = true -- 开启游荡逻辑
    self.wanderSkills = { -- 前后左右的游荡技能
        front = 350290,
        back = 350291,
        left = 350292,
        right = 350293,
    }
    self.wanderWeights = { -- 游荡判断权重
        near = { -- 近距离攻击或游荡
            attack = 50,
            front = 0,
            back = 0,
            left = 0,
            right = 0,
            daze = 50,
        },
        mid = { -- 中距离攻击或游荡
            attack = 50,
            front = 0,
            back = 0,
            left = 0,
            right = 0,
            daze = 50,
        },
        far = { -- 远距离攻击或游荡
            attack = 50,
            front = 0,
            back = 0,
            left = 0,
            right = 0,
            daze = 50,
        }
    }

    self:SetSelfAiDelayOpen(4)

    self.castGroup= {
        -- 距离参考：
        -- 远距离：15
        -- 中距离：8
        -- 近距离：5
        { -- 普通释放组
            [350201]=10, -- 回旋后摆
            [350204]=10, -- 冲撞
        }
    }
    self.isOpenChase = true
end

-- 测试用Update配置，按需临时打开。
--function XChar3502:Update(dt)
--    Base.Update(self,dt)
--    self.skillTestId = 350204
--end
--
---技能测试配置，按需临时打开。
--function XChar3502:SkillTestConfig()
--    self:SetSkillTestActive(true)
--    --self.skillTestType = Base.SkillTestType.CustomFuc -- 开启后只执行这个函数里的测试逻辑
--    --self:InitSkillCd(805201,0,0) -- 格挡
--
--    self.skillTestId = 350204
--    self.skillTestInitialCd = 10 -- 测试初始CD
--    --self.skillTestInitialCd = 1.5 -- 测试初始CD
--    self.skillTestCd = 5
--    --self:SetOverDriveValueFull() -- 满OD
--end

---韧性系统初始化。
---3502继承的XSGMonsterBase默认关闭韧性，这里按角色需求开启韧性条并注册破韧/恢复破韧事件。
function XChar3502:BreakGaugeInit()
    if not self.isBreakGaugeActive then
        return
    end

    -- 激活韧性条功能。
    self._proxy:SetNpcBreakGaugeActive(self._uuid, true)

    -- 注册破韧前后事件，用日志验证事件是否跑通。
    self._proxy:RegisterEvent(EWorldEvent.NpcBrokenBefore)
    self._proxy:RegisterEvent(EWorldEvent.NpcBrokenAfter)

    -- 注册恢复破韧前后事件，用日志验证恢复流程是否跑通。
    self._proxy:RegisterEvent(EWorldEvent.NpcRecoverBrokenBefore)
    self._proxy:RegisterEvent(EWorldEvent.NpcRecoverBrokenAfter)
end

---NPC破韧前事件。
---当前只打印日志验证链路，不做破韧表现。
function XChar3502:OnNpcBrokenBefore(launcherUUID, targetUUID, magicId)
    if targetUUID ~= self._uuid then
        return
    end
    self._proxy:ApplyMagic(self._uuid,self._uuid,1000521,1)

    

end

---NPC破韧后事件。
---当前只打印日志验证链路，不做破韧表现。s
function XChar3502:OnNpcBrokenAfter(launcherUUID, targetUUID, magicId)
    if targetUUID ~= self._uuid then
        return
    end
   
end

---NPC恢复破韧前事件。
---当前只打印日志验证链路，不做恢复表现。
function XChar3502:OnNpcRecoverBrokenBefore(targetUUID)
    if targetUUID ~= self._uuid then
        return
    end

    self._proxy:RemoveBuff(self._uuid,1000521)
   
end

---NPC恢复破韧后事件。
---当前只打印日志验证链路，不做恢复表现。
function XChar3502:OnNpcRecoverBrokenAfter(targetUUID)
    if targetUUID ~= self._uuid then
        return
    end
  
end

function XChar3502:Terminate()
    Base.Terminate(self)
    local efPos = self._proxy:GetNpcPosition(self._uuid)
    local efRot = self._proxy:GetNpcRotation(self._uuid)
    self._proxy:CreateCommonEffect("FxHeiBangDeath",efPos,efRot) -- 创建尸体销毁特效
end

return XChar3502