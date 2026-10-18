--- 超难关关卡入口
---@class XUiGridActivityBossSingle: XUiNode
local XUiGridActivityBossSingle = XClass(XUiNode, "XUiGridActivityBossSingle")
--- UI网格初始化回调，注册按钮事件监听
function XUiGridActivityBossSingle:OnStart()
    self:AutoAddListener()
end

function XUiGridActivityBossSingle:OnDestroy()
    self:_ClearScoreAnimationTimer()
    self:_ClearHardLevelAnimTimer()
end

function XUiGridActivityBossSingle:AutoAddListener()
    self.BtnStage.CallBack = function()
        self:OnBtnStageClick()
    end
end

function XUiGridActivityBossSingle:Refresh(stageId, index)
    self.StageId = stageId
    self.Index = index
    --刷新是否解锁
    local isUnLock = XDataCenter.FubenActivityBossSingleManager.IsChallengeUnlockByStageId(stageId)
    self.BtnStage:SetButtonState(isUnLock and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.BtnStage:SetNameByGroup(0, XFubenActivityBossSingleConfigs.GetBossChallengeDetailTitle(stageId))
    local bgMaskName = "Img" .. index .. "BgMask"
    if self.Parent[bgMaskName] then
        self.Parent[bgMaskName].gameObject:SetActiveEx(isUnLock)
    end
    self.IsUnLock = isUnLock
    --刷新红点显示
    local starMap = XDataCenter.FubenActivityBossSingleManager.GetStageStarMap(stageId)
    for i = 1, #starMap do
        self["ImgOn" .. i].gameObject:SetActiveEx(starMap[i])
        self["ImgOff" .. i].gameObject:SetActiveEx(not starMap[i]) 
    end


    --刷新是否通关显示
    local isPassed = XDataCenter.FubenActivityBossSingleManager.IsChallengePassedByStageId(stageId)
    self.PanelKillParent.gameObject:SetActiveEx(isPassed)

 

    if not XDataCenter.FubenActivityBossSingleManager.IsHardBossLevel(stageId) or not isUnLock then
        self.goHardRoot.gameObject:SetActiveEx(false)
    else
        self.goHardRoot.gameObject:SetActiveEx(true)

        self.hardLv0.gameObject:SetActiveEx(false)
        self.goHardLv1.gameObject:SetActiveEx(false)
        self.goHardLv2.gameObject:SetActiveEx(false)
        self.goHardLv3 .gameObject:SetActiveEx(false)
        -- self.PanelBgNorma01.gameObject:SetActiveEx(false)
        -- self.PanelBgNorma02.gameObject:SetActiveEx(false)
        -- self.PanelBgNorma03.gameObject:SetActiveEx(false)

        local curScore = XDataCenter.FubenActivityBossSingleManager.GetCurDifficultScoreRecord(stageId)
        local lastScore =  XDataCenter.FubenActivityBossSingleManager.GetLastDifficultScoreRecord(stageId)
        
        self:_ClearScoreAnimationTimer()
        if curScore == nil then
            self.txtScore.text = tostring(0)
        elseif lastScore == nil or lastScore >= curScore then
            self.txtScore.text = tostring(curScore)
            XDataCenter.FubenActivityBossSingleManager.SetLastDifficultScoreRecord(stageId, curScore)
        else -- 上次刷新了记录
            self.txtScore.text = tostring(lastScore) 

            -- 分数滚动动画（句柄由业务持有，重开前先Stop旧动画，自然结束在finish回调里置nil）
            self._ScoreAnimTweenHandel = XUiHelper.TweenWithHandelObject(1,
                    XUiGridActivityBossSingle._OnScoreAnimRefreshCb, self,
                    XUiGridActivityBossSingle._OnScoreAnimFinishCb, self)

            -- lastScore 的同步延迟到动画回调内做，回调可从 Manager 实时推导出难度变化
            self:_PlayHardLevelChangeAnim()
        end
        local levelCO = XFubenActivityBossSingleConfigs.GetBossLevelScoreCOByScore(curScore)
        if isUnLock then
            local hardLevel = levelCO.Id
            if hardLevel == 1 then
                self.goHardLv1.gameObject:SetActiveEx(true)
                -- self.PanelBgNorma01.gameObject:SetActiveEx(true)
            elseif hardLevel == 2 then
                self.goHardLv2.gameObject:SetActiveEx(true)
                -- self.PanelBgNorma02.gameObject:SetActiveEx(true)
            else
                self.goHardLv3.gameObject:SetActiveEx(true)
                -- self.PanelBgNorma03.gameObject:SetActiveEx(true)
            end
        else
            self.hardLv0.gameObject:SetActiveEx(true)
        end 
        self.txtHardDesc.text =  levelCO.Des
    end
end

function XUiGridActivityBossSingle:OnBtnStageClick()
    if self.IsUnLock == false then
        XUiManager.TipText("ActivityBossOpenTip")
        return
    end
    
    XLuaUiManager.Open('UiActivityBossSinglePopupStageDetail', self.StageId)
end


function XUiGridActivityBossSingle:_PlayHardLevelChangeAnim()
    self:_ClearHardLevelAnimTimer()
    XScheduleManagerPro.ScheduleOnce(XUiGridActivityBossSingle._OnHardLevelAnimScheduleCb, self, 2000)
end

function XUiGridActivityBossSingle:_OnHardLevelAnimScheduleCb()
    if XTool.UObjIsNil(self.Transform) then
        return
    end
    local stageId = self.StageId
    local curScore = XDataCenter.FubenActivityBossSingleManager.GetCurDifficultScoreRecord(stageId)
    local lastScore = XDataCenter.FubenActivityBossSingleManager.GetLastDifficultScoreRecord(stageId)
    XDataCenter.FubenActivityBossSingleManager.SetLastDifficultScoreRecord(stageId, curScore)
    
    if curScore == nil or lastScore == nil or lastScore >= curScore then
        return
    end
    local curLevelCO = XFubenActivityBossSingleConfigs.GetBossLevelScoreCOByScore(curScore)
    local lastLevelCO = XFubenActivityBossSingleConfigs.GetBossLevelScoreCOByScore(lastScore)
    self:_DoPlayHardLevelChangeAnim(curLevelCO.Id, lastLevelCO.Id)
end

function XUiGridActivityBossSingle:_DoPlayHardLevelChangeAnim(curHardLevel, lastHardLevel)
    if  self.AnimTab1To2 == nil then return end -- 预制体还没触发打包

    self.AnimTab1To2.gameObject:SetActiveEx(false)
    self.AnimTab2To3.gameObject:SetActiveEx(false)
    self.AnimHard3Loop.gameObject:SetActiveEx(false)

    local anim
    if curHardLevel ~= lastHardLevel then
        if curHardLevel == 2 then
            anim = self.AnimTab1To2
        elseif curHardLevel == 3 then
            anim = self.AnimTab2To3
        end
    end

    if curHardLevel == 3 then
        self.AnimHard3Loop.gameObject:SetActiveEx(true)
        self.AnimHard3Loop:Play()
    end

    if anim then
        anim.gameObject:SetActiveEx(true)
        anim:Play()
    end
end


-- 分数滚动动画刷新回调（类级方法）：progress由TweenWithHandelObject算好传入，
-- 当前/上次分数由Manager实时推导，不落快照缓存；对象销毁时仅跳帧（返回nil不中断），与原闭包语义一致
---@param progress number 动画进度0~1
function XUiGridActivityBossSingle:_OnScoreAnimRefreshCb(progress)
    if XTool.UObjIsNil(self.Transform) then
        return
    end
    local stageId = self.StageId
    local curScore = XDataCenter.FubenActivityBossSingleManager.GetCurDifficultScoreRecord(stageId)
    local lastScore = XDataCenter.FubenActivityBossSingleManager.GetLastDifficultScoreRecord(stageId)
    if curScore == nil or lastScore == nil then
        return
    end
    self.txtScore.text = tostring( math.floor(CS.UnityEngine.Mathf.Lerp(lastScore, curScore, progress)) )
end

function XUiGridActivityBossSingle:_OnScoreAnimFinishCb()
    self._ScoreAnimTweenHandel = nil -- 自然结束句柄已由内部归还，置nil防持有失效句柄
    if XTool.UObjIsNil(self.Transform) then
        return
    end
    local curScore = XDataCenter.FubenActivityBossSingleManager.GetCurDifficultScoreRecord(self.StageId)
    if curScore ~= nil then
        self.txtScore.text = tostring(curScore)
    end
end

function XUiGridActivityBossSingle:_ClearScoreAnimationTimer()
    XUiHelper.StopTweenWithHandelObject(self._ScoreAnimTweenHandel)
    self._ScoreAnimTweenHandel = nil
end

function XUiGridActivityBossSingle:_ClearHardLevelAnimTimer()
    XScheduleManagerPro.UnSchedule(XUiGridActivityBossSingle._OnHardLevelAnimScheduleCb, self)
end

return XUiGridActivityBossSingle