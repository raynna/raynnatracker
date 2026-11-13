# Raynna's mods — addon development conventions

Read this guide before creating or changing a Raynna addon. It describes the shared
product conventions, not permission to redesign existing features. Explicit user
requests take precedence. Preserve existing appearance and behavior unless the
requested change needs otherwise.

## Scope and reference implementation

- Brand new interfaces as **Raynna's <Name>**. The shared settings category is
  exactly **Raynna's mods**.
- Target WoW Forever. The current Tracker package targets Interface 16001 and Lua
  5.1 syntax. Verify the actual client/API before relying on another WoW version.
- Tracker and Bestiary ship together in `../RaynnaTracker`, using `RaynnaTrackerDB`.
  Preserve existing namespace contracts. The `../ForeverHunt` compatibility package
  loads legacy saved data for a one-time copy into the renamed package; keep it bundled.
- Use `../RaynnaTracker/Theme.lua`, `Widgets.lua`, `Settings.lua`, `UI.lua`,
  `Bestiary.lua` and `Drops.lua` as concrete references. Consult
  `../DEVELOPMENT.md` for their responsibilities and data flow.
- This folder holds conventions; do not move existing addon installations here.
  Future independent addons should have their own installable folder and TOC.

## Shared Settings → AddOns page

Every future Raynna addon must expose useful options under **Escape → Settings →
AddOns → Raynna's mods**, even when it is the only Raynna addon installed.

- Use one shared top-level category, not duplicate categories with the same name.
  Add clearly named sections or child pages for installed Raynna addons only.
- Keep each addon independently usable. Never require Tracker, Bestiary, Questie,
  GearQuest or another Raynna addon just to register or open settings.
- For separately packaged addons, introduce a small, versioned, shared registry
  with a uniquely prefixed global (for example `RaynnaModsSettings`). Each package
  may bundle its bootstrap; initialize the registry/category once, register each
  addon by stable ID, and avoid replacing an already initialized registry.
  Registration must work regardless of addon load order, including late loading.
- Let each addon supply its own controls, getters and setters. Keep saved settings
  in that addon's own declared saved variables. Do not reach into another addon's
  private tables or persist frames/functions in saved variables.
- The current packages now bundle identical `SettingsRegistry.lua` version-1
  bootstraps and share `RaynnaModsSettingsRegistry`. Tracker/Bestiary registers
  `foreverhunt`; Talent Guide registers `talentguide`. Reuse this infrastructure
  and keep bundled bootstrap copies identical; do not create a competing category.
- Prefer the client's `Settings.RegisterCanvasLayoutCategory` and
  `Settings.RegisterAddOnCategory`; use supported subcategory APIs as needed.
  Feature-detect a legacy InterfaceOptions fallback. Open the registered category
  by its actual ID. Avoid hard-coded numeric IDs.
- Include visibility/reopen controls, scale percentage, useful feature toggles,
  and relevant appearance settings. Offer centering for movable windows and a
  minimap toggle when a launcher exists. Do not add meaningless controls merely
  to fill the page.
- Apply changes immediately and refresh controls on page show so slash commands
  and window controls stay in sync. Save preferences on normal logout/reload.
  Existing settings are per character; state that clearly. New addons default to
  per-character settings unless the user requests account-wide sharing.
- Percentage fields accept typed values with Enter, restore on Escape/invalid
  input, and have small minus/plus buttons. Clamp values to usable bounds;
  existing scale range is 40–180%. Use scrolling or subpages when controls no
  longer fit at supported screen/UI sizes.
- Provide a discoverable slash shortcut to settings and a way to reopen a closed
  window. Tracker uses `/rt settings`, `/rt show`, and `/rt` to toggle.
- Keep safe preference resets separate from destructive history resets. Destructive
  resets need an in-addon confirmation with working Reset and Cancel actions.
- Shared appearance controls must have an honest scope. Appearance edits now broadcast through explicit registry providers to registered
  packages, each persisting its own preferences. Keep this scope visible in the
  controls and do not introduce a required cross-package dependency.

## Visual language

Use compact, readable, classic WoW styling: warm dark brown panels, gold borders
and dividers, a brown title bar, subtle parchment grain, beige body text, gold
headings, and familiar red WoW buttons. GearQuest is a visual reference, not an
asset or runtime dependency.

Current baseline in Theme.lua (retain it unless deliberately changing the theme):

| Element | Baseline |
| --- | --- |
| Body background | RGB 0.035, 0.027, 0.018; default opacity 0.97 |
| Border | RGB 0.74, 0.55, 0.22; UI-Tooltip-Border; edge size 12 |
| Title fill | RGB 0.24, 0.115, 0.035 |
| Heading | RGB 1, 0.82, 0.18 |
| Body text | RGB 0.92, 0.86, 0.72 |
| Muted text | RGB 0.8, 0.74, 0.6 |
| Panel inset | Approximately 4–5 pixels |
| Title bar | 22 pixels high, 4-pixel inset; divider at 26 pixels |
| Body grain | Bundled RaynnaParchment.tga; alpha 0.3 |

- Centralize styling in a theme module. Respect stored appearance preferences for
  existing and newly created panels. Preserve defaults when new options are added.
- Use the bundled, original parchment material or licensed client assets. Anchor
  backgrounds to both panel corners so they fill resized panels. Do not stretch
  an atlas region with transparent padding or overlay oversized frame artwork.
- Keep text and controls above decorative artwork. Center header buttons vertically
  within the bar, inset from borders. Portraits must not straddle the divider.
- For collected-loot popups, place the monster name at top-left in the title bar;
  put its portrait below the divider alongside level/kill/XP/coin details.
- Use small item icons beside names, monster portraits where useful, normal item
  quality colors, and explicit quest markers. Preserve standard item tooltips.
- Format large integers with comma separators. Render money with denomination
  icons; do not confuse per-monster values with overall totals. Unknown drop
  chances must not be displayed as zero or invented percentages.
- Size compact panels around their contents. A collapsed tracker shows its title,
  restore button, money and XP with little unused width. Show only the relevant
  minus/plus collapse control for the current state.

## Interaction and accessibility

- Keep dragging smooth. Side handles change one dimension; corner handles change
  both. Resizing the layout and uniformly scaling the UI are distinct actions.
- Preserve the window's top-left location when minimizing/restoring or scaling,
  clamp windows to screen, and persist position, dimensions and scale.
- Tracker supports Ctrl+mouse-wheel scaling and editable scale percentage; explain
  that shortcut on scale-control tooltips. Do not unexpectedly consume ordinary
  list scrolling.
- Show slim visible scrollbars only when content overflows, including hover panels.
  Support wheel scrolling and thumb dragging. Avoid hover gaps that make interactive
  popups unreachable or swap the selected item while moving into them.
- Bestiary Alt-hover keeps the first inventory item locked for that Alt press.
  Retain its panel while Alt is held, the panel is hovered, or it is pinned; hide
  when none applies. Keep comparison/item tooltips and nested tooltips above the
  correct panel, restoring temporary tooltip layers afterward.
- Keep cursor indicators small and directional. The existing resize cursor is a
  client-specific compromise; do not restart cursor experiments or type in-game
  scripts without a user request.
- Closing a display does not silently stop data collection or erase history.
  A close action must always have a discoverable reopen path.

## Code structure and compatibility

- Use readable Lua 5.1, four-space indentation, descriptive local names and small
  functions with clear responsibilities. Follow the workspace `.stylua.toml`.
- Use `local _, Addon = ...` for package-local module communication. Keep transient
  state local; expose only intentional `Addon` methods. Prefix necessary globals,
  named frames and slash registrations to avoid collisions between addons.
- Separate events/data collection, persistence, UI/layout, shared widgets/theme,
  settings, external-data adapters and generated datasets. Add brief section
  comments; explain non-obvious client constraints, not every obvious statement.
- Define load order in the TOC. Guard optional APIs and unavailable/restricted data.
  Do not assume retail API availability or use protected actions to work around
  restrictions. The current client blocks combat-log registration used by earlier
  implementations; retain supported tracking events unless verified otherwise.
- Avoid constant polling when events suffice. Stop OnUpdate/loading work when
  idle. Reuse rows, textures and resolved reference data instead of rebuilding on
  every scroll. Keep large generated data out of handwritten UI files.
- Saved data contains serializable values only. Initialize missing defaults without
  overwriting existing choices. Migrate schema changes deliberately and preserve
  old history, IDs, public interfaces and saved keys.
- Keep preview/demo data separate from real records. Real collection continues
  independently; demo/reset actions must not wipe real history accidentally.
- Persist portrait/display IDs. Reuse loaded portrait textures within a session;
  do not promise that GPU textures survive `/reload` or restarting the client.
- A readability-only refactor must preserve behavior and appearance. Do not mix
  unrelated feature changes into it.

## Standalone data and optional integrations

- Bundle everything needed for advertised core features, with appropriate licenses
  and provenance. Never load another addon's private texture path as a requirement.
- Optional providers may improve bundled data. For current Bestiary metadata, use
  a newer installed QuestieDB when compatible, falling back per field on missing
  data, errors, disabled providers or older versions. Preserve meaningful false
  values and empty tables; do not treat them as missing.
- Reference drop rates come from sourced databases, not the user's observed loot.
  Distinguish Classic reference data, Forever-specific corrections, conditional
  loot, quest requirements, vendors, rewards and unknown coverage.
- Do not imply that optional metadata updates refresh separately bundled drop
  probabilities. Record source versions and reproducible build scripts. Retain
  attribution and license notices for redistributed data/assets.
- Do not hand-edit or hand-format generated databases; change their generator or
  documented correction input and rebuild when needed.

## Validation and delivery

- Inspect existing code and relevant documentation before editing. Use local files
  and tooling; do not control the game or type scripts/chat for routine changes.
- Run appropriate automated checks for changed behavior. Existing mocked Lua tests
  run with `python tests/test_addon.py` when lupa is available. Use StyLua for
  handwritten Lua, excluding generated files, and check whitespace errors.
- Cover persistence/migrations, callbacks, optional-provider fallbacks and load
  order when changed. A shared settings registry needs tests for either addon
  alone, both load orders, late registration and exactly one category.
- For settings changes, verify registration, opening, control callbacks, saved
  values and synchronization. For layout changes, inspect anchors/layers and use
  in-game evidence if available. Mock tests do not prove visual correctness.
- For pure readability refactors, the existing `tools/verify_refactor.py` can compare
  compiled Lua behavior against a captured baseline; do not use it to certify new
  behavior that intentionally changes bytecode.
- When delivering an authorized installed update, bump the TOC version, copy the
  addon files to the established installation, and package a versioned ZIP under
  `dist`. Keep development tools/caches and player saved data out of the package.
  Never delete or overwrite player saved-variable files to deploy an update.
- State what changed, what was checked and whether a user `/reload` is needed.
  Never claim in-game testing when only mocked or static checks were performed.
- Keep this guide and DEVELOPMENT.md aligned with intentional convention changes;
  distinguish future design requirements from infrastructure already implemented.


## Standalone Bestiary distribution

`RaynnaBestiary` is now a separate installable addon using `RaynnaBestiaryDB`.
Tracker 1.18.0 keeps embedded Bestiary as a compatibility fallback, but delegates
when the optional standalone package is enabled. Do not initialize both hover UIs.
The standalone settings page registers `bestiary` in the existing shared registry.
Migrate only Bestiary preferences, appearance and recent portrait IDs from older
Tracker saves, by deep copy; never replace existing standalone settings or copy
kill history into Bestiary. Keep copied theme/reference modules synchronized.
Player ZIPs are built by `tools/package_release.py`; generators stay in source
repositories, while runtime data, art and license notices stay in the ZIP.
