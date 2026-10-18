
---@class XSkyTowerChangePerformStateNode : XLuaBehaviorNode 演出改变状态
---@field AgentProxy XSkyTowerPerformAgent 通天塔演出行为代理
---@field State number 演出状态
local XSkyTowerChangePerformStateNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "SkyTowerChangePerformState", CsBehaviorNodeType.Action, true, false)

function XSkyTowerChangePerformStateNode:OnAwake()
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

function XSkyTowerChangePerformStateNode:OnEnter()
    self.AgentProxy:ChangeState(self.State)
    self.Node.Status = CsNodeStatus.SUCCESS
end