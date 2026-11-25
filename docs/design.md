# The island's design language

After Apple's: Liquid Glass, the Human Interface Guidelines, the Dynamic Island, Control Centre, System Settings. The
tokens are in `components/Config.qml`; every number is a setting (`docs/ipc.md`, Settings).

## Principles

- **Deference.** Content first, chrome recedes: no boxed headers, no outlines. Things are grouped by spacing and platters.
- **Glass, and fills that survive it.** The island is glass at any opacity, even none. What sits on it is the text
  colour at low alpha (`fill1`..`fill4`: 0.20, 0.16, 0.12, 0.08), never an opaque surface colour, so a platter reads
  on any island. Text is `label1`..`label4`: full, 0.6, 0.3, 0.18.
- **One tint.** The accent (`primary`) marks what can be acted on or is on: a switch, a selection, a link.
  Meaning has its own colours (`good`, `warn`, `bad`).
- **Concentric corners.** A radius inside another is the outer one minus the padding between them
  (`Config.radius` > `cardRadius` > `innerRadius` > `smallRadius`).
- **Progressive disclosure.** A panel shows the common case. The rest is one level down: a chevron, an info button,
  a menu. Never more rows.
- **Motion that settles.** The island's own curve, never overshooting (no springs). Reduce motion removes it.

## Type

Inter, digits tabular: large title 28 bold, title 22 semibold, headline 15 semibold, body 15, callout 14, footnote 13,
caption 12. Symbols are Material Symbols Rounded; filled only for an "on" state.

## Components

| | |
|---|---|
| `Header` | A navigation bar: a glass back button, the title, glass action buttons. No card. |
| `ListSection` | A titled platter (`fill3`) of rows, hairlines between them inset past the icon, an optional footer. |
| `ListEntry` | A row: a coloured square icon, title, subtitle, a value, a chevron. `flat` inside a section; alone it is its own platter. |
| `Menu` | A pop-up list: checkmarks, destructive items in red, separators. Replaces rows of chips. |
| `Sheet` | A panel that rises inside the view over a scrim, for a confirmation or a short form. |
| `Toggle` | A switch: the accent when on, a fill when off, a round white knob. |
| `Segmented` | A fill track with one sliding thumb. |
| `Pill` | `tonal`: a glass capsule or circle. `filled`: the one main action. `text`: plain accent text. |

## Island states

Compact is leading, clock, trailing. Expanded is one live activity's expanded layout. Toasts are HUD capsules.
A tray app appears in Compact only when it needs attention, and as a strip of glass circles in Expanded.
Each panel is a title, grouped sections and chevron drill-downs (see the plan: one template for all).
