# Tracking button — 3.1.3

Open `/ht tracking` or the Tracking button shortcut in the main menu.

- Independent Show button, Lock position, and no-tracking reminder switches; button and reminder default on.
- Shift + left-drag outside combat to move; saved position and reset control. Interrupted dragging completes safely after combat.
- Right-click opens an icon-and-name picker beside its button until repositioned for learned spell-backed tracking in the native minimap tracking list. Includes profession tracking such as Find Herbs/Find Minerals when known. Service filters (repair, vendors, etc.) are omitted. Native tracking rules determine which abilities can coexist.
- The button icon follows active tracking; active options have a green asterisk. No confirmed active tracking uses an empty marker.
- After three seconds with no active tracking and at least one learned choice, a dialog offers the tracking abilities, Stay without tracking, or Later (five minutes). Deliberate absence is remembered until tracking becomes active again.
- Automatic reminders pause during combat, death, mounting/travel, other settings and aspect/instance prompts. Unknown tracking state does not manufacture a warning. Secure choices are prepared outside combat and execute only on a user click.
- New module requires a full game restart after installation. Included in 3.1.3. Tracking button/dialog and logout/login were confirmed in-game; latest dialog movement refinements need broader feedback.

Native API reference: https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/MinimapDocumentation.lua
