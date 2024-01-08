local L = CLASSIC_CALENDAR_L
local localeString = tostring(GetLocale())
local currentCalendarTime = C_DateAndTime.GetCurrentCalendarTime()
local SECONDS_IN_DAY = 24 * 60 * 60

function DeepCopyTable(t, seen)
    local result = {}
    seen = seen or {}
    seen[t] = result
    for key, value in pairs(t) do
        if type(value) == "table" then
            result[key] = seen[value] or DeepCopyTable(value, seen)
        else
            result[key] = value
        end
    end
    return result
end

local function addDaysToDate(eventDate, dayCount)
	local dateSeconds = time(eventDate)
	dateSeconds = dateSeconds + dayCount * SECONDS_IN_DAY
	return date("*t", dateSeconds)
end

function SetMinTime(date)
	local newDate = DeepCopyTable(date)
	newDate.hour = 0
	newDate.min = 1
	return newDate
end

function SetMaxTime(date)
	local newDate = DeepCopyTable(date)
	newDate.hour = 23
	newDate.min = 59
	return newDate
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

CLASSIC_CALENDAR_HOLIDAYS = {
	DarkmoonFaireElwynn = {
		name=L.Localization[localeString]["CalendarHolidays"]["DarkmoonFaireElwynn"]["name"],
		description=L.Localization[localeString]["CalendarHolidays"]["DarkmoonFaireElwynn"]["description"],
		startDate={ year=2023, month=12, day=18, hour=0, min=1 },
		endDate={ year=2023, month=12, day=24, hour=23, min=59 },
		frequency=28,
		CVar="calendarShowDarkmoon",
		startTexture="Interface/Calendar/Holidays/Calendar_DarkmoonFaireElwynnStart",
		ongoingTexture="Interface/Calendar/Holidays/Calendar_DarkmoonFaireElwynnOngoing",
		endTexture="Interface/Calendar/Holidays/Calendar_DarkmoonFaireElwynnEnd"
	},
	DarkmoonFaireMulgore = {
		name=L.Localization[localeString]["CalendarHolidays"]["DarkmoonFaireMulgore"]["name"],
		description=L.Localization[localeString]["CalendarHolidays"]["DarkmoonFaireMulgore"]["description"],
		startDate={ year=2023, month=12, day=4, hour=0, min=1 },
		endDate={ year=2023, month=12, day=10, hour=23, min=59 },
		frequency=28,
		CVar="calendarShowDarkmoon",
		startTexture="Interface/Calendar/Holidays/Calendar_DarkmoonFaireMulgoreStart",
		ongoingTexture="Interface/Calendar/Holidays/Calendar_DarkmoonFaireMulgoreOngoing",
		endTexture="Interface/Calendar/Holidays/Calendar_DarkmoonFaireMulgoreEnd"
	},
	WintersVeil = {
		name=L.Localization[localeString]["CalendarHolidays"]["WintersVeil"]["name"],
		description=L.Localization[localeString]["CalendarHolidays"]["WintersVeil"]["description"],
		startDate={ year=2024, month=12, day=16, hour=9, min=0 },
		endDate={ year=2025, month=1, day= 2, hour=9, min=0 },
		startTexture="Interface/Calendar/Holidays/Calendar_WinterVeilStart",
		ongoingTexture="Interface/Calendar/Holidays/Calendar_WinterVeilOngoing",
		endTexture="Interface/Calendar/Holidays/Calendar_WinterVeilEnd"
	},
	Noblegarden = {
		name=L.Localization[localeString]["CalendarHolidays"]["Noblegarden"]["name"],
		description=L.Localization[localeString]["CalendarHolidays"]["Noblegarden"]["description"],
		-- Coincides with Easter Sunday
		startDate=SetMinTime(GetEasterDate(currentCalendarTime.year)),
		endDate=SetMaxTime(GetEasterDate(currentCalendarTime.year)),
		startTexture="Interface/Calendar/Holidays/Calendar_NoblegardenStart",
		ongoingTexture="Interface/Calendar/Holidays/Calendar_NoblegardenOngoing",
		endTexture="Interface/Calendar/Holidays/Calendar_NoblegardenEnd"
	},
	ChildrensWeek = {
		name=L.Localization[localeString]["CalendarHolidays"]["ChildrensWeek"]["name"],
		description=L.Localization[localeString]["CalendarHolidays"]["ChildrensWeek"]["description"],
		startDate={ year=2024, month=4, day=29, hour=13, min=0 },
		endDate={ year=2024, month=5, day=6, hour=13, min=0 },
		startTexture="Interface/Calendar/Holidays/Calendar_ChildrensWeekStart",
		ongoingTexture="Interface/Calendar/Holidays/Calendar_ChildrensWeekOngoing",
		endTexture="Interface/Calendar/Holidays/Calendar_ChildrensWeekEnd"
	},
	HarvestFestival = {
		name=L.Localization[localeString]["CalendarHolidays"]["HarvestFestival"]["name"],
		description=L.Localization[localeString]["CalendarHolidays"]["HarvestFestival"]["description"],
		startDate={ year=2024, month=9, day=13, hour=3, min=0 },
		endDate={ year=2024, month=9, day=20, hour=3, min=0 },
		startTexture="Interface/Calendar/Holidays/Calendar_HarvestFestivalStart",
		ongoingTexture="Interface/Calendar/Holidays/Calendar_HarvestFestivalOngoing",
		endTexture="Interface/Calendar/Holidays/Calendar_HarvestFestivalEnd"
	},
	HallowsEnd = {
		name=L.Localization[localeString]["CalendarHolidays"]["HallowsEnd"]["name"],
		description=L.Localization[localeString]["CalendarHolidays"]["HallowsEnd"]["description"],
		startDate={ year=2024, month=10, day=18, hour=4, min=0 },
		endDate={ year=2024, month=11, day=1, hour=3, min=0 },
		startTexture="Interface/Calendar/Holidays/Calendar_HallowsEndStart",
		ongoingTexture="Interface/Calendar/Holidays/Calendar_HallowsEndOngoing",
		endTexture="Interface/Calendar/Holidays/Calendar_HallowsEndEnd"
	},
	LunarFestival = {
		name=L.Localization[localeString]["CalendarHolidays"]["LunarFestival"]["name"],
		description=L.Localization[localeString]["CalendarHolidays"]["LunarFestival"]["description"],
		-- Coincides with Chinese New Year
		startDate=GetLunarFestivalStart(currentCalendarTime.year),
		endDate=GetLunarFestivalEnd(currentCalendarTime.year),
		startTexture="Interface/Calendar/Holidays/Calendar_LunarFestivalStart",
		ongoingTexture="Interface/Calendar/Holidays/Calendar_LunarFestivalOngoing",
		endTexture="Interface/Calendar/Holidays/Calendar_LunarFestivalEnd"
	},
	LoveisintheAir = {
		name=L.Localization[localeString]["CalendarHolidays"]["LoveisintheAir"]["name"],
		description=L.Localization[localeString]["CalendarHolidays"]["LoveisintheAir"]["description"],
		startDate={ year=2024, month=2, day=5, hour=13, min=0 },
		endDate={ year=2024, month=2, day=19, hour=13, min=0 },
		startTexture="Interface/Calendar/Holidays/Calendar_LoveInTheAirStart",
		ongoingTexture="Interface/Calendar/Holidays/Calendar_LoveInTheAirOngoing",
		endTexture="Interface/Calendar/Holidays/Calendar_LoveInTheAirEnd"
	},
	MidsummerFireFestival = {
		name=L.Localization[localeString]["CalendarHolidays"]["MidsummerFireFestival"]["name"],
		description=L.Localization[localeString]["CalendarHolidays"]["MidsummerFireFestival"]["description"],
		-- Coincides with Summer Solstice. For which hemisphere? Who knows
		startDate={ year=2024, month=6, day=21, hour=7, min=0 },
		endDate={ year=2024, month=6, day=28, hour=7, min=0 },
		startTexture="Interface/Calendar/Holidays/Calendar_MidsummerStart",
		ongoingTexture="Interface/Calendar/Holidays/Calendar_MidsummerOngoing",
		endTexture="Interface/Calendar/Holidays/Calendar_MidsummerEnd"
	},
	FireworksSpectacular = {
		name=L.Localization[localeString]["CalendarHolidays"]["FireworksSpectacular"]["name"],
		description=L.Localization[localeString]["CalendarHolidays"]["FireworksSpectacular"]["description"],
		-- Occurs the last day/night of Midsummer
		startDate={ year=2024, month=6, day=27, hour=9, min=0 },
		endDate={ year=2024, month=28, day=28, hour=3, min=0 },
		startTexture="Interface/Calendar/Holidays/Calendar_Fireworks",
		ongoingTexture="Interface/Calendar/Holidays/Calendar_Fireworks",
		endTexture="Interface/Calendar/Holidays/Calendar_Fireworks"
	},
	warsongGulch = {
		name=L.Localization[localeString]["CalendarPVP"]["WarsongGulch"]["name"],
		description=L.Localization[localeString]["CalendarPVP"]["WarsongGulch"]["description"],
		startDate={ year=2023, month=12, day=15, hour=0, min=1 },
		endDate={ year=2023, month=12, day=19, hour=8, min=0 },
		frequency=28,
		CVar="calendarShowBattlegrounds",
		startTexture="Interface/Calendar/Holidays/Calendar_WeekendBattlegroundsStart",
		ongoingTexture="Interface/Calendar/Holidays/Calendar_WeekendBattlegroundsOngoing",
		endTexture="Interface/Calendar/Holidays/Calendar_WeekendBattlegroundsEnd"
	},
	-- arathiBasin = {
	-- 	name=L.Localization[localeString]["CalendarPVP"]["ArathiBasin"]["name"],
	-- 	description=L.Localization[localeString]["CalendarPVP"]["ArathiBasin"]["description"],
	-- 	startDate={ year=2023, month=12, day=22, hour=0, min=1 },
	-- 	endDate={ year=2023, month=12, day=26. hour=8, min=0 },
	--  frequency=28,
	--  CVar="calendarShowBattlegrounds",
	--  startTexture="Interface/Calendar/Holidays/Calendar_WeekendBattlegroundsStart",
	--  ongoingTexture="Interface/Calendar/Holidays/Calendar_WeekendBattlegroundsOngoing",
	--  endTexture="Interface/Calendar/Holidays/Calendar_WeekendBattlegroundsEnd"
	-- },
	-- alteracValley = {
	-- 	name=L.Localization[localeString]["CalendarPVP"]["AlteracValley"]["name"],
	-- 	description=L.Localization[localeString]["CalendarPVP"]["AlteracValley"]["description"],
	-- 	startDate={ year=2023, month=12, day=29, hour=0, min=1 },
	-- 	endDate={ year=2024, month=1, day=2, hour=8, min=0 },
	--  frequency=28,
	--  CVar="calendarShowBattlegrounds",
	--  startTexture="Interface/Calendar/Holidays/Calendar_WeekendBattlegroundsStart",
	--  ongoingTexture="Interface/Calendar/Holidays/Calendar_WeekendBattlegroundsOngoing",
	--  endTexture="Interface/Calendar/Holidays/Calendar_WeekendBattlegroundsEnd"
	-- }
}