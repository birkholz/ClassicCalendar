local AddonName, AddonTable = ...
local L = CLASSIC_CALENDAR_L
local AddonTitle = C_AddOns.GetAddOnMetadata(AddonName, "Title")

CCConfig = {}

local CCOptions = CreateFrame("Frame")
local localeStringOptions
CCOptions:RegisterEvent("ADDON_LOADED")
CCOptions:RegisterEvent("VARIABLES_LOADED")

local localeString = tostring(GetLocale())

-- Checks localizations for Options and returns "enUS" if none exist

local function checkLocale()
	for _, v in next, L.Options[localeString] do
		if v == "" then
			localeStringOptions = "enUS"
			break
		end
		localeStringOptions = localeString
	end
end

-- Runs function above

checkLocale()

-- INTERFACE OPTIONS (starts building the frame now)

local CCIOFrame = CreateFrame("Frame")
CCIOFrame.name = AddonTitle

local InterfaceOptionsFramePanelContainerWidth = InterfaceOptionsFramePanelContainer:GetWidth()

-- Header

local lblTitle = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
lblTitle:SetFont("Fonts\\FRIZQT__.TTF", 16)
lblTitle:SetPoint("TOPLEFT", CCIOFrame, "TOPLEFT", 12, -12)
lblTitle:SetText("|cFFEFC502" .. AddonTitle .. " (v" .. C_AddOns.GetAddOnMetadata(AddonName, "Version") .. ")|r")

-- HR line for Art options
local hrLine1_p1 = CCIOFrame:CreateLine()
hrLine1_p1:SetColorTexture(0.5, 0.5, 0.5)
hrLine1_p1:SetThickness(1)
hrLine1_p1:SetStartPoint("TOPLEFT", lblTitle, 0, -32)
hrLine1_p1:SetEndPoint("TOPLEFT", lblTitle, (InterfaceOptionsFramePanelContainerWidth/2)-20, -32)

local hrLineText = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
hrLineText:SetFont("Fonts\\FRIZQT__.TTF", 14)
hrLineText:SetPoint("CENTER", hrLine1_p1, "LEFT", (InterfaceOptionsFramePanelContainerWidth/2), 0)
hrLineText:SetText("|cFFEFC502Art|r")

local hrLine1_p2 = CCIOFrame:CreateLine()
hrLine1_p2:SetColorTexture(0.5, 0.5, 0.5)
hrLine1_p2:SetThickness(1)
hrLine1_p2:SetStartPoint("TOPLEFT", hrLine1_p1, (InterfaceOptionsFramePanelContainerWidth/2)+20, 0)
hrLine1_p2:SetEndPoint("TOPLEFT", hrLine1_p1, InterfaceOptionsFramePanelContainerWidth, 0)

-- PVP weekends

local chkIOUsePVPArts = CreateFrame("CheckButton", nil, CCIOFrame, "OptionsBaseCheckButtonTemplate")
chkIOUsePVPArts:SetPoint("TOPLEFT", hrLine1_p1, "BOTTOMLEFT", 0, -16)

chkIOUsePVPArts:SetScript("OnUpdate", function(frame)
	if CCConfig.BattlegroundsArt == "ENABLED" then
		chkIOUsePVPArts:SetChecked(true)
	elseif CCConfig.BattlegroundsArt == "DISABLED" then
		chkIOUsePVPArts:SetChecked(false)
	end
end)

chkIOUsePVPArts:SetScript("OnClick", function(frame)
	local tick = frame:GetChecked()
	if tick == false then
		CCConfig.BattlegroundsArt = 'DISABLED'
	elseif tick == true then
		CCConfig.BattlegroundsArt = 'ENABLED'
	end
end)

local chkIOUsePVPArtsText = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
chkIOUsePVPArtsText:SetPoint("LEFT", chkIOUsePVPArts, "RIGHT", 0, 1)
chkIOUsePVPArtsText:SetText(L.Options[localeStringOptions]["PVPArtText"])

-- Childrens Week

local chkIOShowChildrensWeek = CreateFrame("CheckButton", nil, CCIOFrame, "OptionsBaseCheckButtonTemplate")
chkIOShowChildrensWeek:SetPoint("TOPLEFT", chkIOUsePVPArts, "BOTTOMLEFT", 0, -8) -- Second arguement is the previous local variable name

chkIOShowChildrensWeek:SetScript("OnUpdate", function(frame)
	if CCConfig.ChildrensWeekArt == "ENABLED" then
		chkIOShowChildrensWeek:SetChecked(true)
	elseif CCConfig.ChildrensWeekArt == "DISABLED" then
		chkIOShowChildrensWeek:SetChecked(false)
	end
end)

chkIOShowChildrensWeek:SetScript("OnClick", function(frame)
	local tick = frame:GetChecked()

	if tick == false then
		CCConfig.ChildrensWeekArt = 'DISABLED'
	elseif tick == true then
		CCConfig.ChildrensWeekArt = 'ENABLED'
	end
end)

local chkIOShowChildrensWeekText = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
chkIOShowChildrensWeekText:SetPoint("LEFT", chkIOShowChildrensWeek, "RIGHT", 0, 1)
chkIOShowChildrensWeekText:SetText(L.Options[localeStringOptions]["ChildrensWeekText"])

-- Fireworks Spectacular

local chkIOShowFireworksSpectacular = CreateFrame("CheckButton", nil, CCIOFrame, "OptionsBaseCheckButtonTemplate")
chkIOShowFireworksSpectacular:SetPoint("TOPLEFT", chkIOShowChildrensWeek, "BOTTOMLEFT", 0, -8) -- Second arguement is the previous local variable name

chkIOShowFireworksSpectacular:SetScript("OnUpdate", function(frame)
	if CCConfig.FireworksSpectacularArt == "ENABLED" then
		chkIOShowFireworksSpectacular:SetChecked(true)
	elseif CCConfig.FireworksSpectacularArt == "DISABLED" then
		chkIOShowFireworksSpectacular:SetChecked(false)
	end
end)

chkIOShowFireworksSpectacular:SetScript("OnClick", function(frame)
	local tick = frame:GetChecked()

	if tick == false then
		CCConfig.FireworksSpectacularArt = 'DISABLED'
	elseif tick == true then
		CCConfig.FireworksSpectacularArt = 'ENABLED'
	end
end)

local chkIOShowFireworksSpectacularText = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
chkIOShowFireworksSpectacularText:SetPoint("LEFT", chkIOShowFireworksSpectacular, "RIGHT", 0, 1)
chkIOShowFireworksSpectacularText:SetText(L.Options[localeStringOptions]["FireworksSpectacularText"])

-- HR line for Footer

local hrLine2 = CCIOFrame:CreateLine()
hrLine2:SetColorTexture(0.5, 0.5, 0.5)
hrLine2:SetThickness(1)
hrLine2:SetStartPoint("TOPLEFT", chkIOShowFireworksSpectacular, 0, -41)
hrLine2:SetEndPoint("TOPLEFT", chkIOShowFireworksSpectacular, InterfaceOptionsFramePanelContainerWidth, -41)

-- Discord Info

local DiscordLogo = CCIOFrame:CreateTexture(nil, "OVERLAY")
DiscordLogo:SetPoint("TOPLEFT", hrLine2, "BOTTOMLEFT", 0, -16) -- Second arguement is the previous local variable name
DiscordLogo:SetSize(16, 16)
DiscordLogo:SetTexture("Interface\\AddOns\\ClassicCalendar\\Textures\\DiscordLogo.tga")

local lblDiscord = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
lblDiscord:SetPoint("LEFT", DiscordLogo, "RIGHT", 4, 0)
lblDiscord:SetText("|cFFEFC502https://discord.gg/CMxKsBQFKp|r")

InterfaceOptions_AddCategory(CCIOFrame);

--[[
-- Dropdown

local lblIODropdownText = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
lblIODropdownText:SetPoint("TOPLEFT", lblDiscord, "BOTTOMLEFT", 0, -8) -- Second arguement is the previous local variable name
lblIODropdownText:SetText("Dropdown:")

-- Create the dropdown, and configure its appearance
local ddDropdown = CreateFrame("FRAME", "CCFontSize", CCIOFrame, "UIDropDownMenuTemplate")
ddDropdown:SetPoint("LEFT", lblIODropdownText, "RIGHT", 0, 1)
if GetLocale() == "frFR" then
	UIDropDownMenu_SetWidth(ddDropdown, 128)
else
	UIDropDownMenu_SetWidth(ddDropdown, 96)
end
UIDropDownMenu_SetText(ddDropdown, "Select One")

-- Create and bind the initialization function to the dropdown menu
UIDropDownMenu_Initialize(ddDropdown, function(self, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	info.func = self.SetValue
	info.text, info.arg1 = "Value1", "Value1"
	UIDropDownMenu_AddButton(info)
	info.text, info.arg1 = "Value2", "Value2"
	UIDropDownMenu_AddButton(info)
	info.text, info.arg1 = "Value3", "Value3"
	UIDropDownMenu_AddButton(info)
	info.text, info.arg1 = "Value4", "Value4"
	UIDropDownMenu_AddButton(info)
	info.text, info.arg1 = "Value5", "Value5"
	UIDropDownMenu_AddButton(info)
end)

-- Implement the function to change the dropdown value
function ddDropdown:SetValue(newValue)
	CCConfig.Dropdown = newValue
	DEFAULT_CHAT_FRAME:AddMessage("|cFF0088FF[" .. "ClassicCalendar" .. "]|r " .. "Dropdown changed to" .. " " .. newValue .. ".")
	-- Update the text; if we merely wanted it to display newValue, we would not need to do this
	UIDropDownMenu_SetText(ddDropdown, CCConfig.Dropdown)
	-- Because this is called from a sub-menu, only that menu level is closed by default.
	-- Close the entire menu with this next call
	CloseDropDownMenus()
end
]]--

-- Config Sash Command Handler

local function ccconfiguration(msg, editbox)
	if msg == "" or msg == nil then
		InterfaceOptionsFrame_OpenToCategory(AddonTitle)
		InterfaceOptionsFrame_OpenToCategory(AddonTitle) -- Second call works around the issue detailed at Stanzilla/WoWUIBugs/issues/89
	end
end

local function CCOptionsHandler(self, event, arg1)
	-- If SavedVariable is not set, default settings
	if event == "ADDON_LOADED" then
		if next(CCConfig) == nil then
			CCConfig = {
				["BattlegroundsArt"] = "DISABLED",
				["ChildrensWeekArt"] = "DISABLED",
				["FireworksSpectacularArt"] = "DISABLED",
				--["Dropdown"] = "Value1",
			}
		end
	end

	if event == "VARIABLES_LOADED" then
		SlashCmdList["CCCONFIG"] = ccconfiguration;
		SLASH_CCCONFIG1, SLASH_CCCONFIG2 = "/caloptions", "/calendaroptions"
	end
end

CCOptions:SetScript("OnEvent", CCOptionsHandler)

