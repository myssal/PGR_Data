
---@class XSkyTowerPerformStateCheckNode : XLuaBehaviorNode 对比演出的状态
---@field AgentProxy XSkyTowerPerformAgent 通天塔演出行为代理
---@field State number 演出状态
local XSkyTowerPerformStateCheckNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "SkyTowerPerformStateCheck", CsBehaviorNodeType.Condition, true, false)

function XSkyTowerPerformStateCheckNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["State"] == 0 then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.State = self.Fields["State"]
end


function XSkyTowerPerformStateCheckNode:OnEnter()
    local isEqual = self.AgentProxy:IsEqualState(self.State)
    if isEqual then
        self.Node.Status = CsNodeStatus.SUCCESS
    else
        self.Node.Status = CsNodeStatus.FAILED
    end
end