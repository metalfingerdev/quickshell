# The island's design language

Apple's philosophy (hierarchy, restraint, grouping, progressive disclosure), drawn in the Control Centre's own look:
one tonal family, icons in the text colour on raised circles, the accent only for what is on or chosen. Android's
patterns where they are clearer (whole-scheme colour circles, accent section titles). The tokens are in
`components/Config.qml`; every number is a setting (`docs/ipc.md`, Settings).

## Principles

- Nothing on the bare glass. The island can be any material at any opacity, even none, over any wallpaper.
  Everything on it sits in a container: a tile (`Config.tile`) under anything you read or press, `Config.raised`
  for what sits on a tile (an icon's circle, a slider's track, a control inside a `Card`). Never tile on tile:
  inside a container, step up. Both follow "Cards and controls" (`Config.surfaceAlpha`).
- One tint. The accent (`primary`) marks what can be acted on or is on: a switch, a selection, a heading.
  Meaning has its own colours (`good`, `warn`, `bad`).
- Concentric corners. A radius inside another is the outer one minus the padding between them
  (`Config.radius` > `cardRadius` > `innerRadius` > `smallRadius`); capsules where a shape is low.
- Progressive disclosure. A panel shows the common case. The rest is one level down, as a registered view
  (Back and IPC work), never more rows or a section swapped inside a view.
- Honest. A control shows what it will really do: a colour circle is the scheme it makes, as drawn
  (`Config.readable`); when something set elsewhere wins (a colour set by hand), the view says so.
- Motion that settles. The island's own curve, never overshooting. Reduce motion removes it.

## Containers

| | |
|---|---|
| `Card` | A tile holding a group, with an optional accent title (and a trailing link) inside it. Not focusable. |
| `Header` | The navigation bar as a capsule: back, the title and subtitle, actions on `raised`. |
| `ListSection` | A connected list of tiles; its title and footer are pieces of the same list. |
| `ListEntry` | A row tile; `flat` inside a ListSection, `lit` (the accent) when on or connected. |
| `SectionLabel` | A heading on a capsule of its own, for a group of tiles that isn't a Card. |
| `EmptyState` | A card saying what is missing and why; `compact` inside a Card (give it `color: Config.raised`). |
| `KeyHints` | The keys on a capsule, while the keyboard is in use. |
| `Tile`, `QuickTile`, `SettingTile` | Tiles you press. |

Compact, the switcher and the toasts put their content on a capsule inset from the island's edge.

## Type

Inter, digits tabular: `Config.small` 12, `body` 14, `large` 17, `title` 22, `headline` 30, `display` 56. Symbols are
Material Symbols Rounded; filled only for an "on" state.

## Controls

| | |
|---|---|
| `Pill` | `tonal`: a raised capsule or circle. `filled`: the one main action. `text`: only inside a container. |
| `Segmented` | The Control Centre's connected group, the chosen one in the accent. |
| `Toggle` | A switch. |
| `Slider`, `ColourBar` | A thick pill slider; a bar drawn in the colours it gives. |
| `PaletteDot` | A whole scheme as a circle: accent on top, secondary and surface below. |
| `Menu`, `Sheet` | A pop-up list; a panel rising over a scrim for a confirmation. |
