
---@class XSkyTowerLoadEffectNode : XLuaBehaviorNode 小人加载特效
---@field AgentProxy XSkyTowerCharAgent 通天塔小人行为代理
---@field EffectId number 特效Id，Effect表查看
---@field Position UnityEngine.Vector3Int 特效位置相对角色
local XSkyTowerLoadEffectNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "SkyTowerLoadEffect", CsBehaviorNodeType.Action, true, false)

function XSkyTowerLoadEffectNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["EffectId"] == 0 then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    
    self.EffectId = self.Fields["EffectId"]
    self.PositionX = self.Fields["PositionX"]
    self.PositionY = self.Fields["PositionY"]
    self.PositionZ = self.Fields["PositionZ"]
end

function XSkyTowerLoadEffectNode:OnEnter()
    self.AgentProxy:DoLoadEffect(self.EffectId, self.PositionX, self.PositionY, self.PositionZ)
    self.Node.Status = CsNodeStatus.SUCCESS
end