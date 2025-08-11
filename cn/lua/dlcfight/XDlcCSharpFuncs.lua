---@class XDlcCSharpFuncs
---@alias float number
---@alias int number
---@alias Action function
---@alias bool boolean
---@alias Vector4 UnityEngine.Vector4
---@alias Vector3 UnityEngine.Vector3
---@alias Vector2 UnityEngine.Vector2
local XDlcCSharpFuncs = {}

---@desc 结束战斗并通知所有客户端退出战斗
---@return void 
function XDlcCSharpFuncs:FinishFight()
end

---@desc 统一结算所有玩家（相当于用相同的参数批量对所有玩家调用SettlePlayer）
---@param win bool 是否胜利
---@return void 
function XDlcCSharpFuncs:SettleFight(win)
end

---@desc 单独结算某个玩家
---@param npcUUID int 玩家npc的UUID
---@param win bool 是否胜利
---@return void 
function XDlcCSharpFuncs:SettlePlayer(npcUUID, win)
end

---@desc 获取进入本场战斗的玩家数量
---@return int 玩家数量
function XDlcCSharpFuncs:GetPlayerCount()
end

---@desc 根据玩家NpcUUID获取玩家ID
---@param npcId int 
---@return int 玩家ID
function XDlcCSharpFuncs:GetPlayerIdByNpc(npcId)
end

---@desc 获取战斗当前时间
---@return float 时间
function XDlcCSharpFuncs:GetFightTime()
end

---@desc 判断玩家是否离线
---@param npcUUID int 
---@return bool 
function XDlcCSharpFuncs:CheckNpcIsDisconnect(npcUUID)
end

---@desc 设置战斗配置float
---@param key string 
---@param value float 
---@return void 
function XDlcCSharpFuncs:SetFloatConfig(key, value)
end

---@desc 添加定时器任务
---@param delayTimeSeconds float 延迟时间，单位：秒
---@param callback Action 回调函数
---@return int 计时器任务ID，成功时返回大于0的ID，失败时返回0
function XDlcCSharpFuncs:AddTimerTask(delayTimeSeconds, callback)
end

---@desc 移除定时器任务
---@param taskId int 计时器任务ID
---@return void 
function XDlcCSharpFuncs:RemoveTimerTask(taskId)
end

---@desc 将某个Actor的局部坐标转换为世界坐标
---@param uuid int 
---@param point Vector3 
---@return Vector3 
function XDlcCSharpFuncs:TransformPointByActor(uuid, point)
end

---@desc 将世界坐标转换为某个Actor的局部坐标
---@param uuid int 
---@param point Vector3 
---@return Vector3 
function XDlcCSharpFuncs:InverseTransformPointByActor(uuid, point)
end

---@desc 获取一定范围内的随机数
---@param min int 随机范围下限
---@param max int 随机范围上限
---@return int 
function XDlcCSharpFuncs:Random(min, max)
end

---@desc 记录自定义结算数据
---@param playerId int 玩家ID（可通过GetPlayerIdByNpc提前获取）
---@param key int 
---@param value int 
---@return void 
function XDlcCSharpFuncs:SetFightResultCustomData(playerId, key, value)
end

---@desc 发送副本结算数据
---@desc 详情:https://kurogame.feishu.cn/wiki/Fvqsw1u6pi6vzzkpPzlcMsQjnLb
---@param settleType int 结算类型
---@param settleDataLuaTable LuaTable 结算数据结构
---@return void 
function XDlcCSharpFuncs:OpenInstLevelSettleUi(settleType, settleDataLuaTable)
end

---@desc 记录副本结算数据(通常是埋点)
---@desc 详情:https://kurogame.feishu.cn/wiki/Fvqsw1u6pi6vzzkpPzlcMsQjnLb
---@param settleType int 结算类型
---@param settleDataLuaTable LuaTable 结算数据结构
---@return void 
function XDlcCSharpFuncs:RecordInstLevelSettleData(settleType, settleDataLuaTable)
end

---@desc 获取指定类型指定Id的关卡脚本对象
---@param scriptType EScriptType 脚本类型（参考EScriptType枚举）
---@param levelId int 关卡ID
---@return ILuaFightScript 
function XDlcCSharpFuncs:GetLevelScriptObject(scriptType, levelId)
end

---@desc 获取指定Actor的指定Id的脚本对象
---@param scriptType EScriptType 脚本类型（参考EScriptType枚举）
---@param actorId int Npc或SceneObject的UUID
---@param scriptId int 脚本ID（例如4001就是Q版露西亚）
---@return ILuaFightScript 
function XDlcCSharpFuncs:GetActorScriptObject(scriptType, actorId, scriptId)
end

---@desc 给Npc添加角色脚本
---@param npcUUID int npc对象UUID
---@param scriptId int 角色脚本Id
---@return void 
function XDlcCSharpFuncs:AddNpcCharScript(npcUUID, scriptId)
end

---@desc 给Npc移除角色脚本
---@param npcUUID int npc对象UUID
---@param scriptId int 角色脚本Id
---@return void 
function XDlcCSharpFuncs:RemoveNpcCharScript(npcUUID, scriptId)
end

---@desc 加载关卡NPC
---@param placeId int 关卡NPC的PlaceId
---@return bool true成功，false失败
function XDlcCSharpFuncs:LoadLevelNpc(placeId)
end

---@desc 通过PlaceId获取Npc的UUID
---@param placeId int 
---@return int 
function XDlcCSharpFuncs:GetNpcUUID(placeId)
end

---@desc 生成Npc，并返回其对象Id。
---@param templateId int 
---@param camp int 
---@param position Vector3 
---@param rotation Vector3 
---@param canLaunchInteraction bool 默认值:false 
---@return int 
function XDlcCSharpFuncs:GenerateNpc(templateId, camp, position, rotation, canLaunchInteraction)
end

---@desc 获取辅助机对象UUID
---@return int 
function XDlcCSharpFuncs:GetAssistNpcUUID()
end

---@desc 设置Npc显隐，会将角色控制器、角色碰撞一同显隐
---@param uuid int 
---@param active bool 
---@return void 
function XDlcCSharpFuncs:SetNpcActive(uuid, active)
end

---@desc 读取Npc的显隐状态
---@param uuid int 
---@return bool 
function XDlcCSharpFuncs:GetNpcActive(uuid)
end

---@desc 移除Npc
---@param uuid int 
---@return void 
function XDlcCSharpFuncs:DestroyNpc(uuid)
end

---@desc 卸载关卡NPC
---@param placeId int 关卡NPC的PlaceId
---@return void 
function XDlcCSharpFuncs:UnloadLevelNpc(placeId)
end

---@desc 检查技能时间
---@param npcId int Npc对象的UUID
---@param type int 技能时间类型：Jump = 1, Move = 2, Skill = 3, UseAnimationY = 4
---@return bool 
function XDlcCSharpFuncs:CheckSkillTiming(npcId, type)
end

---@desc 使Npc释放指定技能
---@param npcId int 
---@param skillId int 
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastSkill(npcId, skillId)
end

---@desc 使Npc释放指定技能(部分技能)
---@param npcId int 
---@param skillId int 
---@param startTime float 开始时间
---@param endTime float 结束时间
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastSkillEx(npcId, skillId, startTime, endTime)
end

---@desc 向指定坐标放技能
---@param npcId int 
---@param skillId int 
---@param position Vector3 位置
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastSkillToPosition(npcId, skillId, position)
end

---@desc 向指定坐标放技能(部分技能)
---@param npcId int 
---@param skillId int 
---@param position Vector3 位置
---@param startTime float 开始时间
---@param endTime float 结束时间
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastSkillToPositionEx(npcId, skillId, position, startTime, endTime)
end

---@desc 向指定Npc放技能
---@param npcId int 要释放技能的Npc对象的UUID
---@param skillId int 技能Id
---@param targetNpcId int 目标Npc对象的UUID
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastSkillToTarget(npcId, skillId, targetNpcId)
end

---@desc 向指定Npc放技能(部分技能)
---@param npcId int 要释放技能的Npc对象的UUID
---@param skillId int 技能Id
---@param targetNpcId int 目标Npc对象的UUID
---@param startTime float 开始时间
---@param endTime float 结束时间
---@return bool 返回是否释放成功
function XDlcCSharpFuncs:CastSkillToTargetEx(npcId, skillId, targetNpcId, startTime, endTime)
end

---@desc 打断Npc当前技能
---@param npcId int 
---@param force bool 默认值:false 
---@return void 
function XDlcCSharpFuncs:AbortSkill(npcId, force)
end

---@desc 检查Npc当前技能是否为指定技能
---@param npcId int 
---@param skillId int 
---@return bool 
function XDlcCSharpFuncs:CheckNpcCurrentSkill(npcId, skillId)
end

---@desc 获取当前技能的配置ID以及类型
---@param npcId int 
---@param skillId out int 
---@param skillType out int 
---@return bool 
function XDlcCSharpFuncs:TryGetCurrentSkill(npcId, skillId, skillType)
end

---@desc 使Npc死亡
---@param npcId int 
---@return void 
function XDlcCSharpFuncs:NpcDie(npcId)
end

---@desc 使Npc开始移动并看向lookPosition
---@param npcId int 
---@param lookPosition Vector3 
---@return void 
function XDlcCSharpFuncs:NpcStartMove(npcId, lookPosition)
end

---@desc 使Npc开始移动并看向lookPosition
---@param npcUUID int 
---@param destination Vector3 
---@param moveType ENpcMoveType 
---@return void 
function XDlcCSharpFuncs:NpcMoveTo(npcUUID, destination, moveType)
end

---@desc 使Npc开始沿着给定的路线移动
---@param npcUUID int 
---@param routeId int 
---@param moveType ENpcMoveType 
---@return void 
function XDlcCSharpFuncs:NpcMoveByRoute(npcUUID, routeId, moveType)
end

---@desc 使Npc停止移动
---@param npcId int 
---@return void 
function XDlcCSharpFuncs:NpcStopMove(npcId)
end

---@desc 【注意】要求存在寻路数据配置，
---@desc 文档:https://kurogame.feishu.cn/docx/JHIfd7qInosGvpxkgvwcDa0UnGc
---@desc 令Npc寻路到达某处
---@param npcUUID int 要寻路的NpcId
---@param position Vector3 目标地点
---@param moveType int 默认值:1 npc的移动方式(走、跑、疾跑)
---@return void 
function XDlcCSharpFuncs:NpcNavigateTo(npcUUID, position, moveType)
end

---@desc 禁止频繁调用（会发送同步消息
---@desc 设置Npc坐标
---@param npcId int 
---@param position Vector3 
---@param resetNpcState bool 默认值:false 
---@return void 
function XDlcCSharpFuncs:SetNpcPosition(npcId, position, resetNpcState)
end

---@desc 禁止频繁调用（会发送同步消息
---@desc 设置Npc朝向（rotation为各轴旋转角度
---@param npcId int 
---@param rotation Vector3 
---@return void 
function XDlcCSharpFuncs:SetNpcRotation(npcId, rotation)
end

---@desc 禁止频繁调用（会发送同步消息
---@desc 设置Npc坐标与朝向
---@desc rotation：各轴的旋转角度（单位：°，非弧度）
---@desc resetNpcState：是否重置Npc状态为待机状态
---@param npcId int 
---@param position Vector3 
---@param rotation Vector3 
---@param resetNpcState bool 默认值:false 
---@return void 
function XDlcCSharpFuncs:SetNpcPosAndRot(npcId, position, rotation, resetNpcState)
end

---@desc 设置Npc移动方向
---@param npcId int 
---@param direction int 参考枚举ENpcMoveDirection
---@return void 
function XDlcCSharpFuncs:SetNpcMoveDirection(npcId, direction)
end

---@desc 设置Npc移动类型
---@param npcId int 
---@param type int 参考枚举ENpcMoveType
---@return void 
function XDlcCSharpFuncs:SetNpcMoveType(npcId, type)
end

---@desc 获取Npc移动类型
---@param npcId int 
---@return int 参考枚举ENpcMoveType
function XDlcCSharpFuncs:GetNpcMoveType(npcId)
end

---@desc 设置Npc看向坐标
---@param npcId int 
---@param position Vector3 
---@return void 
function XDlcCSharpFuncs:SetNpcLookAtPosition(npcId, position)
end

---@desc 设置Npc看向目标
---@param npcId int 
---@param targetNpcId int 
---@return void 
function XDlcCSharpFuncs:SetNpcLookAtNpc(npcId, targetNpcId)
end

---@desc 设置玩家Npc相机锁定目标
---@param npcId int 
---@param targetId int 
---@return bool 
function XDlcCSharpFuncs:SetNpcFocusTarget(npcId, targetId)
end

---@desc 移除玩家Npc相机锁定目标
---@param npcId int 
---@return void 
function XDlcCSharpFuncs:RemoveNpcFocusTarget(npcId)
end

---@desc 获取本端玩家角色的Npc的UUID
---@return int 
function XDlcCSharpFuncs:GetLocalPlayerNpcId()
end

---@desc 获取本段玩家指挥官NPC的UUID
---@return int 
function XDlcCSharpFuncs:GetLocalPlayerSelfNpcId()
end

---@desc 检查是否存在对应npcUUID的Npc
---@param npcId int 
---@return bool 
function XDlcCSharpFuncs:CheckNpc(npcId)
end

---@desc 检查Npc动作状态机是否处于action
---@param npcId int 
---@param action int 
---@return bool 
function XDlcCSharpFuncs:CheckNpcAction(npcId, action)
end

---@desc 检查Npc能否释放技能
---@param npcId int 
---@return bool 
function XDlcCSharpFuncs:CheckCanCastSkill(npcId)
end

---@desc 检测Npc与目标距离是否在指定值内
---@param npc int 
---@param target int 
---@param distance float 
---@return bool 
function XDlcCSharpFuncs:CheckNpcDistance(npc, target, distance)
end

---@desc 计算Npc与目标的距离
---@param npc int 
---@param target int 
---@return float 
function XDlcCSharpFuncs:CalcNpcDistance(npc, target)
end

---@desc 检测target和Npc的连线与Npc朝向的夹角是否在给定的agnle角度内，angle单位为度。
---@param npc int 
---@param target int 
---@param angle float 
---@return bool 
function XDlcCSharpFuncs:CheckNpcInAngle(npc, target, angle)
end

---@desc 检测target和Npc的连线与Npc朝向的夹角是否在from和to的角度范围内，from和to单位为度。
---@param npc int 主体角色UUID
---@param target int 目标角色UUID
---@param from float 区间起始角度
---@param to float 区间结束角度，不能小于from
---@return bool 是否在from和to构成的角度区间内
function XDlcCSharpFuncs:CheckNpcInAngleRangeHorizontal(npc, target, from, to)
end

---@desc 检测Npc是否在空中
---@param npcId int 
---@return bool 
function XDlcCSharpFuncs:CheckNpcOnAir(npcId)
end

---@desc 获取Npc坐标
---@param npcId int 
---@return Vector3 
function XDlcCSharpFuncs:GetNpcPosition(npcId)
end

---@desc 获取Npc朝向（返回各轴角度
---@param npcId int 
---@return Vector3 
function XDlcCSharpFuncs:GetNpcRotation(npcId)
end

---@desc attrib参考枚举ENpcAttrib
---@param npcId int 
---@param attrib int 
---@return float 
function XDlcCSharpFuncs:GetNpcAttribRate(npcId, attrib)
end

---@desc 获取Npc阵营（返回值参考ENpcCamp
---@param npcId int 
---@return int 
function XDlcCSharpFuncs:GetNpcCamp(npcId)
end

---@desc 比较两个Npc的阵营是否相同
---@param npcA int 
---@param npcB int 
---@return bool 
function XDlcCSharpFuncs:CompareNpcCamp(npcA, npcB)
end

---@desc 返回值参考枚举ENpcKind
---@param npc int 
---@return int 
function XDlcCSharpFuncs:GetNpcKind(npc)
end

---@desc 获取关卡内所有Npc组成的列表
---@return LuaTable 
function XDlcCSharpFuncs:GetNpcList()
end

---@desc 获取玩家Npc对象列表
---@return LuaTable 
function XDlcCSharpFuncs:GetPlayerNpcList()
end

---@desc 是否为玩家NPC
---@param npcId int 
---@return bool 
function XDlcCSharpFuncs:IsPlayerNpc(npcId)
end

---@desc NPC是否死亡
---@param uuid int 
---@return bool 
function XDlcCSharpFuncs:IsNpcDead(uuid)
end

---@desc 判断Actor是否还存在
---@param uuid int 
---@return bool 
function XDlcCSharpFuncs:CheckActorExist(uuid)
end

---@desc 复活Npc
---@param launcherId int 
---@param targetId int 
---@return void 
function XDlcCSharpFuncs:RebornNpc(launcherId, targetId)
end

---@desc 执行Magic
---@param launcherId int 
---@param targetId int 
---@param magicId int 
---@param level int 
---@param contextId int 
---@param count int 
---@return void 
function XDlcCSharpFuncs:ApplyMagic(launcherId, targetId, magicId, level, contextId, count)
end

---@desc 检查Npc是否有指定buff
---@param npcId int 
---@param kind int 
---@return bool 
function XDlcCSharpFuncs:CheckBuffByKind(npcId, kind)
end

---@desc 重置Npc到安全点（系统自动计算的安全点
---@param npcId int 
---@return void 
function XDlcCSharpFuncs:ResetNpcToSafePoint(npcId)
end

---@desc 重置Npc到已记录的检查点（自动选择检查点配置点位之一
---@param npcId int 
---@return void 
function XDlcCSharpFuncs:ResetNpcToCheckPoint(npcId)
end

---@desc 重置Npc到指定检查点（自动选择检查点配置点位之一
---@param npcId int 
---@param checkPointPlaceId int 
---@return void 
function XDlcCSharpFuncs:ResetNpcToSpecificCheckPoint(npcId, checkPointPlaceId)
end

---@desc 设置Npc的检查点（本质是设置重生坐标
---@param npcId int 
---@param checkPointPlaceId int 
---@return void 
function XDlcCSharpFuncs:SetNpcCheckPoint(npcId, checkPointPlaceId)
end

---@desc 获取Npc记录的检查点
---@param npcId int 
---@param x out float 
---@param y out float 
---@param z out float 
---@return void 
function XDlcCSharpFuncs:GetNpcLastCheckPoint(npcId, x, y, z)
end

---@desc 设置Npc被救状态
---@param launcherId int 
---@param targetId int 
---@param state bool 为true代表开始被救，false代表结束被救
---@return void 
function XDlcCSharpFuncs:SetNpcRescuedState(launcherId, targetId, state)
end

---@desc 添加技能球
---@param npcId int 目标NPC的UUID
---@param key int 三色球的ID
---@param count int 要添加的数量
---@return void 
function XDlcCSharpFuncs:AddSkillBall(npcId, key, count)
end

---@desc 清除所有技能球
---@param npcId int 目标Npc的UUID
---@return int 清除的球数量
function XDlcCSharpFuncs:ClearAllSkillBalls(npcId)
end

---@desc 获取所有球的类型列表
---@param npcId int 目标Npc的UUID
---@return LuaTable int数组Table，包含了每个球的类型
function XDlcCSharpFuncs:GetBallKindsList(npcId)
end

---@desc 获取Npc技能球数量
---@param npcId int 
---@param countBackend bool 是否将后台球也计算在内
---@return int 
function XDlcCSharpFuncs:GetSkillBallCount(npcId, countBackend)
end

---@desc 设置NPC任务提示图标显隐
---@param placeId int Npc对象的placeId
---@param questId int 任务ID（用于设置对应任务类型的图标样式）
---@param active bool true显示，false隐藏
---@return void 
function XDlcCSharpFuncs:SetNpcQuestTipIconActive(placeId, questId, active)
end

---@desc 设置Npc作为交互发起者进行交互时是否转身面向交互目标
---@param uuid int Npc对象的UUID
---@param enable bool 是否允许
---@return void 
function XDlcCSharpFuncs:SetNpcInteractTurnEnable(uuid, enable)
end

---@desc 设置Npc重力
---@param uuid int Npc对象的UUID
---@param jumpGravity float 跳跃重力
---@param freeFallGravity float 自由落体重力
---@return void 
function XDlcCSharpFuncs:SetNpcGravity(uuid, jumpGravity, freeFallGravity)
end

---@desc 移动Npc（暂定）
---@param uuid int Npc对象的UUID
---@param vector Vector3 移动向量
---@return bool 是否未受阻挡地移动（true表示没有受到阻挡）
function XDlcCSharpFuncs:MoveNpc(uuid, vector)
end

---@desc 转向Npc
---@param npcUUID1 int 要转向的Npc对象的UUID
---@param npcUUID2 int 要朝向的Npc对象的UUID
---@return void 
function XDlcCSharpFuncs:TurnNpc(npcUUID1, npcUUID2)
end

---@desc 检查目标Actor是否应该响应玩家的交互
---@param uuid int 目标Actor的UUID
---@return bool 返回的值实际上是在关卡编辑器中为NPC/SceneObject配置的同名字段值，若为false则代表该Actor只响应库洛洛这类“助理NPC”的交互
function XDlcCSharpFuncs:ShouldActorReactToPlayerInteract(uuid)
end

---@desc 获取目标Actor的交互发起者点位 （每个可以交互的Actor，如果要响应库洛洛这种“助理NPC”的交互，则需要配置相应的坐标点位供他们使用）
---@param targetUUID int 目标Actor的UUID
---@return Vector3 
function XDlcCSharpFuncs:GetActorInteractionLauncherSpot(targetUUID)
end

---@desc 使NPC向指定目标发起交互
---@param launcherUUID int 交互发起者UUID
---@param targetUUID int 目标ActorUUID
---@param optionId int 交互选项ID
---@return bool 
function XDlcCSharpFuncs:NpcStartInteractWith(launcherUUID, targetUUID, optionId)
end

---@desc 设置Actor的交互响应回调 （可交互Actor一般有默认的交互响应逻辑，当你不希望它们执行时，使用此函数进行“重写”以替换响应逻辑）
---@param uuid int 目标actor的UUID
---@param callback Action<int, int, int> ：回调函数，其参数为：（launcherUUID）交互发起者UUID，（optionId）交互选项ID，（phase）交互阶段。
---@return bool 
function XDlcCSharpFuncs:SetActorInteractionReactCallback(uuid, callback)
end

---@desc 设置Npc忽略其他Npc的所有碰撞
---@desc 已包含同步和断线重连逻辑
---@param uuid int 设置的目标NpcUUID
---@param ignore bool true忽略，false取消忽略
---@return void 
function XDlcCSharpFuncs:SetNpcIgnoreOtherNpcAllCollisions(uuid, ignore)
end

---@desc 检查Npc完整状态
---@desc 子状态填写-1 或 者当前主状态没有子状态时 子状态参数无效
---@desc 子状态ID请查阅“g工具表“的”NPC状态类型”子表
---@param uuid int 
---@param mainState int 主状态 0待机 1移动 2跳跃 3技能 4受击 5濒死 6出生 7死亡 8被抓  9瘫痪 10乘骑
---@param subState int 子状态
---@return bool Npc状态和参数一致则返回true
function XDlcCSharpFuncs:CheckNpcFullActionState(uuid, mainState, subState)
end

---@desc 判断Npc的受击状态
---@param uuid int Npc对象的UUID
---@param state int 受击状态枚举，详见EHitType
---@return bool 
function XDlcCSharpFuncs:CheckNpcBeHitState(uuid, state)
end

---@desc 判断Npc是否处于后台
---@param uuid int 
---@return bool 
function XDlcCSharpFuncs:IsNpcBackState(uuid)
end

---@desc 切换玩家Npc
---@param uuid int 当前玩家NpcUuid
---@param operationKey int 切换的按键，参考 ENpcOperationKey.SwitchNpc1 
---@return void 
function XDlcCSharpFuncs:SwitchPlayerNpc(uuid, operationKey)
end

---@desc 本地控制角色跳跃
---@desc TODO 目前仅用于本地控制角色使用, 待优化
---@param uuid int Npc对象的UUID
---@param isMoving bool 是否为跑跳
---@return void 
function XDlcCSharpFuncs:Jump(uuid, isMoving)
end

---@desc 判断Npc的跳跃状态
---@param uuid int Npc对象的UUID
---@param state int 跳跃状态枚举，详见ENpcJumpState
---@return bool 
function XDlcCSharpFuncs:CheckNpcJumpState(uuid, state)
end

---@desc 请找程序 ，没注释
---@param uuid int 
---@param speed float 
---@return void 
function XDlcCSharpFuncs:SetNpcJumpLookAtSpeed(uuid, speed)
end

---@desc 用于传送后设置Npc为在地面(防止空中状态动量残留)
---@param uuid int 
---@return void 
function XDlcCSharpFuncs:TeleportResetNpcOnGround(uuid)
end

---@desc 设置Npc动画控制器层
---@param uuid int npc对象的UUID
---@param layerIndex int 动画层级
---@return void 
function XDlcCSharpFuncs:SetNpcAnimationLayer(uuid, layerIndex)
end

---@desc 设置Npc是否可交互
---@param uuid int Npc对象的UUID
---@param enable bool 是否可交互
---@return void 
function XDlcCSharpFuncs:SetNpcInteractComponentEnable(uuid, enable)
end

---@desc 设置Npc FightTarget
---@param uuid int 要锁定npc的npc对象Uuid
---@param targetUuid int 被锁定的npc对象UUid
---@return void 
function XDlcCSharpFuncs:SetFightTarget(uuid, targetUuid)
end

---@desc 获取Npc的 FightTarget的 uuid
---@param uuid int Npc对象的UUID
---@return int FightTarget的UUID
function XDlcCSharpFuncs:GetFightTargetId(uuid)
end

---@desc 检查Npc是否存在FightTarget
---@param uuid int Npc对象的UUID
---@return bool 存在返回true
function XDlcCSharpFuncs:CheckFightTarget(uuid)
end

---@desc 移出Npc的FightTarget
---@param uuid int Npc对象的UUID
---@return void 
function XDlcCSharpFuncs:RemoveFightTarget(uuid)
end

---@desc 获取相对于Npc的偏移坐标位置
---@param uuid int Npc对象的UUID
---@param position Vector3 计算方向的位置坐标
---@param euler Vector3 偏移的角度
---@param distance float 偏移的长度
---@return Vector3 最终偏移的世界坐标
function XDlcCSharpFuncs:GetNpcOffsetPosition(uuid, position, euler, distance)
end

---@desc 获取Npc朝向目标位置世界坐标系的旋转
---@param uuid int Npc对象的UUID
---@param position Vector3 计算方向的位置坐标
---@param eulerOffset Vector3 偏移的角度
---@param isOnlyY bool 是否只是Y轴旋转
---@return Vector3 世界坐标下旋转的欧拉角
function XDlcCSharpFuncs:GetNpcOffsetRotation(uuid, position, eulerOffset, isOnlyY)
end

---@desc 获取相对于Npc的偏移向量（忽略npc自身旋转）
---@param uuid int Npc对象的UUID
---@param position Vector3 偏移的位置坐标
---@param euler Vector3 偏移的角度
---@param distance float 偏移的长度
---@return Vector3 最终偏移向量
function XDlcCSharpFuncs:GetNpcOffset(uuid, position, euler, distance)
end

---@desc 获取相对于Npc朝向的偏移坐标
---@param uuid int Npc对象的UUID
---@param euler Vector3 偏移的角度
---@param distance float 偏移的长度
---@return Vector3 最终偏移的世界坐标
function XDlcCSharpFuncs:GetNpcOffsetPositionByFacing(uuid, euler, distance)
end

---@desc 移动Npc到指定位置
---@param uuid int Npc对象的UUID
---@param position Vector3 移动到的位置
---@return void 
function XDlcCSharpFuncs:MoveToPosition(uuid, position)
end

---@desc Npc朝向指定位置
---@param uuid int Npc对象的UUID
---@param position Vector3 朝向的位置
---@return void 
function XDlcCSharpFuncs:LookAtPositionImmediately(uuid, position)
end

---@desc 获取与目标的距离
---@param uuid int Npc对象的UUID
---@param targetUuid int 目标对象的UUID
---@param ignoreY bool 是否忽略Y轴
---@return float 距离
function XDlcCSharpFuncs:GetNpcDistance(uuid, targetUuid, ignoreY)
end

---@desc 获取Npc的时间
---@param uuid int Npc对象的UUID
---@return float 
function XDlcCSharpFuncs:GetNpcTime(uuid)
end

---@desc 检查Npc的时间是否大于指定时间加上额外时间的总和
---@param uuid int Npc对象的UUID
---@param time float 时间
---@param extraTime float 额外时间
---@return bool 
function XDlcCSharpFuncs:CheckNpcTime(uuid, time, extraTime)
end

---@desc 设置Npc输入行为组
---@param uuid int Npc对象的UUID
---@param id int 输入行为组Id
---@return bool 是否设置成功
function XDlcCSharpFuncs:SetNpcInputActionGroup(uuid, id)
end

---@desc 添加连线特效
---@param launcherNpcUUID int 释放者UUID
---@param uuidA int 被连接的ActorA的UUID
---@param uuidB int 被连接的ActorB的UUID
---@param jointA string ActorA被连接的部位
---@param jointB string ActorB被连接的部位
---@param effectName string 特效名
---@param updateAlways bool 是否一直更新(否则隐藏不更新)
---@return int 返回链接的Id
function XDlcCSharpFuncs:AddLink(launcherNpcUUID, uuidA, uuidB, jointA, jointB, effectName, updateAlways)
end

---@desc 检查连线特效是否存在
---@param linkId int 连接的Id
---@return bool 是否存在该链接
function XDlcCSharpFuncs:CheckLink(linkId)
end

---@desc 查询连线特效的ActorA和B的UUID
---@param linkId int 连接的Id
---@param actorBUUID out int ActorB的Id
---@return int ActorA的Id
function XDlcCSharpFuncs:QueryLinkActor(linkId, actorBUUID)
end

---@desc 移除指定的连线特效
---@param launcherNpcUUID int 施放者的UUID
---@param linkId int 链接的Id
---@return void 
function XDlcCSharpFuncs:RemoveLink(launcherNpcUUID, linkId)
end

---@desc 移除指定Actor的所有连线特效
---@param launcherNpcUUID int 施放者的UUID
---@param actorUUID int Actor的UUID
---@return void 
function XDlcCSharpFuncs:RemoveAllActorLink(launcherNpcUUID, actorUUID)
end

---@desc 获取Npc的属性值
---@param uuid int Npc的UUID
---@param attribType ENpcAttrib Npc属性类型枚举
---@return int 
function XDlcCSharpFuncs:GetNpcAttribValue(uuid, attribType)
end

---@desc 获取Npc的属性最大值
---@param uuid int Npc的UUID
---@param attribType ENpcAttrib Npc属性类型枚举
---@return int 
function XDlcCSharpFuncs:GetNpcAttribMaxValue(uuid, attribType)
end

---@desc 增加Npc属性的加成值
---@param uuid int npcid
---@param attribType ENpcAttrib 属性类型
---@param value int 基础值
---@param percent int 万分比加成
---@return void 
function XDlcCSharpFuncs:AddNpcAttribAdditive(uuid, attribType, value, percent)
end

---@desc 检查Npc与位置的距离是否小于指定距离
---@param uuid int Npc的UUID
---@param position Vector3 指定位置
---@param distance float 指定距离
---@param ignoreY bool 是否忽略Y轴
---@return bool 
function XDlcCSharpFuncs:CheckNpcPositionDistance(uuid, position, distance, ignoreY)
end

---@desc 获取Npc与位置的距离
---@param uuid int Npc的UUID
---@param position Vector3 指定位置
---@param ignoreY bool 是否忽略Y轴
---@return float 
function XDlcCSharpFuncs:GetNpcToPositionDistance(uuid, position, ignoreY)
end

---@desc 3.6自走棋造成伤害（仅单机使用）
---@param launcherUUID int 施放者NpcUUID
---@param targetUUID int 目标NpcUUID
---@param partId int 受击部位Id
---@param magicId int MagicId
---@param kind int 伤害类型(由策划配表定义）
---@param permyriad int 伤害万分比
---@param elementType int 元素类型
---@param hackValue int 骇破伤害
---@param hackPermyriad int 骇破伤害万分比
---@param skillCap int 技能伤害上限
---@return void 
function XDlcCSharpFuncs:DamageRelinkStandalone(launcherUUID, targetUUID, partId, magicId, kind, permyriad, elementType, hackValue, hackPermyriad, skillCap)
end

---@desc 3.6自走棋造成治疗（仅单机使用）
---@param launcherUUID int 施放者NpcUUID
---@param targetUUID int 目标NpcUUID
---@param magicId int MagicId
---@param attribType int 属性类型
---@param type int 治疗类型
---@param value int 治疗量
---@param permyriad int 技能恢复倍率万分比
---@param useTargetAttrib bool 是否使用目标属性
---@param useHealAmpP bool 使用恢复强度
---@return void 
function XDlcCSharpFuncs:CureRelinkStandalone(launcherUUID, targetUUID, magicId, attribType, type, value, permyriad, useTargetAttrib, useHealAmpP)
end

---@desc 获取Npc护盾总值
---@param uuid int 
---@return int 
function XDlcCSharpFuncs:GetNpcProtector(uuid)
end

---@desc 根据类型获取Npc护盾值
---@param uuid int 
---@param type int 护盾类型
---@return int 
function XDlcCSharpFuncs:GetNpcProtectorByType(uuid, type)
end

---@desc 检测基于Npc计算出的射线是否命中关卡障碍
---@param npcUUID int NPC的UUID
---@param posOffset Vector3 射线原点基于NPC位置的偏移
---@param rotOffset Vector3 射线方向基于NPC朝向的旋转偏移
---@param distance float 射线长度
---@param hitPos out Vector3 (第二个返回值)命中的障碍位置
---@return bool 是否命中障碍
function XDlcCSharpFuncs:CheckNpcRayCastObstacle(npcUUID, posOffset, rotOffset, distance, hitPos)
end

---@desc 检测基于Npc计算出的球体是否碰撞到关卡障碍
---@param npcUUID int NPC的UUID
---@param posOffset Vector3 计算球体最终位置的射线原点基于NPC位置的偏移
---@param rotOffset Vector3 计算球体最终位置的射线方向基于NPC朝向的旋转偏移
---@param distance float 计算球体最终位置的射线长度
---@param radius float 球体半径
---@return bool 是否碰撞到关卡障碍
function XDlcCSharpFuncs:CheckNpcSphereObstacle(npcUUID, posOffset, rotOffset, distance, radius)
end

---@desc 检测世界坐标系下的射线是否命中关卡障碍
---@param npcUUID int NPC的UUID
---@param pos Vector3 射线原点世界坐标系位置
---@param rot Vector3 射线世界坐标系旋转
---@param distance float 射线距离
---@param hitPos out Vector3 (第二个返回值)命中的障碍位置
---@return bool 是否命中障碍
function XDlcCSharpFuncs:CheckRayCastObstacle(npcUUID, pos, rot, distance, hitPos)
end

---@desc 检测世界坐标系下的球体是否碰撞到关卡障碍
---@param npcUUID int NPC的UUID
---@param pos Vector3 球体世界坐标系位置
---@param radius float 球体半径
---@return bool 球体是否碰到障碍
function XDlcCSharpFuncs:CheckSphereObstacle(npcUUID, pos, radius)
end

---@desc 获取Npc最大仇恨的目标NPC的UUID
---@param uuid int 当前Npc的UUID
---@return int 最大仇恨的NpcUUID（返回0没有）
function XDlcCSharpFuncs:GetMaxThreatNpc(uuid)
end

---@desc 获取Npc最小仇恨的目标NPC的UUID
---@param uuid int 当前Npc的UUID
---@return int 最小仇恨的NpcUUID（返回0没有）
function XDlcCSharpFuncs:GetMinThreatNpc(uuid)
end

---@desc 检查Npc仇恨列表是否为空（不为空返回true）
---@param uuid int 当前Npc的UUID
---@return bool 
function XDlcCSharpFuncs:CheckThreatList(uuid)
end

---@desc 检查目标Npc是否在当前Npc的仇恨列表中
---@param uuid int 当前Npc的UUID
---@param targetUUID int 目标Npc的UUID
---@return bool 
function XDlcCSharpFuncs:CheckNpcInThreatList(uuid, targetUUID)
end

---@desc 获取当前Npc对目标NPC的仇恨值
---@desc 如果目标不在仇恨列表返回 0
---@param uuid int 当前Npc的UUID
---@param targetUUID int 目标Npc的UUID
---@return int 
function XDlcCSharpFuncs:GetThreatValue(uuid, targetUUID)
end

---@desc 设置计算伤害前上下文
---@param contextId int 上下文Id
---@param physicalPermyraid int 物理倍率
---@param elementPermyraid int 元素倍率
---@param hackDamage int hack伤害
---@param hackPermyraid int hack倍率
---@param isCrit bool 是否暴击
---@return void 
function XDlcCSharpFuncs:SetBeforeDamageMagicContext(contextId, physicalPermyraid, elementPermyraid, hackDamage, hackPermyraid, isCrit)
end

---@desc 设置计算伤害后上下文
---@param contextId int 上下文Id
---@param physicalDamage int 最终物理伤害
---@param elementDamage int 最终元素伤害
---@param finalHackDamage int 最终Hack伤害
---@return void 
function XDlcCSharpFuncs:SetAfterDamageMagicContext(contextId, physicalDamage, elementDamage, finalHackDamage)
end

---@desc 设置计算治疗前上下文
---@param contextId int 上下文Id
---@param value int 基础值
---@param permyraid int 万分比
---@return void 
function XDlcCSharpFuncs:SetBeforeCureMagicContext(contextId, value, permyraid)
end

---@desc 设置计算治疗后上下文
---@param contextId int 上下文Id
---@param finalValue int 最终值
---@return void 
function XDlcCSharpFuncs:SetAfterCureMagicContext(contextId, finalValue)
end

---@desc 添加伤害上下文附加值
---@param contextId int contextId
---@param attrType int 属性枚举
---@param v int 固定值
---@param p int 万分比
---@return void 
function XDlcCSharpFuncs:AddDamageMagicContextValue(contextId, attrType, v, p)
end

---@desc 设置伤害上下文附加值
---@param contextId int contextId
---@param attrType int 属性枚举
---@param v int 固定值
---@param p int 万分比
---@return void 
function XDlcCSharpFuncs:SetDamageMagicContextValue(contextId, attrType, v, p)
end

---@desc 添加治疗上下文附加值
---@param contextId int contextId
---@param attrType int 属性枚举
---@param v int 固定值
---@param p int 万分比
---@return void 
function XDlcCSharpFuncs:AddCureMagicContextValue(contextId, attrType, v, p)
end

---@desc 设置治疗上下文附加值
---@param contextId int contextId
---@param attrType int 属性枚举
---@param v int 固定值
---@param p int 万分比
---@return void 
function XDlcCSharpFuncs:SetCureMagicContextValue(contextId, attrType, v, p)
end

---@desc 修改技能预输入上下文
---@param contextId int 上下文Id
---@param targetType int 目标类型
---@param targetUUID int 目标UUID
---@param targetPos Vector3 目标位置
---@return void 
function XDlcCSharpFuncs:SetCastSkillByInputActionBeforeValue(contextId, targetType, targetUUID, targetPos)
end

---@desc 以Npc为半径搜索符合条件的Npc
---@param centerNpcUuid int Npc对象的UUID
---@param campValue int 阵营，详细见枚举ENpcCampType
---@param typeValue int npc类型，详细见枚举ENpcTargetType
---@param range float 半径范围
---@param rangeCoe int 范围系数
---@return int Npc对象的UUID
function XDlcCSharpFuncs:SearchNpc(centerNpcUuid, campValue, typeValue, range, rangeCoe)
end

---@desc 【使用了相机方向，仅限玩家npc调用】搜索npc
---@param selfNpcUuid int 玩家操控的Npc对象UUID
---@param campValue int 阵营，详细见枚举ENpcCampType
---@param typeValue int npc类型，详细见枚举ENpcTargetType
---@param range float 半径范围
---@param rangeCoe int 范围系数
---@param angleCoe int 范围系数
---@return int Npc对象的UUID
function XDlcCSharpFuncs:SearchNpcForRole(selfNpcUuid, campValue, typeValue, range, rangeCoe, angleCoe)
end

---@desc 【使用了相机方向，仅限玩家npc调用】搜索npc部位
---@param selfNpcUuid int 玩家操控的Npc对象UUID
---@param campValue int 阵营，详细见枚举ENpcCampType
---@param typeValue int npc类型，详细见枚举ENpcTargetType
---@param range float 半径范围
---@param rangeCoe int 范围系数
---@param angleCoe int 范围系数
---@return LuaTable { NpcUUID:目标NpcId PartId:部位Id PartBoneUID:部位骨骼id}
function XDlcCSharpFuncs:SearchNpcPartForRole(selfNpcUuid, campValue, typeValue, range, rangeCoe, angleCoe)
end

---@desc 获取首个搜索目标的UID，若无则返回0。
---@param uuid int 当前Npc的uuid
---@param npcTargetType int Npc目标类型(ENpcTargetType)
---@return int 
function XDlcCSharpFuncs:GetFirstSearchTarget(uuid, npcTargetType)
end

---@desc 获取搜索目标列表，若无则返回null。
---@param uuid int 当前Npc的uuid
---@param npcTargetType int Npc目标类型(ENpcTargetType)
---@return LuaTable 
function XDlcCSharpFuncs:GetSearchTargetList(uuid, npcTargetType)
end

---@desc 检查Npc对应key的Int类型字典值是否存在
---@param npcId int 
---@param key int 
---@return bool 
function XDlcCSharpFuncs:CheckNpcNoteInt(npcId, key)
end

---@desc 检查Npc对应key的float类型字典值是否存在
---@param npcId int 
---@param key int 
---@return bool 
function XDlcCSharpFuncs:CheckNpcNoteFloat(npcId, key)
end

---@desc 检查Npc对应key的bool类型字典值是否存在
---@param npcId int 
---@param key int 
---@return bool 
function XDlcCSharpFuncs:CheckNpcNoteBool(npcId, key)
end

---@desc 检查Npc对应key的float3类型字典值是否存在
---@param npcId int 
---@param key int 
---@return bool 
function XDlcCSharpFuncs:CheckNpcNoteFloat3(npcId, key)
end

---@desc 获取Npc对应key的Int类型字典值
---@param npcId int 
---@param key int 
---@return int 
function XDlcCSharpFuncs:GetNpcNoteInt(npcId, key)
end

---@desc 获取Npc对应key的float类型字典值
---@param npcId int 
---@param key int 
---@return float 
function XDlcCSharpFuncs:GetNpcNoteFloat(npcId, key)
end

---@desc 获取Npc对应key的float3类型字典值
---@param npcId int 
---@param key int 
---@return Vector3 
function XDlcCSharpFuncs:GetNpcNoteFloat3(npcId, key)
end

---@desc 修改Npc对应key的Int类型字典值
---@param npcId int 
---@param key int 
---@param value int 
---@return void 
function XDlcCSharpFuncs:SetNpcNoteInt(npcId, key, value)
end

---@desc 修改Npc对应key的float类型字典值
---@param npcId int 
---@param key int 
---@param value float 
---@return void 
function XDlcCSharpFuncs:SetNpcNoteFloat(npcId, key, value)
end

---@desc 修改Npc对应key的float2类型字典值
---@param npcId int 
---@param key int 
---@param v1 float 
---@param v2 float 
---@return void 
function XDlcCSharpFuncs:SetNpcNoteFloat2(npcId, key, v1, v2)
end

---@desc 修改Npc对应key的float3类型字典值
---@param npcId int 
---@param key int 
---@param v1 float 
---@param v2 float 
---@param v3 float 
---@return void 
function XDlcCSharpFuncs:SetNpcNoteFloat3(npcId, key, v1, v2, v3)
end

---@desc 使一Npc向另一Npc发射子弹
---@param launcherId int 发射Npc的uuid
---@param targetId int 目标Npc的uuid
---@param launchId int 子弹发射参数id，与子弹帧事件id相同
---@param level int 子弹等级，作为子弹击中目标时执行的magic的等级，一般默认为1
---@return bool 发射是否成功
function XDlcCSharpFuncs:LaunchMissile(launcherId, targetId, launchId, level)
end

---@desc 从指定坐标向另一指定坐标发射线性子弹
---@param launcherId int 发射Npc的uuid
---@param launchId int 子弹发射参数id，与子弹帧事件id相同
---@param launchPos Vector3 发射坐标
---@param targetPos Vector3 目标坐标
---@param level int 子弹等级，作为子弹击中目标时执行的magic的等级，一般默认为1
---@return bool 发射是否成功
function XDlcCSharpFuncs:LaunchMissileFromPosToPos(launcherId, launchId, launchPos, targetPos, level)
end

---@desc 移除所有指定发射者的子弹
---@param launcherId int 发射Npc的uuid
---@return bool 移除是否执行成功
function XDlcCSharpFuncs:DestroyAllMissileDependOnLauncher(launcherId)
end

---@desc 激活虚拟相机
---@desc （激活指定玩家npc对应端的虚拟相机
---@desc （priority为优先级，一般取100，上限9999
---@desc 激活一个固定的虚拟相机的方式，referenceId填0、followId填0、lookAtId填0
---@param playerNpcId int 
---@param vCam string 
---@param blendIn float 
---@param blendOut float 
---@param referenceId int 
---@param x float 
---@param y float 
---@param z float 
---@param eulerX float 
---@param eulerY float 
---@param eulerZ float 
---@param followId int 
---@param lookAtId int 
---@param priority int 
---@param allClients bool 
---@return void 
function XDlcCSharpFuncs:ActivateVCam(playerNpcId, vCam, blendIn, blendOut, referenceId, x, y, z, eulerX, eulerY, eulerZ, followId, lookAtId, priority, allClients)
end

---@desc 关闭虚拟相机 （关闭指定玩家npc对应端的虚拟相机
---@param playerNpcId int 
---@param vCam string 
---@param allClients bool 
---@return void 
function XDlcCSharpFuncs:DeactivateVCam(playerNpcId, vCam, allClients)
end

---@desc 获取目标点和相机坐标连线到相机朝向的夹角
---@param position Vector3 
---@param ignoreY bool 
---@return float 
function XDlcCSharpFuncs:GetCameraAngleFromPos(position, ignoreY)
end

---@desc 添加自定义相机旋转
---@param id int 
---@param x float 
---@param y float 
---@param z float 
---@param blendIn float 
---@param blendOut float 
---@param relative bool 
---@param bind bool 
---@return void 
function XDlcCSharpFuncs:AddCustomCameraRotation(id, x, y, z, blendIn, blendOut, relative, bind)
end

---@desc 移除自定义相机旋转
---@param id int 
---@return void 
function XDlcCSharpFuncs:RemoveCustomCameraRotation(id)
end

---@desc 开关低饱和度屏幕效果（黑白滤镜
---@param target XNpc 
---@param enabled bool 
---@param allClients bool 
---@return void 
function XDlcCSharpFuncs:SetLowSaturation(target, enabled, allClients)
end

---@desc 让程序补注释！
---@param ignoreHeightLerpOnAir bool 
---@return void 
function XDlcCSharpFuncs:SetCameraIgnoreHeightLerpOnAir(ignoreHeightLerpOnAir)
end

---@desc 重置相机位置
---@param resetAngleX bool 是否重置相机X轴
---@param rotYEulerOffset float 重置Y轴后的偏移
---@param isEndRotationOverride bool 是否强制重置（忽略玩家正在操作相机）
---@return void 
function XDlcCSharpFuncs:ResetCamera(resetAngleX, rotYEulerOffset, isEndRotationOverride)
end

---@desc 获取当前世界ID
---@return int 
function XDlcCSharpFuncs:GetWorldId()
end

---@desc 获取当前关卡ID
---@return int 
function XDlcCSharpFuncs:GetCurrentLevelId()
end

---@desc 切换Level
---@param nextLevelId int  下一个进入的LevelId
---@param position Vector3  目标坐标
---@return void 
function XDlcCSharpFuncs:SwitchLevel(nextLevelId, position)
end

---@desc 进入副本Level，要和RequestLeaveInstanceLevel()成对使用
---@param nextLevelId int 要进入的副本LevelId
---@param position Vector3 目标坐标
---@return void 
function XDlcCSharpFuncs:RequestEnterInstLevel(nextLevelId, position)
end

---@desc 退出副本Level，要和RequestEnterInstLevel()成对使用
---@param resetSaveDataExit bool 是否保存数据退出
---@return void 
function XDlcCSharpFuncs:RequestLeaveInstanceLevel(resetSaveDataExit)
end

---@desc 设置关卡存储值Int
---@param key int 
---@param value int 
---@return void 
function XDlcCSharpFuncs:SetLevelMemoryInt(key, value)
end

---@desc 设置关卡存储值Float
---@param key int 
---@param value float 
---@return void 
function XDlcCSharpFuncs:SetLevelMemoryFloat(key, value)
end

---@desc 移除关卡存储值Int
---@param key int 
---@return void 
function XDlcCSharpFuncs:RemoveLevelMemoryInt(key)
end

---@desc 移除关卡存储值Float
---@param key int 
---@return void 
function XDlcCSharpFuncs:RemoveLevelMemoryFloat(key)
end

---@desc 获取关卡存储值Int
---@param key int 
---@return int 
function XDlcCSharpFuncs:GetLevelMemoryInt(key)
end

---@desc 获取关卡存储值Float
---@param key int 
---@return float 
function XDlcCSharpFuncs:GetLevelMemoryFloat(key)
end

---@desc 检查关卡Int存储值是否存在
---@param key int 
---@return bool 
function XDlcCSharpFuncs:CheckLevelMemoryInt(key)
end

---@desc 检查关卡Float存储值是否存在
---@param key int 
---@return bool 
function XDlcCSharpFuncs:CheckLevelMemoryFloat(key)
end

---@desc 获取关卡点位
---@param id int 
---@return Vector3 
function XDlcCSharpFuncs:GetSpot(id)
end

---@desc 创建一个挂载到指定Actor的触发器（Npc或SceneObject）
---@param uuid int 
---@param touchType int 触发器接触类型，参考ESceneObjectTouchType
---@param shapeType int 触发器的形状，参考EShapeType
---@param triggerName string 触发器的内部名称
---@param localPosition Vector3 trigger在Actor局部坐标系下的坐标 
---@param eulerAngles Vector3 trigger的朝向（欧拉角，单位：度）
---@param size Vector3 尺寸/大小，仅当类型为Box时有效
---@param radius float 半径，仅当类型为Sphere或Capsule时有效
---@param height float 高度，仅当类型为Capsule时有效
---@param direction int 胶囊体延展轴向，仅当类型为Capsule时有效
---@return int 返回TriggerId（成功时大于0，失败为0）
function XDlcCSharpFuncs:CreateActorTrigger(uuid, touchType, shapeType, triggerName, localPosition, eulerAngles, size, radius, height, direction)
end

---@desc 获取配置的救援时间
---@return float 
function XDlcCSharpFuncs:GetRescueTime()
end

---@desc 启动关卡玩法计时器
---@param time float 需计时间（单位：秒）
---@param isCountDown bool 默认值:false 是否为倒计时
---@return bool 
function XDlcCSharpFuncs:StartLevelPlayTimer(time, isCountDown)
end

---@desc 获取关卡玩法计时器当前时间（单位：秒）
---@return float 
function XDlcCSharpFuncs:GetLevelPlayTimerCurTime()
end

---@desc 暂停关卡玩法计时器
---@return bool 
function XDlcCSharpFuncs:PauseLevelPlayTimer()
end

---@desc 恢复关卡玩法计时器
---@return bool 
function XDlcCSharpFuncs:ResumeLevelPlayTimer()
end

---@desc 终止关卡玩法计时器
---@return bool 
function XDlcCSharpFuncs:StopLevelPlayTimer()
end

---@desc 设置BGM的AISAC控制参数
---@param controlName string 
---@param value float 
---@return void 
function XDlcCSharpFuncs:SetBgmAisacControl(controlName, value)
end

---@desc 创建关卡特效
---@param effectRefId int 
---@param effectName string 
---@param posX float 
---@param posY float 
---@param posZ float 
---@param rotX float 
---@param rotY float 
---@param rotZ float 
---@param offsetX float 
---@param offsetY float 
---@param offsetZ float 
---@return void 
function XDlcCSharpFuncs:CreateLevelEffect(effectRefId, effectName, posX, posY, posZ, rotX, rotY, rotZ, offsetX, offsetY, offsetZ)
end

---@desc 移除关卡特效
---@param effectRefId int 
---@return void 
function XDlcCSharpFuncs:RemoveLevelEffect(effectRefId)
end

---@desc 检查关卡特效是否存在
---@param effectRefId int 
---@return bool 
function XDlcCSharpFuncs:CheckLevelEffectExist(effectRefId)
end

---@desc 播放相机Timeline
---@param name string 
---@param targetId int 
---@param blendIn float 
---@param blendOut float 
---@param locationType int 0-世界坐标系起始为目标坐标，1-目标局部坐标系
---@return void 
function XDlcCSharpFuncs:PlayCameraTimeline(name, targetId, blendIn, blendOut, locationType)
end

---@desc 停止相机Timeline
---@param name string 
---@param targetId int 
---@return void 
function XDlcCSharpFuncs:StopCameraTimeline(name, targetId)
end

---@desc 播放场景动画（场景美术事先在场景里编辑好的动画
---@param id int 
---@return void 
function XDlcCSharpFuncs:PlaySceneAnimation(id)
end

---@desc 开关场景Timeline
---@param id int timeline序号，从1开始
---@param state bool true播放，false停止
---@return void 
function XDlcCSharpFuncs:SwitchSceneTimeline(id, state)
end

---@desc 禁止反复开关（会发送同步消息
---@desc 开关动态障碍
---@param obstacleId int 障碍ID（必须是动态障碍的ID）
---@param active bool true开，false关
---@return void 
function XDlcCSharpFuncs:SetObstacleActive(obstacleId, active)
end

---@desc 禁止频繁调用（会发送同步消息
---@desc 设置Npc忽略障碍
---@param npcId int Npc对象的UUID
---@param obstacleId int 障碍ID（静态/动态障碍都可以）
---@param ignore bool true忽略，false取消忽略
---@return void 
function XDlcCSharpFuncs:SetNpcIgnoreObstacle(npcId, obstacleId, ignore)
end

---@desc 联系程序补充注释
---@param npcId int 
---@param groupName string 
---@param colliderIndex int 
---@param ignore bool 
---@return void 
function XDlcCSharpFuncs:SetSceneColliderIgnoreCollision(npcId, groupName, colliderIndex, ignore)
end

---@desc 设置两个Actor间互相忽略碰撞
---@param actorUUIDA int 对象A的UUID
---@param actorUUIDB int 对象B的UUID
---@param ignore bool true忽略，false取消忽略
---@return void 
function XDlcCSharpFuncs:SetActorIgnoreCollision(actorUUIDA, actorUUIDB, ignore)
end

---@desc 获取当前技能的运行时间
---@param npcId int 
---@param elapsedTime out float 
---@return bool 
function XDlcCSharpFuncs:TryGetNpcCurrentSkillElapsedTime(npcId, elapsedTime)
end

---@desc 获取技能类型
---@param skillId int 
---@return int 
function XDlcCSharpFuncs:GetSkillType(skillId)
end

---@desc 获取Npc技能的技能类型(技能Id传0时，使用上一个技能Id作为技能Id)
---@param uuid int Npc的UUID
---@param skillId int 技能Id
---@return int 
function XDlcCSharpFuncs:GetNpcSkillType(uuid, skillId)
end

---@desc 设置技能优先级(技能Id传0时，使用上一个技能Id作为技能Id)
---@param npcUUID int Npc的UUID
---@param skillId int 技能Id
---@param priority int 优先级
---@return void 
function XDlcCSharpFuncs:SetSkillPriority(npcUUID, skillId, priority)
end

---@desc 获取技能优先级(技能Id传0时，使用上一个技能Id作为技能Id)
---@param npcUUID int Npc的UUID
---@param skillId int 技能Id
---@param priority out int 优先级(第二个返回值)
---@return bool 
function XDlcCSharpFuncs:TryGetSkillPriority(npcUUID, skillId, priority)
end

---@desc 获取技能特征标签(技能Id传0时，使用上一个技能Id作为技能Id)
---@param npcUUID int Npc的UUID
---@param skillId int 技能Id
---@return LuaTable 
function XDlcCSharpFuncs:GetSkillFeatureTag(npcUUID, skillId)
end

---@desc 检查技能特征标签(技能Id传0时，使用上一个技能Id作为技能Id)
---@param npcUUID int Npc的UUID
---@param skillId int 技能Id
---@param featureTag int 要检查的标签值
---@return bool 
function XDlcCSharpFuncs:CheckSkillFeatureTag(npcUUID, skillId, featureTag)
end

---@desc 获取Buff脚本的配置Id
---@return int 
function XDlcCSharpFuncs:GetSelfBuffId()
end

---@desc 获取Buff脚本所属的BUff的UUID
---@return int 
function XDlcCSharpFuncs:GetSelfBuffUUID()
end

---@desc 获取Buff脚本所属的BUff的CasterNpcUUID
---@return int 
function XDlcCSharpFuncs:GetSelfBuffCasterNpcUUID()
end

---@desc 获取Buff脚本所属的BUff的NpcUUID
---@return int 
function XDlcCSharpFuncs:GetSelfBuffNpcUUID()
end

---@desc 获取Buff层数
---@param npcUUID int 
---@param buffTempId int 
---@return int 
function XDlcCSharpFuncs:GetBuffStacks(npcUUID, buffTempId)
end

---@desc 根据Kind获取Buff数量
---@param npcUUID int 
---@param kind int 
---@return int 
function XDlcCSharpFuncs:GetBuffCountByKind(npcUUID, kind)
end

---@desc 检查Buff是否属于传入的类型
---@param buffTempId int Buff的配置Id
---@param kinds List<int> 要检查的类型列表
---@return bool 
function XDlcCSharpFuncs:CheckBuffKinds(buffTempId, kinds)
end

---@desc 检查Buff列表是否属于传入类型列表
---@param buffTempIds List<int> Buff的配置Id列表
---@param kinds List<int> 要检查的类型列表
---@return bool 
function XDlcCSharpFuncs:CheckBuffListKinds(buffTempIds, kinds)
end

---@desc 加载场景物件
---@param placeId int 场景物件的PlaceId
---@return bool true成功，false失败
function XDlcCSharpFuncs:LoadSceneObject(placeId)
end

---@desc 联系程序补充注释
---@param placeId int 
---@return void 
function XDlcCSharpFuncs:UnloadSceneObject(placeId)
end

---@desc 获取场景物件对象id
---@param placeId int 
---@return int 
function XDlcCSharpFuncs:GetSceneObjectUUID(placeId)
end

---@desc 获取场景物件坐标
---@param placeId int 
---@return Vector3 
function XDlcCSharpFuncs:GetSceneObjectPositionByPlaceId(placeId)
end

---@desc 获取场景物件朝向
---@param placeId int 
---@return Vector3 
function XDlcCSharpFuncs:GetSceneObjectRotationByPlaceId(placeId)
end

---@desc 获取场景物件坐标
---@param uuid int 
---@return Vector3 
function XDlcCSharpFuncs:GetSceneObjectPosition(uuid)
end

---@desc 获取场景物件朝向
---@param uuid int 
---@return Vector3 
function XDlcCSharpFuncs:GetSceneObjectRotation(uuid)
end

---@desc 开关场景物件
---@param sceneObjectPlaceId int 
---@param active bool 
---@return void 
function XDlcCSharpFuncs:SetSceneObjectActive(sceneObjectPlaceId, active)
end

---@desc 场景物件是否开启
---@param sceneObjectPlaceId int 
---@return bool 
function XDlcCSharpFuncs:IsSceneObjectActive(sceneObjectPlaceId)
end

---@desc 开关场景物件阴影（仅在客户端生效）
---@param sceneObjectPlaceId int 
---@param enable bool 
---@return void 
function XDlcCSharpFuncs:SetSceneObjectShadowEnable(sceneObjectPlaceId, enable)
end

---@desc 请联系程序补充注释
---@param sceneObjectPlaceId int 
---@param nodeId int 
---@return void 
function XDlcCSharpFuncs:MoveSceneObjectToNode(sceneObjectPlaceId, nodeId)
end

---@desc 请联系程序补充注释
---@param sceneObjectPlaceId int 
---@param isRotate bool 
---@return void 
function XDlcCSharpFuncs:SetSceneObjectAutoRotate(sceneObjectPlaceId, isRotate)
end

---@desc 请联系程序补充注释
---@param sceneObjectPlaceId int 
---@param isQueue bool 默认值:false 
---@return void 
function XDlcCSharpFuncs:TriggerSceneObjectRotate(sceneObjectPlaceId, isQueue)
end

---@desc 开关场景物件钩点组件
---@param soPlaceId int 
---@param enable bool 
---@return void 
function XDlcCSharpFuncs:SetHookableSceneObjectEnable(soPlaceId, enable)
end

---@desc 使场景物件执行指定动作
---@param soPlaceId int 
---@param actionId int 
---@return bool 
function XDlcCSharpFuncs:DoSceneObjectAction(soPlaceId, actionId)
end

---@desc 检查场景物件是否在执行指定动作
---@param soPlaceId int 
---@param actionId int 
---@return bool 
function XDlcCSharpFuncs:CheckSceneObjectAction(soPlaceId, actionId)
end

---@desc 请联系程序补充注释
---@param soPlaceId int 
---@param scriptId int 
---@return void 
function XDlcCSharpFuncs:AddSceneObjectScript(soPlaceId, scriptId)
end

---@desc 请联系程序补充注释
---@param soPlaceId int 
---@param scriptId int 
---@return void 
function XDlcCSharpFuncs:RemoveSceneObjectScript(soPlaceId, scriptId)
end

---@desc 生成SceneObject
---@param sceneObjId int 
---@param position Vector3 
---@param rotation Vector3 
---@return int 
function XDlcCSharpFuncs:CreateSceneObject(sceneObjId, position, rotation)
end

---@desc 移除SceneObject
---@param sceneObjUUID int 
---@return void 
function XDlcCSharpFuncs:DestroySceneObject(sceneObjUUID)
end

---@desc 设置SceneObject锁定状态（仅限控制端调用）
---@param soPlaceId int 
---@param locked bool 
---@return void 
function XDlcCSharpFuncs:SetSceneObjectLocked(soPlaceId, locked)
end

---@desc 播放剧情
---@param questId int 
---@param actorList List<int> 
---@param dramaName string 
---@param referencePos Vector3 
---@param referenceRot Vector3 
---@return void 
function XDlcCSharpFuncs:PlayDrama(questId, actorList, dramaName, referencePos, referenceRot)
end

---@desc 播放简易台词
---@desc 枚举文档:https://kurogame.feishu.cn/sheets/JLxYs1gwShWf25tBScrc9xqqngd?sheet=3zVYsP
---@param captionName string 简易台词名字
---@param isSequential bool 默认值:false 是否采用流水线播放模式
---@return void 
function XDlcCSharpFuncs:PlayDramaCaption(captionName, isSequential)
end

---@desc 设置任务剧情选项显示列表
---@param questId int 
---@param dramaName string 
---@param decisionNodeId int
---@param optionShowList List<int> 
---@return void 
function XDlcCSharpFuncs:SetQuestDecisionDialogShowList(questId, dramaName, decisionNodeId, optionShowList)
end

---@desc 设置npc剧情选项显示列表
---@param npcUUID int 
---@param decisionNodeId int
---@param optionShowList List<int> 填选项Id的列表
---@return void 
function XDlcCSharpFuncs:SetNpcDecisionDialogShowList(npcUUID, decisionNodeId, optionShowList)
end

---@desc 获取某个节点第一次选的选项Id
---@param nodeId int ClipId
---@return int 
function XDlcCSharpFuncs:GetDramaDialogFirstDecisionId(nodeId)
end

---@desc 获取某个节点所有选择过的选项Id（有循环跳转的时候，一个分歧会被选择多次）
---@param nodeId int 
---@return LuaTable 
function XDlcCSharpFuncs:GetDramaDialogDecisionIdList(nodeId)
end

---@desc 开关锚点UI
---@param soPlaceId int 
---@param active bool 
---@return void 
function XDlcCSharpFuncs:SetSpearPointUiActive(soPlaceId, active)
end

---@desc 设置锚点UI进度
---@param soPlaceId int 
---@param progress float 
---@return void 
function XDlcCSharpFuncs:SetSpearPointUiProgress(soPlaceId, progress)
end

---@desc 显示提示
---@param id int 
---@param var int 
---@return void 
function XDlcCSharpFuncs:ShowTip(id, var)
end

---@desc 关闭提示
---@param id int 
---@return void 
function XDlcCSharpFuncs:CloseTip(id)
end

---@desc 显示战斗引导
---@param id int 引自Table\Client\StatusSyncFight\FightGuideStepDLC.tab
---@return void 
function XDlcCSharpFuncs:ShowGuide(id)
end

---@desc 关闭战斗引导
---@return void 
function XDlcCSharpFuncs:HideGuide()
end

---@desc 手动触发系统引导开启检查
---@return void 
function XDlcCSharpFuncs:TryActiveSystemGuide()
end

---@desc 显隐指定UI界面
---@param uiIndex int UI界面索引
---@param active bool 是否显示
---@return void 
function XDlcCSharpFuncs:SetUiActive(uiIndex, active)
end

---@desc 显隐指定UI界面下某个部件
---@param uiIndex int UI界面索引
---@param widgetKey int UI界面内部件编号
---@param active bool 是否显示
---@return void 
function XDlcCSharpFuncs:SetUiWidgetActive(uiIndex, widgetKey, active)
end

---@desc 设置是否允许Npc使用顶部血条
---@param npcId int 
---@param enable bool 
---@return void 
function XDlcCSharpFuncs:SetNpcTopHpEnable(npcId, enable)
end

---@desc 开关动态血条
---@param npcId int npc对象唯一ID
---@param show bool true开，false关
---@return void 
function XDlcCSharpFuncs:ShowDynamicHpBar(npcId, show)
end

---@desc 开关Npc头顶标识信息
---@param npcId int 
---@param active bool 
---@return void 
function XDlcCSharpFuncs:SetNpcTopInfoActive(npcId, active)
end

---@desc 开关假结算（黑白龙转场演出用
---@param active bool 
---@return void 
function XDlcCSharpFuncs:SetFakeSettleActive(active)
end

---@desc 打开通用黑幕特效
---@param enterDuration float 进入黑幕时长(单位/s)
---@param exitDuration float 退出黑幕时长(单位/s)
---@return void 
function XDlcCSharpFuncs:PlayBlackScreenEffect(enterDuration, exitDuration)
end

---@desc 播放屏幕特效(控制时长)【注】引用的屏幕特效需要添加脚本资源依赖表
---@param screenEffectId int 屏幕特效Id，引自Product\Table\Client\StatusSyncFight\ScreenEffect.tab
---@param enterDuration float 特效渐入时长(单位/s)
---@param exitDuration float 特效渐出时长(单位/s)
---@return void 
function XDlcCSharpFuncs:PlayScreenEffectById(screenEffectId, enterDuration, exitDuration)
end

---@desc 播放持续屏幕特效(不控制时长), 需要使用KillStayScreenEffectById关闭【注】引用的屏幕特效需要添加脚本资源依赖表
---@param screenEffectId int 屏幕特效Id，引自Product\Table\Client\StatusSyncFight\ScreenEffect.tab
---@return void 
function XDlcCSharpFuncs:PlayStayScreenEffectById(screenEffectId)
end

---@desc 卸载屏幕特效(不控制时长)
---@param screenEffectId int 屏幕特效Id，引自Product\Table\Client\StatusSyncFight\ScreenEffect.tab
---@return void 
function XDlcCSharpFuncs:KillStayScreenEffectById(screenEffectId)
end

---@desc 播放背景音乐
---@desc 参考文档：【需求】V2.13 音频需求对接-音频战斗控制逻辑相关(2024.02.29) -【2.3 BGM相关】
---@param cueId int 音频文件id
---@param stopDuration float 默认值:-1 本次播放的BGM停止时其声音降低所需时间
---@param startTime float 默认值:-1 本次播放的起始时刻（相对于音频时间长度）
---@param endTime float 默认值:-1 本次播放的截止时刻（相对于音频时间长度）
---@param lastFor float 默认值:-1 本次播放持续多久时间
---@param fadeIn float 默认值:0 即将播放的BGM淡入的时间
---@param fadeOut float 默认值:0 :当前BGM淡出的时间
---@return void 
function XDlcCSharpFuncs:PlayMusicInOut(cueId, stopDuration, startTime, endTime, lastFor, fadeIn, fadeOut)
end

---@desc 以平滑过渡形式修改BGM的aisac参数
---@param controlName string aisac参数名
---@param targetValue float 目标值
---@param startValue float 默认值:-1 起始值
---@param curveTime float 默认值:-1 过渡时间
---@return void 
function XDlcCSharpFuncs:ChangeMusicAisacTween(controlName, targetValue, startValue, curveTime)
end

---@desc 增加QTE时间
---@param time float 
---@return void 
function XDlcCSharpFuncs:AddQTETime(time)
end

---@desc 设置在场玩家进入QTE时间（黯角boss战专用） 参数分别是第几位成员进入QTE增加的时间
---@param time1 float 
---@param time2 float 
---@param time3 float 
---@return void 
function XDlcCSharpFuncs:UpdateRoleCountQTETime(time1, time2, time3)
end

---@desc 玩家摇杆用力量化长度
---@return float 
function XDlcCSharpFuncs:GetMoveNormalizedDist()
end

---@desc 【仅限玩家npc调用】查询摇杆值
---@desc 接口使用示例：
---@desc local success, axis = self._proxy:TryGetQueryStickAxis()
---@param xyAxis out Vector2 
---@return bool 
function XDlcCSharpFuncs:TryGetQueryStickAxis(xyAxis)
end

---@desc 检测按键是否按下
---@param opKey int 参考枚举ENpcOperationKey
---@return bool 
function XDlcCSharpFuncs:IsKeyDown(opKey)
end

---@desc 检测按键是否长按
---@param opKey int 
---@param time out float 长按时间
---@return bool 
function XDlcCSharpFuncs:IsKeyHold(opKey, time)
end

---@desc 检测按键是否抬起
---@param opKey int 
---@return bool 
function XDlcCSharpFuncs:IsKeyUp(opKey)
end

---@desc 请提示程序补充注释
---@return bool 
function XDlcCSharpFuncs:HasMoveInput()
end

---@desc 请提示程序补充注释
---@return Vector3 
function XDlcCSharpFuncs:GetMoveInputOperation()
end

---@desc 注册一个Debug用的按钮功能
---@desc 客户端调用 文档:https://kurogame.feishu.cn/wiki/WZkHwYJGNinbyykpvNgcsglWnfg
---@param keyCode int keycode映射看链接
---@param key ENpcOperationKey 
---@param op EOperationType 
---@param remove bool true为移除，false为添加
---@return void 
function XDlcCSharpFuncs:RegisterKeyboardOperator(keyCode, key, op, remove)
end

---@desc 修改团队分数
---@param delta int 分数变化量
---@return void 
function XDlcCSharpFuncs:ChangeRubikTeamScore(delta)
end

---@desc 获取当前团队分数
---@return int 
function XDlcCSharpFuncs:GetRubikTeamScore()
end

---@desc 修改玩家分数
---@param playerNpcId int 玩家Npc的UUID
---@param delta int 分数变化量
---@return void 
function XDlcCSharpFuncs:ChangeRubikPlayerScore(playerNpcId, delta)
end

---@desc 获取玩家分数
---@param playerNpcId int 玩家Npc的UUID
---@return int 
function XDlcCSharpFuncs:GetRubikPlayerScore(playerNpcId)
end

---@desc 设置玩家猫鼠阵营
---@param npcId int true为猫
---@param isCat bool false为鼠
---@return void 
function XDlcCSharpFuncs:SetMouseHunterPlayerCamp(npcId, isCat)
end

---@desc 设置玩家积分
---@param npcId int 
---@param score int 
---@return void 
function XDlcCSharpFuncs:SetMouseHunterPlayerScore(npcId, score)
end

---@desc 设置猫的捕鼠数量
---@param npcId int 
---@param huntCount int 
---@return void 
function XDlcCSharpFuncs:SetCatHuntCount(npcId, huntCount)
end

---@desc 设置老鼠存活时间
---@param npcId int 
---@param liveTime int 秒
---@return void 
function XDlcCSharpFuncs:SetMouseAliveTime(npcId, liveTime)
end

---@desc 设置老鼠数量
---@param liveCount int 当前存活老鼠数量
---@param totalCount int 总共的老鼠数量（不论死活）
---@return void 
function XDlcCSharpFuncs:SetPlayerMouseCount(liveCount, totalCount)
end

---@desc 创建老鼠变身选项列表
---@param npcId int 
---@param reserveOptionsTable LuaTable 关卡预定的变身选项列表（包含与出生地关联的几个变身选项）
---@return void 
function XDlcCSharpFuncs:CreateMouseTransformOptionList(npcId, reserveOptionsTable)
end

---@desc 开关猫鼠阵营提示
---@desc 该方法会自动判断调用的客户端玩家阵营，显示对应的阵营图标。
---@param tipId int FightTips表中配置的ID
---@return void 
function XDlcCSharpFuncs:ShowMouseHunterCampTip(tipId)
end

---@desc 生成道具
---@param key int 
---@param position Vector3 
---@return void 
function XDlcCSharpFuncs:GenerateMouseHunterItem(key, position)
end

---@desc 根据子弹UUID获取对应的道具key
---@param missileUUID int 
---@return int 
function XDlcCSharpFuncs:MouseHunterGetItemKey(missileUUID)
end

---@desc 获取玩家的阵营。[玩家ID] = 阵营  1为猫2为鼠
---@return LuaTable 
function XDlcCSharpFuncs:MouseHunterGetCatCampIndex()
end

---@desc 设置技能CD
---@param skillId int 
---@param skillCD float 
---@return void 
function XDlcCSharpFuncs:MouseHunterSetSkillCD(skillId, skillCD)
end

---@desc 标记关卡玩法完成
---@param isFullyCleared bool 是否为完全通关（达成所有要求/条件）
---@return void 
function XDlcCSharpFuncs:CompleteLevelPlay(isFullyCleared)
end

---@desc 通知任务系统，任务目标脚本enter执行结束
---@return void 
function XDlcCSharpFuncs:FinishQuestObjectiveScriptEnter()
end

---@desc 通知任务系统，任务目标脚本exit执行结束
---@return void 
function XDlcCSharpFuncs:FinishQuestObjectiveScriptExit()
end

---@desc 设置任务步骤进度完成类型
---@param questId int 
---@param stepId int 
---@param objectiveId int 
---@param type int 
---@return void 
function XDlcCSharpFuncs:SetQuestObjectiveFinishType(questId, stepId, objectiveId, type)
end

---@desc 获取任务步骤进度完成类型
---@param objectiveId int 
---@return int 
function XDlcCSharpFuncs:GetQuestObjectiveFinishType(objectiveId)
end

---@desc 获取任务步骤进度是否完成
---@param objectiveId int 
---@return bool 
function XDlcCSharpFuncs:IsQuestObjectiveFinished(objectiveId)
end

---@desc 设置Actor任务占用
---@desc 如果Actor设置了任务占用并且在任务完成期间未再设设置回未占用状态，则会在任务结束后自动将占用Actor设 置为未占用
---@param questId int 任务ID
---@param uuid int 目标Actor对象的UUID（Npc和SceneObject都是Actor）
---@param isIn bool true/false 对应 占用/未占用
---@return void 
function XDlcCSharpFuncs:SetActorInQuest(questId, uuid, isIn)
end

---@desc 联系程序补充注释
---@param uuid int 
---@return bool 
function XDlcCSharpFuncs:IsActorInQuest(uuid)
end

---@desc 添加任务导航点（为关卡NPC）
---@param levelId int 关卡ID
---@param questId int 任务ID
---@param uiStyleId int 导航点UI样式配置ID
---@param placeId int 关卡NPC的placeId
---@param displayOffset Vector3 导航点在世界坐标系下的显示偏移（为了与特效显示不重叠）
---@param showEffect bool 是否显示标识特效
---@param forceMapPinActive bool 是否强制显示该点对应的地图标记
---@return int 导航点ID
function XDlcCSharpFuncs:AddQuestNavPointForLevelNpc(levelId, questId, uiStyleId, placeId, displayOffset, showEffect, forceMapPinActive)
end

---@desc 添加任务导航点（为关卡场景物件）
---@param levelId int 关卡ID
---@param questId int 任务ID
---@param uiStyleId int 导航点UI样式配置ID
---@param placeId int 关卡场景物件的placeId
---@param displayOffset Vector3 导航点在世界坐标系下的显示偏移（为了与特效显示不重叠）
---@param showEffect bool 是否显示标识特效
---@param forceMapPinActive bool 是否强制显示该点对应的地图标记
---@return int 导航点ID
function XDlcCSharpFuncs:AddQuestNavPointForLevelSceneObject(levelId, questId, uiStyleId, placeId, displayOffset, showEffect, forceMapPinActive)
end

---@desc 添加任务导航点（固定坐标）
---@param levelId int 关卡ID
---@param questId int 任务ID
---@param uiStyleId int 导航点UI样式配置ID
---@param point Vector3 导航点坐标
---@param displayOffset Vector3 导航点在世界坐标系下的显示偏移（为了与特效显示分开）
---@param showEffect bool 是否显示标识特效
---@param forceMapPinActive bool 是否强制显示该点对应的地图标记
---@return int 导航点ID
function XDlcCSharpFuncs:AddQuestNavPoint(levelId, questId, uiStyleId, point, displayOffset, showEffect, forceMapPinActive)
end

---@desc 移除任务导航点
---@param questId int 任务ID
---@param navPointId int 导航点ID
---@return void 
function XDlcCSharpFuncs:RemoveQuestNavPoint(questId, navPointId)
end

---@desc 打开任务道具交付UI
---@param objectiveId int 任务步骤目标ID
---@return void 
function XDlcCSharpFuncs:OpenQuestItemDeliveryUI(objectiveId)
end

---@desc 试用角色加入队伍
---@param trialNpcIds List<int> 试用角色配置id列表（Share\StatusSyncFight\Npc\TrialNpc.tab）
---@param addMode ETrialNpcAddMode 枚举ETrialNpcAddMode，Cover表示试用角色替换整个当前队伍、Append表示试用角色附加在当前队伍前面
---@param curNpcPos int 试用角色加入队伍后立即切换到对应位置的试用角色，0表示不进行此操作，大于0的范围为[1,试用角色列表长度]
---@return void 
function XDlcCSharpFuncs:AddTrialNpcToTeam(trialNpcIds, addMode, curNpcPos)
end

---@desc 试用角色离开队伍
---@return void 
function XDlcCSharpFuncs:RemoveTrialNpcFromTeam()
end

---@desc 提醒程序补充注释
---@return void 
function XDlcCSharpFuncs:FinishInstLevel()
end

---@desc 手动接取任务 仅限任务Objective脚本使用，使用时quest不配AutoUndertake字段
---@return void 
function XDlcCSharpFuncs:UnderTakeSelfQuest()
end

---@desc 添加任务自动卸载Npc白名单
---@param levelId int 
---@param placeIdList List<int> npc PlaceIdList
---@return void 
function XDlcCSharpFuncs:AddUnloadNpcWhiteList(levelId, placeIdList)
end

---@desc 添加任务自动卸载SceneObj白名单
---@param levelId int 
---@param placeIdList List<int> SceneObj PlaceIdList
---@return void 
function XDlcCSharpFuncs:AddUnloadSceneObjWhiteList(levelId, placeIdList)
end

---@desc 检查系统条件是否达成
---@param conditionId int
---@return bool 
function XDlcCSharpFuncs:CheckSystemCondition(conditionId)
end

---@desc 设置系统功能开放或屏蔽
---@param systemFunctionType ESystemFunctionType 系统功能类型枚举
---@param enable bool 是否开放
---@return void 
function XDlcCSharpFuncs:SetSystemFuncEntryEnable(systemFunctionType, enable)
end

---@desc 设置一批系统功能开放或屏蔽
---@param enableList List<int> 开放的系统功能类型枚举数组
---@param disableList List<int> 屏蔽的系统功能类型枚举数组
---@return void 
function XDlcCSharpFuncs:SetSystemFuncEntryEnableBatch(enableList, disableList)
end

---@desc 控制具体的系统功能状态
---@param systemFunctionType ESystemFunctionType 系统功能类型枚举
---@param args List<object> 控制参数（参数由关卡和系统共同协商，系统定制化解析）例如：关卡要控制小地图是否可以点击打开大地图，控制是否可以进行地图传送等。
---@return void 
function XDlcCSharpFuncs:ControlSystemFunction(systemFunctionType, args)
end

---@desc 打开【玩家自定义外观】的UI
---@return void 
function XDlcCSharpFuncs:ShowPlayerDIYUI()
end

---@desc 发送短信
---@param messageId int 
---@return void 
function XDlcCSharpFuncs:SendChatMessage(messageId)
end

---@desc 显示大世界图文教学
---@param teachId int 
---@return void 
function XDlcCSharpFuncs:ShowBigWorldTeach(teachId)
end

---@desc 在空花下打开玩法入口并推进相机到指定位置
---@param bigWorldActivityId int 
---@return void 
function XDlcCSharpFuncs:OpenGameplayMainEntrance(bigWorldActivityId)
end

---@desc OperateDormitoryPhotoWall
---@return void 
function XDlcCSharpFuncs:OperateDormitoryPhotoWall()
end

---@desc 宿舍玩法-与摆件架交互
---@return void 
function XDlcCSharpFuncs:OperateDormitoryFrameWall()
end

---@desc 宿舍玩法-修改宿舍涂装
---@return void 
function XDlcCSharpFuncs:ChangeDormitorySkin()
end

---@desc 打开拍照玩法
---@param camParamId int 
---@param npcPlaceIdList List<int> 
---@param sceneObjectPlaceIdList List<int> 
---@return void 
function XDlcCSharpFuncs:OpenGameplayPhotograph(camParamId, npcPlaceIdList, sceneObjectPlaceIdList)
end

---@desc 获取自走棋Npc自动模式
---@param uuid int npcId
---@return bool 
function XDlcCSharpFuncs:GetAutoChessNpcAutoMode(uuid)
end

---@desc 设置自走棋技能冷却显示
---@param uuid int npcId
---@param id int 技能ID
---@param current float 当前进度
---@param max float 最大进度
---@return void 
function XDlcCSharpFuncs:SetAutoChessSkillData(uuid, id, current, max)
end

---@desc 设置自走棋技能队列状态
---@param uuid int npcId
---@param id int 技能ID
---@return void 
function XDlcCSharpFuncs:SetAutoChessSkillTriggerState(uuid, id)
end

---@desc 设置自走棋技能释放状态
---@param uuid int npcId
---@param id int 技能ID
---@return void 
function XDlcCSharpFuncs:SetAutoChessSkillActiveState(uuid, id)
end

---@desc 设置自走棋宝石冷却显示
---@param uuid int npcId
---@param id int 宝石ID
---@param current float 当前进度
---@param max float 最大进度
---@return void 
function XDlcCSharpFuncs:SetAutoChessGemData(uuid, id, current, max)
end

---@desc 设置自走棋宝珠触发状态
---@param uuid int npcId
---@param id int 技能ID
---@return void 
function XDlcCSharpFuncs:SetAutoChessGemTriggerState(uuid, id)
end

---@desc 设置自走棋宝珠持续生效状态
---@param uuid int npcId
---@param id int 技能ID
---@return void 
function XDlcCSharpFuncs:SetAutoChessGemActiveState(uuid, id)
end

---@desc 打开自走棋疲劳UI
---@return void 
function XDlcCSharpFuncs:ShowAutoChessTriedMessageTip()
end

---@desc 打开自走棋倒计时UI
---@param seconds int 
---@return void 
function XDlcCSharpFuncs:ShowAutoChessCountDownMessageTip(seconds)
end

---@desc 获取自走棋Npc
---@param self bool 是否自身
---@return int 
function XDlcCSharpFuncs:GetAutoChessNpc(self)
end

---@desc 添加自走棋宝珠触发次数
---@param npcId int 
---@param gemId int 
---@param value int 
---@return void 
function XDlcCSharpFuncs:AddAutoChessGemTriggerRecord(npcId, gemId, value)
end

---@desc TODO 自走棋调试用 绑定UI
---@param uuid int npcId
---@param self bool 是否自身
---@return void 
function XDlcCSharpFuncs:SetAutoChessNpcUi(uuid, self)
end

---@desc 获取自走棋角色配置ID
---@param uuid int 
---@return int 
function XDlcCSharpFuncs:GetAutoChessCharacterId(uuid)
end

---@desc 设置自走棋UI显隐动画
---@param active bool 
---@param animName string 
---@return void 
function XDlcCSharpFuncs:SetAutoChessUiActive(active, animName)
end

---@desc 设置自走棋计时器UI显隐
---@param active bool 
---@param offset int 
---@return void 
function XDlcCSharpFuncs:SetAutoChessTimerTipsActive(active, offset)
end

---@desc 根据SkillId获取技能配置
---@param id int 
---@return XTable.XTableTheatre5ItemSkill 
function XDlcCSharpFuncs:GetAutoChessSkillConfig(id)
end

---@desc 根据MagicId获取技能配置
---@param id int 
---@return XTable.XTableTheatre5ItemSkill 
function XDlcCSharpFuncs:GetAutoChessSkillConfigByMagicId(id)
end

---@desc 获取角色配置
---@param id int 
---@return XTable.XTableTheatre5Character 
function XDlcCSharpFuncs:GetAutoChessCharacterConfig(id)
end

---@desc 获取宝珠配置
---@param id int 
---@return XTable.XTableTheatre5ItemRune 
function XDlcCSharpFuncs:GetAutoChessRuneConfig(id)
end

return XDlcCSharpFuncs;
