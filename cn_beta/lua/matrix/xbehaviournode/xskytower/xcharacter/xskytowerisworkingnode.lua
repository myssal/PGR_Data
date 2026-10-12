
---@class XSkyTowerIsWorkingNode : XLuaBehaviorNode 判断员工是否工作中（非暂停）
---@field AgentProxy XSkyTowerCharAgent 通天塔小人行为代理
local XSkyTowerIsWorkingNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "SkyTowerIsWorking", CsBehaviorNodeType.Condition, true, false)

function XSkyTowerIsWorkingNode:OnEnter()
    local isWorking = self.AgentProxy:DoIsWorking()

    if isWorking then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end