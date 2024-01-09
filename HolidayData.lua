local L = CLASSIC_CALENDAR_L
local localeString = tostring(GetLocale())
local currentCalendarTime = C_DateAndTime.GetCurrentCalendarTime()
local SECONDS_IN_DAY = 24 * 60 * 60
local date = date
local time = time
local floor = floor
local tinsert = tinsert

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

function SetMinTime(dateD)
	local newDate = DeepCopyTable(dateD)
	newDate.hour = 0
	newDate.min = 1
	return newDate
end

function SetMaxTime(dateD)
	local newDate = DeepCopyTable(dateD)
	newDate.hour = 23
	newDate.min = 59
	return newDate
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
	return date("*t", result)
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
	local b = floor(year / 100)
	local c = year % 100
	local d = floor(b / 4)
	local e = b % 4
	local f = floor((b + 8) / 25)
	local g = floor((b - f + 1) / 3)
	local h = (19 * a + b - d - g + 15) % 30
	local i = floor(c / 4)
	local k = c % 4
	local n = (32 + 2 * e + 2 * i - h - k) %7
	local m = floor((a + 11 * h + 22 * n) / 451)
	local month = floor((h + n - 7 * m + 114) / 31)
	local day = (h + n - 7 * m + 114) % 31 + 1
	if month == 2 then	--adjust dates in February
		day = leap_year and day - 2 or day - 3
	end
	return { year=year, month=month, day=day }
end

local function GetNewMoons(dateD)
	local LUNAR_MONTH = 29.5305888531  -- https://en.wikipedia.org/wiki/Lunar_month
	local y = dateD.year
	local m = dateD.month
	local d = dateD.day
	-- https://www.subsystems.us/uploads/9/8/9/4/98948044/moonphase.pdf
	if (m <= 2) then
		y = y - 1
		m = m + 12
	end
	local a = floor(y / 100)
	local b = floor(a / 4)
	local c = 2 - a + b
	local e = floor(365.25 * (y + 4716))
	local f = floor(30.6001 * (m + 1))
	local julian_day = c + d + e + f - 1524.5
	local days_since_last_new_moon = julian_day - 2451549.5
	local new_moons = days_since_last_new_moon / LUNAR_MONTH
	-- local days_into_cycle = (new_moons % 1) * LUNAR_MONTH
	return new_moons
end

local function InChineseNewYear(dateD)
	--[[ The date is decided by the Chinese Lunar Calendar, which is based on the
	cycles of the moon and sun and is generally 21–51 days behind the Gregorian
	(internationally-used) calendar. The date of Chinese New Year changes every
	year, but it always falls between January 21st and February 20th. --]]
	return floor(GetNewMoons(dateD)) > floor(GetNewMoons({ year=dateD.year, month=1, day=20 }))
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

local CLASSIC_CALENDAR_HOLIDAYS = {
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
		artConfig="ChildrensWeekArt",
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
		startDate={ year=2024, month=2, day=11, hour=13, min=0 },
		endDate={ year=2024, month=2, day=16, hour=13, min=0 },
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
		endDate={ year=2024, month=6, day=28, hour=3, min=0 },
		artConfig="FireworksSpectacularArt",
		startTexture="Interface/Calendar/Holidays/Calendar_Fireworks",
		ongoingTexture="Interface/Calendar/Holidays/Calendar_Fireworks",
		endTexture="Interface/Calendar/Holidays/Calendar_Fireworks"
	},
	Fishing = {
		name=L.Localization[localeString]["CalendarHolidays"]["StranglethornFishingExtravaganza"]["name"],
		description=L.Localization[localeString]["CalendarHolidays"]["StranglethornFishingExtravaganza"]["description"],
		startDate={ year=2024, month=2, day=11, hour=14, min=0 },
		endDate={ year=2024, month=2, day=11, hour=16, min=0 },
		frequency=7,
		CVar="calendarShowWeeklyHolidays",
		startTexture="Interface/Calendar/Holidays/Calendar_FishingExtravaganza",
		ongoingTexture="Interface/Calendar/Holidays/Calendar_FishingExtravaganza",
		endTexture="Interface/Calendar/Holidays/Calendar_FishingExtravaganza"
	},
	warsongGulch = {
		name=L.Localization[localeString]["CalendarPVP"]["WarsongGulch"]["name"],
		description=L.Localization[localeString]["CalendarPVP"]["WarsongGulch"]["description"],
		startDate={ year=2023, month=12, day=15, hour=0, min=1 },
		endDate={ year=2023, month=12, day=19, hour=8, min=0 },
		frequency=28,
		CVar="calendarShowBattlegrounds",
		artConfig="BattlegroundsArt",
		startTexture="Interface/Calendar/Holidays/Calendar_WeekendBattlegroundsStart",
		ongoingTexture="Interface/Calendar/Holidays/Calendar_WeekendBattlegroundsOngoing",
		endTexture="Interface/Calendar/Holidays/Calendar_WeekendBattlegroundsEnd"
	},
	arathiBasin = {
		name=L.Localization[localeString]["CalendarPVP"]["ArathiBasin"]["name"],
		description=L.Localization[localeString]["CalendarPVP"]["ArathiBasin"]["description"],
		startDate={ year=2024, month=2, day=16, hour=0, min=1 },
		endDate={ year=2024, month=2, day=20, hour=8, min=0 },
		frequency=28,
		CVar="calendarShowBattlegrounds",
		artConfig="BattlegroundsArt",
		startTexture="Interface/Calendar/Holidays/Calendar_WeekendBattlegroundsStart",
		ongoingTexture="Interface/Calendar/Holidays/Calendar_WeekendBattlegroundsOngoing",
		endTexture="Interface/Calendar/Holidays/Calendar_WeekendBattlegroundsEnd"
	},
	-- alteracValley = {
	--	 name=L.Localization[localeString]["CalendarPVP"]["AlteracValley"]["name"],
	--	 description=L.Localization[localeString]["CalendarPVP"]["AlteracValley"]["description"],
	--	 startDate={ year=2023, month=12, day=29, hour=0, min=1 },
	--	 endDate={ year=2024, month=1, day=2, hour=8, min=0 },
	--  frequency=28,
	--  CVar="calendarShowBattlegrounds",
	--  artConfig="BattlegroundsArt",
	--  startTexture="Interface/Calendar/Holidays/Calendar_WeekendBattlegroundsStart",
	--  ongoingTexture="Interface/Calendar/Holidays/Calendar_WeekendBattlegroundsOngoing",
	--  endTexture="Interface/Calendar/Holidays/Calendar_WeekendBattlegroundsEnd"
	-- },
	phase2Launch = {
		name="Phase 2 Launch",
		description="Season of Discovery Phase 2 officially arrives! And with it comes the Arathi Basin battleground (and its call to arms every 4 weeks), the Stranglethorn Fishing Extravaganza on Sundays, the Gnomeragon raid, and the Stranglethorn Vale PvP event!\r\n\r\n|c50666666(details to be determined)|r",
		startDate={ year=2024, month=2, day=8, hour=8, min=0 },
		endDate={ year=2024, month=2, day=8, hour=8, min=0 },
		startTexture="Interface/Calendar/Holidays/Calendar_AnniversaryStart",
		ongoingTexture="Interface/Calendar/Holidays/Calendar_AnniversaryStart",
		endTexture="Interface/Calendar/Holidays/Calendar_AnniversaryStart"
	}
}

local holidaySchedule = {}

local WEEKDAYS = {
	Sunday = 1,
	Monday = 2,
	Tuesday = 3,
	Wednesday = 4,
	Thursday = 5,
	Friday = 6,
	Saturday = 7
}

local function getDSTDates(year)
	-- Start of DST is 2nd Sunday of March
	local firstDayMarch = {year=year, month=3, day=1}
	local weekAdjustment = 1
	if date("*t", time(firstDayMarch)).wday ~= WEEKDAYS.Sunday then
		weekAdjustment = weekAdjustment + 1
	end
	local secondSundayMarch = changeWeekdayOfDate(firstDayMarch, WEEKDAYS.Sunday, weekAdjustment)
	secondSundayMarch.hour = 2

	-- End of DST is 1st Sunday of November
	local firstDayNov = {year=year, month=11, day=1}
	weekAdjustment = 0
	if date("*t", time(firstDayNov)).wday ~= WEEKDAYS.Sunday then
		weekAdjustment = weekAdjustment + 1
	end
	local firstSundayNov = changeWeekdayOfDate(firstDayNov, WEEKDAYS.Sunday, weekAdjustment)
	firstSundayNov.hour = 2


	return secondSundayMarch, firstSundayNov
end

local function adjustDST(dateTime)
	local dateD = date("*t", dateTime)
	local dstStart, dstEnd = getDSTDates(dateD.year)
	if dateTime > time(dstStart) and dateTime < time(dstEnd) then
		dateTime = dateTime - (60*60)
	end
	return dateTime
end

function GetClassicHolidays()
	if next(holidaySchedule) ~= nil then
		return holidaySchedule
	end

	for _, holiday in next, CLASSIC_CALENDAR_HOLIDAYS do
		local startTime = time(holiday.startDate)
		local endTime = time(holiday.endDate)

		holiday.startDate = date("*t", startTime)
		holiday.endDate = date("*t", endTime)
		tinsert(holidaySchedule, holiday)
		if holiday.frequency ~= nil then
			local days = 0
			while days < 365 do
				local eventCopy = DeepCopyTable(holiday)
				startTime = startTime + (SECONDS_IN_DAY * holiday.frequency)
				endTime = endTime + (SECONDS_IN_DAY * holiday.frequency)
				eventCopy.startDate = date("*t", adjustDST(startTime))
				eventCopy.endDate = date("*t", adjustDST(endTime))
				tinsert(holidaySchedule, eventCopy)
				days = days + holiday.frequency
			end
		end
	end

	table.sort(holidaySchedule, function(a,b)
		if (a.startDate.year ~= b.startDate.year) then
			return a.startDate.year < b.startDate.year
		end

		return a.startDate.yday < b.startDate.yday
	end)

	return holidaySchedule
end
