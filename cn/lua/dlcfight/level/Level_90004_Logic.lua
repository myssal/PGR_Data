local XLevelScript90004 = XDlcScriptManager.RegLevelLogicScript(90004, "XLevel90004") --注册脚本类到管理器（逻辑脚本注册
--小辉辉战斗关卡
---@param proxy XDlcCSharpFuncs
function XLevelScript90004:Ctor(proxy) --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy --脚本代理对象，通过它来调用战斗程序开放的函数接口。
end

function XLevelScript90004:Init() --初始化逻辑
    -- --创建怪物配置
    local monsterId = 8052   --小辉辉
    local monsterCamp= ENpcCampType.Camp2
    local monsterBornPos = {x = 83, y = 1.86, z = 55}
    local monsterBornRota = {x = 0, y = 180, z = 0}
    
    -----------------创建怪物--------------------------------------------------------------------------------------------
    self.monster_UUID = self._proxy:GenerateNpc(monsterId, monsterCamp, monsterBornPos, monsterBornRota)
end

---@param dt number @ delta time
function XLevelScript90004:Update(dt) --每帧更新逻辑
end

---@param eventType number
---@param eventArgs userdata
function XLevelScript90004:HandleEvent(eventType, eventArgs) --事件响应逻辑
end

function XLevelScript90004:Terminate() --脚本结束逻辑（脚本被卸载、Npc死亡、关卡结束......）

end

return XLevelScript90004