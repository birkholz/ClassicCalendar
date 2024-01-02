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
};

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

function StubbedEventGetTextures(eventType)
	
	local original_textures = deep_copy(C_Calendar.EventGetTextures(eventType));

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
			title="Razoren Kraul",
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
