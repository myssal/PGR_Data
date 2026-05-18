local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10262090 : XTheatre6SkillBase
local XBuffScript10262090 = XDlcScriptManager.RegBuffScript(10262090, "XBuffScript10262090", XTheatre6SkillBase)

--效果说明：本场战斗中首次任意一方生命值低于30%时触发：
--获得100点【怒火】；
--本场战斗中每获得或消耗过一次【怒火】，恢复自身4/6/8点【体力值】。

function XBuffScript10262090:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --生命值比例
    self._propHP = 3000
    -- 体力回复
    self._recoverTL = {
        [1] = 4,
        [2] = 6,
        [3] = 8
    }
    -- 怒火回复值
    self._recoverAnger = 100
    -- 是否已经使用
    self._isUsed = 0
    -- 怒火变化初始次数
    self._angerChange = 0
    -- 怒火控制器
    self._AngerController = self:GetNpc():GetAngerController()
    -- 怒火buff的id
    self._angerBuff = self._AngerController.StackBuffAnger
    
end

function XBuffScript10262090:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage) --注册伤害事件
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff) --注册添加buff事件
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff) --注册移除buff事件
end

--伤害事件，判断血量
function XBuffScript10262090:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType,
                                        realDamage, isCritical)
    --如果技能已经加过队列了就不放了
    if self._isUsed == 1 then return end
    --if launcherId ~= self._npcUUID then return end
    
    -- 敌方生命
    local _enemyMaxHP = self._proxy:GetNpcAttribMaxValue(self._enemyUUID,0)
    local _enemyTargetHP = _enemyMaxHP * self._propHP / 10000
    -- 我方生命
    local _maxHP = self._proxy:GetNpcAttribMaxValue(self._npcUUID,0)
    local _targetHP = _maxHP * self._propHP / 10000
    --当前生命
    local _nowHP = self._proxy:GetNpcAttribValue(self._npcUUID,0)
    local _enemyNowHP = self._proxy:GetNpcAttribValue(self._enemyUUID,0)
    
    -- 生命判断，是否触发
    if _nowHP < _targetHP or _enemyNowHP < _enemyTargetHP then
        self._level:RequestInsertSkill(self._npcUUID,self.TargetSkill)
        self._isUsed = 1
    end
    
end

-- 添加怒火时判断
function XBuffScript10262090:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId) --创建buff事件
    if buffId == self._angerBuff and npcUUID == self._npcUUID then
        self._angerChange = self._angerChange + 1
    end
end

-- 移除怒火时判断
function XBuffScript10262090:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId) --创建buff事件
    if buffId == self._angerBuff and npcUUID == self._npcUUID then
        self._angerChange = self._angerChange + 1
    end
end

function XBuffScript10262090:OnLuaSkillStart(eventArgs)
    ------------执行------------
    --保底处理，如果不是自己/技能id不对，直接退出
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end

    --回怒火
    self._AngerController:AddSkillCount(self._recoverAnger)
    --判断要回多少体力
    local _recover = self._angerChange * self._recoverTL[self._lv]
    self._proxy:Theatre6ChangeStaminaValue(self._npcUUID,_recover,0)
end

return XBuffScript10262090

