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

local state = {
	monthOffset=0
}

local DARKMOON_ELWYNN_LOCATION = 0
local DARKMOON_MULGORE_LOCATION = 1

local darkmoonLocations = {
	Elwynn = DARKMOON_ELWYNN_LOCATION,
	Mulgore = DARKMOON_MULGORE_LOCATION
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

local function darkmoonStart(monthOffset, monthDay, location)
	local currentCalendarTime = C_DateAndTime.GetCurrentCalendarTime()
	local presentWeekday = currentCalendarTime.weekday
	local presentMonth = currentCalendarTime.month
	local presentDay = currentCalendarTime.monthDay
	local presentYear = currentCalendarTime.year
	local iconTexture
	if location == darkmoonLocations.Elwynn then
		iconTexture = 235448
	elseif location == darkmoonLocations.Mulgore then
		iconTexture = 235451
	end

	local fakeDarkmoonEvent = { -- CalendarEvent
		clubID=0,
		-- eventID=479,
		title="Darkmoon Faire",
		isCustomTitle=true,
		startTime={ -- CalendarTime
			year=presentYear,
			month=presentMonth,
			monthDay=7,
			weekDay=1,
			hour=0,
			minute=1
		}, 
		endTime={
			year=presentYear,
			month=presentMonth,
			monthDay=13,
			weekDay=monthDay,
			hour=23,
			minute=59
		},
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

local function darkmoonOngoing(monthOffset, monthDay, sequenceIndex, location)
	local iconTexture
	if location == darkmoonLocations.Elwynn then
		iconTexture = 235447
	elseif location == darkmoonLocations.Mulgore then
		iconTexture = 235450
	end

	local fakeDarkmoonEvent = { -- CalendarEvent
		clubID=0,
		-- eventID=479,
		title="Darkmoon Faire",
		isCustomTitle=true,
		startTime={ -- CalendarTime
			year=2024,
			month=1,
			monthDay=7,
			weekDay=1,
			hour=0,
			minute=1
		}, 
		endTime={
			year=2024,
			month=1,
			monthDay=13,
			weekDay=7,
			hour=23,
			minute=59
		},
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

local function darkmoonEnd(monthOffset, monthDay, location)
	local iconTexture
	if location == darkmoonLocations.Elwynn then
		iconTexture = 235446
	elseif location == darkmoonLocations.Mulgore then
		iconTexture = 235449
	end

	local fakeDarkmoonEvent = { -- CalendarEvent
		clubID=0,
		-- eventID=479,
		title="Darkmoon Faire",
		isCustomTitle=true,
		startTime={ -- CalendarTime
			year=2024,
			month=1,
			monthDay=7,
			weekDay=1,
			hour=0,
			minute=1
		}, 
		endTime={
			year=2024,
			month=1,
			monthDay=13,
			weekDay=7,
			hour=23,
			minute=59
		},
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

local function createResetEvent(monthOffset, monthDay)
	local currentCalendarTime = C_DateAndTime.GetCurrentCalendarTime()
	local presentMonth = currentCalendarTime.month
	local presentYear = currentCalendarTime.year

	local fakeResetEvent = { -- CalendarEvent
		clubID=0,
		-- eventID="0x1F410000035FB4A7",
		eventType=CalendarEventType.Other,
		sequenceType="",
		isCustomTitle=true,
		startTime={ -- CalendarTime
			year=presentYear,
			month=presentMonth,
			monthDay=monthDay,
			-- weekDay=1,
			hour=8,
			minute=0
		},
		difficultyName="",
		-- endTime={
		-- 	year=presentYear,
		-- 	month=presentMonth,
		-- 	monthDay=monthDay,
		-- 	-- weekDay=1,
		-- 	hour=23,
		-- 	minute=59
		-- },
		invitedBy="",
		inviteStatus=0,
		dontDisplayEnd=false,
		-- difficulty=198,
		isLocked=false,
		title="Blackfathom Deeps",
		calendarType="RAID_RESET",
		-- iconTexture=235448,
		inviteType=CalendarInviteType.Normal,
		sequenceIndex=1,
		dontDisplayBanner=false,
		modStatus=""
	}

	return fakeResetEvent
end

function dayHasDarkmoon(monthOffset, monthDay)
	if GetCVar("calendarShowDarkmoon") == "0" then
		return false
	end
	local event1 = (monthOffset == -1 and monthDay > 17 and monthDay < 25)
	local event2 = (monthOffset == 0 and monthDay > 0 and monthDay < 8)
	local event3 = (monthOffset == 0 and monthDay > 14 and monthDay < 22)
	local event4 = ((monthOffset == 0 and monthDay > 28) or (monthOffset == 1 and monthDay < 5))
	return event1 or event2 or event3 or event4
end

function dayHasReset(monthOffset, monthDay)
	if GetCVar("calendarShowResets") == "0" then
		return false
	end

	local resets_last_month = (monthOffset == -1 and tableHasValue({3,6,9,12,15,18,21,24,27,30}, monthDay))
	local resets_this_month = (monthOffset == 0 and tableHasValue({2,5,8,11,14,17,20,23,26,29}, monthDay))
	local resets_next_month = (monthOffset == 1 and tableHasValue({1,4,7,10,13,16,19,22,25,28}, monthDay))

	return resets_last_month or resets_this_month or resets_next_month
end

function trueMonthOffset(monthOffset)
	-- Apply the month offset accumulated by stubbedSetMonth
	return monthOffset + state.monthOffset
end

function stubbedGetNumDayEvents(monthOffset, monthDay)
	-- Stubbing C_Calendar.getNumDayEvents to return fake events
	local originalEventCount = C_Calendar.GetNumDayEvents(monthOffset, monthDay)
	local monthOffset = trueMonthOffset(monthOffset)

	if dayHasDarkmoon(monthOffset, monthDay) then
		originalEventCount = originalEventCount + 1
	end
	if dayHasReset(monthOffset, monthDay) then
		originalEventCount = originalEventCount + 1
	end

	return originalEventCount
end

function stubbedGetDayEvent(monthOffset, monthDay, index)
	-- Stubbing  C_Calendar.GetDayEvent to return events
	local originalEventCount = C_Calendar.GetNumDayEvents(monthOffset, monthDay)
	local originalEvent = C_Calendar.GetDayEvent(monthOffset, monthDay, index)
	local monthOffset = trueMonthOffset(monthOffset)

	if originalEvent == nil then -- Fake Event
		if (dayHasDarkmoon(monthOffset, monthDay) and index == originalEventCount + 1) then
			-- Holiday is always the first event processed, because there's only 1 at a time
			if (monthOffset == -1 and monthDay == 18) or (monthOffset == 0 and monthDay == 15) then
				return darkmoonStart(monthOffset, monthDay, darkmoonLocations.Elwynn)
			elseif (monthOffset == 0 and monthDay == 1) or (monthOffset == 0 and monthDay == 29) then
				return darkmoonStart(monthOffset, monthDay, darkmoonLocations.Mulgore)
			elseif (monthOffset == -1 and monthDay > 17 and monthDay < 24 ) or (monthOffset == 0 and monthDay > 14 and monthDay < 21 ) then
				return darkmoonOngoing(monthOffset, monthDay, monthDay - 6, darkmoonLocations.Elwynn)
			elseif (monthOffset == 0 and monthDay > 1 and monthDay < 7 ) or (monthOffset == 0 and monthDay > 29) or (monthOffset == 1 and monthDay < 4) then
				return darkmoonOngoing(monthOffset, monthDay, monthDay - 6, darkmoonLocations.Mulgore)
			elseif (monthOffset == -1 and monthDay == 24) or (monthOffset == 0 and monthDay == 21) then
				return darkmoonEnd(monthOffset, monthDay, darkmoonLocations.Elwynn)
			elseif (monthOffset == 0 and monthDay == 7) or (monthOffset == 1 and monthDay == 4) then
				return darkmoonEnd(monthOffset, monthDay, darkmoonLocations.Mulgore)
			end
		end
	
		if dayHasReset(monthOffset, monthDay) then
			return createResetEvent(monthOffset, monthDay)
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
end

function communityName()
	-- Gets Guild Name from Player since built in functionality is broken
    local communityName = GetGuildInfo("player");
	return communityName
end
