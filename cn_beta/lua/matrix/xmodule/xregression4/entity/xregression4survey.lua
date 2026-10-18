---@class XRegression4Survey
---@field ActiveSurveySet
---@field ActiveTaskSet
local XRegression4Survey = XClass(nil, 'XRegression4Survey')

--- 服务端数据更新
---@param notifyData Server.XRegression4SignInData
---@return nil
--------------------------
function XRegression4Survey:UpdateData(notifyData)
    if not notifyData then
        return
    end
    
    self._ActiveSurveyList = notifyData.ActiveSurveyList
end

function XRegression4Survey:AddSurveyData(surveyData)
    if self._ActiveSurveyList == nil then
        self._ActiveSurveyList = {}
    end
    
    table.insert(self._ActiveSurveyList, surveyData)
end

function XRegression4Survey:GetSurveyTaskIdBySurveyId(surveyId)
    if not XTool.IsTableEmpty(self._ActiveSurveyList) then
        for i, v in pairs(self._ActiveSurveyList) do
            if v.SurveyId == surveyId then
                return v.TaskId
            end
        end
    end
end

function XRegression4Survey:CheckHasAnySurvey()
    return not XTool.IsTableEmpty(self._ActiveSurveyList)
end

function XRegression4Survey:CheckHasFinished()
    if not XTool.IsTableEmpty(self._ActiveSurveyList) then
        for i, surveyData in pairs(self._ActiveSurveyList) do
            if not XDataCenter.TaskManager.CheckTaskFinished(surveyData.TaskId) then
                return false
            end
        end
        return true
    end
    return false
end

return XRegression4Survey