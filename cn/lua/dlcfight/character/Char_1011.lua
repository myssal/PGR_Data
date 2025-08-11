---@type XAFKCharBase
local Base = require("Character/FightCharBase/XAFKCharBase")

---自走棋渡边脚本
---@class XCharTes1011 : XAFKCharBase
local XCharTes1011 = XDlcScriptManager.RegCharScript(1011, "XCharTes1011", Base)

--region EventCallBack
function XCharTes1011:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    --按需求解除注释进行注册
end

function XCharTes1011:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcAddBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)

    if npcUUID ~= self._uuid then
        return
    end

    if buffId == 1011001  then--创建钩锁
        self:CreatLink()  
    end
    
    if buffId == 1011002 then--删除钩锁
        self:RemoveLink()  
    end

end

function XCharTes1011:OnNpcCastSkillBeforeEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    Base.OnNpcCastSkillBeforeEvent(self,skillId, launcherId, targetId, targetSceneObjId, isAbort)
    if launcherId ~= self._uuid then
        return
    end

    if (skillId == 101107) or (skillId == 101111) or (skillId == 101130) then --闪避技能
        self:FaceTargetSide()
    end
    
end

function XCharTes1011:FaceTargetSide()--看向侧面
    local own = self._uuid
    local targetPosition = self._proxy:GetNpcPosition(self._proxy:GetFightTargetId(own))  --获取自己战斗目标的位置
    local distance = 3
    local euler = {x=0,y=45,z=0} --概率左右，增加变化
    
    if self:GetRandomSuccess(50) then
        euler = {x=0,y=-45,z=0}
    end
    
    local pos = self._proxy:GetNpcOffsetPosition(self._uuid,targetPosition,euler,distance) --获取和目标一个偏移的位置，用来看向这个位置
    
    self._proxy:SetNpcLookAtPosition(self._uuid,pos) --看向侧面
end--向侧面望去

function XCharTes1011:CreatLink()  --创建链接
    local target = self._proxy:GetFightTargetId(self._uuid)
    local own = self._uuid
    
    if target == 0 then
        return
    end
    
    self._proxy:AddLink(own,own,target,"Bip001RHand","HitCase","FxR4DubianAtk46HookLoop") --创建链接
    
end

function XCharTes1011:RemoveLink()--删除链接
    self._proxy:RemoveAllActorLink(self._uuid,self._uuid)--自己移除自己身上的所有Link
end

function XCharTes1011:GetRandomSuccess(maybe)--概率成功
    local isSuccess = false

    if self._proxy:Random(0,100) < maybe then
        isSuccess = true
    end
    
    return isSuccess
end

function XCharTes1011:Terminate()
    Base.Terminate(self)
end

return XCharTes1011
