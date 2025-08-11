local XLevelScript90002 = XDlcScriptManager.RegLevelLogicScript(90002, "XLevel90002") --注册脚本类到管理器（逻辑脚本注册

---@param proxy XDlcCSharpFuncs
function XLevelScript90002:Ctor(proxy) --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy --脚本代理对象，通过它来调用战斗程序开放的函数接口。
end

function XLevelScript90002:Init() --初始化逻辑
    -- XLog.Error("90003初始化")

    self._playerNpcUUID = self._proxy:GetLocalPlayerNpcId() 
    local _playerNpcUUID = self._playerNpcUUID   --获取玩家UUI


    -- --创建怪物配置
    local monsterId = 8005   --白龙
    local monsterCamp= ENpcCampType.Camp2
    local monsterBornPos = {x = 86, y = 1.9, z = 65}
    local monsterBornRota = {x = 0, y = 180, z = 0}
    
    -----------------创建怪物--------------------------------------------------------------------------------------------
    self.monster_UUID = self._proxy:GenerateNpc(monsterId, monsterCamp, monsterBornPos, monsterBornRota)
end

---@param dt number @ delta time
function XLevelScript90002:Update(dt) --每帧更新逻辑
end

---@param eventType number
---@param eventArgs userdata
function XLevelScript90002:HandleEvent(eventType, eventArgs) --事件响应逻辑
end

function XLevelScript90002:Terminate() --脚本结束逻辑（脚本被卸载、Npc死亡、关卡结束......）

end

return XLevelScript90002