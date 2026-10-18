# Aspect chooser — 3.1.2

- Optional movable aspect button; enabled by default. Left-drag to move it, right-click for a secure learned-aspect picker. Position saves per character; enable, lock and reset controls are in aspect settings. The current aspect icon updates outside combat, with a question mark when none is confirmed. Prepared picker buttons can be used in combat; learned choices refresh after combat.
- Optional no-aspect pop-up; enabled by default. Configure with `/ht aspects` or the Aspect reminders button in the main menu.
- Shows only learned aspects, using the highest known rank in each spell family. Aspect names come from the client. No aspect is cast automatically; each action uses a secure click button.
- Stay without an aspect saves intentional absence per character until you next activate an aspect. An identifiable direct cancellation through C_UnitAuras.CancelAuraByInstanceID is also remembered, using the cached public identity of your own aspect. Other cancellation paths may require the explicit Stay without choice; aura loss alone is never assumed intentional.
- Later snoozes for five minutes. Turn off this reminder disables the relevant reminder; independent settings control missing-aspect and Pack entry warnings.
- Waits for three seconds of confirmed aspect absence. Pauses through combat, death, mounting, taxi/vehicle travel and configuration menus. Unavailable/secret aura data is not treated as absence.
- If your own Pack is on when entering a dungeon or raid, the chooser suggests other learned aspects and omits Pack from replacement choices. Keep Pack dismisses that entry reminder. Intentionally enabling Pack later in the instance is not nagged about.
- Growl has a separate secure Disable Growl button. The old Disable Pack and Disable Both actions are removed; choosing an aspect replaces Pack instead of cancelling it into no aspect. Growl and aspect dialogs do not overlap.
- Fresh instance entry rechecks Pack/Growl. The Dungeon checks master switch and existing Pack preference remain respected. The no-aspect reminder is independently configurable.

Automated Lua 5.1 checks cover learned/highest-rank choices, grace time, explicit absence/cancellation/reset, disable/snooze controls, successful versus failed aspect selection, other hunters' Pack, instance entry semantics, Growl coordination, settings navigation, and combat/secret/API-failure guards. Aspect-button movement, independent enable/lock, reset, icon states and secure picker attributes also have automated coverage. Real secure spell-button behavior and default-client cancellation hooks still need in-game confirmation. Restart WoW to load the new module. This build has not been published.

Spell families are factual IDs from the retained Forever client spell shards. Aura API reference: https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua . Cancellation is observed with a secure post-hook; HunterTools never calls that cancellation API.

In-game feedback, October 17, 2026: user confirmed the aspect button works. Combat switching, intentional-cancellation handling and the instance Pack replacement chooser remain separate testing items. User also confirmed the enlarged pet heal-range warning in the range window.
