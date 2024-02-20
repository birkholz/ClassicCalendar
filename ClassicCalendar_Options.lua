local AddonName, AddonTable = ...
local L = CLASSIC_CALENDAR_L
local AddonTitle = C_AddOns.GetAddOnMetadata(AddonName, "Title")

local localeString = tostring(GetLocale())
local CCOptions = CreateFrame("Frame")
CCOptions:RegisterEvent("ADDON_LOADED")
CCOptions:RegisterEvent("VARIABLES_LOADED")

function GoToCCSettings(msg, editbox)
	if msg == "" or msg == nil then
		InterfaceOptionsFrame_OpenToCategory(AddonTitle)
		InterfaceOptionsFrame_OpenToCategory(AddonTitle) -- Second call works around the issue detailed at Stanzilla/WoWUIBugs/issues/89
	end
end

local defaultOptions = {
	["BattlegroundsArt"] = false,
	["ChildrensWeekArt"] = false,
	["FireworksSpectacularArt"] = true,
	["HideCalendarButton"] = false,
	["StartDay"] = nil,
	["SendRaidWarning"] = false,
	["PlayAlarmSound"] = false,
	["FlashCalButton"] = false,
	["UnlockCalendarButton"] = false,
	["AlarmNumber"] = 15,
	["AlarmUnit"] = "minute"
}

local function ToggleCalButtonLock(checked)
	if checked then
		CalendarButtonFrame:SetMovable(true)
		CalendarButtonFrame:SetScript("OnDragStart", CalendarButtonFrame.StartMoving)
		CalendarButtonFrame:SetScript("OnDragStop", CalendarButtonFrame.StopMovingOrSizing)
	else
		CalendarButtonFrame:SetParent(MinimapCluster)
		CalendarButtonFrame:SetFrameLevel(CalendarButtonFrame:GetFrameLevel() + 2)
		CalendarButtonFrame:SetMovable(false)
		CalendarButtonFrame:ClearAllPoints()
		CalendarButtonFrame:SetPoint("TOPRIGHT", MinimapCluster, "TOPRIGHT", 2, -24)
		CalendarButtonFrame:SetScript("OnDragStart", function() end)
		CalendarButtonFrame:SetScript("OnDragStop", function() end)
	end
end

-- Checks localizations for Options and falls back to enUS if any are missing

local function checkLocale()
	for k, v in next, L.Options[localeString] do
		if v == "" then
			L.Options[localeString][k] = L.Options["enUS"][k]
		end
	end
end

-- Runs function above

checkLocale()

-- Randomization of attribution names

local function shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
end

local randomName = {"Toxiix-WildGrowth(NA)", "Lovediodes-WildGrowth(NA)"}
shuffle(randomName) -- Randomize order of displayed names

-- INTERFACE OPTIONS (starts building the frame now)

local CCIOFrame = CreateFrame("Frame")
CCIOFrame.name = AddonTitle

local InterfaceOptionsFramePanelContainerWidth = InterfaceOptionsFramePanelContainer:GetWidth()

local function createHorizontalRule(text, anchorFrame)
	local hrLine_p1 = CCIOFrame:CreateLine()
	hrLine_p1:SetColorTexture(0.5, 0.5, 0.5)
	hrLine_p1:SetThickness(1)
	hrLine_p1:SetStartPoint("TOPLEFT", anchorFrame, 0, -32)
	hrLine_p1:SetEndPoint("TOPLEFT", anchorFrame, (InterfaceOptionsFramePanelContainerWidth/2)-36, -32)

	local hrLineText = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
	hrLineText:SetFont("Fonts\\FRIZQT__.TTF", 14)
	hrLineText:SetPoint("CENTER", hrLine_p1, "LEFT", (InterfaceOptionsFramePanelContainerWidth/2), 0)
	hrLineText:SetText("|cFFEFC502"..text.."|r")
	local textWidth = hrLineText:GetWidth()
	hrLine_p1:SetEndPoint("TOPLEFT", anchorFrame, (InterfaceOptionsFramePanelContainerWidth/2)-((textWidth/2) + 8), -32)

	local hrLine_p2 = CCIOFrame:CreateLine()
	hrLine_p2:SetColorTexture(0.5, 0.5, 0.5)
	hrLine_p2:SetThickness(1)
	hrLine_p2:SetStartPoint("TOPLEFT", hrLine_p1, (InterfaceOptionsFramePanelContainerWidth/2)+((textWidth/2) + 8), 0)
	hrLine_p2:SetEndPoint("TOPLEFT", hrLine_p1, InterfaceOptionsFramePanelContainerWidth, 0)

	return hrLine_p1
end

-- Header

local lblTitle = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
lblTitle:SetFont("Fonts\\FRIZQT__.TTF", 16)
lblTitle:SetPoint("TOPLEFT", CCIOFrame, "TOPLEFT", 12, -12)
lblTitle:SetText("|cFFEFC502" .. AddonTitle .. " (v" .. C_AddOns.GetAddOnMetadata(AddonName, "Version") .. ")|r")

-- HR line for General options
local horizRule1 = createHorizontalRule(L.Options[localeString]["GeneralHeaderText"], lblTitle)

-- Set starting weekday

local startingWeekdayDropdownText = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
startingWeekdayDropdownText:SetPoint("TOPLEFT", horizRule1, "BOTTOMLEFT", 0, -20) -- Second arguement is the previous local variable name
startingWeekdayDropdownText:SetText(L.Options[localeString]["StartWeekText"]..":")

local startingWeekdayDropdown = CreateFrame("FRAME", "CCFontSize", CCIOFrame, "UIDropDownMenuTemplate")
startingWeekdayDropdown:SetPoint("LEFT", startingWeekdayDropdownText, "RIGHT", 0, -3)
UIDropDownMenu_SetWidth(startingWeekdayDropdown, 120)

local function InitStartingWeekdayDropdown(self, level, menuList)
    local info = UIDropDownMenu_CreateInfo()
    info.func = self.SetValue
    info.text, info.arg1, info.arg2 = L.Options[localeString]["SelectDefaultText"], L.Options[localeString]["SelectDefaultText"], nil
	info.checked = CCConfig.StartDay == nil and true or false
    UIDropDownMenu_AddButton(info)
    info.text, info.arg1, info.arg2 = WEEKDAY_SUNDAY, WEEKDAY_SUNDAY, 1
	info.checked = CCConfig.StartDay == 1 and true or false
    UIDropDownMenu_AddButton(info)
    info.text, info.arg1, info.arg2 = WEEKDAY_MONDAY, WEEKDAY_MONDAY, 2
	info.checked = CCConfig.StartDay == 2 and true or false
    UIDropDownMenu_AddButton(info)
end

local startingWeekdayText = L.Options[localeString]["SelectDayText"]

function startingWeekdayDropdown:SetValue(newStartingWeekdayText, newStartingWeekdayNumber)
	startingWeekdayText = newStartingWeekdayText
	CCConfig.StartDay = newStartingWeekdayNumber
    CloseDropDownMenus()
end

-- Loads current selected Start Week Day (if any) and updates dropdown menu text
local function DropdownSelectionHandler()
	if CCConfig.StartDay == false or CCConfig.StartDay == nil then
		startingWeekdayText = L.Options[localeString]["SelectDayText"]
	elseif CCConfig.StartDay == 1 then
		startingWeekdayText = WEEKDAY_SUNDAY
	elseif CCConfig.StartDay == 2 then
		startingWeekdayText = WEEKDAY_MONDAY
	end
end

startingWeekdayDropdown:SetScript("OnShow", DropdownSelectionHandler)

startingWeekdayDropdown:SetScript("OnUpdate", function(frame)
	UIDropDownMenu_SetText(startingWeekdayDropdown, startingWeekdayText)
end)

-- Unlock the Calendar Button

local unlockCalButton = CreateFrame("CheckButton", nil, CCIOFrame, "OptionsBaseCheckButtonTemplate")
unlockCalButton:SetPoint("TOPLEFT", startingWeekdayDropdownText, "BOTTOMLEFT", 0, -16)

unlockCalButton:SetScript("OnUpdate", function(frame)
	unlockCalButton:SetChecked(CCConfig.UnlockCalendarButton)
end)

unlockCalButton:HookScript("OnClick", function(frame)
	local checked = frame:GetChecked()
	CCConfig.UnlockCalendarButton = checked
	ToggleCalButtonLock(checked)
end)

local unlockCalButtonText = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
unlockCalButtonText:SetPoint("LEFT", unlockCalButton, "RIGHT", 0, 1)
unlockCalButtonText:SetText(L.Options[localeString]["UnlockCalButtonText"])

local unlockCalButtonDesc = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
unlockCalButtonDesc:SetPoint("LEFT", unlockCalButton, "LEFT", 0, -24)
unlockCalButtonDesc:SetText("|cFF9CD6DE"..L.Options[localeString]["UnlockCalButtonDesc"].."|r")

-- Hide the Calendar Button

local chkIOHideCalButton = CreateFrame("CheckButton", nil, CCIOFrame, "OptionsBaseCheckButtonTemplate")
chkIOHideCalButton:SetPoint("TOPLEFT", unlockCalButton, "BOTTOMLEFT", 0, -24)

chkIOHideCalButton:SetScript("OnUpdate", function(frame)
	chkIOHideCalButton:SetChecked(CCConfig.HideCalendarButton)
end)

chkIOHideCalButton:HookScript("OnClick", function(frame)
	local checked = frame:GetChecked()
	CCConfig.HideCalendarButton = checked
	if checked then
		CalendarButtonFrame:Hide()
	else
		CalendarButtonFrame:Show()
	end
end)

local chkIOHideCalButtonText = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
chkIOHideCalButtonText:SetPoint("LEFT", chkIOHideCalButton, "RIGHT", 0, 1)
chkIOHideCalButtonText:SetText(L.Options[localeString]["HideCalButtonText"])

local chkIOHideCalButtonDesc = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
chkIOHideCalButtonDesc:SetPoint("LEFT", chkIOHideCalButton, "LEFT", 0, -24)
chkIOHideCalButtonDesc:SetText("|cFF9CD6DE"..L.Options[localeString]["HideCalButtonDesc"].."|r")

-- HR line for event alarm options
local horizRule3 = createHorizontalRule(L.Options[localeString]["EventAlarmsHeaderText"], chkIOHideCalButtonDesc)

local eventAlarmsDesc = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
eventAlarmsDesc:SetPoint("LEFT", horizRule3, "LEFT", 0, -24)
eventAlarmsDesc:SetText("|cFF9CD6DE"..L.Options[localeString]["EventAlarmsDesc"].."|r")

--- Event alarm time

local eventAlarmTimeText = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
eventAlarmTimeText:SetPoint("TOPLEFT", eventAlarmsDesc, "BOTTOMLEFT", 0, -16)
eventAlarmTimeText:SetText(L.Options[localeString]["EventAlarmFrontText"])

local function InitEventAlarmNumberDropdown(self, level, menuList)
    local info = UIDropDownMenu_CreateInfo()
    info.func = self.SetValue
	local startN, endN, stepN
	if CCConfig.AlarmUnit == "minute" then
		startN, endN, stepN = 5, 55, 5
	elseif CCConfig.AlarmUnit == "hour" then
		startN, endN, stepN = 1, 24, 1
	end
	for num = startN, endN, stepN do
		info.text, info.arg1 = num, num
		info.checked = CCConfig.AlarmNumber == num and true or false
		UIDropDownMenu_AddButton(info)
	end
end

local eventAlarmNumberDropdown = CreateFrame("FRAME", "CCFontSize", CCIOFrame, "UIDropDownMenuTemplate")
eventAlarmNumberDropdown:SetPoint("LEFT", eventAlarmTimeText, "RIGHT", -12, -3)
UIDropDownMenu_SetWidth(eventAlarmNumberDropdown, 48)

function eventAlarmNumberDropdown:SetValue(newValue)
	CCConfig.AlarmNumber = newValue
    CloseDropDownMenus()
end

eventAlarmNumberDropdown:SetScript("OnUpdate", function(frame)
	UIDropDownMenu_SetText(eventAlarmNumberDropdown, CCConfig.AlarmNumber)
end)

local eventAlarmUnitDropdown = CreateFrame("FRAME", "CCFontSize", CCIOFrame, "UIDropDownMenuTemplate")
eventAlarmUnitDropdown:SetPoint("LEFT", eventAlarmNumberDropdown, "RIGHT", -32, 0)
UIDropDownMenu_SetWidth(eventAlarmUnitDropdown, 80)

local function InitEventAlarmUnitDropdown(self, level, menuList)
    local info = UIDropDownMenu_CreateInfo()
    info.func = self.SetValue
    info.text, info.arg1 = "minutes", "minute"
	info.checked = CCConfig.AlarmUnit == "minute" and true or false
    UIDropDownMenu_AddButton(info)
    info.text, info.arg1 = "hours", "hour"
	info.checked = CCConfig.AlarmUnit == "hour" and true or false
    UIDropDownMenu_AddButton(info)
end

function eventAlarmUnitDropdown:SetValue(newUnitText)
	CCConfig.AlarmUnit = newUnitText
	if newUnitText == "minute" then
		CCConfig.AlarmNumber = 15
	elseif newUnitText == "hour" then
		CCConfig.AlarmNumber = 1
	end
	UIDropDownMenu_Initialize(eventAlarmNumberDropdown, InitEventAlarmNumberDropdown)
    CloseDropDownMenus()
end

eventAlarmUnitDropdown:SetScript("OnUpdate", function(frame)
	local pluralUnit
	if CCConfig.AlarmUnit == "hour" then
		if CCConfig.AlarmNumber == 1 then
			pluralUnit = L.Options[localeString]["HourSingular"]
		else
			pluralUnit = L.Options[localeString]["HourPlural"]
		end
	else
		pluralUnit = L.Options[localeString]["MinutePlural"]
	end
	UIDropDownMenu_SetText(eventAlarmUnitDropdown, pluralUnit)
end)

local eventAlarmTimeEndingText = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
eventAlarmTimeEndingText:SetPoint("LEFT", eventAlarmUnitDropdown, "RIGHT", -8, 3)
eventAlarmTimeEndingText:SetText(L.Options[localeString]["EventAlarmBackText"])


-- Flash Calendar Button

local flashCalButtonButton = CreateFrame("CheckButton", nil, CCIOFrame, "OptionsBaseCheckButtonTemplate")
flashCalButtonButton:SetPoint("TOPLEFT", eventAlarmTimeText, "BOTTOMLEFT", 0, -16)

flashCalButtonButton:SetScript("OnUpdate", function(frame)
	flashCalButtonButton:SetChecked(CCConfig.FlashCalButton)
end)

flashCalButtonButton:HookScript("OnClick", function(frame)
	local checked = frame:GetChecked()
	CCConfig.FlashCalButton = checked
end)

local flashCalButtonButtonText = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
flashCalButtonButtonText:SetPoint("LEFT", flashCalButtonButton, "RIGHT", 0, 1)
flashCalButtonButtonText:SetText(L.Options[localeString]["FlashCalButtonText"])

-- Raid Warning

local raidWarningButton = CreateFrame("CheckButton", nil, CCIOFrame, "OptionsBaseCheckButtonTemplate")
raidWarningButton:SetPoint("TOPLEFT", flashCalButtonButton, "BOTTOMLEFT", 0, -8)

raidWarningButton:SetScript("OnUpdate", function(frame)
	raidWarningButton:SetChecked(CCConfig.SendRaidWarning)
end)

raidWarningButton:HookScript("OnClick", function(frame)
	local checked = frame:GetChecked()
	CCConfig.SendRaidWarning = checked
end)

local raidWarningButtonText = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
raidWarningButtonText:SetPoint("LEFT", raidWarningButton, "RIGHT", 0, 1)
raidWarningButtonText:SetText(L.Options[localeString]["SendRaidWarningText"])

-- Alarm Sound

local alarmSoundButton = CreateFrame("CheckButton", nil, CCIOFrame, "OptionsBaseCheckButtonTemplate")
alarmSoundButton:SetPoint("TOPLEFT", raidWarningButton, "BOTTOMLEFT", 0, -8)

alarmSoundButton:SetScript("OnUpdate", function(frame)
	alarmSoundButton:SetChecked(CCConfig.PlayAlarmSound)
end)

alarmSoundButton:HookScript("OnClick", function(frame)
	local checked = frame:GetChecked()
	CCConfig.PlayAlarmSound = checked
end)

local alarmSoundButtonText = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
alarmSoundButtonText:SetPoint("LEFT", alarmSoundButton, "RIGHT", 0, 1)
alarmSoundButtonText:SetText(L.Options[localeString]["PlayAlarmSoundText"])

-- HR line for Art options
local horizRule2 = createHorizontalRule(L.Options[localeString]["ArtHeaderText"], alarmSoundButton)

-- PVP weekends

local chkIOUsePVPArts = CreateFrame("CheckButton", nil, CCIOFrame, "OptionsBaseCheckButtonTemplate")
chkIOUsePVPArts:SetPoint("TOPLEFT", horizRule2, "BOTTOMLEFT", 0, -16)

chkIOUsePVPArts:SetScript("OnUpdate", function(frame)
	chkIOUsePVPArts:SetChecked(CCConfig.BattlegroundsArt)
end)

chkIOUsePVPArts:SetScript("OnClick", function(frame)
	CCConfig.BattlegroundsArt = frame:GetChecked()
end)

local chkIOUsePVPArtsText = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
chkIOUsePVPArtsText:SetPoint("LEFT", chkIOUsePVPArts, "RIGHT", 0, 1)
chkIOUsePVPArtsText:SetText(L.Options[localeString]["PVPArtText"])

-- Childrens Week

local chkIOShowChildrensWeek = CreateFrame("CheckButton", nil, CCIOFrame, "OptionsBaseCheckButtonTemplate")
chkIOShowChildrensWeek:SetPoint("TOPLEFT", chkIOUsePVPArts, "BOTTOMLEFT", 0, -8) -- Second arguement is the previous local variable name

chkIOShowChildrensWeek:SetScript("OnUpdate", function(frame)
	chkIOShowChildrensWeek:SetChecked(CCConfig.ChildrensWeekArt)
end)

chkIOShowChildrensWeek:SetScript("OnClick", function(frame)
	CCConfig.ChildrensWeekArt = frame:GetChecked()
end)

local chkIOShowChildrensWeekText = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
chkIOShowChildrensWeekText:SetPoint("LEFT", chkIOShowChildrensWeek, "RIGHT", 0, 1)
chkIOShowChildrensWeekText:SetText(L.Options[localeString]["ChildrensWeekText"])

-- Fireworks Spectacular

local chkIOShowFireworksSpectacular = CreateFrame("CheckButton", nil, CCIOFrame, "OptionsBaseCheckButtonTemplate")
chkIOShowFireworksSpectacular:SetPoint("TOPLEFT", chkIOShowChildrensWeek, "BOTTOMLEFT", 0, -8) -- Second arguement is the previous local variable name

chkIOShowFireworksSpectacular:SetScript("OnUpdate", function(frame)
	chkIOShowFireworksSpectacular:SetChecked(CCConfig.FireworksSpectacularArt)
end)

chkIOShowFireworksSpectacular:SetScript("OnClick", function(frame)
	CCConfig.FireworksSpectacularArt = frame:GetChecked()
end)

local chkIOShowFireworksSpectacularText = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
chkIOShowFireworksSpectacularText:SetPoint("LEFT", chkIOShowFireworksSpectacular, "RIGHT", 0, 1)
chkIOShowFireworksSpectacularText:SetText(L.Options[localeString]["FireworksSpectacularText"])

-- Attributions

local attLine1 = createHorizontalRule(L.Options[localeString]["AuthorHeaderText"], chkIOShowFireworksSpectacular)

local attLine2 = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
attLine2:SetPoint("CENTER", attLine1, "LEFT", (InterfaceOptionsFramePanelContainerWidth/3), -16)
attLine2:SetText("|cFF9CD6DE"..randomName[1].."|r")

local attLine3 = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
attLine3:SetPoint("CENTER", attLine1, "LEFT", (InterfaceOptionsFramePanelContainerWidth/3)*2, -16)
attLine3:SetText("|cFF9CD6DE"..randomName[2].."|r")

-- Discord Info

local DiscordLogo = CCIOFrame:CreateTexture(nil, "OVERLAY")
DiscordLogo:SetPoint("TOPLEFT", attLine1, "BOTTOMLEFT", 0, -32) -- Second arguement is the previous local variable name
DiscordLogo:SetSize(16, 16)
DiscordLogo:SetTexture("Interface\\AddOns\\ClassicCalendar\\Textures\\DiscordLogo.tga")

local lblDiscord = CCIOFrame:CreateFontString(nil, nil, "GameFontHighlight")
lblDiscord:SetPoint("LEFT", DiscordLogo, "RIGHT", 4, 0)
lblDiscord:SetText("|cFFEFC502https://discord.gg/CMxKsBQFKp|r")

InterfaceOptions_AddCategory(CCIOFrame);

-- Loading handler

local function CCOptionsHandler(self, event, arg1)
	-- If SavedVariable is not set, default settings
	if event == "ADDON_LOADED" and arg1 == AddonName then
		CCConfig = CCConfig or defaultOptions

		for key, value in pairs(defaultOptions) do
			if CCConfig[key] == nil then
				CCConfig[key] = value
			end
		end

		SlashCmdList["CCCONFIG"] = GoToCCSettings;
		SLASH_CCCONFIG1, SLASH_CCCONFIG2 = "/caloptions", "/calendaroptions"

		if CCConfig.HideCalendarButton == true then
			CalendarButtonFrame:Hide()
		end

		ToggleCalButtonLock(CCConfig.UnlockCalendarButton)

		-- Delay loading the alarm dropdowns so they can use saved vars
		UIDropDownMenu_Initialize(startingWeekdayDropdown, InitStartingWeekdayDropdown)
		UIDropDownMenu_Initialize(eventAlarmNumberDropdown, InitEventAlarmNumberDropdown)
		UIDropDownMenu_Initialize(eventAlarmUnitDropdown, InitEventAlarmUnitDropdown)
	end
end

CCOptions:SetScript("OnEvent", CCOptionsHandler)
