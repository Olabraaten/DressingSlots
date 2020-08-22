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
local showSettingsButton
local settingsDropdown

local updateSlots

-- Toggle buttons visibility
local function showButtons(show)
    for slot, button in pairs(buttons) do
        if show then
            button:Show()
        else
            button:Hide()
        end
    end
    if show then
        undressButton:Show()
        showSettingsButton:Show()
    else
        undressButton:Hide()
        showSettingsButton:Hide()
    end
end

-- Button click event
local function onClick(self, button)
	if button == "RightButton" then
		local slotID, slotTexture = GetInventorySlotInfo(self.slot)
        DressUpFrame.ModelScene:GetPlayerActor():UndressSlot(slotID)
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
local buttonSizeWithPadding = buttonSize + 5
local sideInsetLeft = 10
local sideInsetRight = 12
local topInset = -80

-- Create item slot buttons
for i, slot in ipairs(SLOTS) do
    local button = CreateFrame("Button", nil, DressUpFrame)
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
    button.slot = slot

    button.icon = button:CreateTexture(nil, "BACKGROUND")
    button.icon:SetSize(buttonSize, buttonSize)
    button.icon:SetPoint("CENTER")
    
    button.highlight = button:CreateTexture()
    button.highlight:SetSize(buttonSize, buttonSize)
    button.highlight:SetPoint("CENTER")
    button.highlight:SetAtlas("bags-glow-white")
    button.highlight:SetBlendMode("ADD")
    button:SetHighlightTexture(button.highlight)
    
    buttons[slot] = button
    if masqueGroup then
        masqueGroup:AddButton(button)
    end
end

-- Undress button
undressButton = CreateFrame("Button", nil, DressUpFrame, "UIPanelButtonTemplate")
undressButton:SetSize(80, 22)
undressButton:SetText("Undress")
undressButton:SetPoint("BOTTOMLEFT", 6, 4)
undressButton:SetScript("OnClick", function()
    DressUpFrame.ModelScene:GetPlayerActor():Undress()
    updateSlots()
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
showSettingsButton:SetPoint("BOTTOMLEFT", 85, 1)
showSettingsButton:SetScript("OnClick", function(self)
    ToggleDropDownMenu(1, nil, settingsDropdown, self, 0, 0)
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end)

-- Updates slot buttons content based on PlayerActor
updateSlots = function()
    local playerActor = DressUpFrame.ModelScene:GetPlayerActor()
    for slot, button in pairs(buttons) do
        local slotID, slotTexture = GetInventorySlotInfo(slot)
		local sourceID = playerActor:GetSlotTransmogSources(slotID)
		if sourceID == NO_TRANSMOG_SOURCE_ID or HIDDEN_SOURCES[sourceID] then
			button.item = nil
			button.text = nil
			button.icon:SetTexture(slotTexture)
			button:Disable()
		else
			local categoryID, appearanceID, canEnchant, icon, isCollected, link = C_TransmogCollection.GetAppearanceSourceInfo(sourceID)
			button.item = link
			button.text = UNKNOWN
			button.icon:SetTexture(icon or [[Interface\Icons\INV_Misc_QuestionMark]])
			button:Enable()
		end
    end
end

-- Hook onto PlayerActor creation in order to hook onto its functions
local _SetupPlayerForModelScene = SetupPlayerForModelScene
function SetupPlayerForModelScene(...)
    local resultSetupPlayerForModelScene = _SetupPlayerForModelScene(...)
    local playerActor = DressUpFrame.ModelScene:GetPlayerActor()
    if playerActor ~= nil then
        showButtons(true)

        if DressMode == START_UNDRESSED_MODE then
            DressUpFrame.ModelScene:GetPlayerActor():Undress()
        end

        -- Update slots when a gear piece has changed
        local _TryOn = playerActor.TryOn
        playerActor.TryOn = function (...)
          if DressMode == SINGLE_ITEM_MODE then
                DressUpFrame.ModelScene:GetPlayerActor():Undress()
            end
            local resultTryOn = _TryOn(...)
            updateSlots()
            return resultTryOn
        end

        -- Update slots when reset button has been pressed
        local _Dress = playerActor.Dress
        playerActor.Dress = function (...)
            local resultDress = _Dress(...)
            updateSlots()
            return resultDress
        end
        DressingWait(0.1, updateSlots, nil)
    end
    return resultSetupPlayerForModelScene
end

local _DressUpSources = DressUpSources
function DressUpSources(...)
    local resultDressUpSources = _DressUpSources(...)
    DressingWait(0.1, updateSlots, nil)
    return resultDressUpSources
end

-- Hide buttons for pet preview
local _DressUpBattlePet = DressUpBattlePet
function DressUpBattlePet(...)
    showButtons(false)
    return _DressUpBattlePet(...)
end

-- Hide buttons for mount preview
local _DressUpMount = DressUpMount
function DressUpMount(...)
    showButtons(false)
    return _DressUpMount(...)
end