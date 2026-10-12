local XSkyTowerChar = require("XModule/XSkyTower/XGameObject/XSkyTowerChar")

---@class XSkyTowerRole : XSkyTowerChar 角色模型类
---@field _BubbleTexts string[]
---@field _FreeCount number 能随机次数
---@field _BubbleOffset UnityEngine.Vector3 气泡偏移
---@field _NextBubbleTime number 下次气泡弹出时间
---@field _HideEffectMap table<string, UnityEngine.GameObject> 是否销毁特效
---@field _WorkPosIndex number 工位下标
local XSkyTowerRole = XClass(XSkyTowerChar, "XSkyTowerRole")

function XSkyTowerRole:OnInit(root, id, floorId, index)
    self._WorkPosIndex = index
    XSkyTowerChar.OnInit(self, root, id, floorId)
end

function XSkyTowerRole:GetWorkPosIndex()
    return self._WorkPosIndex
end

function XSkyTowerRole:InitData()
end

function XSkyTowerRole:GetObjName()
    return string.format("@S-%s-WorkPos%s", tostring(self._Id), tostring(self._WorkPosIndex))
end

function XSkyTowerRole:CheckBeforeLoad()
    if not XTool.IsNumberValid(self._Id) then
        XLog.Error("load skyTower character error: character id is invalid")
        return false
    end
    return true
end

function XSkyTowerRole:DelayRelease()
    if not self:Exist() then
        return
    end
    --还有引用，不销毁
    if self._ReferenceCount > 0 then
        return
    end
    self:GetRoom():ReleaseCharacter(self._Id, self._WorkPosIndex)
end

function XSkyTowerRole:GetAssetPath()
    local template = self._Model:GetCharacterModelConfig(self._Id)
    if not template then
        return ""
    end
    return self._Model:GetNpcModelUrl(template.NpcId)
end

function XSkyTowerRole:GetControllerPath()
    local template = self._Model:GetCharacterModelConfig(self._Id)
    if not template then
        return ""
    end
    return self._Model:GetNpcControllerUrl(template.NpcId)
end

function XSkyTowerRole:GetCharTypeDesc()
    return CS.XTextManager.GetLuaText("XSkyTowerRole.lua_54")
end

function XSkyTowerRole:PlayBehaviour()
    XLuaBehaviorManager.PlayId("Loading", self._Agent)
end

function XSkyTowerRole:ChangeState(state)
    if not self._IsDoLoadBehaviour then
        return
    end
    local isWork = self:DoIsWorking()
    local behaviorId = isWork and "Working" or "Pause"
    XLuaBehaviorManager.PlayId(behaviorId, self._Agent)
end

function XSkyTowerRole:OnLoadBehaviourComplete()
    XSkyTowerChar.OnLoadBehaviourComplete(self)
    self:ChangeState()
end

function XSkyTowerRole:Show()
    XSkyTowerChar.Show(self)
    self:PlayBehaviour()
end

--- 设置工作台
---@param target UnityEngine.Transform 目标工作台
---@return
function XSkyTowerRole:SetWorkBench(target, pos, workType)
    if not target then
        return
    end
    --售卖和制作共用Working行为树，重置行为不会回收旧移动节点，重新定位前先停止寻路。
    self:DoStopMove()
    self._WorkType = workType
    self._Transform.position = pos
    self._Transform:LookAt(target.transform)
    --直接获取的配置，需要Clone一份
    self._BubbleTexts = XTool.Clone(self._Model:GetCharacterTextList(self._Id, workType))
    self._FreeCount = #self._BubbleTexts
end

--取消工作
function XSkyTowerRole:UnAssignWork()
    XLuaBehaviorManager.PlayId("UnAssignWork", self._Agent)
end

function XSkyTowerRole:DoIsWorking()
    return self._OwnControl:GetWorkState(self._FloorId, self._WorkPosIndex) == XMVCA.XSkyTower.WorkState.Working
end

function XSkyTowerRole:GetRandomBubbleText()
    --通用员工可以不配置气泡，文本未就绪时也不能随机空区间。
    if XTool.IsTableEmpty(self._BubbleTexts) or not XTool.IsNumberValid(self._FreeCount) then
        return
    end
    local index = math.random(1, self._FreeCount)
    local text = self._BubbleTexts[index]
    self._BubbleTexts[index] = self._BubbleTexts[self._FreeCount]
    self._BubbleTexts[self._FreeCount] = text
    self._FreeCount = self._FreeCount - 1
    if self._FreeCount <= 0 then
        self._FreeCount = #self._BubbleTexts
    end
    return text
end

function XSkyTowerRole:GetBubbleText(index)
    local text = self._BubbleTexts[index]
    return text or "? ? ?"
end

function XSkyTowerRole:GetActionId(index)
    local template = self._Model:GetCharacterModelConfig(self._Id)
    return template and template.Anim[index] or ""
end

function XSkyTowerRole:DoCheckInt(intValue)
    return self._WorkType == intValue
end

function XSkyTowerRole:GetRandomPoint()
    return self:GetRoom():GetRandomPoint(self._WorkPosIndex)
end

--工作是否有加成
--todo 通天塔没有区域Buff，行为树SkyTowerIsWorkWithBuff节点暂时恒判false，待策划把该条件从SkyTower.xml行为树里摘掉后，本函数与节点一并删除
function XSkyTowerRole:IsWorkWithBuff()
    return false
end

function XSkyTowerRole:Release()
    self._BubbleTexts = nil
    XSkyTowerChar.Release(self)
end

function XSkyTowerRole:IsHideWhenStopBusiness()
    return true
end

return XSkyTowerRole
