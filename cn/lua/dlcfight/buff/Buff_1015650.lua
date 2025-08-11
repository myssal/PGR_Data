local Base = require("Common/XFightBase")

---@class XBuffScript1015650 : XFightBase
local XBuffScript1015650 = XDlcScriptManager.RegBuffScript(1015650, "XBuffScript1015650", Base)

--效果说明：疲劳阶段，火伤增加30%
function XBuffScript1015650:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015651
    self.magicLevel = 1
    self.tiredBuff = 1010029
    self.isAdd = false
    ------------执行------------
    self.runeId = self.magicId - 1015000 + 20000 - 1

end

---@param dt number @ delta time 
function XBuffScript1015650:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --是否进疲劳
    if self._proxy:CheckBuffByKind(self._uuid, self.tiredBuff) and not self.isAdd then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
        self.isAdd = true
    end
end
--region EventCallBack
function XBuffScript1015650:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

function XBuffScript1015650:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        --战斗开始时且给runeId重新赋值
        self.runeId = self.magicId - 1015000 + 20000 - 1
    end
end

--endregion
---@param eventType number
---@param eventArgs userdata
function XBuffScript1015650:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015650:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015650

    