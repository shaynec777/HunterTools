# HunterTools publication description

## Required for the next publication

Logo direction requested October 16, 2026: replace the publication logo for the next release with an original hunter jackknife/multi-tool emblem, with a bow, gun, tallstrider and trap extended. The user approved artwork/huntertools-multitool-concept-v1.png and explicitly requested it in the main menu header. Use that design for the next publication.

Add a prominent **New in this update** section to the published description, listing the new features included in that release, with a **Bug fixes** subsection for fixes. Refresh both lists against the final release contents and testing results before publishing.

Draft for the currently unpublished changes:

### New in this update

- Optional movable pet-status window with health and focus bars, happiness, loyalty, training points, diet, food supply, feeding status, and last successful feeding.
- Mouseover status tips for your own pet, with separate Window and Mouseover checkboxes for the details you want to see.
- Saved window position, position locking, and a reset-position control.
- Private feeding confirmation: “Fed <petname> a delicious <petfood>.”

#### Bug fixes

- Saved food lists use pet name and family, with safe legacy cleanup, clearer deletion feedback, and a confirmed inactive-list cleanup option. Summoning creates or reuses a default list with existing food protections applied.

- Fix missing learned-ability updates when hunter training spell IDs differ from pet casting spell IDs, using reference mappings for 32 pet abilities and their ranks.
- Recognize Screech and Demoralizing Screech as the same ability when displaying learned status.
- Prevent premature low-food warnings while inventory is settling after login.

Published as HunterTools 3.0.2 on GitHub on October 16, 2026; submitted to CurseForge with automatic publication after approval. CurseForge file ID: 9206832. Both public release notes include New in this update and Bug fixes sections. The Android app and Windows server-status widget are separate projects and are not HunterTools release features.

Testing update, October 16, 2026: the user confirmed the food-warning fix after logging out and back in, with no false warning immediately or after inventory settled.

FeedomaticToo has morphed into HunterTools due to the many great suggestions we've received!

## Pet database caveat

Pet ability and diet information currently uses a Classic baseline while Forever is in beta and may differ from Forever. Live Beast Lore information takes priority. We plan to verify and refine the database after Forever leaves beta.

## Feedback request

If a feature doesn't work, please leave a comment describing what happened, which feature you were using, and any error message so we can investigate.

## Closing line for the longer mod description

Thanks to Raytchel Bates and Vanauge Imnewtorp for their suggestions!

Testing update, October 16, 2026: user confirmed pet-status window appearance, independent display checkboxes, and pet details appearing only on their own pet. User also confirmed the feeding chat message in-game.

First logo concept saved: artwork/huntertools-multitool-concept-v1.png. User approved this design.

Testing update, October 16, 2026: the user confirmed the redesigned menus look good. Ranged weapon comparisons and scope previews are the next local test feature. The approved jackknife logo now replaces the Hunter class icon in the main menu header.

Next publication description must include the character Auto Shot DPS formula, the distinction from base weapon DPS, and the documented calculation limits. See DESCRIPTION.md and WEAPON-COMPARISONS.md. The user screenshot confirmed one equipped-weapon damage range against the character sheet (17.9-24.9 vs displayed 17-25); candidate swap/scopes remain to be verified in game.

Label ranged weapon comparisons and scope previews **Experimental** in the next publication description. The settings title and comparison tooltip also carry that label.

## HunterTools 3.1.0 publication — October 16, 2026

Published GitHub release v3.1.0: https://github.com/shaynec777/HunterTools/releases/tag/v3.1.0 (commit 4d7087fd5a03e5fbbc3bb976092a624e7d912d68). The release includes the approved jackknife logo and explicitly labels ranged weapon comparisons and scope previews Experimental, with the character Auto Shot DPS formula and calculation limits.

CurseForge logo, summary, and description were saved and verified publicly. Corrected file 9217350 is Under Review with automatic publication after approval. The initial file 9217314 was rejected for top-level documentation; the replacement ZIP contains only addon folders. GitHub's ZIP asset was also replaced with the corrected package. SHA256: 43f7fa20afec91e2685fb60e9e34114df257e9ea63c8565a8f029e2ee985a523. Lua 5.1 syntax, feature regression checks, TOC references, ZIP integrity, and release labels passed before publication.

CurseForge approval verified October 16, 2026: corrected HunterTools 3.1.0 file 9217350 is Approved. https://www.curseforge.com/wow/addons/huntertools/files/9217350


## HunterTools 3.1.1 — October 17, 2026

Published on GitHub: https://github.com/shaynec777/HunterTools/releases/tag/v3.1.1 . Commit 6ddd37453fb1c6076ddcc72598107d3eb48fd2a9. ZIP SHA256 a240183ada1fc00aaf9732794ab6ba1e54a27c83637146dcf523c17fd6b3d4f8 (261331 bytes).

CurseForge file 9233149 submitted with automatic publication; Under Review at last check. Public feature description saved successfully. Hunger/inventory/new-pet sound fixes, clearer selected tabs, Petopia Forever/community beast facts, local collection/export and source fallbacks included. Community and Classic-linked provenance retained; ranged weapon comparisons and scope previews remain Experimental, with formula and limits. Automated release checks passed. User confirmed hungry banner delivery after the latest food-scan fix. Collection still needs broader in-game validation. Installed version synchronized to 3.1.1 with backup and hash verification.

Testing update, October 17, 2026: user confirmed that after the hunter learns a pet ability from a newly tamed pet, mouseover information for a beast teaching that ability/rank shows Learned. This confirms the automatic learned-rank mouseover update; it does not independently confirm the ability browser's next-rank transition.

Testing update, October 17, 2026: user confirmed the aspect button works and the pet healing-distance warning works with the larger text. This confirms the reported button behavior and warning presentation; combat aspect switching, intentional-cancellation handling and the instance Pack replacement chooser were not separately confirmed.

Ongoing requirement, October 17, 2026: always show the current addon version in the main menu. The label now reads F.VERSION dynamically when the menu refreshes; maintain this in all future releases.
