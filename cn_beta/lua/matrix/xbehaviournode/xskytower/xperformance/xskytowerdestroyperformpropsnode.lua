
---@class XSkyTowerDestroyPerformPropsNode : XLuaBehaviorNode 销毁演员/演出道具
---@field AgentProxy XSkyTowerPerformAgent 通天塔演出行为代理
local XSkyTowerDestroyPerformPropsNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "SkyTowerDestroyPerformProps", CsBehaviorNodeType.Action, true, false)

function XSkyTowerDestroyPerformPropsNode:OnEnter()
    self.AgentProxy:DestroyAllProps()
    self.Node.Status = CsNodeStatus.SUCCESS
end