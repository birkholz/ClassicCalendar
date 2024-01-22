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

local function CCOptionsHandler(self, event, arg1)
	-- If SavedVariable is not set, default settings
	if event == "ADDON_LOADED" then
		if CCConfig == nil or CCConfig == "" then
			CCConfig = {
				["BattlegroundsArt"] = false,
				["ChildrensWeekArt"] = false,
				["FireworksSpectacularArt"] = true,
				["HideCalendarButton"] = false,
				--["Dropdown"] = "Value1",
			}
		end
	end

	if event == "VARIABLES_LOADED" then
		SlashCmdList["CCCONFIG"] = GoToCCSettings;
		SLASH_CCCONFIG1, SLASH_CCCONFIG2 = "/caloptions", "/calendaroptions"

		if CCConfig.HideCalendarButton == true then
			CalendarButtonFrame:Hide()
		end
	end
end

CCOptions:SetScript("OnEvent", CCOptionsHandler)

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

function shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
end

local randomName = {"Toxiix-WildGrowth", "Lovediodes-WildGrowth"}
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

-- Hide the Calendar Button

local chkIOHideCalButton = CreateFrame("CheckButton", nil, CCIOFrame, "OptionsBaseCheckButtonTemplate")
chkIOHideCalButton:SetPoint("TOPLEFT", horizRule1, "BOTTOMLEFT", 0, -16)

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

-- HR line for Art options
local horizRule2 = createHorizontalRule(L.Options[localeString]["ArtHeaderText"], chkIOHideCalButtonDesc)

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
