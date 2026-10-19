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

# HunterTools 3.1.3

## New in this update

- Movable Tracking button with a right-click picker for learned hunter and profession tracking, including Find Herbs and Find Minerals when known. Active choices have an icon and green marker. Open `/ht tracking` for enable, lock and reset controls.
- Optional no-tracking reminder offers learned tracking choices, Stay without tracking, and Later (five minutes). Button and reminder can be enabled independently.
- Tracking and aspect choosers now open at matching positions beside their respective buttons until moved.
- Tracking, aspect and dungeon alert dialogs can be repositioned and remember their own positions.

## Bug fixes and refinements

- Standardize all movable HunterTools buttons, windows and dialogs on **Shift + left-drag outside combat**. Locks remain respected; help text matches the controls.
- Reduce tracking/aspect chooser width and spacing, and fit the aspect alert height to its available choices.
- Preserve moved dialog positions across reopening and UI scaling, and safely finish interrupted dialog dragging after combat.
- Suppress no-tracking reminders during combat, travel, other settings and uncertain tracking state. Remember an intentional no-tracking choice until tracking is activated again.

## Existing features and limits

The aspect button, pet healing-range warning and native low-health/death alerts from 3.1.2 remain included. When Forever restricts pet health, the native low-health visual still works, but low-health sound/chat and timed repeats are unavailable. Death alerts work separately.

Ranged weapon comparisons and scope previews remain **Experimental**.

Character Auto Shot DPS = ((estimated minimum shot damage + estimated maximum shot damage) / 2) / effective shot interval in seconds.

The estimate includes character ranged AP, ammo, scope and retained live damage/attack-speed bonuses. It excludes armor, misses, crit, rotations, pet damage, procs and unsupported stat/talent effects. Pet data retains labeled community/Classic fallbacks and local observations; unknown facts remain unknown.

## Updating and validation

Install both addon folders from the ZIP and fully restart WoW to load TrackingButton.lua. Existing settings are retained. `/ht tracking` opens tracking controls; `/ht aspects` opens aspect controls.

The tracking button and no-tracking dialog were confirmed in-game, including logout/login without errors. Automated checks cover hunter/profession discovery, secure picker setup, reminder/toggle/snooze behavior, saved movement and scale conversion, interrupted drags, and rejection of dragging without Shift. Compact dialog layout and the latest movement refinements still need broader in-game feedback. Existing Pack/combat aspect behavior and beast collection retain their previously documented testing limits.

# HunterTools 3.1.2

## New in this update

- Optional aspect chooser when no aspect is active, with learned-aspect icons and an intentional no-aspect choice. A movable, lockable aspect button opens a learned-aspect picker on right-click (`/ht aspects`).
- Instance-entry Pack reminders now offer another learned aspect or an explicit Keep Pack choice. Growl autocast remains a separate click action.
- Optional large Mend Pet out-of-range warning in the range window, including when no target is selected.
- Pet low-health and pet-dead warnings (`/ht petalerts`) with independent enable, banner, chat and sound options, a configurable health threshold, and repeat intervals. When Forever restricts health, a native visual banner still warns below the threshold and says OUT OF RANGE TO MEND PET when confirmed too far away. **Restricted-health low warnings cannot trigger sound/chat or timed repeats; death alerts work separately.**
- The main menu displays the installed addon version.

## Bug fixes

- Fixed aspect picker initialization on Forever, including secure handler bodies and frame-reference setup.
- Finish and save aspect-button dragging safely after combat interrupts a drag.
- Keep aspect reminders from overlapping the settings pages.
- Use font-compatible punctuation in the low-health warning and keep its Mend Pet advice range-aware.

## Experimental features and limitations

Ranged weapon comparisons and scope previews remain **Experimental**.

Character Auto Shot DPS = ((estimated minimum shot damage + estimated maximum shot damage) / 2) / effective shot interval in seconds.

This includes character ranged AP, ammo, scope and retained live damage/attack-speed bonuses, unlike base weapon DPS. It excludes armor, misses, crit, special-shot rotations, pet damage, procs, unsupported effects, stat-percent multipliers and weapon-specific talent changes.

Pet data retains labeled community/Classic fallbacks and local observations; missing facts remain unknown. In restricted combat, pet health can drive a native visual warning but cannot trigger addon sound/chat. The visual persists below the threshold rather than following the repeat interval.

## Updating and validation

Install both addon folders from the ZIP and fully restart WoW to load the new modules. Existing character settings are retained. Use `/ht aspects`, `/ht petalerts`, or the main menu to configure the new tools.

The aspect button, larger pet heal-range warning, pet-dead warning, and native low-health banner with corrected punctuation and out-of-range wording were confirmed in-game. Automated checks cover secure picker setup, combat-interrupted dragging, menu suppression, health thresholds/toggles/repeats, opaque native rendering and failure cleanup. Combat aspect switching, direct-cancellation handling and the Pack replacement chooser still need broader in-game testing.

# HunterTools 3.1.1

## New in this update

- Beast data now includes 622 Petopia Forever creature records, 19 family references, and 32 additional ID-keyed reports from Petopia's community taming sheet, including Vuldren and Ursera. Community reports are labeled unverified; Classic-linked ability teachers remain labeled as such.
- Beast fields use available local observations first, then Petopia Forever and its community reports, Wowhead Forever, and the retained Classic reference. Missing fields can fall through independently. Family training options are separate from innate abilities.
- New local beast field journal (`/ht beasts`): save sightings, explicit Beast Lore details, and the first readable spellbook from a newly tamed pet. Collection is enabled by default and can be turned off. Records stay on your character; a copyable export lets you share them manually. Nothing is uploaded automatically.
- Animal link dialogs offer Petopia, Wowhead Forever and Wowhead Classic copyable addresses, in that order where available.
- Feeding & alerts now displays a live explanation when reminders are paused. `/ht hungerdebug` prints the current alert status.

## Bug fixes

- Hungry text reminders no longer wait indefinitely for inventory loading. Low-food stock warnings still wait for confirmed counts.
- Check whether an item is edible before requesting its food metadata, so uncached non-food items cannot block the food scan.
- Show a normal hungry reminder when usable food is already available, rather than a misleading loading message. Locked food has its own explanation.
- A newly summoned/tamed pet gets its own initial hunger sound rather than inheriting the previous pet's already-alerted state.
- Selected food and ammo tabs remain clickable and have a clear active marker instead of appearing disabled.

## Experimental features and data limits

Ranged weapon comparisons and scope previews remain **Experimental**.

Character Auto Shot DPS = ((estimated minimum shot damage + estimated maximum shot damage) / 2) / effective shot interval in seconds.

This includes character ranged AP, ammo, scope and retained live damage/attack-speed bonuses. The weapon's listed DPS uses only base weapon damage and speed. Estimates exclude armor, misses, crit, special-shot rotations, pets, procs, unsupported effects, stat-percent multipliers and weapon-specific talent changes. See WEAPON-COMPARISONS.md in the source repository for calculation details.

Petopia's Forever site is still incomplete. Some teaching lists retain Classic links, and community reports can change during beta. Unknown ranks, spell IDs and pet-level requirements remain unknown. Family trainable skills are not proof that a particular wild beast has them. The journal's fresh-tame correlation has automated coverage but still needs broader in-game testing; pets tamed before installation cannot be retroactively assigned an NPC identity.

## Updating and testing

Install both addon folders from the ZIP into Interface/AddOns and fully restart WoW. Existing settings are retained. The journal stores up to 2,000 beasts and five nearby player sighting locations per beast; sighting coordinates are not exact spawn points. Collection can be disabled in `/ht beasts`.

Hungry banner delivery was confirmed in-game after the latest fix. Automated Lua 5.1 checks cover the feeding fixes, source precedence, collection events, export, menu navigation and existing features. Broader tame-event ordering and journal visual testing remain outstanding. Please report the feature, what happened, and any error message if something fails.

# HunterTools 3.1.0



## New in this update



- Refreshed menus with illustrated tool cards, readable opaque panels, clearer navigation, and separate food-catalog/feeding-alert and ammo-tracking/alert-settings tabs.

- New original hunter jackknife logo in the main menu and project artwork.

- Independently configurable animal mouseover tips and range-target details, including pet role, ability ranks, diet, and matching food quantities in your bags. Own-pet role has its own controls.

- Pet ability browser (`/ht abilities`): cached learned ranks, next needed or unconfirmed rank, teaching animals, level ranges and zones. Each animal has a copyable Wowhead Forever link. Creature pictures have a saved Show pet pictures switch and a small paging cache.

- Partial Wowhead Forever creature/family data supplements the Classic teaching reference; unknown abilities remain unknown.

- Ammo upgrade advice within Ammo Reminder: level/weapon/faction filters, sources, future upgrades, Include engineered ammo, and red [Obsolete] labels. Separate upgrade notifications offer a repeat interval and banner, chat, or both.

- Depleted equipped-ammo warnings and recommendations based on usable ammunition actually remaining in your bags.

- **Experimental: ranged weapon comparisons and scope previews** (`/ht weapons`). Compare estimated Auto Shot damage/DPS with your equipped weapon and preview an attached, absent, matching equipped, or known damage scope. This feature is still being validated against the Forever beta.



### Bug fixes



- An empty ammo-slot selection no longer masks an upgrade by retaining the damage of ammunition you have exhausted. Native carried counts override stale bag snapshots after readiness checks.

- New beasts with incomplete reference data retain available details rather than losing all animal information.

- Wowhead buttons use the tested copy dialog; the unsuccessful direct-browser launch attempt has been removed.

- Saved pet lists now have clearer return navigation and close with Esc. Disabling animal pictures clears their cached models and stops model requests.



## Experimental comparison formula and limits



Character Auto Shot DPS = ((estimated minimum shot damage + estimated maximum shot damage) / 2) / effective shot interval in seconds.



This includes character ranged AP, ammo, scope, and retained live damage/attack-speed bonuses; base weapon DPS uses only weapon damage and base speed. For example, (17.9 + 24.9) / 2 / 2.03 is approximately 10.5 character Auto Shot DPS. Candidate estimates adjust the live equipped baseline for weapon stats, speed and scope changes, without adding existing buffs twice.



Estimates are before armor, misses and crit, and exclude special-shot rotations, pets, procs and unsupported effects. Weapon-specific talent changes, stat-percent multipliers and scope application rules are not fully modeled. Scope character-level filters use known values; minimum weapon-item-level rules retain a Classic reference and require Forever validation. English item tooltips only. See WEAPON-COMPARISONS.md for the exact swap formula.



## Updating and validation



Install both HunterTools and FeedomaticToo folders from the ZIP, replacing existing files. Restart WoW once for the new modules and logo. Existing per-character settings are retained. `/ht` opens the tool menu. All tools can be enabled or disabled independently.



Lua 5.1 syntax and regression checks cover menus, feeding, pet data/learning, ability browsing, ammo stock/upgrades/notifications, tooltip guards and weapon/scope calculations. Menus, the copy dialog, ammo stock/depletion behavior and selected tooltip features were checked in game. One equipped-weapon damage range matched the character sheet; broader candidate/scope validation remains outstanding, so both comparisons and scope previews are explicitly Experimental.



Pet teaching sources and roles include a Classic baseline and may differ in Forever; live Beast Lore takes priority. Aspect of the Pack and combined disable still need broader in-game testing. If a feature fails, please report what happened, which feature you were using, and any error message.



---



# HunterTools 3.0.2



## New in this update



- Optional movable pet-status window with health and focus bars, happiness, loyalty, training points, diet, food supply, feeding status and last successful feeding.

- Mouseover tips for your own pet, with independent Window and Mouseover checkboxes for displayed details.

- Saved pet-window placement, position locking and reset controls. Right-click opens the main tool menu.

- Private feeding confirmation: Fed <petname> a delicious <petfood>.

- Improved saved-food-list manager with family labels, legacy grouping, deletion feedback, confirmed inactive-list cleanup and an opaque background.



### Bug fixes



- Reuse food lists by pet name and family across summons and reloads. Same-name pets in different families remain separate.

- Create a default list when a pet is summoned, allowing edible foods subject to existing food restrictions and protections. Deleted legacy lists stay removed; summoning creates a fresh default when needed.

- Fix learned-status updates when hunter training IDs differ from pet casting IDs; reference mappings cover 32 abilities and their ranks.

- Treat Screech and Demoralizing Screech as the same ability.

- Prevent premature low-food alerts while inventory settles after login.



Validation: Lua 5.1 regression checks pass. Pet-status display, independent checkboxes, own-pet tips, feeding text, login food warnings, list cleanup/default creation and duplicate prevention were tested in game. Bite 2 was reported as Learned. Broader automatic-learning and live Beast Lore testing is still welcome.



Aspect of the Pack and Disable Both still need in-game testing; my hunter isn't level 40 yet. If a feature fails, please comment with the feature, what happened and any error message. Pet data uses a Classic baseline during Forever beta; live Beast Lore takes priority.



Install both folders from the ZIP into Interface/AddOns, replacing existing files. Keep the FeedomaticToo settings migration loader enabled for the first import and restart the client.



Original engine: Gideon (MIT); adaptation and enhancements: OpenAI Codex, directed and tested by the user.

Thanks to Raytchel Bates and Vanauge Imnewtorp for their suggestions!



# Saved pet food list cleanup and pet-window navigation (unpublished)



- Key new saved food lists by pet name + family, not transient world GUID. Same-name Raptor and Tallstrider stay separate; same name/family reuses rules across summons. Summoning saves a default profile once name and family are available; subsequent summons and reloads reuse it. All edible foods are allowed by default, subject to existing restrictions and protections. Deleting then summoning creates a fresh default profile.

- Preserve unknown-family legacy records without applying them by name. Show these duplicates as one cleanup group per name; exact current GUID matches can safely gain family metadata. Known-family duplicates consolidate by name/family, combining saved allowed and blocked entries with blocks taking precedence. Legacy records sharing the current pet name remain protected until dismissal/switch.

- Saved-list manager shows group/count/family, Previous/Next navigation, confirmed group deletion and visible remaining counts. Add a separate two-click Delete all inactive lists action; validate the selection again before deleting. Existing user profiles are not deleted by this code installation.

- Saved-list deletion window uses a solid opaque background to prevent the window behind it showing through.

- Right-click on the pet status window now opens the main HunterTools tool menu.

- Lua 5.1 identity, legacy safety, deletion/reopen/reload, confirmations, current-pet protection, combat and navigation tests pass along with the existing addon suite. In-game cleanup validation pending.



# In-game validation — October 16, 2026



- User confirmed pet-status window appearance, independent Window/Mouseover display checkboxes, and own-pet-only tooltip details. User also confirmed the feeding chat message in-game.

- User confirmed the login food-warning fix: no premature warning immediately after logging back in, and none after waiting for inventory to settle with suitable food available.

- User reported Bite rank 2 showing Learned during the new-ability test. The conversation did not explicitly confirm whether Beast Training remained unopened.



# Pet status window and configurable mouseover tips (unpublished)



- Add independent Pet status tool checkbox, /ht pet toggle, and /ht petsettings. Window defaults off; own-pet mouseover tips default on.

- Movable, clamped window with saved per-character position, position lock/reset, portrait/name, health/focus bars and ten configurable fields. Separate Window and Mouseover checkboxes control level/family, health, focus, happiness/damage modifier, loyalty/trend, training points, diet, food/next item, feeding status and last feeding.

- Tooltip augmentation applies only to the player's own pet; hovering the status window shows the same selected tooltip fields. Disabled/missing/restricted APIs have safe fallbacks. Pet data reads pause in combat.

- Record food and timestamp per pet only on confirmed HunterTools feeding. Food inventory remains visibly settling until the login scan completes.

- Lua 5.1 UI/data/settings/tooltip, movement/lock/reset, secret/combat/missing API tests, TOC validation, all 304 learning-ID cases and the existing addon suite pass. Live visual/API verification pending.



# Local feeding chat message (unpublished)



- Print privately: Fed <petname> a delicious <petfood>, after HunterTools receives Feed Pet success for a prepared feeding click/keybinding. Capture the pet and food before bag events change selection.

- Failed/interrupted casts, blocked clicks, expired attempts, changed pets and duplicate success events do not announce.

- Lua 5.1 feeding-message checks and existing addon regressions pass; user confirmed the feeding chat message in-game on October 16, 2026.



# Complete pet learning reference mapping (unpublished)



- Generate hunter training IDs and corresponding pet casting IDs from ForeverDB client spell records: Hunter class 3, Learn Spell effect 36, target Pet 5. Validate both records agree on rank; no guessed spell ID ranges.

- 152 hunter training spells and 152 pet casting spells across 32 abilities; all 106 existing baseline ranks covered. Includes additional Forever spell records. Reference presence does not guarantee current beta obtainability.

- Normalize baseline Screech to the client name Demoralizing Screech, preserving previously cached knowledge.

- Full 304-ID message/label tests, exact effect-relationship checks, higher-rank exclusions, unrelated-message guards, actual saved Cower replay and the existing addon regression suite pass. In-game verification remains pending.

- See PET-LEARNING-COVERAGE.md and reference-data/forever-spells/learning-map.json for the audit table and source hashes.



# Local Cower training-spell fix (unpublished)



- Live capture identified hunter learning spell 1748 for Cower rank 2, distinct from pet cast spell 1753. Add the verified training-spell mapping.

- Reprocess the last captured learning message after loading settings, recovering the already-earned ability without editing saved variables or requiring Beast Training.

- Exact captured-message, immediate target-label, higher-rank exclusion, replay and full addon regression checks pass. Live reload verification pending.



# Local food-login hotfix (unpublished)



- Delay food notifications on login/reload and world entry until a 10-second grace period and two seconds of agreeing fresh inventory scans. Restart confirmation on bag, item-data, lock and pet events; reject an unavailable backpack slot count. Keep rescanning on the regular ticker while waiting.

- Suppress low-food and hunger-text notifications during inventory confirmation; normal feeding selection remains usable. Genuine low/empty food warnings resume after confirmation.

- Lua 5.1 login regressions and the existing addon suite pass; live Tallstrider login retest remains pending.





# Local learning hotfix (unpublished)



- User observed Cower learned status updating only after opening Beast Training.

- Handle hunter-learning spell hyperlinks without a visible rank, preferring client rank subtext and using the existing Classic-baseline spell rank data as fallback. Do not infer hunter knowledge from a pet learning a spell or guess ranks from bare names.

- Always register system learning messages even when the optional event validator is absent. Capture the last matched learning message for /ht trainingdebug.

- Lua 5.1 regressions pass for the reproduced Cower link case, rank changes, trainer scans, unsupported events and guarded messages. Exact live failure and the reported error sound remain unconfirmed; in-game retest required.

# HunterTools 3.0.1



- Fix duplicate Feed Pet keybinding warnings when the legacy FeedomaticToo settings loader and HunterTools are both enabled.

- The compatibility folder now includes an empty Bindings.xml, replacing the old binding declaration. Existing Feed Pet key assignments and automatic settings migration are preserved.



Install both folders from the ZIP, overwriting existing files. Enable HunterTools and the FeedomaticToo settings migration loader for the first import; restart the client.



Original engine: Gideon (MIT). Adaptation and enhancements: OpenAI Codex.



# HunterTools 3.0.0



- Rename FeedomaticToo to HunterTools, with a settings-only legacy loader and one-time per-character migration.

- Four-tool configuration menu with enable checkboxes and Settings buttons; /ht and /huntertools commands, old aliases retained.

- Add Growl / Aspect of the Pack entry prompts, with explicit disable buttons and no repeat prompt for intentionally re-enabled effects.

- Add draggable target portrait/name, colored range labels, gray non-enemy targets, and estimated distance bands.

- Bundle 297 Classic ability-teaching creature records and 17 family diets; live Beast Lore overrides baseline details.

- Add optional pet details and learned-ability status colors; adapt Beast Training lookup to Forever's trainer interface.

- Add optional buff-food and cooking-ingredient protection, OFF by default, plus clearer feeding status.

- Fix false low-ammo warnings on entering or leaving instances while inventory/equipment data is loading. Wait for weapon data, confirm fresh carried totals, and allow inventory to settle.

- Fix missing instance-settings initialization and unsupported CRAFT_SHOW registration. Add raptor diet entry.



Known limitations: Classic pet data may differ from Forever. Aspect of the Pack and Disable Both remain untested in game. Automatic ability learning and live Beast Lore parsing need further validation.



My hunter isn't level 40 yet, so I haven't been able to test disabling Aspect of the Pack. If someone can test it, please let me know how it goes in the comments.

If a feature doesn't work, please leave a comment describing what happened and any error message.



Original engine: Gideon (MIT); adaptation and enhancements: OpenAI Codex.

Thanks to Raytchel Bates and Vanauge Imnewtorp for their suggestions!

