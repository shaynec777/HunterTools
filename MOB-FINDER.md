# Mob Finder - local preview after 3.1.4

Open `/ht mobfinder`, or `/ht mobfinder Wolf` to add a name and open the panel. Any class can use it. Watches save per character, up to eight. Exact names are the default; Partial names enables literal substring matching. Enter a name and press Enter/Watch, use Watch target, or choose Watch mob from a standalone or embedded beast detail view. Watch mob from a database record can use its NPC ID. Click a watch row to remove it. Pause/Resume retains watches; Stop/clear removes them. Closing the panel keeps watching. Shift-left-drag moves the unlocked panel and saves its position.

The finder checks at most twice per second outside combat. It uses readable targets, mouseovers, and nameplates; visible nameplates improve detection. When a known NPC ID is available, it also tries the client's nearest-creature location API. Restricted, missing or invalid position data is never treated as coordinates or proximity. No detection does not prove a mob is absent. The nearest-location API cannot confirm alive status; those matches are explicitly labeled as client locations with alive status unknown. Detected players, controlled pets and dead units are excluded.

A readable distance must be within 100 yards to alert. With no readable distance, a matching exposed target/mouseover/nameplate can still alert without claiming a numeric distance. A sound, screen warning and private chat message announce sightings, with sound and screen switches. A continuous sighting does not repeat; a gap of 30 seconds rearms it. Stale notification state is discarded after five minutes. Switching between the nearest-location and visible-unit sources avoids redundant alerts.

A direction arrow appears in the panel only with readable current world coordinates in the player's instance and readable facing. Map markers switch on together: a private pulsing gold marker on the minimap (inside its current radius) and on the world map while it is open on a compatible map. They use live coordinates, disappear on loss/pause/combat/zoning, and never replace the player's waypoint or broadcast group pings. No saved sighting is presented as a live location. If the location/facing/map APIs are unavailable, alerts still work from readable units; navigation degrades silently.

Full game restart required after installing MobFinder.lua. This preview does not change the published 3.1.4 ZIP or GitHub release. Current-pet learned abilities are another unpublished local addition.

Automated coverage includes names/IDs, matching modes, duplicate units and watches, alert rearming, distance limits, player/pet/dead exclusions, saved preferences and UI actions, missing/restricted coordinates, combat deferral, arrow direction, map/minimap placement, instance mismatch, and slash commands. Real Forever detection, API availability, arrow orientation and pin placement still need in-game testing.

API references checked: Gethe/wow-ui-source `forever` branch, UnitDocumentation.lua, MapDocumentation.lua, NamePlateDocumentation.lua and MinimapDocumentation.lua. In particular ClosestUnitPosition has SecretReturns; C_Map.GetPlayerMapPosition only supports players/party and is not used for mob coordinates.

## Native location investigation

Added C_VignetteInfo live map-marker lookup keyed to the matching creature GUID/ID, with safe map-to-world conversion and a player-map-position fallback when UnitPosition(player) is unavailable. Only readable matching living marker data within the detection radius (or confirmed on the minimap when distance is unavailable) can become a sighting. Missing/removed/dead/unrelated markers never supply a location. Existing UnitPosition and ClosestUnitPosition remain optional fallbacks. Debug reports the selected navigation source and marker API availability.

User explicitly requested no Questie integration: there is no Questie code, dependency or saved-spawn fallback. Normal NPCs without readable coordinates or native markers remain alerts-only. No saved sightings are relabeled as current coordinates. RareScanner installed source corroborated native-marker use; Forever generated VignetteInfoDocumentation.lua and MapDocumentation.lua were checked directly. Tests cover live markers, coordinate conversion, player fallback, marker disappearance, dead/unmatched markers and no addon dependencies.

## Click-to-target detection popup

New sightings show a solid popup with the full detected name, Target and Dismiss. Target is a secure user-click action containing only /targetexact followed by the actual detected full name; partial watch text is never used as a targeting macro. No automatic targeting, attacks, macro creation or binding changes occur. If several units share that name, the game chooses the matching target. The popup times out after fifteen seconds, closes securely on combat entry, and follows the same continuous-sighting suppression as sound alerts. Targeting cannot guarantee world-coordinate availability. Input validation and secure action, dismissal, timeout and combat guards have regression coverage. Local preview only.

## Target-click on-screen ping

After the popup Target click, wait up to 1.5 seconds for a matching live target and a visible, non-forbidden nameplate. Pulse a gold frame and FOUND label around that nameplate for three seconds, then remove it. It follows the nameplate on screen and hides on target changes, plate loss or combat. A missing plate produces a private explanation; nameplate visibility is required. This is an on-screen nameplate ping, not a fabricated map/minimap position. Regression checks cover immediate/delayed targeting, expiry, target changes, hidden/forbidden plates and combat cleanup.
