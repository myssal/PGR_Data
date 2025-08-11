local Base = require("Common/XFightBase")

---@class XBuffScript1015104 : XFightBase
local XBuffScript1015104 = XDlcScriptManager.RegBuffScript(1015104, "XBuffScript1015104", Base)

--效果说明：雷属性伤害提升50%，每秒衰减5，最低0
function XBuffScript1015104:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.triggerCD = 1     --宝珠生效CD
    self.magicId = 1015105 --魔法id
    self.magicLevel = 1 --初始魔法等级
    self.magicMaxLevel = 11 --最终魔法等级
    ------------执行------------
    self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.triggerCD  --计算宝珠CD的Timer
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel) --给目标添加特定类型的效果
    --XLog.Warning("等级:" .. self.magicLevel)
    --XLog.Warning("时间:" .. self.cdTimer)
end

---@param dt number @ delta time
function XBuffScript1015104:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    local isCdOk = self._proxy:GetNpcTime(self._uuid) >= self.cdTimer
    local isLevelOk = self.magicLevel < self.magicMaxLevel --判断魔法等级是否小于最终魔法等级

    if isCdOk and isLevelOk then
        --CD好了&魔法等级小于最终魔法等级就执行
        self.magicLevel = self.magicLevel + 1 --每秒等级加1
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel) --给目标添加特定类型的效果
        self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.triggerCD  --计算宝珠CD的Timer

        --XLog.Warning("等级:" .. self.magicLevel)
        --XLog.Warning("时间:" .. self.cdTimer)
    end
end

--region EventCallBack
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015104:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015104:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015104
