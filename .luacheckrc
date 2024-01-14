std = "lua51"
max_line_length = false
exclude_files = {
	"**/Libs/**/*.lua",
	".luacheckrc",

	-- Blizz official code
	"ClassicCalendar.lua", 
	"GameTime_Wrath.lua"
}
ignore = {
	"11./SLASH_.*", -- Slash command registration
	"211", -- Unused local variable
	"212" -- Unused argument
}
globals = {
	-- Providing or overriding existing globals
	"C_Calendar",
	"CALENDAR_INVITESTATUS_INFO",
	"CalendarType",
	"CalendarInviteType",
	"CalendarEventType",
	"CalendarTexturesType",
	"CALENDAR_FILTER_BATTLEGROUND",
	"SlashCmdList",
	"C_DateAndTime",
	"CLASSIC_CALENDAR_L",
	"SetMinTime",
	"SetMaxTime",
	"GetClassicHolidays",
	"CCConfig",
	"GoToCCSettings",
	"UpdateCalendarState",
	"CalendarButtonFrame",
	"GetClassicRaidResets",

	-- Stubbed functions made global to be called from the calendar code
	"newEventGetTextures",
	"stubbedGetNumDayEvents",
	"stubbedGetDayEvent",
	"stubbedSetMonth",
	"stubbedSetAbsMonth",
	"communityName",
	"newGetHolidayInfo",
	"stubbedGetEventIndex",
	"stubbedOpenEvent",
	"stubbedGetRaidInfo",

	-- Various WoW globals
	"Enum",
	"UNKNOWN",
	"NORMAL_FONT_COLOR",
	"CALENDAR_STATUS_CONFIRMED",
	"GREEN_FONT_COLOR",
	"CALENDAR_STATUS_ACCEPTED",
	"CALENDAR_STATUS_DECLINED",
	"RED_FONT_COLOR",
	"CALENDAR_STATUS_OUT",
	"CALENDAR_STATUS_STANDBY",
	"ORANGE_FONT_COLOR",
	"CALENDAR_STATUS_INVITED",
	"CALENDAR_STATUS_SIGNEDUP",
	"CALENDAR_STATUS_NOT_SIGNEDUP",
	"GRAY_FONT_COLOR",
	"CALENDAR_STATUS_TENTATIVE",
	"time",
	"date",
	"floor",
	"tinsert",
	"GetCVar",
	"Calendar_Toggle",
	"GetGuildInfo",
	"GameTimeFrame",
	"GetLocale",
	"CalendarFrame_ShowEventFrame",
	"CalendarViewHolidayFrame",
	"CalendarViewRaidFrame",
	"CreateFrame",
	"C_AddOns",
	"InterfaceOptionsFrame_OpenToCategory",
	"InterfaceOptionsFramePanelContainer",
	"InterfaceOptions_AddCategory",
	"CopyTable",
	"C_Seasons"
}
