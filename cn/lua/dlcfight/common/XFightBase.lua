---@class XFightBase
---@field _uuid number 当前脚本挂载的NpcId
---@field _proxy XDlcCSharpFuncs
local XFightBase = XClass(nil, "FightBase")

---@param proxy XDlcCSharpFuncs
function XFightBase:Ctor(proxy)
    self._proxy = proxy
end

function XFightBase:Init()
    self._uuid = self._proxy:GetSelfNpcId()
    self:InitLuaEvent()
    self:InitEventCallBackRegister()
end

---@param dt number @ delta time
function XFightBase:Update(dt)

end

---@param eventType number
---@param eventArgs userdata
function XFightBase:HandleEvent(eventType, eventArgs)
    if eventType == EWorldEvent.NpcDamage then
        self:OnNpcDamageEvent(eventArgs.LauncherId, eventArgs.TargetId, eventArgs.MagicId, eventArgs.Kind,
                eventArgs.PhysicalDamage, eventArgs.ElementDamage, eventArgs.ElementType, eventArgs.RealDamage, eventArgs.IsCritical)
    end
    if eventType == EWorldEvent.NpcCastSkillBefore then
        self:OnNpcCastSkillBeforeEvent(eventArgs.SkillId, eventArgs.LauncherId, eventArgs.TargetId, eventArgs.TargetSceneObjId, eventArgs.IsAbort)
    end
    if eventType == EWorldEvent.NpcCastSkillAfter then
        self:OnNpcCastSkillAfterEvent(eventArgs.SkillId, eventArgs.LauncherId, eventArgs.TargetId, eventArgs.TargetSceneObjId, eventArgs.IsAbort)
    end
    if eventType == EWorldEvent.NpcExitSkill then
        self:OnNpcExitSkillEvent(eventArgs.SkillId, eventArgs.LauncherId, eventArgs.TargetId, eventArgs.TargetSceneObjId, eventArgs.IsAbort)
    end
    if eventType == EWorldEvent.NpcDie then
        self:OnNpcDieEvent(eventArgs.NpcId, eventArgs.NpcPlaceId, eventArgs.NpcKind, eventArgs.IsPlayer)
    end
    if eventType == EWorldEvent.NpcRevive then
        self:OnNpcReviveEvent(eventArgs.NpcId, eventArgs.NpcPlaceId, eventArgs.NpcKind, eventArgs.IsPlayer)
    end
    if eventType == EWorldEvent.NpcLoadComplete then
        self:OnNpcLoadCompleteEvent(eventArgs.NpcId, eventArgs.NpcPlaceId, eventArgs.NpcKind, eventArgs.IsPlayer)
    end
    if eventType == EWorldEvent.Behavior2ScriptMsg then
        self:OnBehavior2ScriptMsgEvent(eventArgs.NpcUUID, eventArgs.MsgType, eventArgs.IntList, eventArgs.FloatList)
    end
    if eventType == EWorldEvent.NpcAddBuff then
        self:OnNpcAddBuffEvent(eventArgs.CasterUUID, eventArgs.NpcUUID, eventArgs.BuffTableId, eventArgs.BuffKinds, eventArgs.BuffId)
    end
    if eventType == EWorldEvent.NpcRemoveBuff then
        self:OnNpcRemoveBuffEvent(eventArgs.CasterUUID, eventArgs.NpcUUID, eventArgs.BuffTableId, eventArgs.BuffKinds, eventArgs.BuffId)
    end
    if eventType == EWorldEvent.MissileHit then
        self:OnMissileHitEvent(eventArgs.MissileUUID, eventArgs.TargetUUID)
    end
    if eventType == EWorldEvent.MissileDead then
        self:OnMissileDeadEvent(eventArgs.MissileUUID)
    end
    if eventType == EWorldEvent.MissileCreate then
        self:OnMissileCreateEvent(eventArgs.MissileUUID)
    end
    if eventType == EWorldEvent.NpcCalcDamageBefore then
        self:BeforeDamageCalc(eventArgs)
    end
    if eventType == EWorldEvent.NpcCalcDamageAfter then
        self:AfterDamageCalc(eventArgs)
    end
    if eventType == EWorldEvent.NpcCalcCureBefore then
        self:BeforeCureCalc(eventArgs)
    end
    if eventType == EWorldEvent.NpcCalcCureAfter then
        self:AfterCureCalc(eventArgs)
    end
    if eventType == EWorldEvent.NpcAddProtector then
        self:XNpcAddProtectorArgs(eventArgs.LauncherId, eventArgs.TargetId, eventArgs.Value, eventArgs.TotalValue, eventArgs.MagicId)
    end
    if eventType == EWorldEvent.NpcChangeProtector then
        self:XNpcChangeProtectorArgs(eventArgs.LauncherId, eventArgs.TargetId, eventArgs.Value, eventArgs.TotalValue)
    end
    if eventType == EWorldEvent.NpcDodge then
        self:OnNpcDodge(eventArgs.AttackerUUID, eventArgs.Type)
    end
end

---@param eventType number 来自EFightLuaEvent
---@param eventArgs table
function XFightBase:HandleLuaEvent(eventType, eventArgs)
end

function XFightBase:Terminate()
    self:ClearLuaEvent()
end

--region EventCallBack
---事件注册, Buff脚本需按需求在改方法注册事件响应
function XFightBase:InitEventCallBackRegister()
end

---Npc受到伤害
---@param launcherId number 伤害发起者的UUID
---@param targetId number 伤害目标的UUID
---@param magicId number 伤害Magic的配表Id
---@param kind number 策划定义的伤害类型
---@param physicalDamage number 物理伤害
---@param elementDamage number 元素伤害
---@param elementType number 元素伤害类型
---@param realDamage number 真实伤害
---@param isCritical boolean 是否暴击
function XFightBase:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
end

---Npc释放技能前
---@param skillId number 技能ID
---@param launcherId number 发动者UUID
---@param targetId number 目标UUID
---@param targetSceneObjId number 目标场景物件PlaceId
---@param isAbort number 目标场景物件PlaceId，仅在技能退出事件中有效？
function XFightBase:OnNpcCastSkillBeforeEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
end

---Npc释放技能后
---@param skillId number 技能ID
---@param launcherId number 发动者UUID
---@param targetId number 目标UUID
---@param targetSceneObjId number 目标场景物件PlaceId
---@param isAbort number 目标场景物件PlaceId，仅在技能退出事件中有效？
function XFightBase:OnNpcCastSkillAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
end

---Npc退出技能
---@param skillId number 技能ID
---@param launcherId number 发动者UUID
---@param targetId number 目标UUID
---@param targetSceneObjId number 目标场景物件PlaceId
---@param isAbort number 目标场景物件PlaceId，仅在技能退出事件中有效？
function XFightBase:OnNpcExitSkillEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
end

---Npc死亡
---@param npcUUID number
---@param npcPlaceId number
---@param npcKind number
---@param isPlayer boolean
function XFightBase:OnNpcDieEvent(npcUUID, npcPlaceId, npcKind, isPlayer)
end

---Npc复活
---@param npcUUID number
---@param npcPlaceId number
---@param npcKind number
---@param isPlayer boolean
function XFightBase:OnNpcReviveEvent(npcUUID, npcPlaceId, npcKind, isPlayer)
end

---Npc加载资源完成
---@param npcUUID number
---@param npcPlaceId number
---@param npcKind number
---@param isPlayer boolean
function XFightBase:OnNpcLoadCompleteEvent(npcUUID, npcPlaceId, npcKind, isPlayer)
end

---Npc行为树消息
---@param npcUUID number 消息源Npc的UUID
---@param msgType number 消息类型
---@param intList number int参数列表
---@param floatList number float参数列表
function XFightBase:OnBehavior2ScriptMsgEvent(npcUUID, msgType, intList, floatList)
end

---Npc添加Buff
---@param casterNpcUUID number
---@param npcUUID number
---@param buffId number
---@param buffKinds table
---@param buffUUId number
function XFightBase:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
end

---Npc移除Buff
---@param casterNpcUUID number
---@param npcUUID number
---@param buffId number
---@param buffKinds table
---@param buffUUId number
function XFightBase:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
end

---Npc移除Buff
---@param missileUUID number
---@param targetNpcUUID number 子弹目标NpcUUID
function XFightBase:OnMissileHitEvent(missileUUID, targetNpcUUID)
end

---Npc移除Buff
---@param missileUUID number
function XFightBase:OnMissileDeadEvent(missileUUID)
end

---Npc移除Buff
---@param missileUUID number
function XFightBase:OnMissileCreateEvent(missileUUID)
end

---计算伤害前
---@class BeforeDamageCalcEventArgs
---@field Launcher number 发起者NpcId
---@field Target number 目标NpcId
---@field Part number 部位ID
---@field Id number MagicId
---@field Kind number 伤害类型
---@field PhysicalPermyraid number 物理伤害倍率 
---@field ElementPermyraid number 元素伤害倍率
---@field HackDamage number 击破伤害基础值
---@field HackPermyraid number 击破倍率
---@field IsCrit bool 是否暴击
---@field ElementType number 元素类型
---@field Additive table 附加值数组 （可更改）
---@param eventArgs BeforeDamageCalcEventArgs
function XFightBase:BeforeDamageCalc(eventArgs)
end

---计算伤害后
---@class AfterDamageCalcEventArgs
---@field Launcher number 发起者NpcId
---@field Target number 目标NpcId
---@field Part number 部位ID
---@field Id number MagicId
---@field Kind number 伤害类型
---@field PhysicalDamage number 物理伤害（可更改）
---@field ElementDamage number 元素伤害（可更改）
---@field PhysicalPermyraid number 物理伤害倍率 
---@field ElementPermyraid number 元素伤害倍率 
---@field HackDamage number 击破伤害基础值
---@field HackPermyraid number 击破倍率
---@field FinalHackDamage number 最终破击伤害（可更改）
---@field RealDamage number 真实伤害 （Relink暂时无用）
---@field ElementType number 元素类型
---@field IsCrit bool 是否暴击
---@param eventArgs AfterDamageCalcEventArgs
function XFightBase:AfterDamageCalc(eventArgs)
end

---@class BeforeCureCalcEventArgs
---@field Launcher number 发起者NpcId
---@field Target number 目标NpcId
---@field Id number MagicId
---@field AttribType number 参照属性类型
---@field Type number 计算类型
---@field Value number 基础值（可更改）
---@field Permyriad number 倍率（可更改）
---@field Additive table 附加值数组 （可更改）
---计算治疗前
---@param eventArgs AfterDamageCalcEventArgs
function XFightBase:BeforeCureCalc(eventArgs)

end

---@class AfterCureEventArgs
---@field Launcher number 发起者NpcId
---@field Target number 目标NpcId
---@field Id number MagicId
---@field AttribType number 参照属性类型
---@field Type number 计算类型
---@field Value number 基础值
---@field Permyriad number 倍率
---@field FinalValue number FinalValue：计算最终值
---计算治疗后
---@param eventArgs AfterCureEventArgs
function XFightBase:AfterCureCalc(eventArgs)

end

---@param LauncherId number 发起者NpcId
---@param TargetId number 目标NpcId
---@param Value number 获得的护盾值
---@param TotalValue number 当前总护盾值
---@param MagicId number magicId
function XFightBase:XNpcAddProtectorArgs(LauncherId, TargetId, Value, TotalValue, MagicId)

end

---@param LauncherId number 发起者NpcId
---@param TargetId number 目标NpcId
---@param Value number 获得的护盾值
---@param TotalValue number 当前总护盾值
function XFightBase:XNpcChangeProtectorArgs(LauncherId, TargetId, Value, TotalValue)

end

---@class XNpcDodgeEventArgs
---@field AttackerUUID number 被闪避目标
---@field Type number 闪避窗口类型
---触发闪避成功
---@param eventArgs XNpcDodgeEventArgs
function XFightBase:OnNpcDodge(AttackerUUID, Type)

end

--endregion

--region LuaEvent
---初始化Lua事件列表
---@private
function XFightBase:InitLuaEvent()
    self._luaEventDict = {}
end

---注册Lua事件
---@param eventType number 来自EFightLuaEvent
function XFightBase:RegisterLuaEvent(eventType)
    if self._luaEventDict[eventType] then
        return
    end
    self._luaEventDict[eventType] = true
    self._proxy:RegisterLuaEvent(eventType)
end

---注销Lua事件
---@param eventType number 来自EFightLuaEvent
function XFightBase:UnRegisterLuaEvent(eventType)
    if not self._luaEventDict[eventType] then
        return
    end
    self._luaEventDict[eventType] = false
    self._proxy:UnregisterLuaEvent(eventType)
end

---派发Lua事件
---@param targetType number 来自ELuaEventTarget
---@param eventType number 来自EFightLuaEvent
---@param eventArgs table
function XFightBase:DispatchLuaEvent(targetType, eventType, eventArgs)
    self._proxy:DispatchLuaEvent(targetType, eventType, eventArgs)
end

---@private
function XFightBase:ClearLuaEvent()
    for eventType, _ in pairs(self._luaEventDict) do
        self:UnRegisterLuaEvent(eventType)
    end
end
--endregion

--region Random
---在一个选项List里随机选择一个选项
---@param list table
function XFightBase:GetValueByListRandom(list)
    if not list then
        return nil
    end
    local listCount = #list
    local listIndex = 1
    if listCount == 1 then
        listIndex = 1
    else
        listIndex = self._proxy:Random(1, #list)
    end
    return list[listIndex]
end

---在一个选项全是function的List里随机选择一个function并执行
---@param list table<number, function>
function XFightBase:DoFuncByListRandom(list)
    local func = self:GetValueByListRandom(list)
    if func and type(func) == "function" then
        func()
    else
        XLog.Error("[XFightBase] DoFuncByListRandom func is fail, please check the param!")
    end
end

---在一个key为选项 value为选项权值的Dict根据权值随机发里随机选择一个选项
---@param weightDict table key为选项 value为选项权值
function XFightBase:GetValueByWeightRandom(weightDict)
    if not weightDict then
        return nil
    end
    -- 第一步：计算总权值
    local totalWeight = 0
    for _, weight in pairs(weightDict) do
        totalWeight = totalWeight + weight
    end

    -- 第二步：生成随机数（注意：Lua的math.random()需要先调用math.randomseed(os.time())初始化）
    local randomPoint = self._proxy:Random(1, totalWeight)

    -- 第三步：遍历查找对应的选项
    local accumulated = 0
    for option, weight in pairs(weightDict) do
        accumulated = accumulated + weight
        if accumulated >= randomPoint then
            return option
        end
    end
end

---在一个key为function类型的选项 value为选项权值的Dict根据权值随机发里随机选择一个选项
---@param dict table<function, number> key为选项 value为选项权值
function XFightBase:DoFuncByWeightRandom(dict)
    local func = self:GetValueByWeightRandom(dict)
    if func and type(func) == "function" then
        func()
    else
        XLog.Error("[XFightBase] DoFuncByWeightRandom func is fail, please check the param!")
    end
end
--endregion

return XFightBase
