local XTheatre5PVENode = require("XModule/XTheatre5/PVE/Rouge/XTheatre5PVENode")
---@class XTheatre5PVEBattleChapterMainNode
local XTheatre5PVEBattleChapterMainNode = XClass(XTheatre5PVENode, "XTheatre5PVEBattleChapterMainNode")

function XTheatre5PVEBattleChapterMainNode:Ctor()

end

---@param isBattleReturn 战斗后进入的节点
function XTheatre5PVEBattleChapterMainNode:SetData(chapterData, isBattleReturn)
    self._ChapterData = chapterData
    self._IsBattleReturn = isBattleReturn
end

function XTheatre5PVEBattleChapterMainNode:_OnEnter()
    local chapterCfg = self._MainModel:GetPveChapterCfg(self._ChapterData.ChapterId)

    --先查看有没有章节进入的AVG没播  
    if self._ChapterData.CurPveChapterLevel.Level == 1 then
        local isEnterAvgPlay = self._MainModel.PVERougeData:IsEnterAvgPlay(self._ChapterData.ChapterId)
        if not isEnterAvgPlay and not string.IsNilOrEmpty(chapterCfg.StartStory) then
            self:PlayAvg(chapterCfg)
            return
        end
    end
    self:OpenPVEGamePanel()       
end

function XTheatre5PVEBattleChapterMainNode:PlayAvg(chapterCfg)
    self._MainControl:LockControl()
    XDataCenter.MovieManager.PlayMovie(chapterCfg.StartStory,function()
        XMVCA.XTheatre5.PVEAgency:RequestPveAvgPlay(self._ChapterData.ChapterId, true, function(success)
            if success then
                self:OpenPVEGamePanel()
            end
            self._MainControl:UnLockControl()        
        end)
    end)
end

function XTheatre5PVEBattleChapterMainNode:OpenPVEGamePanel()
    if self._IsBattleReturn then
        XLuaUiManager.OpenWithCallback("UiTheatre5PVEGame", function()
            CsXUiManager.Instance:SetRevertAndReleaseLock(false)
        end, self._ChapterData, handler(self, self.ChapterBattlePromote))
    else     
        self:OpenUiPanel("UiTheatre5PVEGame", self._ChapterData, handler(self, self.ChapterBattlePromote))  
    end    
end

function XTheatre5PVEBattleChapterMainNode:_OnExit()
    self._ChapterData = nil
    self._IsBattleReturn = nil
end

return XTheatre5PVEBattleChapterMainNode