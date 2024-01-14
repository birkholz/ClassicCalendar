[![Build Status](https://github.com/birkholz/ClassicCalendar/workflows/CI/badge.svg)](https://github.com/birkholz/ClassicCalendar/actions?workflow=CI)
[![ClassicCalendar on Discord](https://img.shields.io/badge/discord-ClassicCalendar-738bd7.svg?style=flat)](https://discord.gg/CMxKsBQFKp) 

# Classic Calendar

A port of the official Blizzard_Calendar addon from WotLK classic to Season of Discovery and Classic Era. Made possible because of the existence of the core calendar functions `C_Calendar` being present in the classic client even though the interface isn't there. However, even though the calendar functions exist, the only things that worked immediately were player-created events (oddly enough) and raid lockouts, so those functions worked without any changes necessary. For events such as holidays, the game simply acts as if they don't exist. So in the process of porting the addon, these issues have been fixed by injecting the responses we'd expect the game to provide. This means that while we've strived to make the data as accurate as possible, it's ultimately not the game itself as the source, so issues may arise with the dates/strings/textures not being correct. Anywhere where we didn't have an authoritative source of the data, we've made our best guess. Please report any issues you encounter [here](https://github.com/birkholz/ClassicCalendar/issues).

![preview image](./preview.png)

## Features

* A calendar that functions identically to the one found in WotlK classic and retail, while matching the expectations of being in Classic
* Filters to control which categories of events are visible
* Holidays
* Battleground Weekends, including which BG has the call to arms
* Darkmoon Faire's schedule, including the location
* Player-created events visible to anyone invited
* Guild events visible to everyone in the guild
* Raid/dungeon events
* In-game mail notifications when an event is cancelled (we have no control over this)
* The ability to copy/paste events from one day to another
* The ability to mass-invite everyone from an event to your party/raid
* A flashing calendar icon to notify you of pending invites

## Accessing the Calendar

* Clicking the Calendar button at the top right of the minimap, replacing the time-of-day indicator
* Typing `/cal`/`/calendar` in chat, or `/caloptions`/`/calendaroptions` to open the addon options

## Known Issues

* Holiday dates & times may be wrong
* No ability to disable the in-game mail notifications. This is outside of the addon's control and how the game handles events being deleted.
* Pressing escape closes the entire calendar instead of 1 panel at a time. Unfortunately the original implementation uses privileged execution, and causes the "Addon has been blocked from an action only available to the Blizzard UI" error. We have not found an alternative way of implementing this.
* Guild Announcements are unavailable, as are Community events. Both are features that only function in later versions of WoW and aren't really portable because of underlying systems being nonexistent.

## Contributing

We try to keep all changes separate from the original files where possible in case there are ever upstream changes that we want to merge in. Pull Requests are welcome, though only features that fit in Classic will be considered, and anything that doesn't reflect the official calendar must be disabled by default and only enabled through the addon's settings.
