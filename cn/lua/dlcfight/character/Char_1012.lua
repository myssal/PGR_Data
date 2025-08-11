---@type XAFKCharBase
local Base = require("Character/FightCharBase/XAFKCharBase")

---自走棋莉莉丝脚本
---@class XCharTes1012 : XAFKCharBase
local XCharTes1012 = XDlcScriptManager.RegCharScript(1012, "XCharTes1012", Base)

function XCharTes1012:Init() --初始化
    Base.Init(self)
    
    --距离要求，没有在列表内说明没有距离要求，在筛选到技能释放时
    self.skillCastDistanceDic={  --配置技能的释放距离，没有在字典内配置距离的技能表示没有释放距离
        
    }
    
    --默认普攻技能释放列表，这个基类里找
    self.normalAttackList ={ 
        
    }
    
end

---@param dt number @ delta time 
function XCharTes1012:Update(dt)
    Base.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XCharTes1012:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)

end

function XCharTes1012:Terminate()
    Base.Terminate(self)
end

return XCharTes1012
