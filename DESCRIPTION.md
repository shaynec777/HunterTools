# HunterTools

![HunterTools jackknife logo](https://raw.githubusercontent.com/shaynec777/HunterTools/main/artwork/HunterToolsLogo.png)

FeedomaticToo has morphed into HunterTools due to the many great suggestions we've received!

HunterTools brings pet feeding, ammunition reminders and upgrades, dungeon checks, pet information, target range, and an ability browser together for World of Warcraft Forever. All tools can be individually enabled or disabled.

## New in this update

- Mob Finder and Player Finder, accessible from the new Finders section of the main menu or `/ht mobfinder` and `/ht playerfinder`.
- Saved watch lists, optional partial-name matching, sound/screen alerts and a click-to-target detection popup. Player targeting supports Forever surnames.
- Brief highlight on the targeted unit's visible nameplate. Direction arrows and private map markers require genuine public location data; ordinary detections commonly provide none. No Questie dependency.
- Current pet details can display learned abilities from the live pet spellbook, with independent window and mouseover settings.

## Bug fixes and refinements

- Include Sonic Blast in Bat family training options, with Blizzard/Petopia source labeling. This does not claim that every wild bat teaches it or assign unknown ranks.
- Clarify that weapon comparisons assume stationary Auto Shot, including the new 0.5-second standing requirement.
- Reviewed October 15 changes to Dismember, Sonic Blast and Mine!: bundled ability records store spell identities and teaching references, not outdated damage, duration or cooldown descriptions. Pet expertise/crit changes do not require changes to our Auto Shot-only estimate.
- Growl detection and disabling on instance entry confirmed working in game after the update.

## Tools and controls

- **Food:** one-click feeding or your Feed Pet keybinding, per-pet allowed/blocked lists, food protection, hunger sounds/text reminders and supply warnings. Food catalog and Feeding & alerts have separate tabs.
- **Ammunition:** track selected ammo types with individual minimums. Configure stock alerts separately from upgrade advice and its notification interval/channel. Engineered ammo is optional. Counts exclude banks and wait through inventory loading.
- **Range and animals:** movable target window with distance estimates, plus independent mouseover and range-target animal fields. Show roles, abilities/learned ranks, diet and matching bag-food quantities. A family does not guarantee tameability.
- **Pet status:** movable own-pet window and own-pet mouseover tips, independently selected details, position locking and reset. Independent low-health and death warnings include a persistent native visual when health is restricted. Restricted-health low warnings cannot trigger sound/chat or timed repeats; death alerts work separately.
- **Beast details (all classes):** `/ht beastdetails` shows a targeted wild beast with a search box, or opens standalone name search without a suitable target. `/ht beastdetails <name>` searches directly. Enable the addon for each character. Unknown Beast Lore data stays unknown; non-hunters have no hunter learned-rank labels.
- **Pet abilities:** `/ht abilities` shows learned/next ranks and teaching animals with levels/zones. Wowhead opens a selected URL: press Ctrl+C, then paste it into a browser. Show pet pictures can be turned off; first-time creature models can load slowly.
- **Aspects and tracking:** `/ht aspects` and `/ht tracking` configure separate movable buttons and optional missing-aspect/tracking dialogs. Tracking includes learned profession abilities.
- **Dungeon checks:** offer to disable Growl autocast and replace your own Aspect of the Pack with another learned aspect on entry. Changes require your click and wait until combat ends.
- **Experimental weapon comparisons and scope previews:** `/ht weapons` enables/disables tooltip estimates and selects the candidate scope preview. Settings are saved per character.

Use `/ht` or `/huntertools` for the tool menu; `/ht tracking` (tracking chooser/button), `/ht aspects` (aspect chooser/button), `/ht petalerts` (health/death warnings), `/ht petalertdebug` (health diagnostics), `/ht beasts` (collection journal), `/ht hungerdebug` (alert diagnostics), `/ht foods`, `/ht ammo`, `/ht abilities`, `/ht weapons`, and `/ht petsettings` open their respective controls. `/fom` and `/feedomatictoo` remain aliases. Right-click the feeder or pet-status window for the tool menu. Feeding always requires a click or keypress. Move unlocked windows and buttons with Shift + left-drag outside combat.

## Experimental ranged comparison formula

Estimates assume stationary Auto Shot; firing requires standing still for 0.5 seconds.

**Character Auto Shot DPS = ((estimated minimum shot damage + estimated maximum shot damage) / 2) / effective shot interval in seconds.**

For example, `(17.9 + 24.9) / 2 / 2.03` is approximately **10.5 character Auto Shot DPS**. The weapon's own listed DPS uses base weapon damage and base speed. Our estimate includes your character's ranged attack power, ammo, scope and retained live damage/attack-speed bonuses, so it can be higher than the weapon's listed DPS.

Candidate weapons start from your live equipped damage range and add the weapon-stat, attack-power, speed, ammo and scope differences. Current buffs are already in the baseline and are not added again. Scope previews replace the candidate scope; your equipped reference keeps its actual scope. See WEAPON-COMPARISONS.md in the source repository for the exact calculation.

**Ranged weapon comparisons and scope previews are Experimental.** They estimate Auto Shot throughput before armor, misses and critical hits, rather than total hunter DPS. Special-shot rotations, pet damage, procs, conditional effects, stat-percent multipliers and weapon-specific talent changes are not simulated. Unsupported stat changes are flagged. Scope eligibility uses known character levels plus a Classic minimum weapon-item-level rule; actual application still needs verification in Forever. Unknown scope enchants can make an estimate unavailable. English weapon tooltips are currently required.

## Installation and updating

Extract both folders in the release ZIP into Interface/AddOns, replacing the existing addon files, then restart WoW to load the new modules and logo. HunterTools is the addon; FeedomaticToo is a settings-only compatibility loader. Enable both entries for the first migration and keep the compatibility folder until your characters have migrated. Existing per-character settings, food lists and positions are retained. Back up settings before manual installation.

Open Beast Training to seed or refresh learned ranks. Learned and missing labels reflect cached information; incomplete scans or filters can affect confidence. Reference coverage includes 32 abilities / 152 ranks and 297 Classic teaching creatures. Partial Wowhead Forever data supplements creature identities and family diets but does not verify all teaching ranks or locations.

## Beta data and testing

Pet roles, diets and teaching sources combine Petopia Forever, labeled community reports, local observations, Wowhead Forever and a Classic fallback. Live Beast Lore takes priority. The new collection journal still needs broader in-game testing. Unknown details remain unknown; we plan to verify and refine the database after Forever leaves beta.

The menus, animal tooltip changes, ability browser/copy links, ammo recommendations/notifications and depleted-stock behavior have in-game feedback plus automated regression coverage. One equipped-weapon estimate matched the character sheet; candidate weapon and scope effects still need broader testing and remain Experimental. The aspect button, enlarged pet-healing range warning, native low-health banner and its out-of-range wording were confirmed in-game. Learned-rank mouseover updates after a new tame were also confirmed. Tracking button/no-tracking dialog behavior and logout/login without errors were confirmed; the latest compact/movable dialog layout and Shift-drag refinements have automated regression coverage and still need broader in-game feedback. Combat aspect switching, intentional-cancellation handling, the instance Pack replacement chooser and some Beast Lore paths still need broader checks.

If a feature doesn't work, please leave a comment describing what happened, which feature you were using, and any error message so we can investigate.

## Credits and sources

Original feeding engine: FeedPetForever by Gideon (MIT licensed). Adaptation and enhancements: OpenAI Codex, directed and tested by the user. Original Feed-O-Matic concept: Gazmik Fizzwidget. Original notices are retained; no affiliation or endorsement is implied. Blizzard client portraits, textures and sounds are referenced rather than bundled. The jackknife logo is original AI-generated project artwork, directed and approved by the user.

Food and partial Forever reference: Wowhead Forever. Beast/family data: [Petopia Forever](https://www.wow-petopia.com/forever/) and xWillawisp's linked community taming sheet. Classic ability/diet baseline: [Petopia Classic](https://www.wow-petopia.com/classic/abilities.php). See PET-DATA-SOURCES.md and WEAPON-COMPARISONS.md for scope, formula sources and limitations. Buff-food detection recognizes English Well Fed tooltip text; manually block any special foods it misses.

Thanks to Raytchel Bates and Vanauge Imnewtorp for their suggestions!
