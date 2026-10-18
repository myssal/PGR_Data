
---@class XSkyTowerDestroyPropsNode : XLuaBehaviorNode 销毁单个演员/演出道具
---@field AgentProxy XSkyTowerPerformAgent 通天塔演出行为代理
---@field NpcId number 演员/演出道具 Id
local XSkyTowerDestroyPropsNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode,
        "SkyTowerDestroyProps", CsBehaviorNodeType.Action, true, false)

function XSkyTowerDestroyPropsNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["NpcId"] == 0 then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    self.NpcId = self.Fields["NpcId"]
end

function XSkyTowerDestroyPropsNode:OnEnter()
    self.AgentProxy:DoDestroyProps(self.NpcId)
    self.Node.Status = CsNodeStatus.SUCCESS
end