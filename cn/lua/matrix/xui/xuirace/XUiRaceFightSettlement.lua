---@class XUiRaceFightSettlement : XLuaUi 结算
---@field _Control XRaceControl
---@field _3DCamera XUiPanelRace3DCamera
local XUiRaceFightSettlement = XLuaUiManager.Register(XLuaUi, "UiRaceFightSettlement")

function XUiRaceFightSettlement:OnAwake()
    self.BtnNext.CallBack = handler(self, self.OnBtnNextClick)
end

function XUiRaceFightSettlement:OnStart(roundId)
    self._ResultRoundId = roundId
    local roundCfg = self._Control:GetRaceRoundById(self._ResultRoundId)
    local etcd = self._Control:GetEtcdRoundConfig(self._ResultRoundId)
    self.TxtTitle01.text = roundCfg.Name
    self.TxtTitle02.text = roundCfg.SubTitle
    self._IsShowChampion = roundCfg.EndShowType == XEnumConst.Race.RankTag.Champion
    self._RoleIds = nil
    if etcd.TypeId == XEnumConst.Race.Format.PointsRace then
        self:ShowPointsRaceResult(etcd.PointGroupId)
    else
        self:ShowEliminatorResult()
    end

    self._3DCamera = require("XUi/XUiRace/Panel/XUiPanelRace3DCamera").New(self.UiModelGo.transform, self, XEnumConst.Race.SceneType.Settlement)
    self._3DCamera:LookAt(self._RoleIds and self._RoleIds[1])

    local endTime = self._Control:GetTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
            return
        end
    end)

    --关闭其他弹窗和预测界面
    XLuaUiManager.Remove("UiRaceCourse")
    XLuaUiManager.Remove("UiRaceMemberDetail")
    XLuaUiManager.Remove("UiRacePopupCommon")
    XLuaUiManager.Remove("UiRacePopupResultDetail")
    XLuaUiManager.Remove("UiRacePredict")
    XLuaUiManager.Remove("UiRaceProjectChose")
end

function XUiRaceFightSettlement:ShowPointsRaceResult(pointGroupId)
    local data = self._Control:GetPointsRaceData(pointGroupId)
    self._RoleIds = data:GetRankRoleIds()
    local historyRoleIds = XTool.Clone(self._RoleIds)
    local roundIds = data:GetRounds()
    local curIndex = table.indexof(roundIds, self._ResultRoundId) --当前轮次

    if curIndex > 1 then
        --计算上一轮的排名
        table.sort(historyRoleIds, function(a, b)
            local aRank = data:GetOutRoleRank(a, curIndex - 1)
            local bRank = data:GetOutRoleRank(b, curIndex - 1)
            return aRank < bRank
        end)
    end

    --1、显示原先积分和增加的积分
    self:RefreshCustomizedList(historyRoleIds, function(i, roleId, grid)
        local addPoint = data:GetSinglePoint(roleId, curIndex) --当前场次增加的积分
        local point --上一场积分
        if curIndex == 1 then
            point = 0
        else
            point = data:GetSinglePoint(roleId, curIndex - 1)
        end
        grid.TxtAdd1.gameObject:SetActiveEx(true)
        grid.TxtAdd2.gameObject:SetActiveEx(true)
        grid.TxtTotal1.gameObject:SetActiveEx(true)
        grid.TxtTotal2.gameObject:SetActiveEx(true)
        grid.TxtWinTime.gameObject:SetActiveEx(false)
        grid.TxtFailTime.gameObject:SetActiveEx(false)
        grid.TxtAdd1.text = string.format("+%s", addPoint)
        grid.TxtAdd2.text = string.format("+%s", addPoint)
        grid.TxtTotal1.text = point
        grid.TxtTotal2.text = point
        grid.Result.gameObject:SetActiveEx(false)
        grid.WinTxtName.gameObject:SetActiveEx(true)
        grid.FailTxtName.gameObject:SetActiveEx(false)
        grid.ImgWinBgResult01.gameObject:SetActiveEx(false)
        grid.ImgFailBgResult01.gameObject:SetActiveEx(false)
        grid.ImgFailBg01.gameObject:SetActiveEx(false)
        grid.ImgWinBg01.gameObject:SetActiveEx(true)
    end)

    --2、播放动效后 显示最新积分并且重新排序
    local timerId = XScheduleManager.ScheduleOnce(function()
        self:RefreshCustomizedList(self._RoleIds, function(i, roleId, grid)
            local point = 0
            for i = 1, curIndex do
                point = point + data:GetSinglePoint(roleId, i)
            end
            grid.TxtTotal1.text = point
            grid.TxtTotal2.text = point
            -- 只有最后一轮才显示晋升和淘汰
            local isUp = data:IsRoleUp(roleId)
            local isDown = data:IsRoleDown(roleId)
            grid.Result.gameObject:SetActiveEx(true)
            grid.WinTxtName.gameObject:SetActiveEx(isUp)
            grid.FailTxtName.gameObject:SetActiveEx(isDown)
            grid.Win.gameObject:SetActiveEx(isUp)
            grid.Fail.gameObject:SetActiveEx(isDown)
            grid.Champion.gameObject:SetActiveEx(false)
            grid.TxtAdd1.gameObject:SetActiveEx(false)
            grid.TxtAdd2.gameObject:SetActiveEx(false)
            grid.ImgWinBgResult01.gameObject:SetActiveEx(false)
            grid.ImgFailBgResult01.gameObject:SetActiveEx(false)
            grid.ImgFailBg01.gameObject:SetActiveEx(isDown)
            grid.ImgWinBg01.gameObject:SetActiveEx(isUp)
            end)
    end, 1000)
    self:_AddTimerId(timerId)
end

function XUiRaceFightSettlement:ShowEliminatorResult()
    local data = self._Control:GetEliminatorData(self._ResultRoundId)
    self._RoleIds = data:GetRankRoleIds()
    self:RefreshCustomizedList(self._RoleIds, function(i, roleId, grid)
        local timeStr = self._Control:GetPassTimeStr(data:GetRolePassTime(roleId))
        grid.TxtAdd1.gameObject:SetActiveEx(false)
        grid.TxtAdd2.gameObject:SetActiveEx(false)
        grid.TxtTotal1.gameObject:SetActiveEx(false)
        grid.TxtTotal2.gameObject:SetActiveEx(false)
        grid.TxtWinTime.gameObject:SetActiveEx(true)
        grid.TxtFailTime.gameObject:SetActiveEx(true)
        grid.TxtWinTime.text = timeStr
        grid.TxtFailTime.text = timeStr
        grid.Result.gameObject:SetActiveEx(true)
        grid.ImgFailBg01.gameObject:SetActiveEx(false)
        grid.ImgWinBg01.gameObject:SetActiveEx(false)
        if self._IsShowChampion then
            local isChampion = i == 1
            grid.Win.gameObject:SetActiveEx(false)
            grid.Fail.gameObject:SetActiveEx(false)
            grid.Champion.gameObject:SetActiveEx(isChampion)
            grid.WinTxtName.gameObject:SetActiveEx(isChampion)
            grid.FailTxtName.gameObject:SetActiveEx(not isChampion)
            grid.ImgWinBgResult01.gameObject:SetActiveEx(isChampion)
            grid.ImgFailBgResult01.gameObject:SetActiveEx(not isChampion)
        else
            local isUp = data:IsRoleUp(roleId)
            local isDown = data:IsRoleDown(roleId)
            grid.Win.gameObject:SetActiveEx(isUp)
            grid.Fail.gameObject:SetActiveEx(isDown)
            grid.WinTxtName.gameObject:SetActiveEx(isUp)
            grid.FailTxtName.gameObject:SetActiveEx(isDown)
            grid.Champion.gameObject:SetActiveEx(false)
            grid.ImgWinBgResult01.gameObject:SetActiveEx(isUp)
            grid.ImgFailBgResult01.gameObject:SetActiveEx(isDown)
        end
    end)
end

function XUiRaceFightSettlement:RefreshCustomizedList(roleIds, func)
    XUiHelper.RefreshCustomizedList(self.GridData.parent, self.GridData, #roleIds, function(i, go)
        local uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.ImgRank:SetSprite(self._Control:GetClientConfig("RankNumIcon", i))

        local roleId = roleIds[i]
        local roleCfg = self._Control:GetRaceCharacterById(roleId)
        uiObject.WinTxtName.text = roleCfg.Name
        uiObject.FailTxtName.text = roleCfg.Name
        uiObject.BtnHead:SetRawImage(roleCfg.Icon)
        uiObject.BtnHead.CallBack = function()
            XLuaUiManager.Open("UiRaceMemberDetail", roleId, uiObject.BtnHead.transform)
        end

        func(i, roleId, uiObject)
    end)
end

function XUiRaceFightSettlement:OnBtnNextClick()
    self._Control:RequestGuessSingleRoundResult(self._ResultRoundId, function()
        XLuaUiManager.Open("UiRaceFightPredictSettlement", self._ResultRoundId)
        self:Close()
    end)
end

return XUiRaceFightSettlement