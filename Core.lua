local Masque = LibStub("Masque", true)
local masqueGroup
if Masque then
    masqueGroup = Masque:Group("DressingSlots")
end

local SLOTS = {
	"HeadSlot",
	"ShoulderSlot",
	"BackSlot",
	"ChestSlot",
	"ShirtSlot",
	"TabardSlot",
	"WristSlot",
	
	"HandsSlot",
	"WaistSlot",
	"LegsSlot",
	"FeetSlot",
	
	"MainHandSlot",
	"SecondaryHandSlot",
}
local HIDDEN_SOURCES = {
	[77344] = true, -- head
	[77343] = true, -- shoulder
	[77345] = true, -- back
	[83202] = true, -- shirt
	[83203] = true, -- tabard
	[84223] = true, -- waist
}
local NORMAL_MODE = 1
local START_UNDRESSED_MODE = 2
local SINGLE_ITEM_MODE = 3
if DressMode == nil then
    DressMode = NORMAL_MODE
end

local buttons = {}
local undressButton
local toggleSheatheButton
local showSettingsButton
local settingsDropdown
local resizeButton

local updateSlots
local makePrimarySlotButton
local makeSecondarySlotButton

-- Toggle buttons visibility
local function showButtons(show)
    for slot, slotButtons in pairs(buttons) do
        for i, button in ipairs(slotButtons) do
            if show then
                if i == 1 then
                    button:Show()
                end
            else
                button:Hide()
            end
        end
    end
    if show then
        undressButton:Show()
        showSettingsButton:Show()
        toggleSheatheButton:Show()
    else
        undressButton:Hide()
        showSettingsButton:Hide()
        toggleSheatheButton:Hide()
    end
end

-- Button click event
local function onClick(self, button)
	if button == "RightButton" then
        local playerActor = DressUpFrame.ModelScene:GetPlayerActor()
        local slotID = GetInventorySlotInfo(self.slot)
        local itemTransmogInfo = playerActor:GetItemTransmogInfo(slotID)
        if itemTransmogInfo.secondaryAppearanceID ~= Constants.Transmog.NoTransmogID then
            itemTransmogInfo.appearanceID = itemTransmogInfo.secondaryAppearanceID
            itemTransmogInfo.secondaryAppearanceID = Constants.Transmog.NoTransmogID
            playerActor:SetItemTransmogInfo(itemTransmogInfo, slotID, false)
        else
            playerActor:UndressSlot(slotID)
        end
        updateSlots()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	elseif self.item and IsModifiedClick() then
		HandleModifiedItemClick(self.item)
	end
end

local function secondaryOnClick(self, button)
	if button == "RightButton" then
        local playerActor = DressUpFrame.ModelScene:GetPlayerActor()
        local slotID = GetInventorySlotInfo(self.slot)
        local itemTransmogInfo = playerActor:GetItemTransmogInfo(slotID)
        itemTransmogInfo.secondaryAppearanceID = Constants.Transmog.NoTransmogID
        playerActor:SetItemTransmogInfo(itemTransmogInfo, slotID, false)
        updateSlots()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	elseif self.item and IsModifiedClick() then
		HandleModifiedItemClick(self.item)
	end
end

-- Button hover event
local function onEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	if self.item then
		GameTooltip:SetHyperlink(self.item)
	else
		GameTooltip:SetText(self.text or _G[string.upper(self.slot)])
	end
end

-- Button size constants
local buttonSize = 35
local secondaryButtonSize = 25
local buttonSizeWithPadding = buttonSize + 5
local sideInsetLeft = 10
local sideInsetRight = 12
local topInset = -80

-- Create item slot buttons
makePrimarySlotButton = function(i, slot)
    local button = CreateFrame("Button", nil, DressUpFrame)
    button.slot = slot
    button:SetFrameStrata("HIGH")
    button:SetSize(buttonSize, buttonSize)
    if i <= 7 then
        button:SetPoint("TOPLEFT", sideInsetLeft, topInset + -buttonSizeWithPadding * (i - 1))
    else
        local place = i
        if i > 11 then
            place = place + 1
        end
        button:SetPoint("TOPRIGHT", -sideInsetRight, topInset + -buttonSizeWithPadding * (place - 8))
    end
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetMotionScriptsWhileDisabled(true)
    button:SetScript("OnClick", onClick)
    button:SetScript("OnEnter", onEnter)
    button:SetScript("OnLeave", GameTooltip_Hide)

    button.icon = button:CreateTexture(nil, "BACKGROUND")
    button.icon:SetSize(buttonSize, buttonSize)
    button.icon:SetPoint("CENTER")
    
    button.highlight = button:CreateTexture()
    button.highlight:SetSize(buttonSize, buttonSize)
    button.highlight:SetPoint("CENTER")
    button.highlight:SetAtlas("bags-glow-white")
    button.highlight:SetBlendMode("ADD")
    button:SetHighlightTexture(button.highlight)

    return button
end

makeSecondarySlotButton = function(i, slot)
    local button = CreateFrame("Button", nil, DressUpFrame)
    button.slot = slot
    button:SetFrameStrata("HIGH")
    button:SetSize(secondaryButtonSize, secondaryButtonSize)
    if i <= 7 then
        button:SetPoint("TOPLEFT", sideInsetLeft + buttonSizeWithPadding, topInset + -buttonSizeWithPadding * (i - 1))
    else
        local place = i
        if i > 11 then
            place = place + 1
        end
        button:SetPoint("TOPRIGHT", -sideInsetRight - buttonSizeWithPadding, topInset + -buttonSizeWithPadding * (place - 8))
    end
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetMotionScriptsWhileDisabled(true)
    button:SetScript("OnClick", secondaryOnClick)
    button:SetScript("OnEnter", onEnter)
    button:SetScript("OnLeave", GameTooltip_Hide)

    button.icon = button:CreateTexture(nil, "BACKGROUND")
    button.icon:SetSize(secondaryButtonSize, secondaryButtonSize)
    button.icon:SetPoint("CENTER")
    
    button.highlight = button:CreateTexture()
    button.highlight:SetSize(secondaryButtonSize, secondaryButtonSize)
    button.highlight:SetPoint("CENTER")
    button.highlight:SetAtlas("bags-glow-white")
    button.highlight:SetBlendMode("ADD")
    button:SetHighlightTexture(button.highlight)

    return button
end

for i, slot in ipairs(SLOTS) do
    local primaryButton = makePrimarySlotButton(i, slot)
    local secondaryButton = makeSecondarySlotButton(i, slot)
    
    buttons[slot] = {primaryButton, secondaryButton}
    if masqueGroup then
        masqueGroup:AddButton(primaryButton)
        masqueGroup:AddButton(secondaryButton)
    end
end

-- Undress button
undressButton = CreateFrame("Button", nil, DressUpFrame, "UIPanelButtonTemplate")
undressButton:SetSize(80, 22)
undressButton:SetText("Undress")
undressButton:SetPoint("BOTTOMLEFT", 7, 4)
undressButton:SetScript("OnClick", function()
    DressUpFrame.ModelScene:GetPlayerActor():Undress()
    updateSlots()
    PlaySound(SOUNDKIT.GS_TITLE_OPTION_OK)
end)

-- Toggle sheathe button
toggleSheatheButton = CreateFrame("Button", nil, DressUpFrame, "UIPanelButtonTemplate")
toggleSheatheButton:SetSize(120, 22)
toggleSheatheButton:SetText("Toggle sheathe")
toggleSheatheButton:SetPoint("BOTTOMLEFT", 87, 4)
toggleSheatheButton:SetScript("OnClick", function()
    local playerActor = DressUpFrame.ModelScene:GetPlayerActor()
    playerActor:SetSheathed(not playerActor:GetSheathed())
    PlaySound(SOUNDKIT.GS_TITLE_OPTION_OK)
end)

-- Settings dropdown
settingsDropdown = CreateFrame("Frame", "DressingSlotsSettingsDropdown", nil, "UIDropDownMenuTemplate")
settingsDropdown.initialize = function(self, level)
    local info = UIDropDownMenu_CreateInfo()

    info.isTitle = 1
    info.text = "DressingSlots mode"
    info.notCheckable = 1
    UIDropDownMenu_AddButton(info, level)

    info.disabled = nil
    info.isTitle = nil
    info.notCheckable = nil
    info.text = "Normal"
    info.checked = function()
        return DressMode == NORMAL_MODE
    end
    info.func = function()
        DressMode = NORMAL_MODE
    end
    UIDropDownMenu_AddButton(info, level)
    info.text = "Start undressed"
    info.checked = function()
        return DressMode == START_UNDRESSED_MODE
    end
    info.func = function()
        DressMode = START_UNDRESSED_MODE
    end
    UIDropDownMenu_AddButton(info, level)
    info.text = "Single item"
    info.checked = function()
        return DressMode == SINGLE_ITEM_MODE
    end
    info.func = function()
        DressMode = SINGLE_ITEM_MODE
    end
    UIDropDownMenu_AddButton(info, level)
end

-- Settings dropdown toggle button
showSettingsButton = CreateFrame("DropDownToggleButton", "ShowSettingsButton", DressUpFrame)
showSettingsButton:SetSize(27, 27)
showSettingsButton:SetNormalTexture("Interface/ChatFrame/UI-ChatIcon-ScrollDown-Up")
showSettingsButton:SetPushedTexture("Interface/ChatFrame/UI-ChatIcon-ScrollDown-Down")
showSettingsButton:SetHighlightTexture("Interface/Buttons/UI-Common-MouseHilight", "ADD")
showSettingsButton:SetPoint("BOTTOMLEFT", 207, 1)
showSettingsButton:SetScript("OnClick", function(self)
    ToggleDropDownMenu(1, nil, settingsDropdown, self, 0, 0)
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end)

-- Resize window button
resizeButton = CreateFrame("Button", nil, DressUpFrame)
resizeButton:SetSize(16, 16)
resizeButton:SetNormalTexture("Interface/ChatFrame/UI-ChatIM-SizeGrabber-Up")
resizeButton:SetHighlightTexture("Interface/ChatFrame/UI-ChatIM-SizeGrabber-Highlight")
resizeButton:SetPushedTexture("Interface/ChatFrame/UI-ChatIM-SizeGrabber-Down")
resizeButton:SetPoint("BOTTOMRIGHT", -2, 2)
resizeButton:SetScript("OnMouseDown", function(self, button)
    DressUpFrame:StartSizing("BOTTOMRIGHT")
end)
resizeButton:SetScript("OnMouseUp", function(self, button)
    DressUpFrame:StopMovingOrSizing()
    UpdateUIPanelPositions(self)
    DressHeight = DressUpFrame:GetHeight()
    DressWidth = DressUpFrame:GetWidth()
end)

-- Updates slot buttons content based on PlayerActor
updateSlots = function()
    local playerActor = DressUpFrame.ModelScene:GetPlayerActor()
    if playerActor then
        for slot, slotButtons in pairs(buttons) do
            local primaryButton = slotButtons[1]
            local secondaryButton = slotButtons[2]
            local slotID, slotTexture = GetInventorySlotInfo(slot)
            local itemTransmogInfo = playerActor:GetItemTransmogInfo(slotID)
		    if itemTransmogInfo == nil or HIDDEN_SOURCES[itemTransmogInfo.appearanceID] then
			    primaryButton.item = nil
			    primaryButton.text = nil
			    primaryButton.icon:SetTexture(slotTexture)
			    primaryButton:Disable()
		    else
			    local categoryID, appearanceID, canEnchant, icon, isCollected, link = C_TransmogCollection.GetAppearanceSourceInfo(itemTransmogInfo.appearanceID)
			    primaryButton.item = link
			    primaryButton.text = UNKNOWN
			    primaryButton.icon:SetTexture(icon or [[Interface\Icons\INV_Misc_QuestionMark]])
			    primaryButton:Enable()
		    end
            if itemTransmogInfo ~= nil and itemTransmogInfo.secondaryAppearanceID ~= Constants.Transmog.NoTransmogID and not HIDDEN_SOURCES[itemTransmogInfo.secondaryAppearanceID] then
                local categoryID, appearanceID, canEnchant, icon, isCollected, link = C_TransmogCollection.GetAppearanceSourceInfo(itemTransmogInfo.secondaryAppearanceID)
			    secondaryButton.item = link
			    secondaryButton.text = UNKNOWN
			    secondaryButton.icon:SetTexture(icon or [[Interface\Icons\INV_Misc_QuestionMark]])
			    secondaryButton:Enable()
                if DressUpFrame.ResetButton:IsShown() then
                    secondaryButton:Show()
                end
            else
                secondaryButton:Hide()
            end
        end
    end
end

-- Hook onto save button update events to trigger slot updates
local _DressUpFrameOutfitDropDown_UpdateSaveButton = DressUpFrameOutfitDropDown.UpdateSaveButton
function DressUpFrameOutfitDropDown:UpdateSaveButton(...)
    if DressMode == SINGLE_ITEM_MODE then
        DressUpFrame.ModelScene:GetPlayerActor():Undress()
    end
    updateSlots()
    return _DressUpFrameOutfitDropDown_UpdateSaveButton(self, ...)
end

-- Hook onto PlayerActor creation in order to hook onto its functions
local _SetupPlayerForModelScene = SetupPlayerForModelScene
function SetupPlayerForModelScene(...)
    -- Resize stuff
    DressUpFrameCancelButton:SetPoint("BOTTOMRIGHT", -20, 4)
    DressUpFrame:SetResizable(true)
    DressUpFrame:SetMinResize(334, 423)
    DressUpFrame:SetMaxResize(DressUpFrame:GetTop() * 0.8, DressUpFrame:GetTop())
    if DressHeight and DressHeight <= DressUpFrame:GetTop() and DressWidth <= (DressUpFrame:GetTop()) then
        DressUpFrame:SetSize(DressWidth, DressHeight)
        UpdateUIPanelPositions(self)
    end
    -- Listen for minimize/maximize to reset size
    local maximize = DressUpFrame.MaximizeMinimizeFrame.MaximizeButton:GetScript("OnClick")
    DressUpFrame.MaximizeMinimizeFrame.MaximizeButton:SetScript("OnClick", function(self)
        DressHeight = nil
        DressWidth = nil
        maximize(self)
    end)
    local minimize = DressUpFrame.MaximizeMinimizeFrame.MinimizeButton:GetScript("OnClick")
    DressUpFrame.MaximizeMinimizeFrame.MinimizeButton:SetScript("OnClick", function(self)
        DressHeight = nil
        DressWidth = nil
        minimize(self)
    end)

    local resultSetupPlayerForModelScene = _SetupPlayerForModelScene(...)
    local playerActor = DressUpFrame.ModelScene:GetPlayerActor()
    if playerActor then
        if DressMode == START_UNDRESSED_MODE then
            DressUpFrame.ModelScene:GetPlayerActor():Undress()
        end

        -- Nasty workaround for when shoulders have been undressed while secondary appearance is active
        local _GetItemTransmogInfo = playerActor.GetItemTransmogInfo
        function playerActor:GetItemTransmogInfo(slotId, ...)
            local result = _GetItemTransmogInfo(self, slotId, ...)
            if not result and slotId == 3 then
                result = ItemUtil.CreateItemTransmogInfo(77343)
            end
        return result
        end
    end

    return resultSetupPlayerForModelScene
end

DressUpFrame.ResetButton:HookScript("OnHide", function ()
    showButtons(false)
end)
DressUpFrame.ResetButton:HookScript("OnShow", function ()
    showButtons(true)
end)
