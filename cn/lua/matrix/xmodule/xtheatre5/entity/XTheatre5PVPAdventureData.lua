local XTheatre5AdventureDataBase = require('XModule/XTheatre5/Entity/XTheatre5AdventureDataBase')

---@class XTheatre5PVPAdventureData: XTheatre5AdventureDataBase
---@field TrophyNum number
---@field EnemyData
local XTheatre5PVPAdventureData = XClass(XTheatre5AdventureDataBase, 'XTheatre5PVPAdventureData')


function XTheatre5PVPAdventureData:Ctor()

    self.HasData = false
end

function XTheatre5PVPAdventureData:ClearData()
    XTheatre5PVPAdventureData.Super.ClearData(self)
    self._AttrAddsMap = nil
    self.HasData = false
end

--- PVP局内数据全量更新
function XTheatre5PVPAdventureData:UpdatePVPAdventureData(adventureData)
    if not XTool.IsTableEmpty(adventureData) then
        for k, v in pairs(adventureData) do
            self[k] = v
        end
        
        self.HasData = true

        self:SetNeedUpdateAdds()   
    end
end

--region 基础信息

--- 更新奖杯数（局内）
function XTheatre5PVPAdventureData:UpdateTrophyNum(trophyNum)
    self.TrophyNum = trophyNum
end

function XTheatre5PVPAdventureData:GetTrophyNum()
    return self.TrophyNum or 0
end

--endregion

--region 匹配的敌人信息

--- 更新匹配的敌人数据
function XTheatre5PVPAdventureData:UpdateMatchEnemyData(enemyData)
    self.EnemyData = enemyData
end

function XTheatre5PVPAdventureData:GetCurMatchedEnemy()
    return self.EnemyData
end

--- 获取敌人的技能Id列表
function XTheatre5PVPAdventureData:GetEnemySkillIds()
    if self.EnemyData then
        return XTool.ToArray(self.EnemyData.SkillIds)
    end
end

--- 获取敌人宝珠栏宝珠Id的列表（合并同类宝珠）
function XTheatre5PVPAdventureData:GetEnemyRuneIds()
    if self.EnemyData then
        -- 转换成有序列表
        local runeIds = {}

        for i, v in pairs(self.EnemyData.RuneIds) do
            if not runeIds[v] then
                runeIds[v] = i
            end
        end
        
        return runeIds
    end
end

function XTheatre5PVPAdventureData:GetEnemyCharacterId()
    if self.EnemyData then
        return self.EnemyData.CharacterId
    end
end
--endregion

return XTheatre5PVPAdventureData