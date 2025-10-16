local XTeam = require("XEntity/XTeam/XTeam")
---@class XTeamPrefab:XTeam 队伍预设 全部都是假数据
local XTeamPrefab = XClass(XTeam, "XTeamPrefab")

--- 初始化所有字段数据
---@param data table 原始预设数据
function XTeamPrefab:Ctor(data)
    self.Id = data.TeamId
    self.CaptainPos = data.CaptainPos or 1
    self.FirstFightPos = data.FirstFightPos or 1
    self.TeamName = data.TeamName
    self.SelectedGeneralSkill = data.SelectedGeneralSkill
    self.EnterCgIndex = data.EnterCgIndex
    self.SettleCgIndex = data.SettleCgIndex

    -- 空位初始
    self.EntitiyIds = {0,0,0}
    if data.TeamData then
        for idx, v in pairs(data.TeamData) do
            self.EntitiyIds[idx] = v
        end
    end

    -- 调用 InitXX 进行本地初始化
    self:InitPartnerData(data.PartnerData)
    self:InitEquipData(data.EquipData)
    self:RefreshGeneralSkills(true, true)  -- 假设此方法本身不需要上行
end

--- 更新伙伴预设数据
---@param partnerData table
function XTeamPrefab:InitPartnerData(partnerData)
    local XPartnerPrefab = require("XEntity/XPartner/XPartnerPrefab")
    self.PartnerPrefab = self.PartnerPrefab or XPartnerPrefab.New(self.Id, partnerData)
end

--- 更新伙伴预设（触发上行）
---@param partnerData table
function XTeamPrefab:UpdatePartnerData(partnerData)
    if not self.PartnerPrefab then return end
    self.PartnerPrefab:UpdateAll(partnerData)
end

--- 单位置伙伴更新（触发上行）
function XTeamPrefab:UpdatePartnerDataAtPos(pos, data)
    if not self.PartnerPrefab then return end
    self.PartnerPrefab:UpdatePartnerDataAtPos(pos, data)
end

--- 更新装备和意识数据
---@param equipData table
function XTeamPrefab:InitEquipData(equipData)
    if not equipData then
        XLog.Warning("XTeamPrefab:InitEquipData equipData is nil, Id:", self.Id)
        return
    end

    self.WeaponData = self.WeaponData or {}
    self.AwarenessData = self.AwarenessData or {}

    for position, equipGroup in pairs(equipData) do
        self.WeaponData[position] = self.WeaponData[position] or nil
        self.AwarenessData[position] = self.AwarenessData[position] or {}

        if equipGroup.EquipDataDict then
            for slot, item in pairs(equipGroup.EquipDataDict) do
                if slot == 0 then
                    self.WeaponData[position] = item
                else
                    self.AwarenessData[position][slot] = item
                end
            end
        end
    end
end

function XTeamPrefab:ClearAllData()
    self.WeaponData = {}
    self.AwarenessData = {}
    self:UpdateEntityIds({0,0,0})
end

function XTeamPrefab:ClearPosData(pos)
    self.WeaponData[pos] = nil
    self.AwarenessData[pos] = nil
    local charId = self:GetEntityIdByTeamPos(pos)
    self:UpdateEntityTeamPos(charId, pos)
end

function XTeamPrefab:ClearAwarenessData(pos, notSyncToServer)
    for i = 1, 6, 1 do
        self:UpdateEquipAt(pos, i, nil, true)
    end

    if not notSyncToServer then
        self:SyncEquipDataToServer(pos)
    end
end

--- 单独更新某个位置某槽位的装备
function XTeamPrefab:UpdateEquipAt(pos, slot, item, notSyncToServer, cb)
    self.WeaponData = self.WeaponData or {}
    self.AwarenessData = self.AwarenessData or {}

    local curEquipId = item and item.EquipId
    local isConflict, conflictPos, conflictSlot = self:CheckEquipIdConflict(curEquipId, pos)
    -- 如果冲突，把被冲突的位置的意识给扒下来
    -- 如果是武器冲突则替换，因为武器是一定要穿戴的
    if slot == 0 then
        if isConflict then
            self.WeaponData[conflictPos] = self.WeaponData[pos]
        end
        self.WeaponData[pos] = item
    else
        if isConflict then
            self.AwarenessData[conflictPos][conflictSlot] = nil
        end
        self.AwarenessData[pos] = self.AwarenessData[pos] or {}
        self.AwarenessData[pos][slot] = item
    end

    if not notSyncToServer then
        self:SyncEquipDataToServer(pos, cb)
    end
end

function XTeamPrefab:CheckEquipIdConflict(equipId, targetPos)
    local curPos, slot = self:GetPosByEquipId(equipId)
    if not curPos then
        return false
    end

    return curPos ~= targetPos, curPos, slot
end

--- 更新指定位置的意识装备列表，并处理位置冲突与穿脱(这个接口目前专为意识预设套装穿戴使用)
---@param targetPos number 目标位置（self.CurrentPos 原本位置）
---@param equipList table slot->EquipId
function XTeamPrefab:UpdateAwarenessEquipList(targetPos, equipList)
    local conflictInfoList = {}
    local characterType = XMVCA.XCharacter:GetCharacterType(self:GetEntityIdByTeamPos(targetPos))
    local count = 0
    for slot, equipId in pairs(equipList) do count = count + 1 end

    for slot, equipId in pairs(equipList) do
        -- 类型不匹配检查
        if not XMVCA.XEquip:IsCharacterTypeFit(equipId, characterType) then
            XUiManager.TipText("EquipAwarenessSuitPrefabCharacterTypeWrong")
            return
        end

        -- 冲突检测
        local curPos = self:GetPosByEquipId(equipId)
        if XTool.IsNumberValid(curPos) and curPos ~= targetPos then
            table.insert(conflictInfoList, {
                EquipId = equipId,
                CharacterId = self:GetEntityIdByTeamPos(curPos),
                TeamPos = curPos,
                Slot = slot,
            })
        end
    end

    table.sort(conflictInfoList, function(a, b)
        return XMVCA.XEquip:GetEquipSiteByEquipId(a.EquipId) < XMVCA.XEquip:GetEquipSiteByEquipId(b.EquipId)
    end)

    local isConflict = not XTool.IsTableEmpty(conflictInfoList)

    local function doUpdate()
        -- 直接穿 冲突的意识已经在UpdateEquipAt里处理了，会先将被冲突的角色的装备脱掉
        local count2 = 0
        for slot, equipId in pairs(equipList) do
            count2 = count2 + 1
            local notSync = (count2 ~= count)
            -- 有冲突就不要单独发装备信息 而是发全部的信息
            self:UpdateEquipAt(targetPos, slot, {EquipId = equipId}, notSync or isConflict)
        end

        if isConflict then
            self:SyncFullDataToServer(function ()
                XUiManager.TipText("TeamPrefabEquipModifySuccess")
            end)
        end
    end

    if not isConflict then
        doUpdate()
    else
        return conflictInfoList, doUpdate
    end

    return true
end

-- 获取指定位置的武器数据
function XTeamPrefab:GetWeaponData(pos)
    return self.WeaponData and self.WeaponData[pos] or nil
end

-- 获取指定位置的武器共鸣数据表
function XTeamPrefab:GetWeaponResonance(pos)
    local weapon = self:GetWeaponData(pos)
    return weapon and weapon.ResonanceDict or nil
end

-- 获取指定位置武器的超频套装ID
function XTeamPrefab:GetWeaponOverrunSuitId(pos)
    local weapon = self:GetWeaponData(pos)
    return weapon and weapon.WeaponOverrunSuitId or 0
end

-- 获取指定位置指定槽位的意识数据
function XTeamPrefab:GetAwarenessData(pos, slot)
    if self.AwarenessData and self.AwarenessData[pos] then
        return self.AwarenessData[pos][slot]
    end
    return nil
end

-- 获取预设穿戴的套装列表信息
function XTeamPrefab:GetWearingSuitInfoListByPos(pos)
    local equipList = {}
    
    local awarenessData = self:GetAllAwarenessData(pos)
    if not awarenessData then
        return equipList
    end

    for i, v in pairs(awarenessData) do
        table.insert(equipList, XMVCA.XEquip:GetEquip(v.EquipId))
    end

    -- 武器
    local equipWeapon = nil
    local usingWeaponId = self:GetWeaponData(pos).EquipId
    local overrunSuitId = self:GetWeaponOverrunSuitId(pos)
    local weaponEquipSuitInfo = nil
    if XTool.IsNumberValid(usingWeaponId) and XTool.IsNumberValid(overrunSuitId) then
        equipWeapon = XMVCA.XEquip:GetEquip(usingWeaponId)
        
        local suitName = XMVCA.XEquip:GetSuitName(overrunSuitId)
        weaponEquipSuitInfo = {
            SuitId = overrunSuitId,
            Name = suitName,
            Count = 0,
            IsOverrun = true -- 因为传入的是 overrunSuitId，所以默认标记为超限
        }

        local skillDescs = XMVCA.XEquip:GetEquipSuitSkillDescription(overrunSuitId)
        for addCnt = 1, XEnumConst.EQUIP.OVERRUN_ADD_SUIT_CNT do
            if skillDescs[addCnt] then
                weaponEquipSuitInfo.Count = addCnt
            end
        end
    end

    -- 意识依然可以用装备通用接口，只是武器由于可以自定义谐振，所以需要单独处理
    local suitInfoList = XMVCA.XEquip:GetWearingSuitInfoListByEquipListAndWeapon(equipList)
    table.insert(suitInfoList, weaponEquipSuitInfo)
    return suitInfoList
end

-- 获取指定位置所有意识槽位数据
function XTeamPrefab:GetAllAwarenessData(pos)
    return self.AwarenessData and self.AwarenessData[pos] or nil
end

--- 获取某个装备ID所在的预设位置
---@param equipId number
---@return number|nil 找不到则返回 nil
function XTeamPrefab:GetPosByEquipId(equipId)
    if not equipId then return nil end

    -- 检查武器数据
    if self.WeaponData then
        for pos, weapon in pairs(self.WeaponData) do
            if weapon and weapon.EquipId == equipId then
                return pos
            end
        end
    end

    -- 检查意识数据
    if self.AwarenessData then
        for pos, slotDict in pairs(self.AwarenessData) do
            if slotDict then
                for slot, item in pairs(slotDict) do
                    if item and item.EquipId == equipId then
                        return pos, slot
                    end
                end
            end
        end
    end

    return nil
end

-- 获取指定位置的伙伴数据
---@return XPartnerPrefab
function XTeamPrefab:GetPartnerData()
    return self.PartnerPrefab
end

-- 每次换人调用，检测当前首发位和队长位是否为空，空的话找到按顺序找到最近的一个有角色的pos,自动换上去
function XTeamPrefab:CheckOnlyOneEntityToSyncFirstAndCaptainPos()
    -- 找第一个有效角色位置
    local firstValidPos = nil
    for pos, charId in ipairs(self:GetEntityIds()) do
        if XTool.IsNumberValid(charId) then
            firstValidPos = pos
            break
        end
    end

    if not firstValidPos then
        return -- 队伍完全没角色，直接返回
    end

    -- 队长位
    if not XTool.IsNumberValid(self:GetCaptainPosEntityId()) then
        self:UpdateCaptainPos(firstValidPos, true)
    end

    -- 首发位
    if not XTool.IsNumberValid(self:GetFirstFightPosEntityId()) then
        self:UpdateFirstFightPos(firstValidPos, true)
    end
end

function XTeamPrefab:SwapPosData(posA, posB, notSyncToServer)
    if not posA or not posB or posA == posB then
        return
    end

    -- 1. 交换角色 ID
    self.EntitiyIds[posA], self.EntitiyIds[posB] = self.EntitiyIds[posB], self.EntitiyIds[posA]

    -- 2. 交换武器数据
    self.WeaponData[posA], self.WeaponData[posB] = self.WeaponData[posB], self.WeaponData[posA]

    -- 3. 交换意识数据
    self.AwarenessData[posA], self.AwarenessData[posB] = self.AwarenessData[posB], self.AwarenessData[posA]

    -- 4. 交换伙伴数据
    if self.PartnerPrefab then
        self.PartnerPrefab:SwapPosData(posA, posB)
    end

    self:CheckOnlyOneEntityToSyncFirstAndCaptainPos()

    -- 5. 同步到服务器
    if not notSyncToServer then
        self:SyncFullDataToServer()
    end
end

-- 将对应角色实际穿戴的装备数据复制到预设中
function XTeamPrefab:CopyRealCharacterEquipData(characterId, pos, notSyncToServer)
    -- 检查队伍里对应的角色，并拿到
    if not characterId then return end
    if not XTool.IsNumberValid(pos) then return end

    local equipData = XMVCA.XEquip:GetCharacterEquips(characterId)
    for k, xEquip in pairs(equipData) do
        if xEquip:IsWeapon() then
            self:CopyRealWeaponData(xEquip.Id, pos, true)
        else
            self:UpdateEquipAt(pos, xEquip:GetSite(), {EquipId = xEquip.Id, ResonanceDict = {}, WeaponOverrunSuitId = 0}, true)
        end
    end
    -- 检测 如果没有成功复制武器 说明复制有问题 中断并清空所有数据
    local weaponData = self:GetWeaponData(pos)
    if not weaponData or (not XTool.IsNumberValid(weaponData.EquipId)) then
        self:ClearPosData(pos)
        XLog.Error("XTeamPrefab:CopyRealCharacterEquipData:TeamPrefabId = %s, characterId = %s, pos = %s, 复制失败", self:GetId(), characterId, pos)
    end

    if not notSyncToServer then
        self:SyncFullDataToServer()
    end
end

--- 将拥有的实际的武器数据复制到预设中对应的位置
function XTeamPrefab:CopyRealWeaponData(equipId, pos, notSyncToServer, cb)
    -- 判断这个装备是否可以由该角色装备
    if not equipId or not pos then 
        return 
    end

    local xEquip = XMVCA.XEquip:GetEquip(equipId)
    if not xEquip:IsWeapon() then 
        return 
    end
    
    local characterId = self:GetEntityIdByTeamPos(pos)
    if not XTool.IsNumberValid(characterId) then 
        return 
    end

    if not xEquip:CheckCanCharWear(characterId) then
        XLog.Error("XTeamPrefab:CopyRealWeaponData:TeamPrefabId = %s, equipId = %s, characterId = %s, pos = %s, 不能装备", self:GetId(), equipId, characterId, pos)
        return
    end

    local data = 
    {
        EquipId = equipId,
        ResonanceDict = XMVCA.XEquip:GetResonanceSkillList(equipId),
        WeaponOverrunSuitId = xEquip:GetOverrunChoseSuit(),
    }

    self:UpdateEquipAt(pos, 0, data, notSyncToServer, cb)
end

function XTeamPrefab:CopyRealWeaponResonance(resonanceDict, pos, notSyncToServer)
    local weaponData = self:GetWeaponData(pos)
    if not weaponData then return end
    weaponData.ResonanceDict = resonanceDict
    self:UpdateEquipAt(pos, 0, weaponData, notSyncToServer)
end

function XTeamPrefab:CopyRealWeaponWeaponOverrunSuitId(weaponOverrunSuitId, pos, notSyncToServer)
    local weaponData = self:GetWeaponData(pos)
    if not weaponData then return end
    weaponData.WeaponOverrunSuitId = weaponOverrunSuitId
    self:UpdateEquipAt(pos, 0, weaponData, notSyncToServer)
end

-- 将角色数据复制到对应位置（武器、意识、辅助机），角色Id为空时卸载对应位置
function XTeamPrefab:CopyRealCharacterToPos(characterId, pos, notSyncToServer)
    local isCharIdValid = XTool.IsNumberValid(characterId)
    self:UpdateEntityTeamPos(characterId, pos, isCharIdValid)
    if XTool.IsNumberValid(characterId) then
        self:CopyRealCharacterEquipData(characterId, pos, true)
        local realTeamPartner = XDataCenter.PartnerManager.GetCarryPartnerEntityByCarrierId(characterId)
        local newPartnerId = realTeamPartner and realTeamPartner:GetId()
        if XTool.IsNumberValid(newPartnerId) then
            self:GetPartnerData():EquipWithRealSkill(pos, newPartnerId)
        else
            self:GetPartnerData():Unload(pos)
        end
    else
        -- 卸载
        -- 清空武器
        self:UpdateEquipAt(pos, 0, nil, true)
        -- 清空意识
        self:ClearAwarenessData(pos, true)
        -- 清空辅助机
        self:GetPartnerData():Unload(pos)
    end

    self:RefreshGeneralSkills(true)

    self:CheckOnlyOneEntityToSyncFirstAndCaptainPos()

    if not notSyncToServer then
        self:SyncFullDataToServer()
    end
end

--- 用真正的队伍数据xTeam覆盖当前预设数据(from)
---@param xTeam XTeam
function XTeamPrefab:CoverFromRealTeamData(xTeam, cb, notSyncToServer)
    self:UpdateEntityIds(xTeam:GetEntityIds())
    self:UpdateCaptainPosAndFirstFightPos(xTeam:GetCaptainPos(), xTeam:GetFirstFightPos())
    self:SetEnterCgIndex(xTeam:GetEnterCgIndex(), true)
    self:SetSettleCgIndex(xTeam:GetSettleCgIndex(), true)
    self:RefreshGeneralSkills(true, true)  -- 假设此方法本身不需要上行
    if XTool.IsNumberValid(self.SelectedGeneralSkill) then -- 必须要判断，因为有可能是0
        self.SelectedGeneralSkill = xTeam.SelectedGeneralSkill
    end
    for pos, characterId in ipairs(xTeam:GetEntityIds()) do
        self:CopyRealCharacterToPos(characterId, pos, true)
    end

    if not notSyncToServer then
        self:SyncFullDataToServer(cb)
    end
end

--- 应用当前预设到真正的队伍XTeam中(to)
---@param xTeam XTeam
function XTeamPrefab:CoverToRealTeamData(xTeam)
    xTeam:UpdateEntityIds(self.EntitiyIds)
    xTeam:UpdateCaptainPosAndFirstFightPos(self.CaptainPos, self.FirstFightPos)
    xTeam:SetEnterCgIndex(self.EnterCgIndex)
    xTeam:SetSettleCgIndex(self.SettleCgIndex)
    xTeam:RefreshGeneralSkills(true, true)  -- 假设此方法本身不需要上行
    if XTool.IsNumberValid(xTeam.SelectedGeneralSkill) then -- 必须要判断，因为有可能是0
        xTeam.SelectedGeneralSkill = self.SelectedGeneralSkill
    end
end

function XTeamPrefab:UpdateTeamName(name, cb)
    local oldName = self.TeamName
    self.TeamName = name
    self:SyncMetaDataToServer(function ()
        self.TeamName = name
        if cb then
            cb()
        end
    end)
    self.TeamName = oldName
end

function XTeamPrefab:UpdateFirstFightPos(value, notSyncToServer, cb)
    self.FirstFightPos = value
    if not notSyncToServer then
        self:SyncMetaDataToServer(cb)
    end
end

function XTeamPrefab:UpdateCaptainPos(value, notSyncToServer, cb)
    self.CaptainPos = value
    if not notSyncToServer then
        self:SyncMetaDataToServer(cb)
    end
end

function XTeamPrefab:SetEnterCgIndex(index, notSyncToServer, cb)
    self.EnterCgIndex = index
    if not notSyncToServer then
        self:SyncMetaDataToServer(cb)
    end
end

function XTeamPrefab:SetSettleCgIndex(index, notSyncToServer, cb)
    self.SettleCgIndex = index
    if not notSyncToServer then
        self:SyncMetaDataToServer(cb)
    end
end

-- 获取指定位置的所有数据快照
function XTeamPrefab:GetFullSnapshotAt(pos)
    return {
        CharacterId = self:GetCharacterId(pos),
        Weapon = self:GetWeaponData(pos),
        Resonance = self:GetWeaponResonance(pos),
        OverrunSuitId = self:GetWeaponOverrunSuitId(pos),
        Awareness = self:GetAllAwarenessData(pos),
        PartnerId = self:GetPartnerData():GetPartnerIdByPos(pos),
    }
end

--- 同步接口
function XTeamPrefab:SyncFullDataToServer(cb)
    XDataCenter.TeamManager.TeamPrefabSetTeamRequestV4P40(self, cb)
end

function XTeamPrefab:SyncEquipDataToServer(pos, cb)
    XDataCenter.TeamManager.TeamPrefabUpdateEquipRequest(self, pos, cb)
end

function XTeamPrefab:SyncPartnerDataToServer(pos, cb)
    local partnerData = self:GetPartnerData()
    if not partnerData or not pos then return end

    local partnerId = partnerData:GetPartnerIdByPos(pos)
    XDataCenter.PartnerManager.TeamPreSetPartnerRequest(self:GetId(), pos, partnerId, partnerData:GetSkillData(partnerId), cb)
end

function XTeamPrefab:SyncMetaDataToServer(cb)
    XDataCenter.TeamManager.TeamPrefabUpdateMetadataRequest(self, cb)
end

--region 禁用方法
function XTeamPrefab:LoadTeamData() end
function XTeamPrefab:Save() end
function XTeamPrefab:GetSaveKey() end
function XTeamPrefab:LoadEntitiyIds() end
function XTeamPrefab:ManualSave() end
function XTeamPrefab:_Save() end
function XTeamPrefab:UpdateSaveCallback(callback) end
function XTeamPrefab:UpdateAutoSave(value) end
function XTeamPrefab:UpdateLocalSave(value) end
--endregion

return XTeamPrefab
