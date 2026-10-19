# Player Finder - unpublished local preview

Use `/ht playerfinder` to open the separate player watch window, or `/ht playerfinder Leona` to add a watch and open it. Names only: there is no realm field or realm-specific matching. Multiword character names are accepted. Exact matching is the default; enable Partial names to match a literal substring, such as Leon matching Leona Star. Matching ignores case.

Up to eight player watches save per character, independently of Mob Finder. Use Watch target for a currently selected player. Click a watch row to remove it. Pause/Resume preserves the list; Stop/clear removes it. Closing keeps watching; Shift-left-drag moves and saves the window position.

Outside combat, readable player targets, mouseovers and nameplates are checked twice per second. The finder ignores NPCs, controlled pets, your own character and dead players. Detection is limited to units the game exposes; there is no server-wide character search or coordinate lookup. Friendly or enemy nameplate visibility affects discovery.

New sightings generate a private chat alert, optional sound/screen warning and a Player detected popup with Target/Dismiss. Target uses the actual detected full character name, even when the watch is partial. A user click is required; it never targets automatically or attacks. The popup expires after fifteen seconds and closes on combat entry. Dismissed continuous sightings do not repeatedly pop up; thirty seconds absent rearms alerts. Visible selected nameplates get the same three-second gold FOUND ping. No realm input, map ping, world arrow, remote-player tracking or addon dependency is added.

Full WoW restart required to load PlayerFinder.lua after installing. Not included in published HunterTools 3.1.4. Automated tests cover separate settings, exact/partial/multiword names, full-name secure targeting, target/nameplate duplication, repeat suppression, self/NPC/dead exclusions, combat/restricted values, input guards, list limits, UI and player nameplate pings. In-game confirmation remains pending.

## Native targeting correction

Player Finder now prepares a SecureActionButtonTemplate target action with a verified live unit token, preferring nameplates over volatile mouseover references. The clicked player's GUID is rechecked outside combat just before the secure action; recycled tokens are replaced only with another readable reference for the same GUID. If none remains, the action is disarmed and explains that the player is unavailable. Player targeting no longer uses macrotext or name parsing. Mob Finder retains its existing exact-name macro flow. Checks cover native attributes, GUID revalidation/reassignment, token loss, combat guards and shared ping compatibility. In-game targeting verification pending.

## Forever surname and fallback correction

User confirmed /targetexact Darius Winterspoon works. UnitNameUnmodified returns first name and surname on this Forever client, as corroborated by installed client-facing source. Player Finder now captures both parts, without adding realm handling or duplicating a surname already included in the name. Exact watches match the full character name; Partial names lets a first-name watch match the full identity. Target prefers a GUID-verified native unit reference and falls back to /targetexact with the captured full name after mouseover/nameplate loss. Missing/secret surnames are not guessed or stringified. Tests cover the Darius Winterspoon case, partial first-name matching, disappearing mouseover, token reuse, duplicate surname and secret surname data. Player nameplate pings use the same full-name helper.

Main menu navigation: /ht now includes a dedicated Finders section with Mob Finder and Player Finder buttons, labeled for all classes. The main panel retains automatic small-screen scaling. Opening a finder hides the menu; returning to the menu hides finder windows without stopping saved watches. Navigation and combat guards passed automated menu checks.
