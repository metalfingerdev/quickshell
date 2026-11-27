# island

A Dynamic-Island-style top bar for [Quickshell](https://quickshell.outfoxxed.me/). The island is one
rounded surface that morphs between views (a clock, a hub, detail panels, toasts), driven by a small
pure state machine. It is drawn in Material 3, like Android's quick settings: tonal surfaces, pill tiles
with an icon circle, thick pill sliders, segmented buttons and sentence-case type.

Moving through it:

```
Compact (rest) ──pointer on the island──► Expanded (only while it's there)
   clock + live                              time, what's on, what's playing
   indicators
      │                                         │
      └───────────────── click ─────────────────┴──► Tabs (the hub) ──► any view
                                                       clock, workspaces, one tab per view,
                                                       status (each segment opens its view, the group the dashboard)

Backspace, the mouse's back button, ← ──► the view that was open before
Escape, a click outside, a timer      ──► home (the clock)
```

Status: prototype. These work: the morphing surface (pill or notch, on Hyprland's frosted glass),
hover/peek, pinning, back-history, auto-hide, IPC and multi-monitor. So does every view: the hub (tabs),
dashboard, launcher, network, bluetooth, media, volume mixer, notifications, workspace overview, clock,
battery, power, theme and wallpaper, settings, and the shortcuts cheat-sheet (Super + Shift + /, kept in step with hypr's `binds.lua` by hand). Toasts (volume, brightness, notifications, battery,
workspace switch) and privacy dots work too. What is still open is in [docs/roadmap.md](docs/roadmap.md).

## Running

```sh
qs -p /path/to/this/folder
```

`shell.qml` is the entry point. It creates one `Ipc`, one `Triggers` and one `Bar` per screen. It also
creates the lock screen (`Lock`, locked with `qs ipc call lock screen`) and the `ActivateLinux` text in
each corner.

## Tests

```sh
for t in modules/tests/*.test.js; do node "$t"; done                        # the machine and the pure .js
node modules/tests/lint-views.js                                           # tokens and the panel standard
QT_QPA_PLATFORM=offscreen qmltestrunner -input modules/tests/tst_keyboard.qml   # default keyboard
qs -p lock-test.qml                                                        # the lock screen, in a window
```

`machine.test.js` replays event sequences against `Machine.js`, with the view list and the Registry read
from `Engine.qml` and `Registry.qml` themselves. The other `*.test.js` run the pure `.js` the services read
their answers with (Open-Meteo, the agenda, generations, the task board's cards), through `harness.js`.
`tst_keyboard.qml` sends real key events to `ViewLoader` and the controls. GitHub Actions runs all of
them on every push (`.github/workflows/tests.yml`), the keyboard test with Qt from nixpkgs.

In the session the shell runs as the `quickshell` systemd user service (nixos-dotfiles,
`modules/features/quickshell`), which restarts it if it crashes. Super+R also restarts it.

## Layout

Every file opens with a comment saying what it is and why. This is the map:

```
shell.qml           entry point: services, one Bar per screen, the lock
lock-test.qml       the lock surface in a normal window, nothing locked (at the root, or `qs.*` won't resolve)
assets/             the pictures it comes with: wallpaper (and its still for battery saver), the lock
                    screen's background (and still), the avatar
modules/
  island/           the island itself
    Machine.js      pure statechart: reduce(state, event, cfg) -> state (docs/state-machine.md)
    Engine.qml      singleton: holds the snapshot, owns the one Timer, the public API
    Registry.qml    every view: name, priority, timeout, queue flag, file
    Bar.qml         per screen: the windows, the morphing surface, hover, the tray beside it
    ViewLoader.qml  the view slot and its default keyboard
    Ipc.qml         `qs ipc call island ...` (docs/ipc.md)
    Triggers.qml    system events -> toasts and sounds
    views/          one file per view (adding one: docs/adding-a-view.md)
  overview/         the workspace overview's tiles and live previews
  lock/             the session lock, its settings, and idle (dim, lock, screens off, suspend)
  parts/            pieces several views share, which use services
  components/       pure UI: Config (palette, shape, type), controls, Store
  services/         system state, no island logic (audio, network, players, wallpaper, agent...)
  activatelinux/    a click-through text in each screen's corner
  tests/            node tests (Machine.js, layouts, parsers) and qmltestrunner's keyboard tests
```

## From the environment

The island works on its own. One value comes from nixos-dotfiles, on the `quickshell` service:

| Variable | Read by | What it is |
|---|---|---|
| `NIXOS_FLAKE` | `Generations.qml` | where the flake is checked out (else `~/nixos-dotfiles`) |

`ISLAND_DRY=1` keeps `Glass.qml` from sending anything to Hyprland, for test instances.

What it offers depends on what's installed. The agent tiles, actions and process need `nilo-agent` and
`crush` (nixos-dotfiles' `agent` bundle). Hibernate needs logind to answer yes to `CanHibernate`, which
means a swap to hibernate into.

## How it fits together

```
input (hover, clicks, IPC, system events)
        │
        ▼
Engine.open/close/back/alert/hover/key/...  ──►  Machine.reduce(snapshot, event, cfg)
        │                                              │
        │                           new snapshot ◄─────┘   (phase, view, anchor, timer, history, queue)
        ▼
Bar: Loader shows Registry.get(view).url
     proxy snaps to the view's size/position  ──►  surface animates onto it
```

- [docs/architecture.md](docs/architecture.md): the layers, and how the proxy/surface morph works
- [docs/state-machine.md](docs/state-machine.md): phases, events, timers, history and the alert queue
- [docs/adding-a-view.md](docs/adding-a-view.md): how to add a view or toast
- [docs/ipc.md](docs/ipc.md): command-line control
- [docs/roadmap.md](docs/roadmap.md): known issues and next steps

## Configuration

| Where | Property | Default | Meaning |
|---|---|---|---|
| `Engine.qml` | `debug` | `false` | debug overlay + proxy box; IPC `debug` / `toggleDebug` |
| | `peekView` | `Expanded` | view shown when the pointer is on the resting island's surface (not at the top edge); `-1` turns peeking off. The peek key shows the rest view instead |
| | `hoverMs` | 140 | hover delay before peeking |
| | `graceMs` | 140 | how long a peek stays after the pointer leaves |
| | `hideMs` | 700 | auto-hide: how long the island lingers before hiding |
| | initial `autoHide` | `true` | second argument to `Machine.initial(...)` |
| `Config.qml` | `source` | `accent` | where colours come from: `preset`, `accent` or `wallpaper`; IPC `colours` |
| | `name` | `teal` | preset palette (teal blue graphite midnight nord rose forest paper); IPC `palette` |
| | `accent` / `surfaceHue` / `tint` / `darkMode` | / 0.005 / `0` / `true` | a generated scheme: its colour (made just lighter or darker if it wouldn't read on the surface, `Config.readable`), the surfaces' own hue (not the accent's) and how much of it they take (0..1), dark or light; IPC `accent` `surface` `tint` `mode` |
| | `wallpaperSaturation` / `wallpaperTone` | `0.8` / `0.72` | how the wallpaper colour's hue becomes a primary |
| | `scale` | 1.0 | the whole island's size (0.8 .. 1.4); IPC `size` |
| | `style` | `pill` | `pill` floats below the edge; `notch` is flush with it, with anti-corners; IPC `style` |
| | `handle` | `strip` | auto-hide: a thin bar stays at the top edge while hidden (`none`: nothing); IPC `handle` |
| | `radius` | 28 | the island's largest corner (Material's extra large); lower shapes are capsules |
| | `curve` / `motionMs` | `[0.22, 1, 0.36, 1]` / 350 | the morph's ease-out (`Motion`), never overshooting; read from Hyprland's `windows` animation (`Glide` in hypr/modules/look.lua, speed 3.5 = 350 ms; `Desktops.windowCurve`, re-read on `hyprctl reload`), so change it there. These are the fallback until Hyprland answers. The workspace buttons in Tabs move with it, so they stay with the island's edge |
| `hypr/modules/look.lua` | `active_opacity` / `inactive_opacity`, `blur`, layer rule `glass` | 0.8 | the glass: every window at 80 % over a frosted blur; layers named `glass` or `glass:*` (the island is `glass:island`) get the blur, and the island takes `active_opacity` too (`Desktops.windowOpacity`, re-read on `hyprctl reload`) |
| `Bar.qml` | `gap` / `edgePad` | 8 (notch: 0) / 8 | distance from the top edge / from the screen sides |
| | `space` | `gap` + 36 | height reserved at the top when auto-hide is off |
| | `hotZone` | 4 | height of the top-edge strip that reveals the island |
| | `debug` | `Engine.debug` | draws the proxy as a translucent green box |
| | `pinView` | `false` | content stays put while the surface slides over it |
| `Registry.qml` | per view | | `priority`, `critical`, `timeout` (ms, 0 = none), `queue` |
| `Engine.qml` | `screenName` | `""` | screen that shows the island (`""` or an unplugged screen = the first) |
| `Notifier.qml` | `lowMs` / `normalMs` / `criticalMs`, `maxPopups` | 10000 / 10000 / 0, 3 | dunst-style popup timing |
| | `graceMs` / `historySize` | 2000 / 50 | a popup's least time left once the pointer leaves it / how many the center keeps |
| `Sounds.qml` | `enabled` / `volume` | `true` / 0.5 | the freedesktop theme's cues, via pw-play; remembered; IPC `sounds` |
| `ClipHistory.qml` | `size` | 50 | copies the clipboard history keeps, on disk in `$XDG_STATE_HOME/island/clipboard` so it survives a reboot (pictures are cached as files there, not inlined) |
| `Triggers.qml` | `followFocus` | `true` | the idle island moves to the monitor Hyprland focuses |
| | `switcherToasts` | `true` | switching workspace shows GNOME-style dots (`views/Switcher.qml`) |
| `Notifier.qml` | `dnd` | `false` | Do not disturb: only critical notifications pop up; remembered |
| `Toggles.qml` | `warmth` | 4500 | night light colour temperature (K), via hyprsunset; remembered |
| `Energy.qml` | `lowAt` / `criticalAt` | 15 / 5 | battery warnings (a toast; critical interrupts) |
| `Wallpaper.qml` | `folders`, `transition`, `duration` | `[~/Pictures/Wallpapers]`, fade, 0.8 | the folders the picker shows (Settings → Wallpaper), listed with the island's own `assets/wallpapers`; awww. A GIF with a same-named still beside it shows the still on battery saver |
| `modules/overview/OverviewConfig.qml` | `rows` / `columns`, `previewMode`, ... | 2 / 5, live | the workspace overview |
