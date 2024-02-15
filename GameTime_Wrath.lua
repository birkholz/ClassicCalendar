GAMETIME_AM = true;
GAMETIME_PM = false;

local GAMETIME_DAWN = ( 5 * 60) + 30;		-- 5:30 AM
local GAMETIME_DUSK = (21 * 60) +  0;		-- 9:00 PM

local date = date;
local format = format;
local GetCVarBool = GetCVarBool;
local tonumber = tonumber;

local PI = PI;
local TWOPI = PI * 2.0;
local cos = math.cos;
local INVITE_PULSE_SEC	= 1.0 / (2.0*1.0);	-- mul by 2 so the pulse constant counts for half a flash

-- General GameTime functions are currently defined GameTime_Shared.lua

-- CalendarButtonFrame functions

function CalendarButtonFrame_OnLoad(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("CALENDAR_UPDATE_PENDING_INVITES");
	self:RegisterEvent("CALENDAR_EVENT_ALARM");
	self:RegisterForClicks("AnyUp");

	-- adjust button texture layers to not interfere with overlaid textures
	local tex;
	tex = self:GetNormalTexture();
	tex:SetDrawLayer("BACKGROUND");
	tex = self:GetPushedTexture();
	tex:SetDrawLayer("BACKGROUND");

	self:GetFontString():SetDrawLayer("BACKGROUND");

	self.timeOfDay = 0;
	-- self:SetFrameLevel(self:GetFrameLevel() + 2);
	self.pendingCalendarInvites = 0;
	self.hour = 0;
	self.flashTimer = 0.0;
	CalendarButtonFrame_OnUpdate(self);

	self:RegisterForDrag("LeftButton")
end

function CalendarButtonFrame_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT");
end

function CalendarButtonFrame_OnEvent(self, event, ...)

	if ( event == "CALENDAR_UPDATE_PENDING_INVITES" or event == "PLAYER_ENTERING_WORLD" ) then
		local pendingCalendarInvites = C_Calendar.GetNumPendingInvites();
		if ( pendingCalendarInvites > self.pendingCalendarInvites ) then
			if ( not CalendarFrame or (CalendarFrame and not CalendarFrame:IsShown()) ) then
				GameTimeCalendarInvitesTexture:Show();
				GameTimeCalendarInvitesGlow:Show();
				CalendarButtonFrame.flashInvite = true;
				self.pendingCalendarInvites = pendingCalendarInvites;
			end
		elseif ( pendingCalendarInvites == 0 ) then
			GameTimeCalendarInvitesTexture:Hide();
			GameTimeCalendarInvitesGlow:Hide();
			CalendarButtonFrame.flashInvite = false;
			self.pendingCalendarInvites = 0;
		end
		CalendarButtonFrame_SetDate();
	elseif ( event == "CALENDAR_EVENT_ALARM" ) then
		local title, hour, minute = ...;
		local info = ChatTypeInfo["SYSTEM"];
		DEFAULT_CHAT_FRAME:AddMessage(format(CALENDAR_EVENT_ALARM_MESSAGE, title), info.r, info.g, info.b, info.id);
		--UIFrameFlash(GameTimeCalendarEventAlarmTexture, 1.0, 1.0, 6);
	end
end

function CalendarButtonFrame_OnUpdate(self, elapsed)
	local hour, minute = GetGameTime();
	local time = (hour * 60) + minute;
	if(time ~= self.timeOfDay) then
		self.timeOfDay = time;
		local minx = 0;
		local maxx = 50/128;
		local miny = 0;
		local maxy = 50/64;
		if(time < GAMETIME_DAWN or time >= GAMETIME_DUSK) then
			minx = minx + 0.5;
			maxx = maxx + 0.5;
		end
		if ( hour ~= self.hour ) then
			self.hour = hour;
			CalendarButtonFrame_SetDate();
		end
		GameTimeTexture:SetTexCoord(minx, maxx, miny, maxy);
	end
	
	if(GameTooltip:IsOwned(self)) then
		GameTooltip:ClearLines();
		if ( GameTimeCalendarInvitesTexture:IsShown() ) then
			GameTooltip:AddLine(GAMETIME_TOOLTIP_CALENDAR_INVITES);
			if ( CalendarFrame and not CalendarFrame:IsShown() ) then
				GameTooltip:AddLine(" ");
				GameTooltip:AddLine(GAMETIME_TOOLTIP_TOGGLE_CALENDAR);
			end
		else
			if ( not TimeManagerClockButton or not TimeManagerClockButton:IsVisible() or TimeManager_IsAlarmFiring() ) then
				GameTooltip:AddLine(GameTime_GetGameTime(true), HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
				GameTooltip:AddLine(" ");
			end
			GameTooltip:AddLine(GAMETIME_TOOLTIP_TOGGLE_CALENDAR);
		end
		GameTooltip:Show();
	end

	-- Flashing stuff
	if ( elapsed and CalendarButtonFrame.flashInvite ) then
		local flashIndex = TWOPI * self.flashTimer * INVITE_PULSE_SEC;
		local flashValue = max(0.0, 0.5 + 0.5*cos(flashIndex));
		if ( flashIndex >= TWOPI ) then
			self.flashTimer = 0.0;
		else
			self.flashTimer = self.flashTimer + elapsed;
		end

		GameTimeCalendarInvitesTexture:SetAlpha(flashValue);
		GameTimeCalendarInvitesGlow:SetAlpha(flashValue);
	end
end

function CalendarButtonFrame_OnClick(self)
	UIFrameFlashStop(GameTimeCalendarEventAlarmTexture)
	if ( GameTimeCalendarInvitesTexture:IsShown() ) then
		if ( Calendar_Show ) then
			Calendar_Show();
		end
		GameTimeCalendarInvitesTexture:Hide();
		GameTimeCalendarInvitesGlow:Hide();
		self.pendingCalendarInvites = 0;
		CalendarButtonFrame.flashInvite = false;
	else
		Calendar_Toggle();
	end
end

function CalendarButtonFrame_SetDate()
	local currentCalendarTime = C_DateAndTime.GetCurrentCalendarTime();
	local day = currentCalendarTime.monthDay;
	CalendarButtonFrame:SetText(day);
end
