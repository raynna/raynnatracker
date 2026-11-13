# Raynna's Tracker and Bestiary

Standalone WoW Forever addon (Interface 16001). Install both folders from `RaynnaTracker-1.18.0-CurseForge.zip`. `RaynnaTracker` contains Tracker and Bestiary; the tiny `ForeverHunt` compatibility package only loads old saves for automatic migration. No Questie, QuestieDB or GearQuest is required. Restart WoW after upgrading from the old folder name.

New saves use `RaynnaTrackerDB` in `RaynnaTracker.lua`. On first load, existing `ForeverHuntDB` data is copied only if the new database does not exist. Old saved-variable files are left intact. Keep the legacy data loader enabled so every character can migrate when it next logs in.

A fixed summary above the monster list shows quests completed and their total reward XP, starting at zero. **Include quest XP** is checked by default: checked includes quest rewards in XP gained, unchecked subtracts the tracked quest subtotal. The quest subtotal remains visible and tracking continues. These per-character totals start with newly observed turn-ins, include repeatable quests, and do not reconstruct historical rewards. Overall XP remains independently measured; quest rewards are not added to it twice.

## Tracker

- `/rt`, `/fh` or the minimap button toggles the window. Tracking continues while hidden.
- Drag the title to move. Drag edges/corners to resize; Ctrl + scroll scales the UI.
- Type a percentage and press Enter, or use the scale +/- buttons (40%�180%).
- The title-bar minus button collapses to title, money and XP; plus restores the list.
- Rows show cached monster portraits, merged level ranges, kills, coins and XP.
- Hover a row for collected loot, with a monster portrait, item icons and item tooltips.
- **Reset all** clears monster history, collected loot, quest totals, money and XP after confirmation; preferences are preserved. Hover a monster row for its right-side **x**, then confirm removal of that record. Individual removal leaves overall money and XP totals intact.
- `/rt center` recovers the window. `/rt demo` creates 20 sample monsters; `/rt demo off` returns to live data. Demo data is saved separately and never replaces character history.

## Bestiary

Hold Alt over a creature to see possible drops. Hold Alt over an inventory item to see monster, vendor and quest-reward sources. Known drop chances sort highest first. Monster entries include reference level ranges, zones and portraits.

The first inventory item stays selected for the duration of that Alt press, allowing the pointer to cross other bag slots to reach the list. Release and press Alt again for another item. Panels remain open while Alt is held or the panel is hovered; Pin keeps them open independently.

Quest items have a yellow [Quest] marker. Related quest names appear where the bundled snapshot has them. Conditional chances have an asterisk; unknown chances show ?. Hover a row for its full explanation. Quest eligibility is not checked against your quest log.

The Bestiary button or `/rb demo` opens a Bloodscalp Warrior reference preview. `/rb hide` closes it.

## Data and persistence

Kills, collected items, money, XP, settings and demo data are saved per character on normal logout or UI reload. Overall income counts positive wallet changes; spending does not subtract. Creature-specific coins and items require a known corpse source. Kill XP attribution uses named receipt events, while overall XP includes other rewards and level-up rollover. Hiding messages in chat does not disable their events.

NPC portrait textures are cached during the UI session. They load off-screen before display and are reused while scrolling. Reloading the UI clears WoW's rendered textures, so portraits must rebuild; recorded monster IDs and tracking history remain saved.

## Standalone reference coverage

The bundle includes Classic loot tables and portrait display IDs, plus a frozen Forever metadata snapshot covering 13,417 NPCs, 21,442 items and 5,233 quests. Source metadata includes locations, quest associations, vendor/reward sources and the relevant faction-specific NPC/item corrections. Additional quest associations are derived from the snapshot's item objectives.

When an enabled QuestieDB has a newer release version than the bundled snapshot, source metadata queries prefer it. Missing fields, unavailable APIs and query errors fall back to bundled data; explicit empty lists are respected. Equal, older or unknown versions use the snapshot. QuestieDB remains optional. This updates metadata (locations, quests and sources), not the separately bundled Classic drop probabilities.

Backgrounds use our own full-size opaque parchment texture, with no GearQuest dependency. Bundled data updates still arrive with addon updates.

Standalone does not mean a complete or authoritative Forever database: Classic probabilities can differ, and newly discovered sources can be missing. Unknown probabilities are never invented. See `RaynnaTracker/REFERENCE-SOURCES.txt`, `LICENSE-QuestieDB.txt`, `GPL-3.0.txt` and `LICENSE-ClassicDB.txt` for provenance and upstream terms.

## Development

See [DEVELOPMENT.md](DEVELOPMENT.md) for the source map. Run `python tests/test_addon.py` with `lupa` installed. These mocked-runtime checks cover behavior and serialization; they do not replace an in-game visual check.

### In-game settings
Open Escape > Settings > AddOns > Raynna's mods, or type `/rt settings`.
The page includes tracker visibility, minimization, minimap button, centering and
scale; bestiary NPC/item Alt-hover toggles and scale; and shared parchment and
background opacity controls. Percentages accept typed values followed by Enter
or the adjacent minus/plus buttons. Changes apply immediately and save per
character. `/rt show` reopens a closed tracker; `/rt` toggles it. Closing the
tracker does not stop collection. The page currently covers Tracker and Bestiary.



Standalone Bestiary: Tracker 1.18.0 detects RaynnaBestiary when installed and uses its panel and settings, avoiding duplicate hover hooks. Without it, the embedded Bestiary remains available.
