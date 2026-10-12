
---@class XSkyTowerPerformAgent : XLuaBehaviorAgent 通天塔演出代理
---@field Perform XSkyTowerPerform
local XSkyTowerPerformAgent = XLuaBehaviorManager.RegisterAgent(XLuaBehaviorAgent, "SkyTowerPerform")

function XSkyTowerPerformAgent:SetPerform(perform)
    self.Perform = perform
end

function XSkyTowerPerformAgent:LoadPerformProp(isActor, npcId, floorId, position, rotation, loadCb)
    if isActor then
        self.Perform:LoadActor(npcId, floorId, position, rotation, loadCb)
    else
        self.Perform:LoadFurniture(npcId, floorId, position, rotation, loadCb)
    end
end

function XSkyTowerPerformAgent:IsEqualState(state)
    return self.Perform:IsEqualState(state)
end

function XSkyTowerPerformAgent:ChangeState(state)
    self.Perform:ChangeState(state)
end

function XSkyTowerPerformAgent:BeginPerform()
    self.Perform:DoBegin()
end

function XSkyTowerPerformAgent:DoBubble(npcId, dialogId, index)
    self.Perform:DoBubble(npcId, dialogId, index)
end

function XSkyTowerPerformAgent:DoHideBubble(npcId)
    self.Perform:DoHideBubble(npcId)
end

function XSkyTowerPerformAgent:DoDestroyProps(npcId)
    self.Perform:DoDestroyProps(npcId)
end

function XSkyTowerPerformAgent:DestroyAllProps()
    self.Perform:DestroyAllProps(true)
end