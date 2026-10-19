# Pet status window and mouseover tips

Restart WoW once after installation to ensure the new PetStatus.lua module and TOC are loaded.

- `/ht` → check **Pet status** to show the window. `/ht pet` toggles it directly.
- Hold Shift and drag with the left mouse button outside combat. Right-click for the main HunterTools tool menu.
- `/ht petsettings` opens the field controls, position lock and position reset.
- Separate **Window** and **Mouseover** checkboxes select each of ten details. Pet name is always the window header.
- **Enable mouseover pet tips** adds the chosen details when hovering your own pet or the status window. Tips default on independently of the window, which defaults off.
- Health/focus bars and detailed pet reads pause during combat. Mouseover unit tips are not augmented during combat. No pet prompts you to summon one; missing APIs show unavailable.
- Last fed records only future successful HunterTools feedings. Food supply respects the current allowed/protected foods and reports inventory settling during login.

Preferences and window position are per character. This is an unpublished local addition; live visual confirmation is still needed.

## Unpublished learned-abilities addition

Own-pet status and mouseover tips now include Learned abilities, independently selectable for Window and Mouseover. Reads the current pet spellbook with ranks; does not substitute the hunter training cache or database abilities. Handles missing pet, combat, loading, partial data, duplicate spells and legacy spellbook APIs. Defaults on for both surfaces. Automated pet-status and menu checks passed. Added after 3.1.4 publication; not part of the published ZIP.
