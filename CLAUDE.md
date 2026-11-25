# The island (Quickshell)

Read `docs/architecture.md` and `docs/adding-a-view.md` before changing a view; `docs/ipc.md` for the IPC.

- Colours: only `Config` roles (`Config.surface`, `text`, ...). Never hard-code one.
- Spacing and motion: `Config.spaceXs..spaceXl` (4 px grid), `Config.durationFast/Medium`, `Config.motionMs`
  for the morph. No overshoot easings.
- Panels: `Header`, a scrolling body, `EmptyState` for lists, `KeyHints`. Keyboard works everywhere.
- Nothing on the bare glass: every label and control sits in a container (`Card`, a tile, `SectionLabel`'s capsule);
  inside one, controls step up to `Config.raised` (docs/design.md).
- Checks: `node modules/tests/machine.test.js` and `node modules/tests/lint-views.js`.
- A new `Engine.View` value goes at the END of the enum; restart the shell after changing the enum or
  anything in `modules/parts/` (a hot reload keeps the old types).
- Skill `island-view` is the checklist for a new view.
