local addonName, ClassicCalendar = ...
local L = CLASSIC_CALENDAR_L
local localeString = tostring(GetLocale())
local date = date
local time = time

CALENDAR_INVITESTATUS_INFO = {
	["UNKNOWN"] = {
		name		= UNKNOWN,
		color		= NORMAL_FONT_COLOR,
	},
	[Enum.CalendarStatus.Confirmed] = {
		name		= CALENDAR_STATUS_CONFIRMED,
		color		= GREEN_FONT_COLOR,
	},
	[Enum.CalendarStatus.Available] = {
		name		= CALENDAR_STATUS_ACCEPTED,
		color		= GREEN_FONT_COLOR,
	},
	[Enum.CalendarStatus.Declined] = {
		name		= CALENDAR_STATUS_DECLINED,
		color		= RED_FONT_COLOR,
	},
	[Enum.CalendarStatus.Out] = {
		name		= CALENDAR_STATUS_OUT,
		color		= RED_FONT_COLOR,
	},
	[Enum.CalendarStatus.Standby] = {
		name		= CALENDAR_STATUS_STANDBY,
		color		= ORANGE_FONT_COLOR,
	},
	[Enum.CalendarStatus.Invited] = {
		name		= CALENDAR_STATUS_INVITED,
		color		= NORMAL_FONT_COLOR,
	},
	[Enum.CalendarStatus.Signedup] = {
		name		= CALENDAR_STATUS_SIGNEDUP,
		color		= GREEN_FONT_COLOR,
	},
	[Enum.CalendarStatus.NotSignedup] = {
		name		= CALENDAR_STATUS_NOT_SIGNEDUP,
		color		= GRAY_FONT_COLOR,
	},
	[Enum.CalendarStatus.Tentative] = {
		name		= CALENDAR_STATUS_TENTATIVE,
		color		= ORANGE_FONT_COLOR,
	},
}

CalendarType = {
	Player = 0,
	Community = 1,
	RaidLockout = 2,
	RaidReset = 3,
	Holiday = 4,
	HolidayWeekly = 5,
	HolidayDarkmoon = 6,
	HolidayBattleground = 7,
}

CalendarInviteType = {
	Normal = 0,
	Signup = 1,
}

CalendarEventType = {
	Raid = 0,
	Dungeon = 1,
	PvP = 2,
	Meeting = 3,
	Other = 4,
	HeroicDeprecated = 5,
}

CalendarTexturesType = {
	Dungeons = 0,
	Raid = 1,
}

local currentCalendarTime = C_DateAndTime.GetCurrentCalendarTime()

local state = {
	monthOffset=0,
	presentDate={
		year=currentCalendarTime.year,
		month=currentCalendarTime.month,
		day=currentCalendarTime.day
	},
	currentEventIndex=0,
	currentMonthOffset=0
}

local isClassicEra = not C_Seasons.HasActiveSeason()
local isSoD = C_Seasons.HasActiveSeason() and (C_Seasons.GetActiveSeason() == Enum.SeasonID.Placeholder) -- "Placeholder" = SoD

CALENDAR_FILTER_BATTLEGROUND = L.Options[localeString]["CALENDAR_FILTER_BATTLEGROUND"];

-- TODO: Localize these strings
COMMUNITIES_CALENDAR_CHAT_EVENT_BROADCAST_FORMAT = "%s: %s %s";
COMMUNITIES_CALENDAR_CHAT_EVENT_TITLE_FORMAT = "[%s]";
COMMUNITIES_CALENDAR_EVENT_FORMAT = "%s at %s";
COMMUNITIES_CALENDAR_MOTD_FORMAT = "\"%s\"";
COMMUNITIES_CALENDAR_ONGOING_EVENT_PREFIX = "Event occurring now";
COMMUNITIES_CALENDAR_TODAY = "Today";
COMMUNITIES_CALENDAR_TOOLTIP_TITLE = "Bulletin";

-- Date Utilities

local function dumpTable(o)
	if type(o) == 'table' then
	   local s = '{ '
	   for k,v in pairs(o) do
		  if type(k) ~= 'number' then k = '"'..k..'"' end
		  s = s .. '['..k..'] = ' .. dumpTable(v) .. ','
	   end
	   return s .. '} '
	else
	   return tostring(o)
	end
end

local SECONDS_IN_DAY = 24 * 60 * 60

local function fixLuaDate(dateD)
	local result = {
		year=dateD.year,
		month=dateD.month,
		monthDay=dateD.day,
		weekDay=dateD.wday,
		day=dateD.day,
		hour=dateD.hour,
		min=dateD.min,
		minute=dateD.min
	}
	return result
end

local function dateGreaterThan(date1, date2)
	return time(date1) > time(date2)
end

local function dateLessThan(date1, date2)
	return time(date1) < time(date2)
end

local function dateIsOnFrequency(eventDate, epochDate, frequency)
	-- If one date has DST and the other doesn't, this fails
	local eventDateTime = time(SetMinTime(eventDate))
	local epochDateTime = time(SetMinTime(epochDate))

	if date("*t", eventDateTime).isdst and not date("*t", epochDateTime).isdst then
		-- add an hour to DST datetimes
		 eventDateTime = eventDateTime + 60*60
	end

	if date("*t", epochDateTime).isdst and not date("*t", eventDateTime).isdst then
		epochDateTime = epochDateTime + 60*60
	end

	if frequency == 0 then
		return eventDateTime == epochDateTime
	end

	return ((eventDateTime - epochDateTime) / (SECONDS_IN_DAY)) % frequency == 0
end

local function adjustMonthByOffset(dateD, offset)
	dateD.month = dateD.month + offset
	if dateD.month > 12 then
		dateD.year = dateD.year + 1
		dateD.month = 1
	elseif dateD.month == 0 then
		dateD.year = dateD.year - 1
		dateD.month = 12
	end
end

local function tableHasValue(tab, val)
	for _, value in ipairs(tab) do
		if value == val then
			return true
		end
	end

	return false
end

function newEventGetTextures(eventType)
	-- Stubbing C_Calendar.EventGetTextures to actually return textures, and only SoD-available raids/dungeons
	if eventType == 0 then -- Raids
		local raidTextures = {}
		if isSoD then
			raidTextures = {
				{
					title=L.DungeonLocalization[localeString][136325][1],
					isLfr=false,
					difficultyId=0,
					mapId=0,
					expansionLevel=0,
					iconTexture="Interface/LFGFrame/LFGIcon-BlackfathomDeeps"
				},
				{
					title=L.DungeonLocalization[localeString][136336][1],
					isLfr=false,
					difficultyId=0,
					mapId=0,
					expansionLevel=0,
					iconTexture="Interface/LFGFrame/LFGIcon-Gnomeregan"
				},
				{
					title=L.DungeonLocalization[localeString][136360][1],
					isLfr=false,
					difficultyId=0,
					mapId=0,
					expansionLevel=0,
					iconTexture="Interface/LFGFrame/LFGICON-SUNKENTEMPLE"
				},
				{
					title=L.RaidLocalization[localeString][136327],
					isLfr=false,
					difficultyId=0,
					mapId=0,
					expansionLevel=0,
					iconTexture="Interface/LFGFrame/LFGICON-BLACKROCKSPIRE"
				},
				{
					title=L.RaidLocalization[localeString][136351],
					isLfr=false,
					difficultyId=0,
					mapId=0,
					expansionLevel=0,
					iconTexture="Interface/LFGFrame/LFGICON-RAID"
				},
				{
					title=L.RaidLocalization[localeString][136346],
					isLfr=false,
					difficultyId=0,
					mapId=0,
					expansionLevel=0,
					iconTexture="Interface/LFGFrame/LFGICON-MOLTENCORE"
				},
				{
					title="Kazzak",
					isLfr=false,
					difficultyId=0,
					mapId=0,
					expansionLevel=0,
					iconTexture="Interface/LFGFrame/LFGICON-RAID"
				},
				{
					title="Azuregos",
					isLfr=false,
					difficultyId=0,
					mapId=0,
					expansionLevel=0,
					iconTexture="Interface/LFGFrame/LFGICON-RAID"
				},
				{
					title=L.RaidLocalization[localeString][136329],
					isLfr=false,
					difficultyId=0,
					mapId=0,
					expansionLevel=0,
					iconTexture="Interface/LFGFrame/LFGICON-BLACKWINGLAIR"
				},
				{
					title=L.RaidLocalization[localeString][136369],
					isLfr=false,
					difficultyId=0,
					mapId=0,
					expansionLevel=0,
					iconTexture="Interface/LFGFrame/LFGICON-ZULGURUB"
				},
				{
					title="Prince Thunderaan",
					isLfr=false,
					difficultyId=0,
					mapId=0,
					expansionLevel=0,
					iconTexture="Interface/LFGFrame/LFGICON-RAID"
				}
			}
		else
			for textureID, raidName in next, L.RaidLocalization[localeString] do
				tinsert(raidTextures, {
					title=raidName,
					isLfr=false,
					difficultyId=0,
					mapId=0,
					expansionLevel=0,
					iconTexture=textureID
				})
			end
		end

		-- sort alphabetically ascending
		table.sort(raidTextures, function(a,b)
			return a.title < b.title
		end)

		return raidTextures
	end

	if eventType == 1 then -- Dungeons
		local dungeonTextures = {}
		local SoDDungeons = {
			[136332]=true,[136353]=true,[136354]=true,[136357]=true,[136364]=true,[136363]=true,[136352]=true,
			[136345]=true,[136368]=true,[136326]=true,[136327]=true,[136333]=true,[136355]=true,[136359]=true
			-- Plus Demon Fall Canyon, and whatever is coming in phase 5?
		}
		local faction, _ = UnitFactionGroup("player")
		if faction == "Horde" then
			-- Only add Ragefire Chasm if horde
			SoDDungeons[136350] = true
		else
			-- Only add Stormwind Stockades if alliance
			SoDDungeons[136358] = true
		end

		for textureID, wingNames in next, L.DungeonLocalization[localeString] do
			if not isSoD or (isSoD and SoDDungeons[textureID]) then
				for _, wingName in next, wingNames do
					tinsert(dungeonTextures, {
						title=wingName,
						isLfr=false,
						difficultyId=0,
						mapId=0,
						expansionLevel=0,
						iconTexture=textureID
					})
				end
			end
		end

		-- sort alphabetically ascending
		table.sort(dungeonTextures, function(a,b)
			return a.title < b.title
		end)

		return dungeonTextures
	end

	return {}
end

function stubbedGetNumDayEvents(monthOffset, monthDay)
	-- Stubbing C_Calendar.getNumDayEvents to return fake events
	local originalEventCount = C_Calendar.GetNumDayEvents(monthOffset, monthDay)
	local monthInfo = C_Calendar.GetMonthInfo(monthOffset)
	local eventDate = {
		year = monthInfo.year,
		month = monthInfo.month,
		day = monthDay
	}
	local eventTime = time(eventDate)

	for _, holiday in next, GetClassicHolidays() do
		local holidayMinStartTime = time(SetMinTime(holiday.startDate))
		if eventTime < holidayMinStartTime then
			break
		end

		local holidayMaxEndTime = time(SetMaxTime(holiday.endDate))

		if (holiday.CVar == nil or GetCVar(holiday.CVar) == "1") and eventTime >= holidayMinStartTime and eventTime <= holidayMaxEndTime then
			originalEventCount = originalEventCount + 1
		end
	end

	if GetCVar("calendarShowResets") ~= "0" then
		for _, raid in next, GetClassicRaidResets() do
			if dateGreaterThan(eventDate, raid.firstReset) and dateIsOnFrequency(eventDate, raid.firstReset, raid.frequency) then
				originalEventCount = originalEventCount + 1
			end
		end
	end

	return originalEventCount
end

function stubbedGetDayEvent(monthOffset, monthDay, index)
	-- Stubbing C_Calendar.GetDayEvent to return events
	local originalEventCount = C_Calendar.GetNumDayEvents(monthOffset, monthDay)
	local originalEvent = C_Calendar.GetDayEvent(monthOffset, monthDay, index)
	local monthInfo = C_Calendar.GetMonthInfo(monthOffset)
	local eventDate = {
		year = monthInfo.year,
		month = monthInfo.month,
		day = monthDay
	}
	local eventTime = time(eventDate)
	local matchingEvents = {}

	if originalEvent == nil then
		for _, holiday in next, GetClassicHolidays() do
			local holidayMinStartTime = time(SetMinTime(holiday.startDate))
			if eventTime < holidayMinStartTime then
				break
			end

			local holidayMaxEndTime = time(SetMaxTime(holiday.endDate))

			if (holiday.CVar == nil or GetCVar(holiday.CVar) == "1") and eventTime >= holidayMinStartTime and eventTime <= holidayMaxEndTime then
				local artDisabled = false
				if holiday.artConfig and CCConfig[holiday.artConfig] == false then
					artDisabled = true
				end

				-- single-day event
				if (holiday.startDate.year == holiday.endDate.year and holiday.startDate.month == holiday.endDate.month and holiday.startDate.day == holiday.endDate.day) then
					local iconTexture = nil
					local ZIndex = 1
					if not artDisabled then
						iconTexture = holiday.startTexture
						ZIndex = holiday.ZIndex
					end

					local eventTable = { -- CalendarEvent
						title=holiday.name,
						isCustomTitle=true,
						startTime=fixLuaDate(holiday.startDate),
						endTime=fixLuaDate(holiday.endDate),
						calendarType="HOLIDAY",
						eventType=CalendarEventType.Other,
						iconTexture=iconTexture, -- single-day events only have one texture
						modStatus="",
						inviteStatus=0,
						invitedBy="",
						inviteType=CalendarInviteType.Normal,
						difficultyName="",
						dontDisplayBanner=false,
						dontDisplayEnd=false,
						isLocked=false,
						sequenceType="",
						sequenceIndex=1,
						numSequenceDays=1,
						ZIndex=ZIndex
					}
					tinsert(matchingEvents, eventTable)
				else
					local numSequenceDays = math.floor((time(SetMinTime(holiday.endDate)) - holidayMinStartTime) / SECONDS_IN_DAY) + 1
					local sequenceIndex = math.floor((time(SetMinTime(eventDate)) - holidayMinStartTime) / SECONDS_IN_DAY) + 1

					local iconTexture, sequenceType
					local ZIndex = holiday.ZIndex
					-- Assign start/ongoing/end texture based on sequenceIndex compared to numSequenceDays
					if sequenceIndex == 1 then
						iconTexture = holiday.startTexture
						sequenceType = "START"
					elseif sequenceIndex == numSequenceDays then
						iconTexture = holiday.endTexture
						sequenceType = "END"
					else
						iconTexture = holiday.ongoingTexture
						sequenceType = "ONGOING"
					end

					if artDisabled then
						iconTexture = nil
						ZIndex=1
					end

					local dontDisplayBanner
					if not iconTexture then
						dontDisplayBanner = true
						ZIndex=1
					else
						dontDisplayBanner = false
					end

					local eventTable = { -- CalendarEvent
						title=holiday.name,
						isCustomTitle=true,
						startTime=fixLuaDate(holiday.startDate),
						endTime=fixLuaDate(holiday.endDate),
						calendarType="HOLIDAY",
						sequenceType=sequenceType,
						eventType=CalendarEventType.Other,
						iconTexture=iconTexture,
						modStatus="",
						inviteStatus=0,
						invitedBy="",
						inviteType=CalendarInviteType.Normal,
						sequenceIndex=sequenceIndex,
						numSequenceDays=numSequenceDays,
						difficultyName="",
						dontDisplayBanner=dontDisplayBanner,
						dontDisplayEnd=false,
						isLocked=false,
						ZIndex=ZIndex
					}
					tinsert(matchingEvents, eventTable)
				end
			end
		end

		if GetCVar("calendarShowResets") ~= "0" then
			for _, raid in next, GetClassicRaidResets() do
				if dateGreaterThan(eventDate, raid.firstReset) and dateIsOnFrequency(eventDate, raid.firstReset, raid.frequency) then
					local eventTable = {
						eventType=CalendarEventType.Other,
						sequenceType="",
						isCustomTitle=true,
						startTime=fixLuaDate(date("*t", time({
							year=eventDate.year,
							month=eventDate.month,
							day=eventDate.day,
							hour=raid.firstReset.hour,
							min=0
						}))),
						difficultyName="",
						invitedBy="",
						inviteStatus=0,
						dontDisplayEnd=false,
						isLocked=false,
						title=raid.name,
						calendarType="RAID_RESET",
						inviteType=CalendarInviteType.Normal,
						sequenceIndex=1,
						dontDisplayBanner=false,
						modStatus="",
						ZIndex=1
					}
					tinsert(matchingEvents, eventTable)
				end
			end
		end

		if #matchingEvents == 0 or matchingEvents[index - originalEventCount] == nil then
			assert(false, string.format("Injected event expected for date: %s", dumpTable(eventDate)))
		else
			table.sort(matchingEvents, function(a,b)
				return a.ZIndex > b.ZIndex
			end)
			return matchingEvents[index - originalEventCount]
		end
	end

	-- Strip difficulty name since Classic has no difficulties
	originalEvent.difficultyName = ""

	return originalEvent
end

function stubbedSetMonth(offset)
	-- C_Calendar.SetMonth updates the game's internal monthOffset that is applied to GetDayEvent and GetNumDayEvents calls,
	-- we have to stub it to do the same for our stubbed methods
	state.currentMonthOffset = state.currentMonthOffset + offset
	C_Calendar.SetMonth(offset)

	adjustMonthByOffset(state.presentDate, offset)
end

function stubbedSetAbsMonth(month, year)
	-- Reset state
	state.presentDate.year = year
	state.presentDate.month = month
	state.currentEventIndex = 0
	state.currentMonthOffset = 0
	C_Calendar.SetAbsMonth(month, year)
end

function communityName()
	-- Gets Guild Name from Player since built in functionality is broken
	local communityName, _ = GetGuildInfo("player")
	return communityName
end

-- Slash command /calendar to open the calendar

SLASH_CALENDAR1, SLASH_CALENDAR2 = '/cal', '/calendar'

function SlashCmdList.CALENDAR(_msg, _editBox)
	Calendar_Toggle()
end

function newGetHolidayInfo(offsetMonths, monthDay, eventIndex)
	-- return C_Calendar.GetHolidayInfo(offsetMonths, monthDay, eventIndex)
	-- Because classic doesn't return any events, we're completely replacing this function
	local event = stubbedGetDayEvent(offsetMonths, monthDay, eventIndex)

	local eventName = event.title
	local eventDesc

	for _, holiday in next, GetClassicHolidays() do
		if event.title == holiday.name then
			eventDesc = holiday.description
		end
	end

	if eventDesc == nil then
		return
	else
		return {
			name=eventName,
			startTime=event.startTime,
			endTime=event.endTime,
			description=eventDesc
		}
	end
end


function UpdateCalendarState(year, month, day)
	state.presentDate.year = year
	state.presentDate.month = month
	state.presentDate.day = day
end

function stubbedGetEventIndex()
	local original = C_Calendar.GetEventIndex()
	if (original and original.offsetMonths == state.presentDate.currentMonthOffset and original.monthDay == state.presentDate.day and original.eventIndex == state.currentEventIndex) then
		-- If there is an original event and our state matches up
		return original
	end

	return {
		offsetMonths=state.currentMonthOffset,
		monthDay=state.presentDate.day,
		eventIndex=state.currentEventIndex
	}
end

function stubbedOpenEvent(monthOffset, day, eventIndex)
	-- Normally, event side panels are opened by the OnEvent handler, however that doesn't work for injected events
	-- So instead, we have hooked into the OpenEvent function to perform the same logic as the event handler
	local original_event = C_Calendar.GetDayEvent(monthOffset, day, eventIndex)
	state.currentEventIndex = eventIndex
	state.currentMonthOffset = monthOffset

	if original_event ~= nil then
		C_Calendar.OpenEvent(monthOffset, day, eventIndex)
	else
		local injectedEvent = stubbedGetDayEvent(monthOffset, day, eventIndex)
		if injectedEvent.calendarType == "HOLIDAY" then
			CalendarFrame_ShowEventFrame(CalendarViewHolidayFrame)
		elseif injectedEvent.calendarType == "RAID_RESET" then
			CalendarFrame_ShowEventFrame(CalendarViewRaidFrame)
		end
	end
end

-- Hide the default Time-of-Day frame because it occupies the same spot as the calendar button
-- This is the same decision Blizzard made according to their comments
GameTimeFrame:Hide()

function stubbedGetRaidInfo(monthOffset, day, eventIndex)
	-- Stubbing to return injected reset events
	local originalInfo = C_Calendar.GetRaidInfo(monthOffset, day, eventIndex)
	if originalInfo ~= nil then
		return originalInfo
	else
		local injectedRaidEvent = stubbedGetDayEvent(monthOffset, day, eventIndex)
		return {
			name=injectedRaidEvent.title,
			difficultyName="",
			time=injectedRaidEvent.startTime
		}
	end
end

-- Replaced reads of GetStartingWeekday with this function so we can override it safely
function GetStartingWeekday()
	if CCConfig.StartDay and CCConfig.StartDay > 0 then
		return CCConfig.StartDay
	else
		return CALENDAR_FIRST_WEEKDAY
	end
end

-- Replacement for CALENDAR_EVENT_ALARM since it never fires
local function AlarmUpcomingEvents()
	local currentDate = C_DateAndTime.GetCurrentCalendarTime()
	currentDate.min = currentDate.minute
	local today = currentDate.monthDay
	local currentTime = time(currentDate)
	local numEvents = C_Calendar.GetNumDayEvents(0, today)

	if ( numEvents <= 0 ) then
		return
	end

	for i = 1, numEvents do
		local event = C_Calendar.GetDayEvent(0, today, i);
		-- We only alarm events created by players and that the player is in
		local alarmInviteStatuses = {
			Enum.CalendarStatus.Signedup,
			Enum.CalendarStatus.Available,
			Enum.CalendarStatus.Confirmed,
			Enum.CalendarStatus.Tentative
		}
		if (event and event.calendarType == "PLAYER" and alarmInviteStatuses[event.inviteStatus] ~= nil) then
			event.startTime.min = event.startTime.minute
			local eventTime = time(event.startTime)

			local alarmMult = 60
			if CCConfig.AlarmUnit == "Minute" then
				alarmMult = 60
			elseif CCConfig.AlarmUnit == "Hour" then
				alarmMult = 3600
			end
			local alarmTime = CCConfig.AlarmNumber * alarmMult
			if eventTime == currentTime + alarmTime then
				local title = event.title
				local info = ChatTypeInfo["SYSTEM"]
				local message
				if CCConfig.AlarmUnit == "Minute" and CCConfig.AlarmNumber == 15 then
					-- Fully localized, but hardcoded to 15 minutes
					message = format(CALENDAR_EVENT_ALARM_MESSAGE, title)
				else
					local pluralizedUnit = format(CCConfig.AlarmUnit == "hour" and D_HOURS or D_MINUTES, CCConfig.AlarmNumber)
					message = format(L.Options[localeString]["EventAlarmMessage"], title, pluralizedUnit)
				end
				DEFAULT_CHAT_FRAME:AddMessage(message, info.r, info.g, info.b, info.id)

				if (CCConfig.FlashCalButton) then
					UIFrameFlash(GameTimeCalendarEventAlarmTexture, 1.0, 1.0, -1)
				end
				if (CCConfig.SendRaidWarning) then
					RaidNotice_AddMessage(RaidWarningFrame, message, ChatTypeInfo["RAID_WARNING"])
				end
				if (CCConfig.PlayAlarmSound) then
					PlaySound(SOUNDKIT.ALARM_CLOCK_WARNING_2)
				end
			end
		end
	end
end

local function AlarmTimer()
	-- Runs every minute and sends alarms for any upcoming events
	AlarmUpcomingEvents()
	C_Timer.After(60, AlarmTimer)
end

local loadFrame = CreateFrame("Frame")
function loadFrame:OnEvent(event, arg1)
	AlarmTimer()
end

loadFrame:RegisterEvent("VARIABLES_LOADED")
loadFrame:SetScript("OnEvent", loadFrame.OnEvent)

function GetCalendarEventLink(monthOffset, monthDay, index)
	local dayEvent = C_Calendar.GetDayEvent(monthOffset, monthDay, index)
	if dayEvent then
		-- return LinkUtil.FormatLink("calendarEvent", dayEvent.title, monthOffset, monthDay, index);
		-- Calendar event links are not supported, so we return the title instead
		return dayEvent.title
	end

	return nil
end

function ToggleCalendar()
	Calendar_Toggle()
end
