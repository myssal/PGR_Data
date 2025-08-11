local XTheatre5PVENode = require("XModule/XTheatre5/PVE/Rouge/XTheatre5PVENode")
---@class XTheatre5PVEAVGNode
local XTheatre5PVEAVGNode = XClass(XTheatre5PVENode, "XTheatre5PVEAVGNode")

function XTheatre5PVEAVGNode:_OnEnter()
    local storyLineContentCfg = self._MainModel:GetStoryLineContentCfg(self._StoryLineContentId)
    self._MainControl:LockControl()
    XDataCenter.MovieManager.PlayMovie(storyLineContentCfg.AvgContent,function()
        self._MainControl:UnLockControl()
        XMVCA.XTheatre5.PVEAgency:RequestPveStoryLinePromote(self._StoryLineId, self._StoryLineContentId)
    end)
end

function XTheatre5PVEAVGNode:_OnExit()

end

return XTheatre5PVEAVGNode