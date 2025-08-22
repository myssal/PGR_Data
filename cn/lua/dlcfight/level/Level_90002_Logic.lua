local XLevelScript90002 = XDlcScriptManager.RegLevelLogicScript(90002, "XLevel90002") --注册脚本类到管理器（逻辑脚本注册

---@param proxy XDlcCSharpFuncs
function XLevelScript90002:Ctor(proxy) --构造函数，用于执行与外部无关的内部构造逻辑（例如：创建内部变量等）
    self._proxy = proxy --脚本代理对象，通过它来调用战斗程序开放的函数接口。
end

function XLevelScript90002:Init() --初始化逻辑
    -- --创建怪物配置
    local monsterId = 8005   --白龙
    local monsterCamp= ENpcCampType.Camp2
    local monsterBornPos = {x = 86, y = 1.9, z = 65}
    local monsterBornRota = {x = 0, y = 180, z = 0}
    self.isLeveEnd =false --关卡是否结束
    -----------------创建怪物--------------------------------------------------------------------------------------------
    self.monster_UUID = self._proxy:GenerateNpc(monsterId, monsterCamp, monsterBornPos, monsterBornRota)
end

---@param dt number @ delta time
function XLevelScript90002:Update(dt) --每帧更新逻辑
    if  self.isLeveEnd then
        return
    end
    self:CheckLevelEnd()
end

---@param eventType number
---@param eventArgs userdata
function XLevelScript90002:HandleEvent(eventType, eventArgs) --事件响应逻辑
end

function XLevelScript90002:CheckLevelEnd() --检查关卡结束
    ----胜利结算检测-----------------
    if self.monster_UUID ~= 0 then
        if self._proxy:CheckNpc(self.monster_UUID) == false or self._proxy:CheckActorExist(self.monster_UUID) == false then
            self._proxy:FinishFight() --仅客户端完成战斗
            self:LevelEnd(true)
            return
        end
    end

    ---关卡失败检测------------------
end

function XLevelScript90002:LevelEnd(isPlayerWin)
    self.isLeveEnd = true
    self._proxy:SettleFight(isPlayerWin)                   --后端结算通知API
    if isPlayerWin then
        XLog.Warning("玩家胜利")
    else
        XLog.Warning("玩家失败")
    end
end

function XLevelScript90002:Terminate() --脚本结束逻辑（脚本被卸载、Npc死亡、关卡结束......）

end

return XLevelScript90002