
local XRedPointConditionSkyTowerEntrance = {}

function XRedPointConditionSkyTowerEntrance.Check()
    return XMVCA.XSkyTower:CheckEntranceRedPoint()
end

return XRedPointConditionSkyTowerEntrance