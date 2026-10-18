# HunterTools

![HunterTools jackknife logo](https://raw.githubusercontent.com/shaynec777/HunterTools/main/artwork/HunterToolsLogo.png)

FeedomaticToo has morphed into HunterTools due to the many great suggestions we've received!

HunterTools brings pet feeding, ammunition reminders and upgrades, dungeon checks, pet information, target range, and an ability browser together for World of Warcraft Forever. All tools can be individually enabled or disabled.

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

## Tools and controls

- **Food:** one-click feeding or your Feed Pet keybinding, per-pet allowed/blocked lists, food protection, hunger sounds/text reminders and supply warnings. Food catalog and Feeding & alerts have separate tabs.
- **Ammunition:** track selected ammo types with individual minimums. Configure stock alerts separately from upgrade advice and its notification interval/channel. Engineered ammo is optional. Counts exclude banks and wait through inventory loading.
- **Range and animals:** movable target window with distance estimates, plus independent mouseover and range-target animal fields. Show roles, abilities/learned ranks, diet and matching bag-food quantities. A family does not guarantee tameability.
- **Pet status:** movable own-pet window and own-pet mouseover tips, independently selected details, position locking and reset. Independent low-health and death warnings include a persistent native visual when health is restricted. Restricted-health low warnings cannot trigger sound/chat or timed repeats; death alerts work separately.
- **Pet abilities:** `/ht abilities` shows learned/next ranks and teaching animals with levels/zones. Wowhead opens a selected URL: press Ctrl+C, then paste it into a browser. Show pet pictures can be turned off; first-time creature models can load slowly.
- **Aspects and tracking:** `/ht aspects` and `/ht tracking` configure separate movable buttons and optional missing-aspect/tracking dialogs. Tracking includes learned profession abilities.
- **Dungeon checks:** offer to disable Growl autocast and replace your own Aspect of the Pack with another learned aspect on entry. Changes require your click and wait until combat ends.
- **Experimental weapon comparisons and scope previews:** `/ht weapons` enables/disables tooltip estimates and selects the candidate scope preview. Settings are saved per character.

Use `/ht` or `/huntertools` for the tool menu; `/ht tracking` (tracking chooser/button), `/ht aspects` (aspect chooser/button), `/ht petalerts` (health/death warnings), `/ht petalertdebug` (health diagnostics), `/ht beasts` (collection journal), `/ht hungerdebug` (alert diagnostics), `/ht foods`, `/ht ammo`, `/ht abilities`, `/ht weapons`, and `/ht petsettings` open their respective controls. `/fom` and `/feedomatictoo` remain aliases. Right-click the feeder or pet-status window for the tool menu. Feeding always requires a click or keypress. Move unlocked windows and buttons with Shift + left-drag outside combat.

## Experimental ranged comparison formula

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
