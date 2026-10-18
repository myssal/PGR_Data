
---@class XSkyTowerIsWorkWithBuffNode : XLuaBehaviorNode 判断员工是否Buff加成
---@field AgentProxy XSkyTowerCharAgent 通天塔小人行为代理
local XSkyTowerIsWorkWithBuffNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "SkyTowerIsWorkWithBuff", CsBehaviorNodeType.Condition, true, false)

function XSkyTowerIsWorkWithBuffNode:OnEnter()
    local isEqual = self.AgentProxy:DoIsWorkWithBuff()
    if isEqual then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end