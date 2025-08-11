---@class XBWMapAxisConversion
local XBWMapAxisConversion = XClass(nil, "XBWMapAxisConversion")

function XBWMapAxisConversion:Ctor(uiType)
    self._OriginPos = {
        x = 0,
        y = 0,
    }
    self._PixelRatio = 1
    self._CanvasType = uiType
end

function XBWMapAxisConversion:ChangeAxis(levelId)
    levelId = XMVCA.XBigWorldMap:GetMapValidLevelId(levelId)

    if not XTool.IsNumberValid(levelId) then
        return
    end

    self._OriginPos.x = XMVCA.XBigWorldMap:GetMapPosXByLevelId(levelId) or 0
    self._OriginPos.y = XMVCA.XBigWorldMap:GetMapPosZByLevelId(levelId) or 0
    self._PixelRatio = XMVCA.XBigWorldMap:GetMapPixelRatioByLevelId(levelId) or 1
end

function XBWMapAxisConversion:WorldToScreenPosition2D(x, y, z)
    local camera = CS.XUiManager.Instance.UiCamera

    if camera then
        return CS.XAxisConverter.Instance:WorldToScreenPoint(Vector3(x, y, z), camera)
    end

    return Vector2.zero
end

function XBWMapAxisConversion:WorldToMapPosition2D(x, y, pixelRatio)
    pixelRatio = self:_GetValidPixelRatio(pixelRatio)

    local offsetX = (x - self._OriginPos.x) * pixelRatio
    local offsetY = (y - self._OriginPos.y) * pixelRatio

    return Vector2(offsetX, offsetY)
end

function XBWMapAxisConversion:MapToWorldPosition2D(x, y, pixelRatio)
    pixelRatio = self:_GetValidPixelRatio(pixelRatio)

    local offsetX = x / pixelRatio + self._OriginPos.x
    local offsetY = y / pixelRatio + self._OriginPos.y

    return Vector2(offsetX, offsetY)
end

function XBWMapAxisConversion:ScreenToRectPosition2D(transform, x, y)
    return CS.XAxisConverter.Instance:ScreenToUILocalPoint(transform, Vector2(x, y), self._CanvasType)
end

function XBWMapAxisConversion:ScreenToWorldPosition2D(x, y)
    local camera = CS.XUiManager.Instance.UiCamera

    return CS.XAxisConverter.Instance:ScreenToWorldPoint(Vector2(x, y), camera)
end

function XBWMapAxisConversion:WorldToMapUIWorldPosition2D(transform, x, y, pixelRatio)
    local position = self:WorldToMapPosition2D(x, y, pixelRatio)
    local worldPosition = transform:TransformPoint(position.x, position.y, 0)

    return Vector2(worldPosition.x, worldPosition.y)
end

function XBWMapAxisConversion:UIToScreenPosition2D(transform)
    return CS.XAxisConverter.Instance:UIToScreenPoint(transform, self._CanvasType)
end

function XBWMapAxisConversion:ScreenToUIDistance(transform, distance, standardScreenWidth)
    local size = CS.UnityEngine.Screen.width / standardScreenWidth * distance
    local leftPos = self:ScreenToRectPosition2D(transform, -size, -size)
    local rightPos = self:ScreenToRectPosition2D(transform, size, size)

    return math.abs(rightPos.x - leftPos.x)
end

function XBWMapAxisConversion:ConversionAreaGroupColor(groupList, currentIndex)
    if not XTool.IsTableEmpty(groupList) then
        for i, imageList in pairs(groupList) do
            if not XTool.IsTableEmpty(imageList) then
                local aplha = 1

                if math.abs(i - currentIndex) == 1 then
                    aplha = 0.3
                elseif math.abs(i - currentIndex) > 1 then
                    aplha = 0
                end

                for _, image in pairs(imageList) do
                    image.color = CS.UnityEngine.Color(1, 1, 1, aplha)

                    if currentIndex == i then
                        image.transform:SetAsLastSibling()
                    end
                end
            end
        end
    end
end

---@param pinNodeMap table<number, XUiBigWorldMapPin>
function XBWMapAxisConversion:FilterScreenPointNearPinDataList(targetPos, pinNodeMap, groupId)
    local result = {}

    if not XTool.IsTableEmpty(pinNodeMap) then
        local distance = XMVCA.XBigWorldMap:GetNearDistance()

        for id, pinNode in pairs(pinNodeMap) do
            local position = pinNode.Transform.position
            local screenPos = self:UIToScreenPosition2D(pinNode.Transform)
            local pinData = pinNode:GetPinData()

            if self:CheckNearbyDistance(screenPos, targetPos, distance) and
                not self:CheckUnimportantPin(pinData, groupId) then
                if pinData then
                    table.insert(result, pinData)
                end
            end
        end
    end

    return result
end

function XBWMapAxisConversion:FilterOutScreenPlayerPosition(transform, targetTransform)
    local playerPos = self:GetCurrentNpcPosition()
    local trackPos = self:FilterOutScreenPosition(transform, targetTransform, playerPos.x, playerPos.z)

    return trackPos
end

---@param pinDatas table<number, XBWMapPinData>
function XBWMapAxisConversion:FilterOutScreenPinsPosition(pinDatas, transform, targetTransform, pixelRatio)
    local result = {}

    if not XTool.IsTableEmpty(pinDatas) then
        for _, pinData in pairs(pinDatas) do
            local pinPosition = pinData:GetWorldPosition2D()
            local trackPos = self:FilterOutScreenPosition(transform, targetTransform, pinPosition.x, pinPosition.y,
                pixelRatio)

            if trackPos then
                result[pinData.PinId] = trackPos
            end
        end
    end

    return result
end

function XBWMapAxisConversion:FilterOutScreenPosition(transform, targetTransform, posX, posY, pixelRatio)
    local result = nil
    local mapPosition = self:WorldToMapPosition2D(posX, posY, pixelRatio)
    local screenRect = self:GetScreenUIRect(transform)
    local targetRect = self:GetScreenUIRect(targetTransform)

    if not screenRect:Contains(mapPosition) then
        local centerPos = screenRect.center
        local trackPos = Vector2.zero
        local direction = Vector2.zero
        local xOffset = mapPosition.x - centerPos.x
        local yOffset = mapPosition.y - centerPos.y

        if mapPosition.x < screenRect.xMin then
            trackPos.x = -targetRect.width / 2
            direction.x = -1
        elseif mapPosition.x > screenRect.xMax then
            trackPos.x = targetRect.width / 2
            direction.x = 1
        else
            local ratio = (targetRect.height / 2) / math.abs(yOffset)

            trackPos.x = xOffset * ratio
            direction.x = 0
        end
        if mapPosition.y < screenRect.yMin then
            trackPos.y = -targetRect.height / 2
            direction.y = -1
        elseif mapPosition.y > screenRect.yMax then
            trackPos.y = targetRect.height / 2
            direction.y = 1
        else
            local ratio = (targetRect.width / 2) / math.abs(xOffset)

            trackPos.y = yOffset * ratio
            direction.y = 0
        end

        result = {
            Position = trackPos,
            Direction = direction,
            Priority = math.pow(xOffset, 2) + math.pow(yOffset, 2),
            Angle = Vector2.SignedAngle(Vector2.up, Vector2(xOffset, yOffset)),
        }
    end

    return result
end

function XBWMapAxisConversion:ConstrainingPointWithinEllipse(x, y, xAxis, yAxis)
    local u = x / xAxis
    local v = y / yAxis
    local magnitudeSqrt = math.pow(u, 2) + math.pow(v, 2)

    if magnitudeSqrt > 1 then
        local magnitude = math.sqrt(magnitudeSqrt)

        u = u / magnitude
        v = v / magnitude
    end

    return Vector2(u * xAxis, v * yAxis)
end

function XBWMapAxisConversion:CheckNearbyDistance(position, targetPosition, targetDistance)
    local xOffset = position.x - targetPosition.x
    local yOffset = position.y - targetPosition.y
    local distance = math.sqrt(math.pow(xOffset, 2) + math.pow(yOffset, 2))

    return distance <= targetDistance
end

---@param pinNode XBWMapPinData
function XBWMapAxisConversion:CheckUnimportantPin(pinData, groupId)
    if pinData then
        if not pinData.TeleportEnable and not XMVCA.XBigWorldMap:CheckPinTracking(pinData.LevelId, pinData.PinId) then
            if pinData:GetAreaGroupId(true) ~= groupId then
                return true
            end
        end

        return false
    end

    return true
end

function XBWMapAxisConversion:GetCurrentNpcTransform()
    return CS.StatusSyncFight.XFightClient.GetCurrentNpcTransform(false)
end

function XBWMapAxisConversion:GetCurrentNpcPosition()
    local transform = self:GetCurrentNpcTransform()

    return transform.position
end

function XBWMapAxisConversion:GetScreenUIRect(transform)
    return CS.XAxisConverter.Instance:GetScreenUILocalRect(transform, self._CanvasType)
end

function XBWMapAxisConversion:_GetValidPixelRatio(pixelRatio)
    if XTool.IsNumberValid(pixelRatio) then
        return pixelRatio
    end

    return self._PixelRatio
end

return XBWMapAxisConversion
