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
	presentYear=currentCalendarTime.year,
	presentMonth=currentCalendarTime.month
}

local DARKMOON_ELWYNN_LOCATION = 0
local DARKMOON_MULGORE_LOCATION = 1

local darkmoonLocations = {
	Elwynn = DARKMOON_ELWYNN_LOCATION,
	Mulgore = DARKMOON_MULGORE_LOCATION
}

local holidays = {
	DarkmoonFaire = 0,
	WintersVeil = 1,
	Noblegarden = 2,
	ChildrensWeek = 3,
	HarvestFestival = 4,
	HallowsEnd = 5,
	LunarFestival = 6,
	LoveisintheAir = 7,
	MidsummerFireFestival = 8,
	PeonDay = 9
}

local function deep_copy(t, seen)
    local result = {}
    seen = seen or {}
    seen[t] = result
    for key, value in pairs(t) do
        if type(value) == "table" then
            result[key] = seen[value] or deep_copy(value, seen)
        else
            result[key] = value
        end
    end
    return result
end

local function tableHasValue(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

-- Date Utilities

local SECONDS_IN_DAY = 24 * 60 * 60

local function dateGreaterThan(date1, date2)
	return time(date1) > time(date2)
end

local function dateLessThan(date1, date2)
	return time(date1) < time(date2)
end

local function addDaysToDate(date, dayCount)
	local dateSeconds = time(date)
	dateSeconds = dateSeconds + dayCount * SECONDS_IN_DAY
	return fixLuaDate(date("*t", dateSeconds))
end

local function dateIsOnFrequency(eventDate, epochDate, frequency)
	return ((time(eventDate) - time(epochDate)) / (SECONDS_IN_DAY)) % frequency == 0
end

local function isDateInRepeatingRange(eventDate, startEpoch, endEpoch, frequency)
	local dateTime = time(eventDate)
	local darkmoonFrequency = frequency * SECONDS_IN_DAY

	while dateTime > startEpoch do
		if dateTime > startEpoch and dateTime < endEpoch then
			return true
		end
		
		dateTime = dateTime - darkmoonFrequency
	end

	return false
end

local WEEKDAYS = {
	Sunday = 1,
	Monday = 2,
	Tuesday = 3,
	Wednesday = 4,
	Thursday = 5,
	Friday = 6,
	Saturday = 7
}

local function fixLuaDate(dateD)
	local result = {
		year=dateD.year,
		month=dateD.month,
		monthDay=dateD.day,
		weekDay=dateD.wday,
		day=dateD.day,
	}
	return result
end

local function changeWeekdayOfDate(dateD, weekday, weekAdjustment)
	-- Change date to the chosen weekday of the same week
	local dateTime = time(dateD)
	local dateWeekday = date("*t", dateTime)["wday"]

	local delta = (dateWeekday - weekday) * SECONDS_IN_DAY
	local result = dateTime - delta
	if weekAdjustment ~= nil then
		result = result + (weekAdjustment * (7 * SECONDS_IN_DAY))
	end
	return fixLuaDate(date("*t", result))
end

function StubbedEventGetTextures(eventType)
	
	local original_textures = deep_copy(C_Calendar.EventGetTextures(eventType))

	-- Delete everything from the original --
	for k in pairs (original_textures) do
		original_textures[k] = nil
	end

	if eventType == 0 then
		tinsert(original_textures, {
			title="Blackfathom Deeps",
			isLfr=false,
			difficultyId=0,
			mapId=0,
			expansionLevel=0,
			iconTexture="Interface\\LFGFrame\\LFGIcon-BlackfathomDeeps"
		})
	end

	if eventType == 1 then
		tinsert(original_textures, {
			title="Deadmines",
			isLfr=false,
			difficultyId=0,
			mapId=0,
			expansionLevel=0,
			iconTexture="Interface\\LFGFrame\\LFGIcon-Deadmines"
		})
		tinsert(original_textures, {
			title="Razorfen Kraul",
			isLfr=false,
			difficultyId=0,
			mapId=0,
			expansionLevel=0,
			iconTexture="Interface\\LFGFrame\\LFGIcon-RazorfenKraul"
		})
		tinsert(original_textures, {
			title="Scarlet Monastery",
			isLfr=false,
			difficultyId=0,
			mapId=0,
			expansionLevel=0,
			iconTexture="Interface\\LFGFrame\\LFGIcon-ScarletMonastery"
		})
		tinsert(original_textures, {
			title="Shadowfang Keep",
			isLfr=false,
			difficultyId=0,
			mapId=0,
			expansionLevel=0,
			iconTexture="Interface\\LFGFrame\\LFGIcon-ShadowfangKeep"
		})
		tinsert(original_textures, {
			title="Stormwind Stockades",
			isLfr=false,
			difficultyId=0,
			mapId=0,
			expansionLevel=0,
			iconTexture="Interface\\LFGFrame\\LFGIcon-StormwindStockades"
		})
		tinsert(original_textures, {
			title="Wailing Caverns",
			isLfr=false,
			difficultyId=0,
			mapId=0,
			expansionLevel=0,
			iconTexture="Interface\\LFGFrame\\LFGIcon-WailingCaverns"
		})
	end

	return original_textures
end

local function isDarkmoonStart(eventDate, location)
	local firstDarkmoonStart
	if location == darkmoonLocations.Elwynn then
		firstDarkmoonStart = { year=2023, month=12, day=18 }
	elseif location == darkmoonLocations.Mulgore then
		firstDarkmoonStart = { year=2023, month=12, day=4 }
	end
	return dateIsOnFrequency(eventDate, firstDarkmoonStart, 28)
end

local function isDarkmoonOngoing(eventDate, location)
	local startEpoch
	local endEpoch
	if location == darkmoonLocations.Mulgore then
		startEpoch = time{ year=2023, month=12, day=4 }
		endEpoch = time{ year=2023, month=12, day=10 }
	elseif location == darkmoonLocations.Elwynn then
		startEpoch = time{ year=2023, month=12, day=18 }
		endEpoch = time{ year=2023, month=12, day=24 }
	end

	return isDateInRepeatingRange(eventDate, startEpoch, endEpoch, 28)
end

local function isDarkmoonEnd(eventDate, location)
	local firstDarkmoonStart
	if location == darkmoonLocations.Elwynn then
		firstDarkmoonStart = { year=2023, month=12, day=24 }
	elseif location == darkmoonLocations.Mulgore then
		firstDarkmoonStart = { year=2023, month=12, day=10 }
	end
	return dateIsOnFrequency(eventDate, firstDarkmoonStart, 28)
end

local function darkmoonStart(eventDate, location)
	local iconTexture
	if location == darkmoonLocations.Elwynn then
		iconTexture = "Interface/Calendar/Holidays/Calendar_DarkmoonFaireElwynnStart"
	elseif location == darkmoonLocations.Mulgore then
		iconTexture = "Interface/Calendar/Holidays/Calendar_DarkmoonFaireMulgoreStart"
	end

	local startTime = fixLuaDate(date("*t", time{
		year=eventDate.year,
		month=eventDate.month,
		day=eventDate.day
	}))
	startTime.hour = 0
	startTime.minute = 1
	local endTime = changeWeekdayOfDate(eventDate, WEEKDAYS.Sunday, 1)
	endTime.hour = 23
	endTime.minute = 59

	local fakeDarkmoonEvent = { -- CalendarEvent
		clubID=0,
		-- eventID=479,
		title="Darkmoon Faire",
		isCustomTitle=true,
		startTime=startTime,
		endTime=endTime,
		calendarType="HOLIDAY",
		sequenceType="START",
		eventType=CalendarEventType.Other,
		iconTexture=iconTexture,
		modStatus="",
		inviteStatus=0,
		invitedBy="",
		-- difficulty=nil,
		inviteType=CalendarInviteType.Normal,
		sequenceIndex=1,
		numSequenceDays=7,
		difficultyName="",
		dontDisplayBanner=false,
		dontDisplayEnd=false,
		isLocked=false,
	}
	return fakeDarkmoonEvent
end

local function darkmoonOngoing(eventDate, location)
	local iconTexture
	if location == darkmoonLocations.Elwynn then
		iconTexture = "Interface/Calendar/Holidays/Calendar_DarkmoonFaireElwynnOngoing"
	elseif location == darkmoonLocations.Mulgore then
		iconTexture = "Interface/Calendar/Holidays/Calendar_DarkmoonFaireMulgoreOngoing"
	end

	-- Calculate weekDay of eventDate, set StartTime to Monday and endTime to Sunday
	local startTime = changeWeekdayOfDate(eventDate, WEEKDAYS.Monday)
	local endTime = changeWeekdayOfDate(eventDate, WEEKDAYS.Sunday, 1)
	local sequenceIndex = ((time(eventDate) - time(startTime)) / SECONDS_IN_DAY) + 1
	startTime.hour = 0
	startTime.minute = 1
	endTime.hour = 23
	endTime.minute = 59

	local fakeDarkmoonEvent = { -- CalendarEvent
		clubID=0,
		-- eventID=479,
		title="Darkmoon Faire",
		isCustomTitle=true,
		startTime=startTime, 
		endTime=endTime,
		calendarType="HOLIDAY",
		sequenceType="ONGOING",
		eventType=CalendarEventType.Other,
		iconTexture=iconTexture,
		modStatus="",
		inviteStatus=0,
		invitedBy="",
		-- difficulty=nil,
		inviteType=CalendarInviteType.Normal,
		sequenceIndex=sequenceIndex,
		numSequenceDays=7,
		difficultyName="",
		dontDisplayBanner=false,
		dontDisplayEnd=false,
		isLocked=false,
	}
	return fakeDarkmoonEvent
end

local function darkmoonEnd(eventDate, location)
	local iconTexture
	if location == darkmoonLocations.Elwynn then
		iconTexture = "Interface/Calendar/Holidays/Calendar_DarkmoonFaireElwynnEnd"
	elseif location == darkmoonLocations.Mulgore then
		iconTexture = "Interface/Calendar/Holidays/Calendar_DarkmoonFaireMulgoreEnd"
	end

	local endTime = fixLuaDate(date("*t", time{
		year=eventDate.year,
		month=eventDate.month,
		day=eventDate.day
	}))
	endTime.hour = 23
	endTime.minute = 59
	local startTime = changeWeekdayOfDate(eventDate, WEEKDAYS.Monday)
	startTime.hour = 0
	startTime.minute = 1

	local fakeDarkmoonEvent = { -- CalendarEvent
		clubID=0,
		-- eventID=479,
		title="Darkmoon Faire",
		isCustomTitle=true,
		startTime=startTime,
		endTime=endTime,
		calendarType="HOLIDAY",
		sequenceType="END",
		eventType=CalendarEventType.Other,
		iconTexture=iconTexture,
		modStatus="",
		inviteStatus=0,
		invitedBy="",
		-- difficulty=nil,
		inviteType=CalendarInviteType.Normal,
		sequenceIndex=7,
		numSequenceDays=7,
		difficultyName="",
		dontDisplayBanner=false,
		dontDisplayEnd=false,
		isLocked=false,
	}
	return fakeDarkmoonEvent
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
			minute=0
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

function dayHasDarkmoon(eventDate)
	if GetCVar("calendarShowDarkmoon") == "0" then
		return false
	end

	local startEpoch = time{year=2023,month=12,day=18,hour=0,minute=1}
	local endEpoch = time{year=2023,month=12,day=24,hour=23,minute=59}

	return isDateInRepeatingRange(eventDate, startEpoch, endEpoch, 14)
end

function dayHasReset(eventDate)
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

function trueMonthOffset(monthOffset)
	-- Apply the month offset accumulated by stubbedSetMonth
	return monthOffset + state.monthOffset
end

function getAbsDate(monthOffset, monthDay)
	local eventDate = {
		year=state.presentYear,
		month=state.presentMonth,
		day=monthDay
	}
	if monthOffset > 0 then
		eventDate.year = state.presentYear + math.floor(monthOffset / 12)
	elseif monthOffset < 0 then
		eventDate.year = state.presentYear + math.ceil(monthOffset / 12)
	end

	eventDate.month = eventDate.month + monthOffset

	return eventDate
end

function dayHasBattleground(eventDate)
	if GetCVar("calendarShowBattlegrounds") == "0" then
		return false
	end

	-- Is it midnight to midnight? or daily reset to reset?
	local startEpoch = time{year=2023,month=12,day=15,hour=0,minute=1}
	local endEpoch = time{year=2023,month=12,day=18,hour=23,minute=59}

	-- Currently only WSG weekend, so 1 week every 4 weeks

	return isDateInRepeatingRange(eventDate, startEpoch, endEpoch, 28)
end

local function isBattlegroundStart(eventDate)
	local firstDarkmoonStart = { year=2023, month=12, day=15 }
	return dateIsOnFrequency(eventDate, firstDarkmoonStart, 28)
end

local function isBattlegroundOngoing(eventDate)
	local startEpoch = time{ year=2023, month=12, day=15 }
	local endEpoch = time{ year=2023, month=12, day=18 }
	return isDateInRepeatingRange(eventDate, startEpoch, endEpoch, 28)
end

local function isBattlegroundEnd(eventDate)
	local firstBattlegroundEnd = { year=2023, month=12, day=18 }
	return dateIsOnFrequency(eventDate, firstBattlegroundEnd, 28)
end

local function battlegroundStart(eventDate)
	local startTime = fixLuaDate(date("*t", time{
		year=eventDate.year,
		month=eventDate.month,
		day=eventDate.day
	}))
	startTime.hour = 0
	startTime.minute = 1
	local endTime = changeWeekdayOfDate(eventDate, WEEKDAYS.Monday, 1)
	endTime.hour = 23
	endTime.minute = 59

	local event = {
		title="Call to Arms (WSG)", -- I have no idea what these events are called
		isCustomTitle=true,
		startTime=startTime,
		endTime=endTime,
		calendarType="HOLIDAY",
		sequenceType="START",
		eventType=CalendarEventType.Other,
		iconTexture="Interface/Calendar/Holidays/Calendar_WeekendBattlegroundsStart",
		modStatus="",
		inviteStatus=0,
		invitedBy="",
		inviteType=CalendarInviteType.Normal,
		sequenceIndex=1,
		numSequenceDays=4,
		difficultyName="",
		dontDisplayBanner=false,
		dontDisplayEnd=false,
		isLocked=false,
	}
	return event
end

local function battlegroundOngoing(eventDate)
	local weekAdjustment = 0
	if date("*t", time(eventDate))['wday'] == WEEKDAYS.Sunday then
		weekAdjustment = -1
	end
	local startTime = changeWeekdayOfDate(eventDate, WEEKDAYS.Friday, weekAdjustment)
	local endTime = changeWeekdayOfDate(eventDate, WEEKDAYS.Monday, weekAdjustment + 1)
	local sequenceIndex = ((time(eventDate) - time(startTime)) / SECONDS_IN_DAY) + 1
	startTime.hour = 0
	startTime.minute = 1
	endTime.hour = 23
	endTime.minute = 59

	local event = {
		title="Call to Arms (WSG)",
		isCustomTitle=true,
		startTime=startTime, 
		endTime=endTime,
		calendarType="HOLIDAY",
		sequenceType="ONGOING",
		eventType=CalendarEventType.Other,
		iconTexture="Interface/Calendar/Holidays/Calendar_WeekendBattlegroundsOngoing",
		modStatus="",
		inviteStatus=0,
		invitedBy="",
		inviteType=CalendarInviteType.Normal,
		sequenceIndex=sequenceIndex,
		numSequenceDays=4,
		difficultyName="",
		dontDisplayBanner=false,
		dontDisplayEnd=false,
		isLocked=false,
	}
	return event
end

local function battlegroundEnd(eventDate)
	local endTime = fixLuaDate(date("*t", time{
		year=eventDate.year,
		month=eventDate.month,
		day=eventDate.day
	}))
	endTime.hour = 23
	endTime.minute = 59
	local startTime = changeWeekdayOfDate(eventDate, WEEKDAYS.Friday, -1)
	startTime.hour = 0
	startTime.minute = 1

	local fakeDarkmoonEvent = {
		title="Call to Arms (WSG)",
		isCustomTitle=true,
		startTime=startTime,
		endTime=endTime,
		calendarType="HOLIDAY",
		sequenceType="END",
		eventType=CalendarEventType.Other,
		iconTexture="Interface/Calendar/Holidays/Calendar_WeekendBattlegroundsEnd",
		modStatus="",
		inviteStatus=0,
		invitedBy="",
		inviteType=CalendarInviteType.Normal,
		sequenceIndex=4,
		numSequenceDays=4,
		difficultyName="",
		dontDisplayBanner=false,
		dontDisplayEnd=false,
		isLocked=false,
	}
	return fakeDarkmoonEvent
end

function stubbedGetNumDayEvents(monthOffset, monthDay)
	-- Stubbing C_Calendar.getNumDayEvents to return fake events
	local originalEventCount = C_Calendar.GetNumDayEvents(monthOffset, monthDay)
	local monthOffset = trueMonthOffset(monthOffset)
	local eventDate = getAbsDate(monthOffset, monthDay)

	if dayHasDarkmoon(eventDate) then
		originalEventCount = originalEventCount + 1
	end
	if dayHasReset(eventDate) then
		originalEventCount = originalEventCount + 1
	end
	if dayHasBattleground(eventDate) then
		originalEventCount = originalEventCount + 1
	end

	return originalEventCount
end

function stubbedGetDayEvent(monthOffset, monthDay, index)
	-- Stubbing C_Calendar.GetDayEvent to return events
	local originalEventCount = C_Calendar.GetNumDayEvents(monthOffset, monthDay)
	local originalEvent = C_Calendar.GetDayEvent(monthOffset, monthDay, index)
	local monthOffset = trueMonthOffset(monthOffset)
	local eventDate = getAbsDate(monthOffset, monthDay)

	if originalEvent == nil then
		if (dayHasDarkmoon(eventDate) and index == originalEventCount + 1) then
			if isDarkmoonStart(eventDate, darkmoonLocations.Elwynn) then
				return darkmoonStart(eventDate, darkmoonLocations.Elwynn)
			elseif isDarkmoonOngoing(eventDate, darkmoonLocations.Elwynn) then
				return darkmoonOngoing(eventDate, darkmoonLocations.Elwynn)
			elseif isDarkmoonEnd(eventDate, darkmoonLocations.Elwynn) then
				return darkmoonEnd(eventDate, darkmoonLocations.Elwynn)
			elseif isDarkmoonOngoing(eventDate, darkmoonLocations.Mulgore) then
				return darkmoonOngoing(eventDate, darkmoonLocations.Mulgore)
			elseif isDarkmoonStart(eventDate, darkmoonLocations.Mulgore) then
				return darkmoonStart(eventDate, darkmoonLocations.Mulgore)
			elseif isDarkmoonEnd(eventDate, darkmoonLocations.Mulgore) then
				return darkmoonEnd(eventDate, darkmoonLocations.Mulgore)
			end
		elseif (dayHasBattleground(eventDate) and (index == originalEventCount + 1 or (dayHasDarkmoon(eventDate) and index == originalEventCount + 2))) then
			if isBattlegroundStart(eventDate) then
				return battlegroundStart(eventDate)
			elseif isBattlegroundOngoing(eventDate) then
				return battlegroundOngoing(eventDate)
			elseif isBattlegroundEnd(eventDate) then
				return battlegroundEnd(eventDate)
			end
		elseif dayHasReset(eventDate) then
			return createResetEvent(eventDate)
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

	local currentCalendarTime = C_DateAndTime.GetCurrentCalendarTime()
	state.presentMonth = currentCalendarTime.month
	state.presentYear = currentCalendarTime.year
end

function stubbedOpenCalendar()
	-- Reset state
	local currentCalendarTime = C_DateAndTime.GetCurrentCalendarTime()
	state.presentMonth = currentCalendarTime.month
	state.presentYear = currentCalendarTime.year
	state.monthOffset = 0
	C_Calendar.OpenCalendar()
end

function communityName()
	-- Gets Guild Name from Player since built in functionality is broken
    local communityName, _ = GetGuildInfo("player")
	return communityName
end

function dumpTable(table, depth)
  if (depth > 200) then
    print("Error: Depth > 200 in dumpTable()")
    return
  end
  for k,v in pairs(table) do
    if (type(v) == "table") then
      print(string.rep("  ", depth)..k..":")
      dumpTable(v, depth+1)
    else
      print(string.rep("  ", depth)..k..": ",v)
    end
  end
end