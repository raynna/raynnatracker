# Release packaging

Run `python tools/package_tracker.py` to produce the player-only CurseForge ZIP.
The ZIP contains RaynnaTracker and the required ForeverHunt legacy-save loader.
Only TOC-loaded Lua, referenced artwork, and attribution/license files are included.
Tests, build tools, caches, and personal saved variables are not shipped.

Install both folders into Interface/AddOns. QuestieDB and GearQuest are not required.
For old installations, leave the legacy loader enabled so each character can migrate.

Install `lupa` to run `python tests/test_addon.py`. Data regeneration additionally
requires the dependencies/input versions documented in the tools and provenance.

This repository includes source generators omitted from the player ZIP. Third-party
notices and license terms remain in RaynnaTracker; do not remove those from releases.
