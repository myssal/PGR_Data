local tonumber = tonumber
local tostring = tostring
local mathFloor = math.floor
local tableInsert = table.insert
local tableRemove = table.remove
local next = next
local CSMovieXMovieManagerInstance = CS.Movie.XMovieManager.Instance

local UI_MOVIE = "UiMovie"
local RESOLUTION_RATIO = CS.XResolutionManager.OriginWidth / CS.XResolutionManager.OriginHeight / CS.XUiManager.DefaultScreenRatio
local TIMELINE_SECONDS_TRANS = 1 / 60
local DEFAULT_SPEED = 1
local DisableFunction = false     --功能屏蔽标记（调试模式时使用）
local CurrentAction = nil;

--可以通过上一页返回到的节点
local MovieBackFilter = {
    [301] = true, --普通对话
}

XMovieManagerCreator = function()
    local AllMovieActions = {}
    local ActionIdToIndexDics = {}

    local CurPlayingMovieId
    local CurPlayingActionIndex
    local AutoPlay
    local WaitToPlayList = {}
    local DelaySelectionDic = {}
    local ReviewDialogList = {}
    local EndCallBack
    local IsPlaying
    local IsYield
    local IsPause = false
    local YieldCallBack
    local MovieBackStack = XStack.New()
    local Speed = 1 -- 自动播放的倍速

    local function InitMovieActions(movieId)
        local movieActions = {}
        local actionIdToIndexDic = {}

        local findEnd = false
        local movieCfg = XMovieConfigs.GetMovieCfg(movieId)
        for index, actionData in ipairs(movieCfg) do
            local actionClass = XMVCA.XMovie.XEnumConst:GetActionClass(actionData.Type)
            if not actionClass then
                XLog.Error("XMovieManager.InitMovieActions 配置节点类型错误，找不到对应的节点，Type: " .. actionData.Type)
                return
            end

            tableInsert(movieActions, actionClass.New(actionData))
            actionIdToIndexDic[actionData.ActionId] = index

            if actionData.IsEnd ~= 0 then
                findEnd = true
            end
        end

        if not findEnd then
            XLog.Error("XMovieManager.InitMovieActions error:没有配置结束标记IsEnd, movieId: ", movieId)
            return
        end

        AllMovieActions[movieId] = movieActions
        ActionIdToIndexDics[movieId] = actionIdToIndexDic

        return movieActions
    end

    local function GetMovieActions(movieId)
        if not AllMovieActions[movieId] then
            InitMovieActions(movieId)
        end

        if not AllMovieActions[movieId] then
            XLog.Error("XMovieManager GetMovieActions error:actions not exsit, movieId is: ", movieId)
            return
        end

        return AllMovieActions[movieId]
    end

    local function GetActionIndexById(movieId, actionId)
        local dic = ActionIdToIndexDics[movieId]
        if not dic then
            XLog.Error("XMovieManager GetActionIndexById error:dic not exsit, movieId is: " .. movieId .. ", actionId is: " .. actionId)
            return
        end

        local index = dic[actionId]
        if not index then
            XLog.Error("XMovieManager GetActionIndexById error:index not exsit, actionId is: " .. actionId)
        end
        return index
    end

    local function ReleaseAll(isRelease)
        if (not CS.XFight.IsRunning) and isRelease then
            CsXUiManager.Instance:ReleaseAll(CsXUiType.Normal)
        end
    end

    local function OnPlayBegin(movieId, hideSkipBtn,isRelease)
        CurPlayingMovieId = movieId
        CurPlayingActionIndex = 1
        WaitToPlayList = GetMovieActions(movieId)
        ReviewDialogList = {}
        MovieBackStack:Clear()
        IsPlaying = true
        IsPause = false
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_MOVIE_BEGIN, movieId)
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BEGIN, movieId)

        if XLuaUiManager.IsUiShow(UI_MOVIE) then return end

        ReleaseAll(isRelease)

        XLuaUiManager.Open(UI_MOVIE, hideSkipBtn)
    end

    local function OnPlayEnd(isLoginOut)
        if not CurPlayingMovieId then return end
        
        XDataCenter.MovieManager.RecordStorylineEnd(CurPlayingMovieId)
        
        if not CS.XFight.IsRunning and not isLoginOut then
            CsXUiManager.Instance:RevertAll()
        end

        CurPlayingMovieId = nil
        CurPlayingActionIndex = nil
        AutoPlay = nil
        ReviewDialogList = {}
        DelaySelectionDic = {}
        WaitToPlayList = {}
        IsPlaying = nil
        IsYield = nil
        IsPause = false
        YieldCallBack = nil
        MovieBackStack:Clear()

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_MOVIE_END)
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_END)

        if CurrentAction then
            CurrentAction:OnDestroy()
        end

        if XLuaUiManager.IsUiShow(UI_MOVIE) then
            XLuaUiManager.Close(UI_MOVIE)
        end
    end

    --剧情UI完全关闭，所有节点清理行为结束
    local function AfterUiClosed()
        if EndCallBack then
            local endCb = EndCallBack --可能会嵌套播放，避免新剧情打开时回调被错误清掉
            EndCallBack = nil

            -- 剧情过程中强制下线
            if not XLoginManager.IsLogin() then
                return
            end

            endCb()
        end
    end

    local function DoAction(ignoreLock)
        if not CurPlayingActionIndex or not next(WaitToPlayList) then
            OnPlayEnd()
            return
        end

        if IsYield then
            return
        end

        if IsPause then
            return
        end
        local action = WaitToPlayList[CurPlayingActionIndex]

        if not ignoreLock and action:IsWaiting() then
            return
        end

        if action:Destroy() then
            if action:IsEnding() then
                OnPlayEnd()
                return
            end
            MovieBackStack:Push(CurPlayingActionIndex)
            local indexChanged

            local selectedActionId = action:GetSelectedActionId()
            if selectedActionId ~= 0 then
                CurPlayingActionIndex = GetActionIndexById(CurPlayingMovieId, selectedActionId)
                indexChanged = true
            end

            local delaySelectedActionId = action:GetDelaySelectActionId()
            if delaySelectedActionId ~= 0 then
                CurPlayingActionIndex = GetActionIndexById(CurPlayingMovieId, delaySelectedActionId)
                indexChanged = true
            end

            local resumeActionId = action:GetResumeActionId()
            if resumeActionId ~= 0 then
                CurPlayingActionIndex = GetActionIndexById(CurPlayingMovieId, resumeActionId)
                indexChanged = true
            end

            if not indexChanged then
                local nextActionId = action:GetNextActionId()
                if nextActionId ~= 0 then
                    CurPlayingActionIndex = GetActionIndexById(CurPlayingMovieId, nextActionId)
                    indexChanged = true
                end
            end

            if not indexChanged then
                CurPlayingActionIndex = CurPlayingActionIndex + 1
            end

            action = WaitToPlayList[CurPlayingActionIndex]
            CurrentAction = action
            action:OnReset()
            if not action then
                OnPlayEnd()
                return
            end
        end

        action:ChangeStatus()
    end

    ---@class XMovieManager
    local XMovieManager = {}

    function XMovieManager.Init()
        XEventManager.AddEventListener(XEventId.EVENT_MOVIE_BREAK_BLOCK, DoAction)
        XEventManager.AddEventListener(XEventId.EVENT_MOVIE_UI_CLOSED, AfterUiClosed)

        DisableFunction = XMovieManager.CheckFuncDisable()
    end

    local function PlayOldMovie(movieId, cb)
        if not CSMovieXMovieManagerInstance:CheckMovieExist(movieId) then return end
        CSMovieXMovieManagerInstance:PlayById(movieId, function()
            if cb then cb() end
        end)
    end

    local function PlayNewMovie(movieId, cb, yieldCb, hideSkipBtn, isRelease)
        EndCallBack = cb
        YieldCallBack = yieldCb
        OnPlayBegin(movieId, hideSkipBtn,isRelease)
    end
    
    --检查剧情存在
    function XMovieManager.CheckMovieExist(movieId)
        if XMovieConfigs.CheckMovieConfigExist(movieId) then
            return true
        end
        if CSMovieXMovieManagerInstance:CheckMovieExist(movieId) then
            return true
        end
        return false
    end

    -- 是否跳过剧情播放
    function XMovieManager.IsSkipMovie()
        return DisableFunction or XUiManager.IsHideFunc
    end
    
    function XMovieManager.PlayMovie(movieId, cb, yieldCb, hideSkipBtn,isRelease)
        if XMain.IsEditorDebug then
            XLog.Debug("开始播放剧情 MovieId = " .. tostring(movieId))
        end
        
        local fun = function ()
            if isRelease == nil then
                isRelease = true
            end
            if XMovieManager.IsSkipMovie() then
                XLog.Warning(string.format("已跳过剧情%s", movieId))
                if cb then cb() end
                return
            end
            XMovieManager.RecordStorylineStart(movieId)
            movieId = tostring(movieId)
            XMVCA.XMovie:RequestMovieOptions(movieId)
            if XMovieConfigs.CheckMovieConfigExist(movieId) then
                PlayNewMovie(movieId, cb, yieldCb, hideSkipBtn, isRelease)
            else
                PlayOldMovie(movieId, cb)
            end
        end

        -- 由于设计 目前这里只有纯剧情关才会走了，若战斗自带剧情关也只会在FubenAgency做检测
        local stageId = XMVCA.XFuben:GetStageIdByBeginStoryId(movieId)
        local isHasCheckStory = XMVCA.XSubPackage:GetHasResIdCheckStoryId(movieId)
        if XTool.IsNumberValid(stageId) and not isHasCheckStory then
            XMVCA.XSubPackage:CheckStageIdListResIdListDownloadComplete({stageId}, fun)
        else
            fun()
        end
    end

    function XMovieManager.StopMovie(isLoginOut)
        if not XMovieManager.IsPlayingMovie() then return end
        if not XLuaUiManager.IsUiShow(UI_MOVIE) then return end
        OnPlayEnd(isLoginOut)
    end

    function XMovieManager.BackToLastAction()
        local curAction = WaitToPlayList[CurPlayingActionIndex]
        local lastId = MovieBackStack:Peek()
        if lastId ~= CurPlayingActionIndex then
            curAction:OnUndo()
            curAction:OnReset()
        end
        if MovieBackStack:Count() == 0 then
            CurPlayingActionIndex = 1
        end
        while (MovieBackStack:Count() ~= 0) do
            local currIndex = MovieBackStack:Pop()
            local action = WaitToPlayList[currIndex]
            action:OnUndo()
            action:OnReset()
            if MovieBackFilter[action:GetType()] then
                CurPlayingActionIndex = currIndex
                break
            end
            if MovieBackStack:Count() == 0 then
                CurPlayingActionIndex = 1
                break
            end
        end
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK)
    end
    
    -- 获取当前播放的Action下标
    function XMovieManager.GetCurPlayingActionIndex()
        return CurPlayingActionIndex
    end

    -- 获取当前播放的Action类型
    function XMovieManager.GetCurPlayingActionType()
        local curAction = WaitToPlayList[CurPlayingActionIndex]
        if curAction then
            return curAction:GetType()
        end
    end

    local function IsPlayingNewMovie()
        return IsPlaying
    end

    local function IsPlayingOldMovie()
        return CSMovieXMovieManagerInstance:IsPlayingMovie()
    end

    function XMovieManager.IsPlayingMovie()
        return IsPlayingNewMovie() or IsPlayingOldMovie()
    end

    function XMovieManager.IsMovieYield()
        if not XMovieManager.IsPlayingMovie() then return false end
        return IsYield or false
    end

    function XMovieManager.YiledMovie()
        if not YieldCallBack then return end --没有恢复回调时不允许挂起

        IsYield = true

        YieldCallBack()
        YieldCallBack = nil
    end

    function XMovieManager.IsMoviePause()
        if not XMovieManager.IsPlayingMovie() then return false end
        return IsPause or false
    end

    function XMovieManager.SetMoviePause(isPause)
        IsPause = isPause
    end

    function XMovieManager.SwitchMovieState()
        IsPause = not IsPause
        local action = WaitToPlayList[CurPlayingActionIndex]
        if (not IsPause) and action:CanContinue() then
            DoAction()
        end
    end

    function XMovieManager.ResumeMovie(index)
        if not IsPlayingNewMovie() then
            if IsPlayingOldMovie() then
                XLog.Error("XMovieManager.ResumeMovie Error: 老版剧情不支持挂起恢复操作")
                return
            end

            XLog.Error("XMovieManager.ResumeMovie Error: 当前没有播放中的剧情")
            return
        end

        local action = WaitToPlayList[CurPlayingActionIndex]
        if not IsYield or not action.ResumeAtIndex then
            XLog.Error("XMovieManager.ResumeMovie Error: 当前没有挂起中的剧情, action: ", action)
            return
        end

        IsYield = nil
        action:ResumeAtIndex(index)
        DoAction()
    end

    function XMovieManager.PushInReviewDialogList(roleName, dialogContent,cueId)
        roleName = roleName and roleName ~= "" and roleName .. ":  " or ""
        if not string.IsNilOrEmpty(roleName) then
            dialogContent = dialogContent and dialogContent ~= "" and dialogContent or ""
        end
        
        local data = {
            RoleName = roleName,
            Content = dialogContent,
            CueId = cueId
        }
        tableInsert(ReviewDialogList, data)
    end

    function XMovieManager.RemoveFromReviewDialogList()
        if ReviewDialogList and #ReviewDialogList > 0 then
            tableRemove(ReviewDialogList)
        end
    end

    function XMovieManager.DelaySelectAction(key, actionId)
        DelaySelectionDic[key] = actionId
    end

    function XMovieManager.GetDelaySelectActionId(key)
        local actionId = DelaySelectionDic[key]
        if actionId then
            DelaySelectionDic[key] = nil
        else
            actionId = 0
        end
        return actionId
    end

    function XMovieManager.SwitchAutoPlay()
        AutoPlay = not AutoPlay
        local action = WaitToPlayList[CurPlayingActionIndex]
        if action then
            XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_AUTO_PLAY, AutoPlay)
        end

        -- 打点
        local dict = {}
        dict["story_id"] = CurPlayingMovieId
        dict["role_level"] = XPlayer.GetLevel()
        dict["speed"] = Speed
        dict["sex"] = XPlayer.Gender or 0
        if AutoPlay then
            CS.XRecord.Record(dict, "200011", "StoryAutoplayStart")
        else
            CS.XRecord.Record(dict, "200012", "StoryAutoplayEnd")
        end
    end

    function XMovieManager.IsAutoPlay()
        return AutoPlay
    end

    function XMovieManager.GetReviewDialogList()
        return ReviewDialogList
    end

    function XMovieManager.ReplacePlayerName(str)
        return XUiHelper.ReplaceWithPlayerName(str, XMovieConfigs.PLAYER_NAME_REPLACEMENT)
    end

    function XMovieManager.Fit(width)
        return width * RESOLUTION_RATIO
    end

    function XMovieManager.ParamToNumber(param)
        return param and param ~= "" and tonumber(param) or 0
    end

    function XMovieManager.TransTimeLineSeconds(time)
        time = time or 0
        local interger = mathFloor(time)
        local decimal = time - interger
        return interger + TIMELINE_SECONDS_TRANS * decimal
    end

    function XMovieManager.ReloadMovies()
        if not XMain.IsDebug then return end

        AllMovieActions = {}
        ActionIdToIndexDics = {}
        XMovieConfigs.DeleteMovieCfgs()
    end

    function XMovieManager.TryGetMovieSkipSummaryCfg()
        return XMovieConfigs.TryGetMovieSkipSummaryCfg(CurPlayingMovieId)
    end
    
    --- 针对传入的文本，根据玩家当前的性别类型进行处理，返回处理过后的文本
    function XMovieManager.GetSummaryContentByGenderCheck(content)
        local OpenMovieThirdGender = XMVCA.XMovie:GetOpenMovieSkipThirdGender()

        -- 这里写死了标签与性别ID的映射，若后期需要走配置，则需要调整这里的逻辑
        if XPlayer.Gender == 0 or XPlayer.Gender == XEnumConst.PLAYER.GENDER_TYPE.MAN or (not OpenMovieThirdGender and XPlayer.Gender == XEnumConst.PLAYER.GENDER_TYPE.SECRECY) then
            -- 未配置、男、保密，均按男的文本
            -- 将由女性标签包围的连续字符串，或男性标签字符串替换为空
            local result = string.gsub(content, '<W>.-</W>', '')
            result = string.gsub(result, '<T>.-</T>', '')
            result = string.gsub(result, '<M>', '')
            result = string.gsub(result, '</M>', '')
            return result
        elseif OpenMovieThirdGender and XPlayer.Gender == XEnumConst.PLAYER.GENDER_TYPE.SECRECY then
            local isManOrWoman = string.gmatch(content, "<T>.-</T>")
            if not isManOrWoman() then
                local result = string.gsub(content, '<W>.-</W>', '')
                result = string.gsub(result, '<M>', '')
                result = string.gsub(result, '</M>', '')
                return result
            end
            local result = string.gsub(content, '<M>.-</M>', '')
            result = string.gsub(result, '<W>.-</W>', '')
            result = string.gsub(result, '<T>', '')
            result = string.gsub(result, '</T>', '')
            return result
        else
            -- 将由男性标签包围的连续字符串，或女性标签字符串替换为空
            local result = string.gsub(content, '<M>.-</M>', '')
            result = string.gsub(result, '<T>.-</T>', '')
            result = string.gsub(result, '<W>', '')
            result = string.gsub(result, '</W>', '')
            return result
        end
    end

    function XMovieManager.GetCurPlayingMovieId()
        return CurPlayingMovieId
    end
    
    function XMovieManager:GetCurPlayingActionId()
        if CurrentAction then
            return CurrentAction:GetActionId()
        end
        return 0
    end

    --检测功能开关
    function XMovieManager.CheckFuncDisable()
        return XMain.IsDebug and XSaveTool.GetData(XPrefs.StoryTrigger)
    end

    function XMovieManager.ChangeFuncDisable(state)
        DisableFunction = state
        XSaveTool.SaveData(XPrefs.StoryTrigger, DisableFunction)
    end

    -- 设置倍速
    function XMovieManager.SetSpeed(speed)
        Speed = speed

        -- 打点
        local dict = {}
        dict["story_id"] = CurPlayingMovieId
        dict["role_level"] = XPlayer.GetLevel()
        dict["speed"] = Speed
        dict["sex"] = XPlayer.Gender or 0
        CS.XRecord.Record(dict, "200013", "StoryAutoplayChangeSpeed")
    end

    -- 获取倍速
    function XMovieManager.GetSpeed()
        if AutoPlay then
            return Speed
        else
            return DEFAULT_SPEED
        end
    end

    -- 重置速度
    function XMovieManager.RestSpeed()
        Speed = DEFAULT_SPEED
    end

    -- 当前是否加速
    function XMovieManager.IsSpeedUp()
        return Speed ~= DEFAULT_SPEED and AutoPlay
    end
    
    --region 埋点相关
    
    --- 记录开始剧情
    function XMovieManager.RecordStorylineStart(id, level, sex)
        sex = sex or XPlayer.Gender
        
        local dict = {}
        dict["story_id"] = id
        dict["role_level"] = level or XPlayer.GetLevel()
        dict["sex"] = sex or 0
        CS.XRecord.Record(dict, "200001", "StorylineStart")
    end

    --- 记录剧情结束
    function XMovieManager.RecordStorylineEnd(id, level, sex)
        sex = sex or XPlayer.Gender
        
        local dict = {}
        dict["story_id"] = id
        dict["role_level"] = level or XPlayer.GetLevel()
        dict["sex"] = sex or 0
        CS.XRecord.Record(dict, "200002", "StorylineEnd")
    end 
    
    --- 记录剧情跳过
    function XMovieManager.RecordStorylineSkip(id, level, sex, stayTime, action_id)
        sex = sex or XPlayer.Gender
        
        local dict = {}
        dict["story_id"] = id
        dict["role_level"] = level or XPlayer.GetLevel()
        dict["sex"] = sex or 0
        dict["stay_time"] = stayTime
        dict["action_id"] = action_id
        CS.XRecord.Record(dict, "200003", "StorylineSkip")
    end
    
    --endregion

    XMovieManager.Init()
    return XMovieManager
end