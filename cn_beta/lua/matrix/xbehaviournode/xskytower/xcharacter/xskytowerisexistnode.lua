
---@class XSkyTowerIsExistNode : XLuaBehaviorNode 判断小人是否加载且显示
---@field AgentProxy XSkyTowerCharAgent 通天塔小人行为代理
local XSkyTowerIsExistNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "SkyTowerIsExist", CsBehaviorNodeType.Condition, true, false)

function XSkyTowerIsExistNode:OnEnter()
    local isExist = self.AgentProxy:DoIsExist()

    if isExist then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end