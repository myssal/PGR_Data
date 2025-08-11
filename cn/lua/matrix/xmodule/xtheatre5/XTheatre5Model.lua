---@class XTheatre5Model : XModel
local XTheatre5Model = XClass(XModel, "XTheatre5Model", true)

--region 初始化部分类
require('XModule/XTheatre5/ModelPartial/XTheatre5ModelConfig')
require('XModule/XTheatre5/ModelPartial/XTheatre5ModelSave')
--endregion

local XTheatre5PVPAdventureData = require('XModule/XTheatre5/Entity/XTheatre5PVPAdventureData')
local XTheatre5PVPCharacterData = require('XModule/XTheatre5/Entity/XTheatre5PVPCharacterData')
local XTheatre5PVERougeData = require('XModule/XTheatre5/Entity/XTheatre5PVERougeData')
local XTheatre5PVEAdventureData = require('XModule/XTheatre5/Entity/XTheatre5PVEAdventureData')

function XTheatre5Model:OnInit()
    self:InitConfigs()
    self:InitLocalSave()
    ---@type XTheatre5PVPAdventureData
    self.PVPAdventureData = XTheatre5PVPAdventureData.New(self)
    ---@type XTheatre5PVPCharacterData
    self.PVPCharacterData = XTheatre5PVPCharacterData.New()

    ---@type XTheatre5AdventureDataBase
    self.CurAdventureData = nil
     ---@type XTheatre5PVERougeData
    self.PVERougeData = XTheatre5PVERougeData.New(self)
    ---@type XTheatre5PVEAdventureData
    self.PVEAdventureData = XTheatre5PVEAdventureData.New(self)
end

function XTheatre5Model:ClearPrivate()
    self:ReleasePriConfigCache()
end

function XTheatre5Model:ResetAll()
    self:SetActivityId(nil)
    self:ReleaseNopriConfigCache()

    self.PVPAdventureData:ClearData()
    self.PVPCharacterData:ClearData()
    self.PVERougeData:ClearData()
    self.PVEAdventureData:ClearData()

    self:SetCurPlayingMode(nil)
end

function XTheatre5Model:SetActivityId(activityId)
    self._ActivityId = activityId
end

function XTheatre5Model:GetActivityId()
    return self._ActivityId or 0
end

--- 设置当前正在游玩的模式, 用于玩法内各界面差异化逻辑判断
function XTheatre5Model:SetCurPlayingMode(mode)
    self._CurPlayingMode = mode

    if self._CurPlayingMode == XMVCA.XTheatre5.EnumConst.GameModel.PVP then
        self.CurAdventureData = self.PVPAdventureData
    else
        self.CurAdventureData = self.PVEAdventureData
    end
    
    XMVCA.XTheatre5:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_GAME_MODE_CHANGED)
end

function XTheatre5Model:GetCurPlayingMode()
    return self._CurPlayingMode
end

function XTheatre5Model:ChangePlayingMode()
    local curPlayingMode = self._CurPlayingMode
    if curPlayingMode == XMVCA.XTheatre5.EnumConst.GameModel.PVE then
        curPlayingMode = XMVCA.XTheatre5.EnumConst.GameModel.PVP
    else
        curPlayingMode = XMVCA.XTheatre5.EnumConst.GameModel.PVE
    end
    self:SetCurPlayingMode(curPlayingMode)        
end

return XTheatre5Model