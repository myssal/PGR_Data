---@class XMovieAgency : XAgency
---@field _Model XMovieModel
local XMovieAgency = XClass(XAgency, "XMovieAgency")

function XMovieAgency:OnInit()
    --初始化一些变量
    self.XEnumConst = require("XModule/XMovie/XMovieEnumConst")
end

function XMovieAgency:InitRpc()
    -- 注册服务器事件
end

function XMovieAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

--============================================================== #region 配置表 ==============================================================
-- 获取ClientConfig表配置
function XMovieAgency:GetClientConfig(key, index)
    return self._Model:GetClientConfig(key, index)
end

-- 获取ClientConfig表配置所有参数
function XMovieAgency:GetClientConfigParams(key)
    return self._Model:GetClientConfigParams(key)
end
--============================================================== #endregion 配置表 ==============================================================

--============================================================== #region rpc ==============================================================
-- 请求剧情选项记录
function XMovieAgency:RequestMovieOptions(movieId)
    if not XLoginManager.IsLogin() then
        return
    end

    local isCfgExit = self._Model:IsRecordOptionsConfigExit(movieId)
    if not isCfgExit then
        return
    end

    local req = { MovieId = movieId }
    XNetwork.CallWithAutoHandleErrorCode("QueryMovieOptionsRequest", req, function(res)
        self._Model:UpdateMovieOptions(movieId, res.MovieList)
    end)
end

-- 请求记录剧情选项
function XMovieAgency:RequestRecordOption(movieId, actionId, optionIndex)
    local isNeed = self._Model:IsOptionNeedRecord(movieId, actionId, optionIndex)
    if not isNeed then
        return
    end

    local optionId = self._Model:PackOptionId(actionId, optionIndex)
    local req = { MovieId = movieId, OptionId = optionId }
    XNetwork.CallWithAutoHandleErrorCode("UpdateMovieOptionsRequest", req, function(res)
        self._Model:AddMovieOption(movieId, optionId)
    end)
end

-- 是否选择过选项
function XMovieAgency:IsOptionPassed(movieId, actionId, optionIndex)
    return self._Model:IsOptionPassed(movieId, actionId, optionIndex)
end

--============================================================== #endregion rpc ==============================================================
-- 参数转数字
function XMovieAgency:ParamToNumber(param)
    if param and param ~= "" then
        return tonumber(param)
    else
        return 0
    end
end

-- 切割参数
function XMovieAgency:SplitParam(param, splitStr, isNumber)
    if not param or param == "" then
        return {}
    end
    
    local result = string.Split(param, splitStr)
    if isNumber then
        local cnt = #result
        for i = 1, cnt do
            result[i] = tonumber(result[i])
        end
    end
    return result
end

-- 提取指挥官性别对应文本
function XMovieAgency:ExtractGenderContent(content)
    local gender = XPlayer.GetShowGender()
    if gender == XEnumConst.PLAYER.GENDER_TYPE.MAN then
        local funcItor = string.gmatch(content, "<W>.-</W>")
        local result = funcItor()
        if result then
            content = string.gsub(content, result, "")
            local funcItorL = string.gmatch(content, "<T>.-</T>")
            local resultL = funcItorL()
            if resultL then
                content = string.gsub(content, resultL, "")
            end
            content = string.gsub(content, "<M>", "")
            content = string.gsub(content, "</M>", "")
            return content
        end
    elseif gender == XEnumConst.PLAYER.GENDER_TYPE.WOMAN then
        local funcItor = string.gmatch(content, "<M>.-</M>")
        local result = funcItor()
        if result then
            content = string.gsub(content, result, "")
            local funcItorL = string.gmatch(content, "<T>.-</T>")
            local resultL = funcItorL()
            if resultL then
                content = string.gsub(content, resultL, "")
            end
            content = string.gsub(content, "<W>", "")
            content = string.gsub(content, "</W>", "")
            return content
        end
    elseif gender == XEnumConst.PLAYER.GENDER_TYPE.SECRECY then
        local isManOrWoman = string.gmatch(content, "<T>.-</T>")
        if not isManOrWoman() then
            local result = string.gsub(content, '<W>.-</W>', '')
            result = string.gsub(result, '<M>', '')
            result = string.gsub(result, '</M>', '')
            content = result
        else
            local result = string.gsub(content, '<M>.-</M>', '')
            result = string.gsub(result, '<W>.-</W>', '')
            result = string.gsub(result, '<T>', '')
            result = string.gsub(result, '</T>', '')
            content = result
        end
      
    end
    return content
end


-- 将十进制编码转换成字符串
-- 配置表string和List<string>里的文本只要有英文逗号，加载出来的文本会自动增加英文的双引号
-- 配置示例：配置{226|153|170}，运行时转{226,153,170}
function XMovieAgency:ReplaceDecimalismCodeToStr(content)
    local replaceDic = {}
    for matchStr in string.gmatch(content, "{.-}") do
        if not replaceDic[matchStr] then
            local bytesStr = string.gsub(matchStr, "|", ",")
            local bytes = load("return " .. bytesStr)()
            local str = self:BytesToStr(bytes)
            content = string.gsub(content, matchStr, str)
            replaceDic[matchStr] = true
        end
    end
    return content
end

-- 十进制数组转字符串
function XMovieAgency:BytesToStr(bytes)
    local str = ""
    for i, v in ipairs(bytes) do
        str = str .. string.char(v)
    end
    return str
end

-- 检查需要设置性别
function XMovieAgency:CheckTipsSetGender(movieId)
    -- 已设置性别
    if XPlayer.Gender and  XPlayer.Gender ~= 0 then return false end

    --local movieCfg = XMovieConfigs.GetMovieCfg(movieId)
    XLuaUiManager.Open("UiPlayer")
    XLuaUiManager.Open('UiPlayerPopupSetGender')
    return true
end

-- 获取第三性别开关配置
function XMovieAgency:GetOpenMovieThirdGender()
   return self._Model:IsOpenMovieThirdGender()
end

function XMovieAgency:GetOpenMovieSkipThirdGender()
    return self._Model:IsOpenMovieSkipThirdGender()
end


return XMovieAgency