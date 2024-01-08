local L = CLASSIC_CALENDAR_L
local localeString = tostring(GetLocale())

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

local DARKMOON_ELWYNN_LOCATION = 0
local DARKMOON_MULGORE_LOCATION = 1

local darkmoonLocations = {
	Elwynn = DARKMOON_ELWYNN_LOCATION,
	Mulgore = DARKMOON_MULGORE_LOCATION
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

local SECONDS_IN_DAY = 24 * 60 * 60

local function fixLuaDate(dateD)
	local result = {
		year=dateD.year,
		month=dateD.month,
		monthDay=dateD.day,
		weekDay=dateD.wday,
		day=dateD.day,
		hour=dateD.hour,
		min=dateD.min
	}
	return result
end

local function addDaysToDate(eventDate, dayCount)
	local dateSeconds = time(eventDate)
	dateSeconds = dateSeconds + dayCount * SECONDS_IN_DAY
	return fixLuaDate(date("*t", dateSeconds))
end

local function dateGreaterThan(date1, date2)
	return time(date1) > time(date2)
end

local function dateLessThan(date1, date2)
	return time(date1) < time(date2)
end

local function SetMinTime(date)
	local newDate = deep_copy(date)
	newDate.hour = 0
	newDate.min = 1
	return newDate
end

local function SetMaxTime(date)
	local newDate = deep_copy(date)
	newDate.hour = 23
	newDate.min = 59
	return newDate
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

local function isDateInRepeatingRange(eventDate, startEpoch, endEpoch, frequency)
	local dateTime = time(eventDate)
	local startEpochTime = time(startEpoch)
	local endEpochTime = time(endEpoch)
	local darkmoonFrequency = frequency * SECONDS_IN_DAY

	while dateTime > startEpochTime do
		if dateTime > startEpochTime and dateTime < endEpochTime then
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

local function adjustMonthByOffset(date, offset)
	date.month = date.month + offset
	if date.month > 12 then
		date.year = date.year + 1
		date.month = 1
	elseif date.month == 0 then
		date.year = date.year - 1
		date.month = 12
	end
end

local function GetEasterDate(year)
    local leap_year
    if year % 4 == 0 then
        if year % 100 == 0 then
            if year % 400 == 0 then
                leap_year = true
            else
                leap_year = false
            end
        else
            leap_year = true
        end
    else
        leap_year = false
    end
    local a = year % 19
    local b = math.floor(year / 100)
    local c = year % 100
    local d = math.floor(b / 4)
    local e = b % 4
    local f = math.floor((b + 8) / 25)
    local g = math.floor((b - f + 1) / 3)
    local h = (19 * a + b - d - g + 15) % 30
    local i = math.floor(c / 4)
    local k = c % 4
    local n = (32 + 2 * e + 2 * i - h - k) %7
    local m = math.floor((a + 11 * h + 22 * n) / 451)
    local month = math.floor((h + n - 7 * m + 114) / 31)
    local day = (h + n - 7 * m + 114) % 31 + 1
    if month == 2 then    --adjust dates in February
        day = leap_year and day - 2 or day - 3
    end
    return { year=year, month=month, day=day }
end

local function GetNewMoons(date)
    local LUNAR_MONTH = 29.5305888531  -- https://en.wikipedia.org/wiki/Lunar_month
    local y = date.year
    local m = date.month
    local d = date.day
    -- https://www.subsystems.us/uploads/9/8/9/4/98948044/moonphase.pdf
    if (m <= 2) then
        y = y - 1
        m = m + 12
	end
    local a = math.floor(y / 100)
    local b = math.floor(a / 4)
    local c = 2 - a + b
    local e = math.floor(365.25 * (y + 4716))
    local f = math.floor(30.6001 * (m + 1))
    local julian_day = c + d + e + f - 1524.5
    local days_since_last_new_moon = julian_day - 2451549.5
    local new_moons = days_since_last_new_moon / LUNAR_MONTH
    -- local days_into_cycle = (new_moons % 1) * LUNAR_MONTH
    return new_moons
end

local function InChineseNewYear(date)
    --[[ The date is decided by the Chinese Lunar Calendar, which is based on the
    cycles of the moon and sun and is generally 21–51 days behind the Gregorian
    (internationally-used) calendar. The date of Chinese New Year changes every
    year, but it always falls between January 21st and February 20th. --]]
    return math.floor(GetNewMoons(date)) > math.floor(GetNewMoons({ year=date.year, month=1, day=20 }))
end

local function GetChineseNewYear(year)
    -- Does not quite line up with https://www.travelchinaguide.com/essential/holidays/new-year/dates.htm
    for i=0, 30 do
        local start = { year=year, month=1, day=21 }
        start = addDaysToDate(start, i)
        if(InChineseNewYear(start)) then
			return start
		end
	end
end

local function GetLunarFestivalStart(year)
	local cny = GetChineseNewYear(year)
	cny.hour = 9
	cny.min = 0
	return cny
end

local function GetLunarFestivalEnd(year)
	local cny = GetChineseNewYear(year)
	cny = addDaysToDate(cny, 7)
	cny.hour = 9
	cny.min = 0
	return cny
end

local holidays = {
	DarkmoonFaireElwynn = {
		name=L.Localization[localeString]["CalendarHolidays"]["DarkmoonFaireElwynn"]["name"],
		description=L.Localization[localeString]["CalendarHolidays"]["DarkmoonFaireElwynn"]["description"],
		startDate={ year=2023, month=12, day=18, hour=0, min=1 },
		endDate={ year=2023, month=12, day=24, hour=23, min=59 },
		frequency=28
	},
	DarkmoonFaireMulgore = {
		name=L.Localization[localeString]["CalendarHolidays"]["DarkmoonFaireMulgore"]["name"],
		description=L.Localization[localeString]["CalendarHolidays"]["DarkmoonFaireMulgore"]["description"],
		startDate={ year=2023, month=12, day=4, hour=0, min=1 },
		endDate={ year=2023, month=12, day=10, hour=23, min=59 },
		frequency=28
	},
	WintersVeil = {
		name=L.Localization[localeString]["CalendarHolidays"]["WintersVeil"]["name"],
		description=L.Localization[localeString]["CalendarHolidays"]["WintersVeil"]["description"],
		startDate={ year=2024, month=12, day=16, hour=9, min=0 },
		endDate={ year=2025, month=1, day= 2, hour=9, min=0 }
	},
	Noblegarden = {
		name=L.Localization[localeString]["CalendarHolidays"]["Noblegarden"]["name"],
		description=L.Localization[localeString]["CalendarHolidays"]["Noblegarden"]["description"],
		-- Coincides with Easter Sunday
		startDate=SetMinTime(GetEasterDate(currentCalendarTime.year)),
		endDate=SetMaxTime(GetEasterDate(currentCalendarTime.year))
	},
	ChildrensWeek = {
		name=L.Localization[localeString]["CalendarHolidays"]["ChildrensWeek"]["name"],
		description=L.Localization[localeString]["CalendarHolidays"]["ChildrensWeek"]["description"],
		startDate={ year=2024, month=4, day=29, hour=13, min=0 },
		endDate={ year=2024, month=5, day=6, hour=13, min=0 }
	},
	HarvestFestival = {
		name=L.Localization[localeString]["CalendarHolidays"]["HarvestFestival"]["name"],
		description=L.Localization[localeString]["CalendarHolidays"]["HarvestFestival"]["description"],
		startDate={ year=2024, month=9, day=13, hour=3, min=0 },
		endDate={ year=2024, month=9, day=20, hour=3, min=0 }
	},
	HallowsEnd = {
		name=L.Localization[localeString]["CalendarHolidays"]["HallowsEnd"]["name"],
		description=L.Localization[localeString]["CalendarHolidays"]["HallowsEnd"]["description"],
		startDate={ year=2024, month=10, day=18, hour=4, min=0 },
		endDate={ year=2024, month=11, day=1, hour=3, min=0 }
	},
	LunarFestival = {
		name=L.Localization[localeString]["CalendarHolidays"]["LunarFestival"]["name"],
		description=L.Localization[localeString]["CalendarHolidays"]["LunarFestival"]["description"],
		-- Coincides with Chinese New Year
		startDate=GetLunarFestivalStart(currentCalendarTime.year),
		endDate=GetLunarFestivalEnd(currentCalendarTime.year)
	},
	LoveisintheAir = {
		name=L.Localization[localeString]["CalendarHolidays"]["LoveisintheAir"]["name"],
		description=L.Localization[localeString]["CalendarHolidays"]["LoveisintheAir"]["description"],
		startDate={ year=2024, month=2, day=5, hour=13, min=0 },
		endDate={ year=2024, month=2, day=19, hour=13, min=0 }
	},
	MidsummerFireFestival = {
		name=L.Localization[localeString]["CalendarHolidays"]["MidsummerFireFestival"]["name"],
		description=L.Localization[localeString]["CalendarHolidays"]["MidsummerFireFestival"]["description"],
		-- Coincides with Summer Solstice. For which hemisphere? Who knows
		startDate={ year=2024, month=6, day=21, hour=7, min=0 },
		endDate={ year=2024, month=6, day=28, hour=7, min=0 }
	},
	FireworksSpectacular = {
		name=L.Localization[localeString]["CalendarHolidays"]["FireworksSpectacular"]["name"],
		description=L.Localization[localeString]["CalendarHolidays"]["FireworksSpectacular"]["description"],
		-- Occurs the last day/night of Midsummer
		startDate={ year=2024, month=6, day=27, hour=9, min=0 },
		endDate={ year=2024, month=28, day=28, hour=3, min=0 }
	}
}

local battlegroundWeekends = {
	warsongGulch = {
		name=L.Localization[localeString]["CalendarPVP"]["WarsongGulch"]["name"],
		description=L.Localization[localeString]["CalendarPVP"]["WarsongGulch"]["description"],
		startDate={ year=2023, month=12, day=15, hour=0, min=1 },
		endDate={ year=2023, month=12, day=19, hour=8, min=0 },
		frequency=28
	},
	-- arathiBasin = {
	-- 	name=L.Localization[localeString]["CalendarPVP"]["ArathiBasin"]["name"],
	-- 	description=L.Localization[localeString]["CalendarPVP"]["ArathiBasin"]["description"],
	-- 	startDate={ year=2023, month=12, day=22, hour=0, min=1 },
	-- 	endDate={ year=2023, month=12, day=26. hour=8, min=0 },
	--  frequency=28
	-- },
	-- alteracValley = {
	-- 	name=L.Localization[localeString]["CalendarPVP"]["AlteracValley"]["name"],
	-- 	description=L.Localization[localeString]["CalendarPVP"]["AlteracValley"]["description"],
	-- 	startDate={ year=2023, month=12, day=29, hour=0, min=1 },
	-- 	endDate={ year=2024, month=1, day=2, hour=8, min=0 },
	--  frequency=28
	-- }
}

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

local function getOngoingDates(startDate, endDate)
	local endTime = time(endDate) - SECONDS_IN_DAY
	return date("*t", time(startDate)), date("*t", endTime)
end

local function isDarkmoonStart(eventDate, location)
	if location == darkmoonLocations.Elwynn then
		return dateIsOnFrequency(eventDate, holidays.DarkmoonFaireElwynn.startDate, holidays.DarkmoonFaireElwynn.frequency)
	elseif location == darkmoonLocations.Mulgore then
		return dateIsOnFrequency(eventDate, holidays.DarkmoonFaireMulgore.startDate, holidays.DarkmoonFaireMulgore.frequency)
	end
	return false
end

local function isDarkmoonOngoing(eventDate, location)
	if location == darkmoonLocations.Mulgore then
		local startEpoch, endEpoch = getOngoingDates(holidays.DarkmoonFaireMulgore.startDate, holidays.DarkmoonFaireMulgore.endDate)
		return isDateInRepeatingRange(eventDate, startEpoch, endEpoch, holidays.DarkmoonFaireMulgore.frequency)
	elseif location == darkmoonLocations.Elwynn then
		local startEpoch, endEpoch = getOngoingDates(holidays.DarkmoonFaireElwynn.startDate, holidays.DarkmoonFaireElwynn.endDate)
		return isDateInRepeatingRange(eventDate, startEpoch, endEpoch, holidays.DarkmoonFaireElwynn.frequency)
	end
	return false
end

local function isDarkmoonEnd(eventDate, location)
	if location == darkmoonLocations.Elwynn then
		return dateIsOnFrequency(eventDate, holidays.DarkmoonFaireElwynn.endDate, holidays.DarkmoonFaireElwynn.frequency)
	elseif location == darkmoonLocations.Mulgore then
		return dateIsOnFrequency(eventDate, holidays.DarkmoonFaireMulgore.endDate, holidays.DarkmoonFaireMulgore.frequency)
	end
	return false
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
	startTime.min = 1
	local endTime = changeWeekdayOfDate(eventDate, WEEKDAYS.Sunday, 1)
	endTime.hour = 23
	endTime.min = 59

	local fakeDarkmoonEvent = { -- CalendarEvent
		clubID=0,
		-- eventID=479,
		title=holidays.DarkmoonFaireElwynn.name,
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
	startTime.min = 1
	endTime.hour = 23
	endTime.min = 59

	local fakeDarkmoonEvent = { -- CalendarEvent
		clubID=0,
		-- eventID=479,
		title=holidays.DarkmoonFaireElwynn.name,
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
	endTime.min = 59
	local startTime = changeWeekdayOfDate(eventDate, WEEKDAYS.Monday)
	startTime.hour = 0
	startTime.min = 1

	local fakeDarkmoonEvent = { -- CalendarEvent
		clubID=0,
		-- eventID=479,
		title=holidays.DarkmoonFaireElwynn.name,
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

local function dayHasDarkmoon(eventDate)
	if GetCVar("calendarShowDarkmoon") == "0" then
		return false
	end

	-- first darkmoon faire was in mulgore
	local startEpoch = holidays.DarkmoonFaireMulgore.startDate
	local endEpoch = holidays.DarkmoonFaireMulgore.endDate

	return isDateInRepeatingRange(eventDate, startEpoch, endEpoch, 14)
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

local function dayHasBattleground(eventDate)
	if GetCVar("calendarShowBattlegrounds") == "0" then
		return false
	end

	-- Set eventDate hour to 1 so it's less than daily reset on endDate
	eventDate = deep_copy(eventDate)
	eventDate.hour=1

	-- Currently only WSG weekend, so 1 week every 4 weeks
	local isWSG = isDateInRepeatingRange(eventDate, battlegroundWeekends.warsongGulch.startDate, battlegroundWeekends.warsongGulch.endDate, battlegroundWeekends.warsongGulch.frequency)
	-- isAB = isDateInRepeatingRange(eventDate, battlegroundWeekends.arathiBasin.startDate, battlegroundWeekends.arathiBasin.endDate, battlegroundWeekends.arathiBasin.frequency)
	-- isAV = isDateInRepeatingRange(eventDate, battlegroundWeekends.alteracValley.startDate, battlegroundWeekends.alteracValley.endDate, battlegroundWeekends.alteracValley.frequency)

	return isWSG
end

local function isBattlegroundStart(eventDate)
	return dateIsOnFrequency(eventDate, battlegroundWeekends.warsongGulch.startDate, battlegroundWeekends.warsongGulch.frequency)
end

local function isBattlegroundOngoing(eventDate)
	local startEpoch, endEpoch = getOngoingDates(battlegroundWeekends.warsongGulch.startDate, battlegroundWeekends.warsongGulch.endDate)
	return isDateInRepeatingRange(eventDate, startEpoch, SetMaxTime(endEpoch), battlegroundWeekends.warsongGulch.frequency)
end

local function isBattlegroundEnd(eventDate)
	return dateIsOnFrequency(eventDate, battlegroundWeekends.warsongGulch.endDate, battlegroundWeekends.warsongGulch.frequency)
end

local function battlegroundStart(eventDate)
	local startTime = fixLuaDate(date("*t", time{
		year=eventDate.year,
		month=eventDate.month,
		day=eventDate.day
	}))
	startTime.hour = 0
	startTime.min = 1
	local endTime = changeWeekdayOfDate(eventDate, WEEKDAYS.Tuesday, 1)
	endTime.hour = 8
	endTime.min = 0

	local event = {
		title=battlegroundWeekends.warsongGulch.name,
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
		numSequenceDays=5,
		difficultyName="",
		dontDisplayBanner=false,
		dontDisplayEnd=false,
		isLocked=false,
	}
	return event
end

local function battlegroundOngoing(eventDate)
	local weekAdjustment = 0
	if date("*t", time(eventDate))['wday'] <= WEEKDAYS.Tuesday then
		weekAdjustment = -1
	end
	local startTime = changeWeekdayOfDate(eventDate, WEEKDAYS.Friday, weekAdjustment)
	local endTime = changeWeekdayOfDate(eventDate, WEEKDAYS.Tuesday, weekAdjustment + 1)
	local sequenceIndex = ((time(eventDate) - time(startTime)) / SECONDS_IN_DAY) + 1
	startTime.hour = 0
	startTime.min = 1
	endTime.hour = 8
	endTime.min = 0

	local event = {
		title=battlegroundWeekends.warsongGulch.name,
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
		numSequenceDays=5,
		difficultyName="",
		dontDisplayBanner=false,
		dontDisplayEnd=false,
		isLocked=false,
	}
	return event
end

local function battlegroundEnd(eventDate)
	local weekAdjustment = 0
	if date("*t", time(eventDate))['wday'] <= WEEKDAYS.Monday then
		weekAdjustment = -1
	end
	local startTime = changeWeekdayOfDate(eventDate, WEEKDAYS.Friday, weekAdjustment)
	startTime.hour = 0
	startTime.min = 1
	local endTime = fixLuaDate(date("*t", time{
		year=eventDate.year,
		month=eventDate.month,
		day=eventDate.day
	}))
	endTime.hour = 8
	endTime.min = 0

	local event = {
		title=battlegroundWeekends.warsongGulch.name,
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
		sequenceIndex=5,
		numSequenceDays=5,
		difficultyName="",
		dontDisplayBanner=false,
		dontDisplayEnd=false,
		isLocked=false,
	}
	return event
end

function stubbedGetNumDayEvents(monthOffset, monthDay)
	-- Stubbing C_Calendar.getNumDayEvents to return fake events
	local originalEventCount = C_Calendar.GetNumDayEvents(monthOffset, monthDay)
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
	local eventDate = getAbsDate(monthOffset, monthDay)

	state.currentEventIndex = index
	state.currentMonthOffset = monthOffset

	if originalEvent == nil then
		if (dayHasDarkmoon(eventDate) and index == originalEventCount + 1) then
			-- Elwynn
			if isDarkmoonStart(eventDate, darkmoonLocations.Elwynn) then
				return darkmoonStart(eventDate, darkmoonLocations.Elwynn)
			elseif isDarkmoonOngoing(eventDate, darkmoonLocations.Elwynn) then
				return darkmoonOngoing(eventDate, darkmoonLocations.Elwynn)
			elseif isDarkmoonEnd(eventDate, darkmoonLocations.Elwynn) then
				return darkmoonEnd(eventDate, darkmoonLocations.Elwynn)
			-- Mulgore
			elseif isDarkmoonStart(eventDate, darkmoonLocations.Mulgore) then
				return darkmoonStart(eventDate, darkmoonLocations.Mulgore)
			elseif isDarkmoonOngoing(eventDate, darkmoonLocations.Mulgore) then
				return darkmoonOngoing(eventDate, darkmoonLocations.Mulgore)
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

	for _, holiday in next, holidays, nil do
		-- No way to differentiate the locations of darkmoon faire
		if eventName == holiday.name then
			eventDesc = holiday.description
		end
	end

	for _, bg in next, battlegroundWeekends, nil do
		if eventName == bg.name then
			eventDesc = bg.description
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