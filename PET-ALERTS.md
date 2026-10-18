# Pet health and death warnings — 3.1.2

Open `/ht petalerts`, or Pet status > Configure > Pet low-health / death warnings.

- Independent master switch, low-health switch and pet-dead switch. These warnings do not depend on the pet-status window being enabled.
- Banner, chat and sound can each be enabled or disabled independently for each warning type.
- Defaults: enabled, banner and sound on, chat off. Low-health threshold 35%; low repeat 15 seconds; death repeat 0 (once until revival). Sound is the built-in raid-warning sound on Master volume.
- Threshold range: 1–95%. Repeat range: 0–600 seconds; 0 means once per episode. Enter or leaving the input saves. A 5-percentage-point recovery margin rearms low-health alerts; revival rearms death alerts. New pet identities start fresh episodes.
- Test buttons use the selected outputs without requiring a pet to be hurt or dead, and do not enable disabled warnings.
- Health/death events provide prompt checks; the existing half-second ticker handles repeats. Public health/death data can be used in combat. When health is restricted, the low-health Banner uses a native health-to-opacity curve to display a persistent red warning below the selected threshold. It does not inspect the secret result. Sound, chat, repeat intervals and episode recovery require readable health; the native visual clears directly at the threshold. Missing/failed native results hide the visual; no stale low-health event is queued for later. Dismissal or absence is not assumed to mean death.
- Existing feeding and heal-range warnings remain independent. No automatic healing, resurrection or other actions occur.

Automated checks cover thresholds, episode recovery, repeat timing, death/revival, pet changes, master/type/output switches, public combat values, secret/loading guards, saved settings, invalid inputs and navigation dependencies. Native sound/banner behavior and actual combat health availability still need in-game testing. Restart WoW to load the new module. Included in 3.1.2.

October 18: installed native visual fallback for restricted health. Controlled by existing master/low-health/Banner switches. Large red warning near the upper center of the screen. `/ht petalertdebug` reports native rendering requests, not whether the secret opacity currently makes the warning visible. Test buttons preview ordinary outputs; actual threshold rendering requires in-game testing.

In-game confirmation, October 18: user verified the native low-health banner and range-aware wording, including corrected punctuation. Restricted-health sound/chat are still unavailable; the death warning is separately confirmed.
