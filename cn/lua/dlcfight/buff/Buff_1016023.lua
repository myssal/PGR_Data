local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1016023 : XBuffBase
local XBuffScript1016023 = XDlcScriptManager.RegBuffScript(1016023, "XBuffScript1016023", Base)
--效果说明：【背水】期间展开领域为自身增加攻击力，同时燃烧领域内的敌人，伤害随敌人在领域内的时间而增加

function XBuffScript1016023:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.missileId = 10210112
    self.atkBuffId = 1021009
    self.magicLevel = 1
    self.dmgMissilieIds = { 10210113, 10210114, 10210115, 10210116, 10210117 }
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.signalId = 1015901 --【背水】标记
    self.targetId = 0
    self.cd = 1
    self.levelUpCnt = 2
    self.maxLevel = 5
    self.cnt = 0
    self.timer = 0
    self.enhBuffId = 1016240    --【背水】通用强化buff标记
    ------------执行------------
end
---@param dt number @ delta time
function XBuffScript1016023:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --Buff不存在时，不运行后续逻辑
    if not self._proxy:CheckBuffByKind(self._uuid, self.signalId) then
        return
    end
    if self._proxy:GetNpcTime(self._uuid) >= self.timer then
        local level = math.floor(self.cnt / self.levelUpCnt)
        self._proxy:LaunchMissile(self._uuid, self.targetId, 0, self.dmgMissilieIds[level], self.magicLevel)
        self.cnt = self.cnt + 1
        self.timer = self._proxy:GetNpcTime(self._uuid) + self.cd
    end

end

--region EventCallBack
function XBuffScript1016023:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

function XBuffScript1016023:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --开局时，获得目标
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        self.targetId = self._proxy:GetFightTargetId(self._uuid)
        self.timer = self._proxy:GetNpcTime(self._uuid) + self.cd
        --更新magic等级
        self.magicLevel = self._proxy:GetBuffStacks(self._uuid,self.enhBuffId)
    end
    if npcUUID == self._uuid and buffId == self.signalId then
        self._proxy:LaunchMissile(self._uuid, self._uuid, 0, self.missileId, self.magicLevel)
        self._proxy:ApplyMagic(self._uuid,self._uuid,self.atkBuffId,self.magicLevel)
    end

end


--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1016023:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1016023:Terminate()
    Base.Terminate(self)
end

return XBuffScript1016023
