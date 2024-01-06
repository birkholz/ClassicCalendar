std = "lua51"
max_line_length = false
exclude_files = {
	"**/Libs/**/*.lua",
	".luacheckrc",
    "ClassicCalendar.lua" -- Blizz official code
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
	"SOD_CALENDAR_L",

	-- Stubbed functions made global to be called from the calendar code
	"StubbedEventGetTextures",
	"stubbedGetNumDayEvents",
	"stubbedGetDayEvent",
	"stubbedSetMonth",
	"stubbedSetAbsMonth",
	"communityName",
	"newGetHolidayInfo",
	"stubbedGetEventIndex",

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
	"tinsert",
	"GetCVar",
	"Calendar_Toggle",
	"GetGuildInfo"
}