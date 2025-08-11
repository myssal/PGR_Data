--- Agency的组件，封装进入战斗相关的接口
---@class XTheatre5BattleAgencyCom
---@field private _OwnerAgency XTheatre5Agency
---@field private _Model XTheatre5Model
local XTheatre5BattleAgencyCom = XClass(nil, 'XTheatre5BattleAgencyCom')

local DlcWorldAttribMultyBase = 1000 -- 基础属性配置值乘法基数

function XTheatre5BattleAgencyCom:Init(ownerAgency, model)
    self._OwnerAgency = ownerAgency
    self._Model = model
    self:_InitSimpleSettleContent()
    self._RankDataCache = {}
    self._RankDataLastReqTime = {}
end

function XTheatre5BattleAgencyCom:Release()
    self._OwnerAgency = nil
    self._Model = nil
    self._AdvanceSettleContent = nil
    self._RankDataCache = nil
    self._RankDataLastReqTime = nil
end

--region 模拟构造战斗数据

--- 初始化战斗数据通用部分的结构
function XTheatre5BattleAgencyCom:_InitSimpleSettleContent()
    --- 非正常结束战斗的结算数据，因为兼容性而存在多层嵌套，因此复用
    self._SimpleSttleContent = {
        DlcReportWorldResult = {
            DlcFightSettleData = {
                SettleState = XMVCA.XTheatre5.EnumConst.DlcFightSettleState.None,
                WorldData = {
                    WorldId = nil,
                    Players = {
                        [1] = {
                            Id = nil
                        }
                    }
                },
                PlayerData = nil
            }
        }
    }
end

--- 局外构造战斗数据用于提前结算
function XTheatre5BattleAgencyCom:_GetSimpleSettleContentForAdvance()
    local worldData = self._SimpleSttleContent.DlcReportWorldResult.DlcFightSettleData.WorldData
    local dlcFightSettleData = self._SimpleSttleContent.DlcReportWorldResult.DlcFightSettleData

    worldData.WorldId = self._Model:GetTheatre5WorldIdByActivityId(self._Model:GetActivityId())
    worldData.Players[1].Id = XPlayer.Id
    self._SimpleSttleContent.DlcReportWorldResult.DlcFightSettleData.IsPlayerWin = false
    self._SimpleSttleContent.DlcReportWorldResult.DlcFightSettleData.SettleState = XMVCA.XTheatre5.EnumConst.DlcFightSettleState.AdvanceExit

    dlcFightSettleData.PlayerData = {
        [XPlayer.Id] = {
            PlayerId = XPlayer.Id
        }
    }
    
    XMessagePack.MarkAsTable(dlcFightSettleData.PlayerData)

    return self._SimpleSttleContent
end

--- 局外构造战斗数据用于放弃战斗
function XTheatre5BattleAgencyCom:_GetSimpleSettleContentForGiveUp()
    local worldData = self._SimpleSttleContent.DlcReportWorldResult.DlcFightSettleData.WorldData
    local dlcFightSettleData = self._SimpleSttleContent.DlcReportWorldResult.DlcFightSettleData

    worldData.WorldId = self._Model:GetTheatre5WorldIdByActivityId(self._Model:GetActivityId())
    worldData.Players[1].Id = XPlayer.Id
    self._SimpleSttleContent.DlcReportWorldResult.DlcFightSettleData.IsPlayerWin = false
    self._SimpleSttleContent.DlcReportWorldResult.DlcFightSettleData.SettleState = XMVCA.XTheatre5.EnumConst.DlcFightSettleState.None

    dlcFightSettleData.PlayerData = {
        [XPlayer.Id] = {
            PlayerId = XPlayer.Id
        }
    }

    XMessagePack.MarkAsTable(dlcFightSettleData.PlayerData)

    return self._SimpleSttleContent
end

--- 局外构造战斗数据用于战斗中断时的回合结算
function XTheatre5BattleAgencyCom:_GetSimpleSettleContentForBattleInterrupt()
    local worldData = self._SimpleSttleContent.DlcReportWorldResult.DlcFightSettleData.WorldData
    local dlcFightSettleData = self._SimpleSttleContent.DlcReportWorldResult.DlcFightSettleData

    worldData.WorldId = self._Model:GetTheatre5WorldIdByActivityId(self._Model:GetActivityId())
    worldData.Players[1].Id = XPlayer.Id
    self._SimpleSttleContent.DlcReportWorldResult.DlcFightSettleData.IsPlayerWin = false
    self._SimpleSttleContent.DlcReportWorldResult.DlcFightSettleData.SettleState = XMVCA.XTheatre5.EnumConst.DlcFightSettleState.PlayerOffline

    dlcFightSettleData.PlayerData = {
        [XPlayer.Id] = {
            PlayerId = XPlayer.Id
        }
    }
    
    XMessagePack.MarkAsTable(dlcFightSettleData.PlayerData)

    return self._SimpleSttleContent
end
--endregion

--region Network
--- 请求游戏提前结算
function XTheatre5BattleAgencyCom:RequestTheatre5AdvanceSettle(cb)
    local content = self:_GetSimpleSettleContentForAdvance()

    XNetwork.Call("DlcSingleFightSettleRequest", content, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        if res.DlcFightSettleData and res.DlcFightSettleData.XAutoChessGameplayResult then
            ---@type XAutoChessGameplayResult
            local autoChessResult = res.DlcFightSettleData.XAutoChessGameplayResult
            
            self._OwnerAgency:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_COMMON_BATTLE_SETTLE, autoChessResult)
        end
        if self._Model:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameModel.PVE then
            self._Model.PVEAdventureData:UpdateTempChapterData()
            self._Model.PVEAdventureData:UpdatePVEChapterData()
        end    

        if cb then
            cb(true, res)
        end

        XLuaUiManager.Open('UiTheatre5Settlement', res.DlcFightSettleData)
    end)
end

--- 请求游戏结算-放弃战斗
function XTheatre5BattleAgencyCom:RequestTheatre5GiveUpSettle(cb)
    local content = self:_GetSimpleSettleContentForGiveUp()

    XNetwork.Call("DlcSingleFightSettleRequest", content, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        self._Model.CurAdventureData:UpdateCurPlayStatus(XMVCA.XTheatre5.EnumConst.PlayStatus.BattleFinish)

        local isFinish = false

        if res.DlcFightSettleData and res.DlcFightSettleData.XAutoChessGameplayResult then
            ---@type XAutoChessGameplayResult
            local autoChessResult = res.DlcFightSettleData.XAutoChessGameplayResult
            self._OwnerAgency:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_COMMON_BATTLE_SETTLE, autoChessResult)

            if autoChessResult.IsFinish then
                if self._Model.CurAdventureData then
                    self._Model.CurAdventureData:ClearData()
                end
                isFinish = true
            end
        end

        if cb then
            cb(true, isFinish)
        end
    end)
end

--- 请求游戏结算-掉线等中断战斗的情况
function XTheatre5BattleAgencyCom:RequestTheatre5InterruptBattle(cb)
    local content = self:_GetSimpleSettleContentForBattleInterrupt()

    XNetwork.Call("DlcSingleFightSettleRequest", content, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end
        local curPlayMode = self._Model:GetCurPlayingMode()
        local status = XMVCA.XTheatre5.EnumConst.PlayStatus.Matching
        if curPlayMode == XMVCA.XTheatre5.EnumConst.GameModel.PVE then
            status = XMVCA.XTheatre5.EnumConst.PlayStatus.Shopping
        end            

        self._Model.CurAdventureData:UpdateCurPlayStatus(status)

        local isFinish = false

        if res.DlcFightSettleData and res.DlcFightSettleData.XAutoChessGameplayResult then
            ---@type XAutoChessGameplayResult
            local autoChessResult = res.DlcFightSettleData.XAutoChessGameplayResult
            self._OwnerAgency:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_COMMON_BATTLE_SETTLE, autoChessResult)

            if autoChessResult.IsFinish then
                if curPlayMode == XMVCA.XTheatre5.EnumConst.GameModel.PVE then
                    self._Model.PVEAdventureData:UpdateTempChapterData()
                    self._Model.PVEAdventureData:UpdatePVEChapterData()
                end        
                isFinish = true
            end
        end

        if cb then
            cb(true, isFinish)
        end

        if isFinish then
            XLuaUiManager.Open('UiTheatre5Settlement', res.DlcFightSettleData)
        end
    end)
end

--- 请求游戏正常结算
function XTheatre5BattleAgencyCom:RequestTheatre5NormalSettle(result, summaryData, cb)
    local contentBytes = result:GetFightsResultsBytes()

    XNetwork.Call("DlcSingleFightSettleRequest", contentBytes, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        if res.DlcFightSettleData and res.DlcFightSettleData.XAutoChessGameplayResult then
            ---@type XAutoChessGameplayResult
            local autoChessResult = res.DlcFightSettleData.XAutoChessGameplayResult
            self._Model.CurAdventureData:UpdateHealth(autoChessResult.Health)
            self._Model.CurAdventureData:UpdateRoundNum(autoChessResult.RoundNum)
            if self._Model:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameModel.PVP then
                self._OwnerAgency:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_COMMON_BATTLE_SETTLE, autoChessResult)
            else
                if not autoChessResult.PveChapterData then --章节结算
                    local isWin = res.DlcFightSettleData and res.DlcFightSettleData.ResultData and res.DlcFightSettleData.ResultData.IsPlayerWin
                    self._Model.PVEAdventureData:UpdateTempChapterData(isWin)
                end    
                self._Model.PVEAdventureData:UpdatePVEChapterData(autoChessResult.PveChapterData) --关卡更新(胜利或失败)
                self._Model.PVERougeData:UpdatePveStoryLine(autoChessResult.PveStoryLineData)     --章节结束
            end

            XEventManager.DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_BATTLE_RESULT,res.DlcFightSettleData)

            -- 战斗校验结果
            if XTool.IsNumberValid(autoChessResult.CheckFailTimes) and autoChessResult.CheckFailTimes > self._Model.CurAdventureData:GetCheckFailTimes() then
                local limit = self._Model:GetTheatre5ConfigValByKey('BattleCheckFailTimesLimit')
                
                if autoChessResult.CheckFailTimes >= limit then
                    local finalSettleFunc = function()
                        -- 达到校验上限后服务端已做提前结算处理，直接显示结果
                        CS.StatusSyncFight.XFightClient.RequestExitFight()
                        XLuaUiManager.Open('UiTheatre5Settlement', res.DlcFightSettleData)
                    end

                    self._OwnerAgency:TryPopupDialogWithOneBtn(XUiHelper.GetText("TipTitle"),
                            self._Model:GetTheatre5ClientConfigText('BattleCheckFailEndGameTips'),
                            nil, finalSettleFunc, nil, nil, true)
                else
                    local restartFunc = function()
                        self:RequestDlcSingleEnterFight(0)
                    end

                    local finalSettleFunc = function()
                        -- 未达校验上限时需要手动请求提前结算
                        self:RequestTheatre5AdvanceSettle(function(success, advanceSettleRes)
                            if success then
                                CS.StatusSyncFight.XFightClient.RequestExitFight()
                                XLuaUiManager.Open('UiTheatre5Settlement', advanceSettleRes.DlcFightSettleData)
                            end
                        end)
                    end

                    self._OwnerAgency:TryPopupDialog(XUiHelper.GetText("TipTitle"),
                            self._Model:GetTheatre5ClientConfigText('BattleCheckFailRestartTips'),
                            nil, restartFunc, finalSettleFunc, nil, nil, true)
                end

                -- 校验失败

                -- 缓存
                self._Model.CurAdventureData:UpdateCheckFailTimes(autoChessResult.CheckFailTimes)
            else
                XLuaUiManager.Open('UiTheatre5RoundSettlement', res.DlcFightSettleData, summaryData)
            end
        end
        local battleStatus = XMVCA.XTheatre5.EnumConst.PlayStatus.BattleFinish
        if self._Model:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameModel.PVE then
            if res.DlcFightSettleData and res.DlcFightSettleData.ResultData and res.DlcFightSettleData.ResultData.IsPlayerWin then
                battleStatus = XMVCA.XTheatre5.EnumConst.PlayStatus.PveEveHandle
            end    
        end    
        self._Model.CurAdventureData:UpdateCurPlayStatus(battleStatus)

        if cb then
            cb(true)
        end
    end, true)
end

--- 请求匹配
function XTheatre5BattleAgencyCom:RequestTheatre5Match(cb)
    XNetwork.Call("Theatre5MatchRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        self._Model.CurAdventureData:UpdateMatchEnemyData(res.EnemyData)

        if cb then
            cb(true, res.EnemyData)
        end
    end)
end

--- 请求进入战斗
function XTheatre5BattleAgencyCom:RequestDlcSingleEnterFight(levelId, enterCb)
    -- 获取当前活动的worldId
    local worldId = self._Model:GetTheatre5WorldIdByActivityId(self._Model:GetActivityId())

    self._OwnerAgency:RequestDlcSingleEnterFight(worldId, levelId, function(success, worldData)
        if success then
            if worldData and worldData.AutoChessGameplayData then
                self._Model.CurAdventureData:UpdateCurPlayStatus(XMVCA.XTheatre5.EnumConst.PlayStatus.Battling)

                if self._Model:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameModel.PVE then
                    self._Model.PVEAdventureData:UpdateEnemyData(worldData.AutoChessGameplayData.EnemyData.AutoChessData)
                end

                if worldData.AutoChessGameplayData.EnemyData then
                    self:_CalNpcAttribsAfterEnterFightRequest(worldData.AutoChessGameplayData.EnemyData.AutoChessData)
                end

                if worldData.AutoChessGameplayData.EnemyData then
                    self:_CalNpcAttribsAfterEnterFightRequest(worldData.AutoChessGameplayData.SelfData.AutoChessData)
                end
                
                local enterFunc = function()
                    CsXBehaviorManager.Instance:Clear()
                    XTableManager.ReleaseAll(true)
                    CS.BinaryManager.OnPreloadFight(true)
                    collectgarbage("collect")

                    CsXUiManager.Instance:ReleaseAll(CsXUiType.Normal, CS.XUiSceneManager.Clear)
                    CsXUiManager.Instance:SetRevertAndReleaseLock(false)

                    local args = self:_GetXFightClientArgs()

                    local csWorldData = self:_GetXWorldData(worldData, levelId)
                    CS.StatusSyncFight.XFight.Init()

                    CS.StatusSyncFight.XFightClient.EnterFight(csWorldData, XPlayer.Id, args)

                    if enterCb then
                        enterCb(worldData)
                    end
                end



                if CS.StatusSyncFight.XFightClient.FightInstance ~= nil then
                    CS.StatusSyncFight.XFightClient.RequestExitFight()
                    --todo: 目前战斗结束是异步逻辑，且暂未支持回调，先手动延迟
                    XScheduleManager.ScheduleOnce(function()
                        enterFunc()
                    end, XScheduleManager.SECOND * 2)
                else
                    enterFunc()
                end
            end
        end
    end)
end
--endregion

--region 战斗数据C#对象构造
function XTheatre5BattleAgencyCom:_GetXWorldData(worldData, levelId)
    local csWorldData = CS.XWorldData()

    csWorldData.Online = worldData.Online
    csWorldData.RoomId = worldData.RoomId
    csWorldData.WorldId = worldData.WorldId
    csWorldData.LevelId = worldData.LevelId
    csWorldData.MissionId = worldData.MissionId
    csWorldData.RebootId = worldData.RebootId
    csWorldData.IsTeaching = worldData.IsTeaching
    csWorldData.IsLocalDebug = worldData.IsLocalDebug
    csWorldData.WorldType = worldData.WorldType
    csWorldData.ServerControllerSeed = worldData.ServerControllerSeed
    csWorldData.IsSingleOnline = worldData.IsSingleOnline
    csWorldData.AutoChessGameplayData = CS.XAutoChessGameplayData()

    local autoChessGameplayData = csWorldData.AutoChessGameplayData
    local autoChessGameplayDataServer = worldData.AutoChessGameplayData

    autoChessGameplayData.SelfData = self:_GetXAutoChessNpcData(autoChessGameplayDataServer.SelfData)
    autoChessGameplayData.EnemyData = self:_GetXAutoChessNpcData(autoChessGameplayDataServer.EnemyData)

    --pve给敌人上buff
    if XTool.IsNumberValid(levelId) and autoChessGameplayData.EnemyData and autoChessGameplayData.EnemyData.AutoChessData then
        local magicDict = self._Model.PVEAdventureData:GetLevelEnemyMagicDict(levelId)
        if not XTool.IsTableEmpty(magicDict) then
            autoChessGameplayData.EnemyData.AutoChessData.MagicIds = magicDict
        end
    end

    if not XTool.IsTableEmpty(worldData.Players) then
        for i, v in ipairs(worldData.Players) do
            csWorldData.Players:Add(self:_GetXWorldPlayerData(v))
        end
    end

    return csWorldData
end

function XTheatre5BattleAgencyCom:_GetXAutoChessNpcData(autoChessNpcDataServer)
    local autoChessNpcData = CS.XAutoChessNpcData()

    autoChessNpcData.TemplateId = autoChessNpcDataServer.TemplateId
    autoChessNpcData.Name = autoChessNpcDataServer.Name
    autoChessNpcData.HeadFrameId = autoChessNpcDataServer.HeadFrameId
    autoChessNpcData.AutoChessData = self:_GetXAutoChessData(autoChessNpcDataServer.AutoChessData)

    return autoChessNpcData
end

function XTheatre5BattleAgencyCom:_GetXAutoChessData(autoChessDataServer)
    local autoChessData = CS.XAutoChessData()

    autoChessData.CharacterId = autoChessDataServer.CharacterId
    autoChessData.FashionId = autoChessDataServer.FashionId
    
    for k, v in pairs(autoChessDataServer.Attribs) do
        autoChessData.Attribs:Add(k, v)
    end

    for i, v in ipairs(autoChessDataServer.Runes) do
        autoChessData.Runes:Add(v)
    end

    for i, v in ipairs(autoChessDataServer.Skills) do
        autoChessData.Skills:Add(v)
    end

    return autoChessData
end

function XTheatre5BattleAgencyCom:_GetXWorldPlayerData(playerDataServer)
    local worldPlayerData = CS.XWorldPlayerData()

    worldPlayerData.Id = playerDataServer.Id
    worldPlayerData.Name = playerDataServer.Name

    return worldPlayerData
end

function XTheatre5BattleAgencyCom:_CalNpcAttribsAfterEnterFightRequest(autoChessData)
    if XTool.IsTableEmpty(autoChessData) then
        return
    end

    -- 获取基础属性
    if XTool.IsNumberValid(autoChessData.CharacterId) then
        ---@type XTableTheatre5Character
        local charaCfg = self._Model:GetTheatre5CharacterCfgById(autoChessData.CharacterId)

        if charaCfg then
            ---@type XTableAttribBase
            local attrCfg = XMVCA.XDlcWorld:GetAttributeConfigById(charaCfg.AttrId)

            if attrCfg then
                for k, v in pairs(attrCfg) do
                    local attribType = XDlcNpcAttribType[k]
                    if type(attribType) == 'number' and type(v) == 'number' then
                        if XMVCA.XTheatre5.EnumConst.EnlargedAttribs[attribType] then
                            autoChessData.Attribs[XDlcNpcAttribType[k]] = XMath.ToMinInt(v * DlcWorldAttribMultyBase)
                        else
                            autoChessData.Attribs[XDlcNpcAttribType[k]] = v
                        end
                    end
                end
            end
        end
    end

    -- 计算宝珠加成
    if not XTool.IsTableEmpty(autoChessData.Runes) then
        for i, runeId in pairs(autoChessData.Runes) do
            ---@type XTableTheatre5ItemRune
            local runeCfg = self._Model:GetTheatre5RuneCfgById(runeId)

            if runeCfg and XTool.IsNumberValid(runeCfg.RuneAttrId) then
                ---@type XTableTheatre5ItemRuneAttr
                local runeAttrCfg = self._Model:GetTheatre5ItemRuneAttrCfgById(runeCfg.RuneAttrId)

                if runeAttrCfg then
                    for index, attr in ipairs(runeAttrCfg.AttrTypes) do
                        if XTool.IsNumberValid(runeAttrCfg.AttrValues[index]) then
                            autoChessData.Attribs[XDlcNpcAttribType[attr]] = autoChessData.Attribs[XDlcNpcAttribType[attr]] and (autoChessData.Attribs[XDlcNpcAttribType[attr]] + runeAttrCfg.AttrValues[index]) or runeAttrCfg.AttrValues[index]
                        end
                    end
                end
            end
        end
    end
end

function XTheatre5BattleAgencyCom:_GetXFightClientArgs()
    local args = CS.StatusSyncFight.XFightClientArgs()

    args.CloseLoadingUiCb = function()
        self._OwnerAgency:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_FIGHT_ENTER_FINISHED)
        --XLuaUiManager.SafeClose("UiTheatre5Loading")
    end

    args.SettleCb = function(result, summary)
        self:RequestTheatre5NormalSettle(result, summary)
    end

    args.InterruptFightCb = function(result, summary)
        self:RequestTheatre5NormalSettle(result, summary)
    end

    return args
end
--endregion

--- 用于控制台测试
function XTheatre5BattleAgencyCom:TestCalNpcAttribsAndBackXAutoChessData(autoChessData)
    self:_CalNpcAttribsAfterEnterFightRequest(autoChessData)

    return self:_GetXAutoChessData(autoChessData)
end

return XTheatre5BattleAgencyCom