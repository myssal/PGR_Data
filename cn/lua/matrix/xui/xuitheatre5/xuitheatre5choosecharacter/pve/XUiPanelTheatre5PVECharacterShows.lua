--- 角色选择界面最开始的界面，展示所有角色
local XUiPanelTheatre5CharacterShows = require('XUi/XUiTheatre5/XUiTheatre5ChooseCharacter/XUiPanelTheatre5CharacterShows')
---@class XUiPanelTheatre5PVECharacterShows: XUiPanelTheatre5CharacterShows
---@field private _Control XTheatre5Control
---@field Parent XUiComTheatre5ChooseCharacter
local XUiPanelTheatre5PVECharacterShows = XClass(XUiPanelTheatre5CharacterShows, 'XUiPanelTheatre5PVECharacterShows')


function XUiPanelTheatre5PVECharacterShows:OnStart()
    self:InitBtnList()
    self.BtnClue.CallBack = handler(self, self.OnClickClueBoard)
end

function XUiPanelTheatre5PVECharacterShows:InitBtnList()
    for i = 1, 100 do
        local btn = self['Character'..i]

        if btn then
            local btnName = btn.gameObject.name
            btn.CallBack = function()
               self:CheckPVEChat(btnName, function()
                    local success = self.Parent:OnSelectCharacter(i, btn.gameObject.name)
                    if success then
                        self:Close()
                    end    
               end)
            end
        else
            break
        end
    end

    local buttons = self.Transform:GetComponentsInChildren(typeof(CS.XUiComponent.XUiButton))
    if buttons then
        for i = 0, buttons.Length - 1 do
            local btn = buttons[i]
            local btnName = btn.gameObject.name
            local startPos, _ = string.find(btnName, "^Character")
            if not startPos then
                buttons[i].CallBack = function() 
                    self:CheckPVEChat(btnName, function()
                        local success = self.Parent:OnSelectCharacter(nil, btnName)
                        if success then
                            self:Close()
                        end    
                    end)  
                end
            end    
        end
    end   
end

function XUiPanelTheatre5PVECharacterShows:CheckPVEChat(btnName, cb)
    --先执行故事线的对话触发
    local success = self._Control.FlowControl:CheckChatTrigger(XMVCA.XTheatre5.EnumConst.ChatTriggerType.ClickBtn, btnName, function()
        if not self.Parent then
            return
        end
        if self.Parent.SafeAreaContentPane then    
            self.Parent.SafeAreaContentPane.gameObject:SetActiveEx(true)
        end 
        cb()     
    end)
    if success then
        if self.Parent.SafeAreaContentPane then
            self.Parent.SafeAreaContentPane.gameObject:SetActiveEx(false)
        end
        return
    end          
    local entranceCfg = self._Control.PVEControl:GetPveStoryEntranceCfg(btnName)  --点的是一个没有故事线的普通物体
    if not entranceCfg then
        local chatGroupId,characters = self._Control.PVEControl:GetPveSceneChatClickObjectChatData(btnName)
        if not XTool.IsNumberValid(chatGroupId) then   
            return
        end
        self._Control.FlowControl:OpenPVEChat(chatGroupId, characters)
    else
        cb() 
    end       
end

function XUiPanelTheatre5PVECharacterShows:OnClickClueBoard()
    XLuaUiManager.Open('UiTheatre5PVEClueBoard')
end

return XUiPanelTheatre5PVECharacterShows