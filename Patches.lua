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

CALENDAR_FILTER_BATTLEGROUND = "Battleground Call to Arms";

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

	if date("*t", eventDateTime).isdst then
		-- add an hour to DST datetimes
		 eventDateTime = eventDateTime + 60*60
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

local dungeonNamesCache = {}

function newEventGetTextures(eventType)
	-- Stubbing C_Calendar.EventGetTextures to actually return textures, and only SoD-available raids/dungeons
	if next(dungeonNamesCache) == nil then
		-- Caching the current localization's names for the dungeons
		local original_dungeon_names = C_Calendar.EventGetTextures(1)
		dungeonNamesCache = {
			BlackfathomDeepsTitle  = original_dungeon_names[1]["title"],
			DeadminesTitle = original_dungeon_names[3]["title"],
			RazorfenKraulTitle = original_dungeon_names[11]["title"],
			ScarletMonasteryTitle = original_dungeon_names[12]["title"],
			ShadowfangKeepTitle = original_dungeon_names[14]["title"],
			StormwindStockadesTitle = original_dungeon_names[15]["title"],
			WailingCavernsTitle = original_dungeon_names[19]["title"]
		}
	end

	if eventType == 0 then
		-- Raids
		return {
			{
				title=dungeonNamesCache.BlackfathomDeepsTitle,
				isLfr=false,
				difficultyId=0,
				mapId=0,
				expansionLevel=0,
				iconTexture="Interface/LFGFrame/LFGIcon-BlackfathomDeeps"
			}
		}
	end

	if eventType == 1 then
		-- Dungeons, alphabetically sorted
		return {
			{
				title=dungeonNamesCache.DeadminesTitle,
				isLfr=false,
				difficultyId=0,
				mapId=0,
				expansionLevel=0,
				iconTexture="Interface/LFGFrame/LFGIcon-Deadmines"
			},
			{
				title=dungeonNamesCache.RazorfenKraulTitle,
				isLfr=false,
				difficultyId=0,
				mapId=0,
				expansionLevel=0,
				iconTexture="Interface/LFGFrame/LFGIcon-RazorfenKraul"
			},
			{
				title=dungeonNamesCache.ScarletMonasteryTitle,
				isLfr=false,
				difficultyId=0,
				mapId=0,
				expansionLevel=0,
				iconTexture="Interface/LFGFrame/LFGIcon-ScarletMonastery"
			},
			{
				title=dungeonNamesCache.ShadowfangKeepTitle,
				isLfr=false,
				difficultyId=0,
				mapId=0,
				expansionLevel=0,
				iconTexture="Interface/LFGFrame/LFGIcon-ShadowfangKeep"
			},
			{
				title=dungeonNamesCache.StormwindStockadesTitle,
				isLfr=false,
				difficultyId=0,
				mapId=0,
				expansionLevel=0,
				iconTexture="Interface/LFGFrame/LFGIcon-StormwindStockades"
			},
			{
				title=dungeonNamesCache.WailingCavernsTitle,
				isLfr=false,
				difficultyId=0,
				mapId=0,
				expansionLevel=0,
				iconTexture="Interface/LFGFrame/LFGIcon-WailingCaverns"
			}
		}
	end

	return {}
end

local function createResetEvent(eventDate)
	local fakeResetEvent = {
		eventType=CalendarEventType.Other,
		sequenceType="",
		isCustomTitle=true,
		startTime={
			year=eventDate.year,
			month=eventDate.month,
			monthDay=eventDate.day,
			hour=8,
			min=0
		},
		difficultyName="",
		invitedBy="",
		inviteStatus=0,
		dontDisplayEnd=false,
		isLocked=false,
		title="Blackfathom Deeps",
		calendarType="RAID_RESET",
		inviteType=CalendarInviteType.Normal,
		sequenceIndex=1,
		dontDisplayBanner=false,
		modStatus=""
	}

	return fakeResetEvent
end

local function dayHasReset(eventDate)
	if GetCVar("calendarShowResets") == "0" then
		return false
	end

	local firstReset = {
		year=2023,
		month=12,
		day=3
	}
	if dateLessThan(eventDate, firstReset) then
		return false
	end

	return dateIsOnFrequency(eventDate, firstReset, 3)
end

local function getAbsDate(monthOffset, monthDay)
	local eventDate = {
		year=state.presentDate.year,
		month=state.presentDate.month,
		day=monthDay
	}
	adjustMonthByOffset(eventDate, monthOffset)

	return eventDate
end

function stubbedGetNumDayEvents(monthOffset, monthDay)
	-- Stubbing C_Calendar.getNumDayEvents to return fake events
	local originalEventCount = C_Calendar.GetNumDayEvents(monthOffset, monthDay)
	local eventDate = getAbsDate(monthOffset, monthDay)

	for _, holiday in next, GetClassicHolidays() do
		if holiday.CVar == nil or GetCVar(holiday.CVar) == "1" then
			if time(eventDate) > time(SetMinTime(holiday.startDate)) and time(eventDate) < time(SetMaxTime(holiday.endDate)) then
				originalEventCount = originalEventCount + 1
			end
		end
	end

	if dayHasReset(eventDate) then
		originalEventCount = originalEventCount + 1
	end

	return originalEventCount
end

function stubbedGetDayEvent(monthOffset, monthDay, index)
	-- Stubbing C_Calendar.GetDayEvent to return events
	local originalEventCount = C_Calendar.GetNumDayEvents(monthOffset, monthDay)
	local originalEvent = C_Calendar.GetDayEvent(monthOffset, monthDay, index)
	local eventDate = getAbsDate(monthOffset, monthDay)

	state.currentEventIndex = index
	state.currentMonthOffset = monthOffset

	local matchingEvents = {}

	if originalEvent == nil then
		for _, holiday in next, GetClassicHolidays() do
			if (holiday.CVar == nil or GetCVar(holiday.CVar) == "1") and
				(time(SetMinTime(holiday.startDate)) <= time(eventDate) and time(SetMaxTime(holiday.endDate)) >= time(eventDate)) then
				local artDisabled = false
				if holiday.artConfig and CCConfig[holiday.artConfig] == "DISABLED" then
					artDisabled = true
				end

				-- single-day event
				if (holiday.startDate.year == holiday.endDate.year and holiday.startDate.month == holiday.endDate.month and holiday.startDate.day == holiday.endDate.day) then
					local iconTexture = nil
					if not artDisabled then
						iconTexture = holiday.startTexture
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
						numSequenceDays=1
					}
					tinsert(matchingEvents, eventTable)
				else
					local numSequenceDays = math.floor((time(SetMinTime(holiday.endDate)) - time(SetMinTime(holiday.startDate))) / SECONDS_IN_DAY) + 1
					local sequenceIndex = math.floor((time(SetMinTime(eventDate)) - time(SetMinTime(holiday.startDate))) / SECONDS_IN_DAY) + 1

					local iconTexture, sequenceType
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
					end

					local dontDisplayBanner
					if not iconTexture then
						dontDisplayBanner = true
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
						isLocked=false
					}
					tinsert(matchingEvents, eventTable)
				end
			end
		end

		if next(matchingEvents) == nil or matchingEvents[index - originalEventCount] == nil then
			if dayHasReset(eventDate) then return createResetEvent(eventDate) end
			assert(false, string.format("Injected event expected for date: %s", dumpTable(eventDate)))
		else
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
	state.monthOffset = state.monthOffset + offset
	C_Calendar.SetMonth(offset)

	adjustMonthByOffset(state.presentDate, offset)
end

function stubbedSetAbsMonth(month, year)
	-- Reset state
	state.presentDate.year = year
	state.presentDate.month = month
	state.monthOffset = 0
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

SLASH_CALENDAR1 = '/calendar'

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
		-- No way to differentiate the locations of darkmoon faire
		if eventName == holiday.name then
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
	local absDate = getAbsDate(monthOffset, day)
	state.presentDate = absDate

	local original_event = C_Calendar.GetDayEvent(monthOffset, day, eventIndex)
	if original_event ~= nil then
		C_Calendar.OpenEvent(monthOffset, day, eventIndex)
	else
		local injectedEvent = stubbedGetDayEvent(monthOffset, day, eventIndex)
		if injectedEvent.calendarType == "HOLIDAY" then
			CalendarFrame_ShowEventFrame(CalendarViewHolidayFrame)
		elseif injectedEvent.calendarType == "RAID_RESET" then
			CalendarFrame_ShowEventFrame(CalendarViewRaidFrame);
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
