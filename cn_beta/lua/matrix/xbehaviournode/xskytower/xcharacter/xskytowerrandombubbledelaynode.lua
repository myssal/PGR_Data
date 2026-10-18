
---@class XSkyTowerRandomBubbleDelayNode : XLuaBehaviorNode 小人随机延时弹出气泡
---@field AgentProxy XSkyTowerCharAgent 通天塔小人行为代理
---@field Min number 最小时间
---@field Max number 最大时间
local XSkyTowerRandomBubbleDelayNode = XLuaBehaviorManager.RegisterNode(XLuaBehaviorNode, 
        "SkyTowerRandomBubbleDelay", CsBehaviorNodeType.Action, true, false)

function XSkyTowerRandomBubbleDelayNode:OnAwake()
    if self.Fields == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end

    if self.Fields["Max"] == nil or self.Fields["Min"] == nil then
        self.Node.Status = CsNodeStatus.ERROR
        return
    end
    
    self.Max = self.Fields["Max"]
    self.Min = self.Fields["Min"]
end


function XSkyTowerRandomBubbleDelayNode:OnEnter()
    if self.AgentProxy:IsShowDelayBubble() then
        self.Node.Status = CsNodeStatus.SUCCESS
        return
    end
    self.Delay = math.random(self.Min, self.Max)
    self.AgentProxy:DoRandomBubbleDelay(self.Delay)
    self.Node.Status = CsNodeStatus.SUCCESS 
end