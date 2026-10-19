# HunterTools 3.1.5

## New features

- Mob Finder and Player Finder, accessible from the new Finders section of the main menu or `/ht mobfinder` and `/ht playerfinder`.
- Saved watch lists, optional partial-name matching, sound/screen alerts and a click-to-target detection popup. Player targeting supports Forever surnames.
- Brief highlight on the targeted unit's visible nameplate. Direction arrows and private map markers require genuine public location data; ordinary detections commonly provide none. No Questie dependency.
- Current pet details can display learned abilities from the live pet spellbook, with independent window and mouseover settings.

## Fixes and compatibility

- Include Sonic Blast in Bat family training options, with Blizzard/Petopia source labeling. This does not claim that every wild bat teaches it or assign unknown ranks.
- Clarify that weapon comparisons assume stationary Auto Shot, including the new 0.5-second standing requirement.
- Reviewed October 15 changes to Dismember, Sonic Blast and Mine!: bundled ability records store spell identities and teaching references, not outdated damage, duration or cooldown descriptions. Pet expertise/crit changes do not require changes to our Auto Shot-only estimate.
- Growl detection and disabling on instance entry confirmed working in game after the update.

## Upgrade and limits

Install both addon folders from the ZIP and fully restart WoW for the new finder modules. Existing character settings are retained.

Player targeting with a full Forever name is confirmed in game. Broader Pack behavior, finder combat transitions, settings persistence and navigation on coordinate-bearing rare/event markers still need in-game coverage. Targeting requires clicking the button and is unavailable during combat.

# HunterTools 3.1.4

## New in this update

- Compact aspect and tracking lists open beneath their floating buttons on right-click. Green markers identify active choices; opening either list closes the other. Automatic reminder dialogs remain separate.
- Favorite aspects and tracking abilities with the star beside each choice. Favorites save per character and appear first; aspect favorites survive learning a higher rank. Favorites can be changed outside combat.
- Native spell tooltips on aspect/tracking choices, aspect reminder choices, and the active spell on each floating button.
- Beast details and name search for every class. `/ht beastdetail` or `/ht beastdetails` inspects a targeted wild beast, or opens search when no suitable beast is targeted. Add a full or partial name to search directly; `/ht beastsearch` also opens search.
- Search the bundled beast references and your character's journal by name, with paged results and distinct NPC identities for beasts sharing a name. Detail windows include a search box and preserve data-source labels and unknown fields.
- Pet Abilities includes a beast-name search that displays results and scrollable details inside the ability browser, with optional portraits and a Back control. Selecting an ability or clearing the beast search returns to teaching animals.

## Bug fixes and refinements

- Keep Pet Abilities searches and details in the ability browser rather than switching to the standalone beast window.
- Give the embedded beast-details panel a solid dark background and raise it above the ability controls for readability.
- Non-hunters can inspect beast information without enabling hunter display options; hunter learned-ability labels are omitted for other classes. HunterTools itself must be enabled for that character.

## Existing features and limits

The aspect button, pet healing-range warning and native low-health/death alerts from 3.1.2 remain included. When Forever restricts pet health, the native low-health visual still works, but low-health sound/chat and timed repeats are unavailable. Death alerts work separately.

Ranged weapon comparisons and scope previews remain **Experimental**.

Character Auto Shot DPS = ((estimated minimum shot damage + estimated maximum shot damage) / 2) / effective shot interval in seconds.

The estimate includes character ranged AP, ammo, scope and retained live damage/attack-speed bonuses. It excludes armor, misses, crit, rotations, pet damage, procs and unsupported stat/talent effects. Pet data retains labeled community/Classic fallbacks and local observations; unknown facts remain unknown.

## Updating and validation

Install both addon folders from the ZIP into Interface/AddOns and fully restart WoW to load the new SpellDropdown.lua module. Existing settings are retained. Enable HunterTools for each character that will use beast details or search, including non-hunters.

The user confirmed aspect/tracking menu behavior, beast details on a druid, and readability of the embedded details panel after the opacity/layering fix. Automated Lua 5.1 checks cover the feeding engine and all 29 Lua regression files, including name search, pagination, source precedence, duplicate names/NPC IDs, standalone command aliases, embedded navigation, tooltips, favorite sorting/rank changes, secure mutual menu exclusion and combat guards. All addon Lua files, TOC references, ZIP integrity and addon-only root folders are checked during packaging.

Existing Pack/combat aspect switching and beast journal collection retain their previously documented need for broader in-game testing. Search uses available local/reference data and does not reveal missing Beast Lore information. Favorites persistence and less-common UI/combat sequences still benefit from broader in-game feedback.
