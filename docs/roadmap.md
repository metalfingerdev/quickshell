# Roadmap

## Open

- [ ] The views brought to one standard (2026-11-25), after Noctalia (its QML version, `legacy-v4`): what
      each lacks next to Noctalia's panel for the same thing, kept small, a control on the panel only
      for what is used often:
  - [x] Power: restart into Windows or into the firmware setup, for one boot (logind's
        `BootLoaderEntries` and `CanRebootToFirmwareSetup`; shown only where they exist)
  - [x] Network: the connection's details (address, gateway, DNS, hardware address) behind a row
        that opens, a value copied with a click
  - [x] Calendar: the days that have events marked, and the chosen day's events under the month
  - [x] Notifications: grouped Today, Yesterday, Earlier
  - [x] Mixer: pick the output and the input device, when there is more than one
  - [x] Wallpapers: a search field
  - [x] Favourites: which pinned apps are running

- [ ] Battery: charge limit and power profiles, for hardware that has them (see old-shell-notes.md).
- [ ] Power profiles: the dashboard's segmented row shows once power-profiles-daemon runs
      (`services.power-profiles-daemon.enable`); it is hidden until then.
- [ ] The media view's "Playing next": MPRIS has no queue, so it lists outputs and other players instead.
- [ ] Keyboard, next steps: give each view real keyboard rules as it gets real content.

## Done

- [x] Settings as code (2026-11-26): every setting in `settings.json` (migrated from island.ini), live-reloaded,
      sparse, with `prefs reset`; Advanced shows each of them (a number takes any value, a colour any colour),
      the colour roles and the scheme's own numbers, the island's geometry and shadow, hyprglass's 38 settings
      and Hyprland's own options, each shared or for dark or light only; opacity runs 0 to 100% with no floor;
      `Keep colours readable` off adjusts nothing. Not yet: Registry timeouts, notification rules, the other
      exposed items of the plan's 2g.

- [x] Colours and settings (2026-11-26): Theme is every colour choice in one place (light or dark,
      standard or high contrast, the colours from the wallpaper, a custom colour or a preset, then that
      source's bars, each drawn in the colours it gives, and the surfaces: matching the colour, a hue of
      their own, or neutral); Colours is only the custom colour's full picker. Compact and Expanded are
      on the island's glass again. Settings after Noctalia's: Look (the island's opacity down to
      see-through, its shadow, the blur level, the windows' opacity, liquid glass, roundness, outlines,
      reduce motion) and Alerts (how long popups stay, sounds, the toasts), the clock's 24 hours and the
      week's first day, and how far the lock screen's picture softens.

- [x] Two looks and a lock (2026-11-25): the panels after Noctalia (a header card with the panel's glyph
      in the primary colour, outlined cards and tiles, list rows as tiles; System as cards with a graph
      of the last minute); liquid glass by hyprglass (a flake input built for the Hyprland it names, switched and
      its look picked in Settings); the lock screen after Apple's (the picture and the time until a key or
      the pointer, then the sign-in over a softened picture), and the island growing over the screen as
      it locks and shrinking back as it unlocks.

- [x] More from Nihil-Shell (2026-11-25): the system tray, a view of its own and not in Tabs, which
      stays uncluttered (the dashboard's More, the launcher, `open tray`): each app, its menu drawn in the
      island (`QsMenuOpener`, with submenus) and Open for its own action; an app can be hidden, and
      Settings shows them again; accessible names and roles on every control; tests for the pure
      `.js` (Open-Meteo, the agenda, generations, the board's cards) and `tst_keyboard.qml` in CI; a light along
      the island's edge after the Glyph Interface (a notification runs once round, a critical one or a low
      battery twice in the warning colour, the charger rises up both sides, an activity's progress stays lit);
      NixOS (generations, what each changed, the flake's inputs and what keeps a dotfile edit from the system:
      uncommitted, unpushed, not in the lock), read-only; a task board (to do, doing, done, in its own JSON
      file); favourite apps (Ctrl+P in the launcher pins one; the Dock view, and pinned first in the launcher).
- [x] The agent (2026-11-24), after Nihil-Shell's Nilo but light: a view of its own (Conversation) with
      the local model through Ollama, streamed, Markdown, Internet (SearXNG, cited) and Think switches,
      the model loaded while you type, and a peek toast when an answer ends with the view closed. `?` in
      the launcher asks it; Crush stays the Coding agent action.
- [x] The launcher (2026-11-24): Clipboard and Emoji filters (and `:` before the words, from any filter);
      emoji, symbols and kaomoji in a grid, typed into the window you were in and copied; the clipboard
      pastes (one line typed, so a terminal works too); actions to record the screen (with the microphone
      too) and voice memos, each shown in Compact while it runs; Super+. opens Emoji.
- [x] Colours, the surfaces (2026-11-24): a hue of their own and a tint, apart from the accent (the
      Surface row; IPC `surface`). From the wallpaper, Android-style: an option per distinct colourful
      colour, the surfaces in the picture's own cast and tinted as much as it is coloured, plus Matched
      and Neutral; each circle shows its whole scheme (accent, secondary, tinted surface), and while the
      colours come from the wallpaper each thumbnail shows the scheme it would make.
- [x] Colours, the accent (2026-11-23): a picked colour that wouldn't read on the island (under 4.5:1) is
      drawn just lighter or darker, and the view says so; the map is the usual saturation/brightness
      square over a hue strip (HSV, every part of it usable), an eyedropper (hyprpicker, as Nihil's) picks
      the accent from anywhere on the screen, and the last eight accents are a click away (Recent).
- [x] Lessons from Nihil-Shell (2026-11-23), easiest first: a crash while locked no longer strands the
      session (Hyprland's `allow_session_lock_restore`, the shell locks again on start, Super+Z works
      locked); the center keeps 50; caffeine survives a shell restart; a battery already low at login
      warns, once per band; pictures sent as a path show; CI runs `machine.test.js`; a popup keeps 2 s
      after the pointer leaves; apps start in their own scope (`uwsm app`); a mic toast; stack tags
      replace; sounds; the shell is a systemd service that restarts; Activities (progress over IPC,
      downloads); the island's curve comes from Hyprland; a clipboard history; Super+Tab, Super+P and
      Super+Shift+V held as Alt+Tab.

- [x] The audit (2026-10-30, see [audit.md](audit.md)): a queued alert can't show twice, a pinned toast keeps
      what it interrupted, the hover intent survives mode changes, and every key a control acts on restarts
      the countdown (ViewLoader owns Enter, Space and stepping). Duplicated code gone; comments say why.
- [x] Overview: going to an empty workspace no longer bounces back, and a special workspace can be left
      (click it again, or click a workspace). Both came from acting before the island let go of the
      keyboard: `Engine.closeThen` acts after. Its arrows, digits and wheel now move a selection (Enter goes
      there, Escape stays put) instead of switching while the island holds the keyboard, which bounced
      back the same way on close. The open special workspace is outlined.
- [x] A workspace switched to from an open view (Tabs) stays when the island closes (`Desktops.keyboardHeld`).
      Enter applies a wallpaper in Wallpapers and Theme, and Theme's strip no longer crawls after the selection.
- [x] No springs: the morph and the workspace buttons ease on `Motion` (`Config.curve` / `motionMs`), which
      never overshoots, so a notch revealed from auto-hide no longer dips a pixel below the top edge and
      settles back. Hyprland's windows use the same curve (`Glide`), and its spring curves are gone.
- [x] Glass moved to Hyprland: every window at 80 % over a frosted blur, and a `glass` layer rule that
      layers named `glass:*` opt into. The island is `glass:island` and takes the windows' opacity;
      the island's own glass toggle and opacity slider are gone.
- [x] Settings is its own view (size, shape, auto-hide and its handle); Theme is colours and a
      wallpaper grid. Each links to the other.
- [x] Tabs: a workspace button coming or going moves the bar and the island's edges as one motion
      (the buttons move on the island's own motion, toward the width the island is already heading for).
- [x] The glance (Expanded) is gone: hovering the clock peeks into the hub (Tabs). Each segment of
      Tabs' status group opens its own view (network, Bluetooth, notifications, battery). No media toast
      when a track starts. A Mixer view: the output, the microphone and each app's stream, a slider
      each; the media view shows every output's volume, and the wheel over one sets it.
- [x] Keyboard everywhere: spatial arrows, a `shortcut` per control (keycaps while the keyboard is in use),
      Backspace back, bold focus rings that no longer vanish under a still pointer, `KeyHints` footers.
- [x] Theme: colours from a preset, an accent or the wallpaper (generated Material-You-style, with
      tonal/vibrant/muted/mono and dark/light), and a Size for the whole island.
- [x] Colours: a full colour map (hue and lightness) with a saturation slider and a hex field instead of
      twelve swatches; `tint` and, for the wallpaper, saturation and lightness sliders instead of the
      tonal/vibrant/muted/mono styles. A wallpaper colour stays on the wallpaper, for that image.
- [x] Expanded is back, small: the pointer on the island's surface grows the clock into it, after the
      Dynamic Island. No keyboard. Tabs opens with a click; the top edge only reveals the clock.
- [x] Tabs rearranged after Apple's toolbars, with Expanded's clock at the far left and its status group
      at the far right: capsules of one size of button instead of dividers, and a back arrow only
      when there is somewhere to go back to.
- [x] The status group (Tabs, Expanded) has a pill of its own: a segment opens its view, the pill and
      its "tune" button the dashboard.
- [x] Shadows after macOS: floating windows only (hypr/modules/look.lua, rules.lua), deeper in focus; the
      island casts its own (Hyprland has none for layers), deeper once it opens.
- [x] Wide views with big controls; Network and Bluetooth laid out like the dashboard; the dashboard
      without its notification list (a bell with a count opens the center).

- [x] Material 3 redesign (Android's quick settings): Config roles, QuickTile, Slider, Segmented, Chip,
      SearchBar; every view restyled. Focus rings only while the keyboard is in use.
- [x] Compact and Expanded are indicators (clock, media, recording, what's on); Expanded's status group
      opens the dashboard and its search bar the launcher. Tabs is the hub (a click on either opens it).
- [x] Dashboard: Wi-Fi/Bluetooth tiles, quick settings (Do not disturb, night light, caffeine, airplane,
      microphone, dark theme, screen record, screenshot), volume/brightness sliders, power profiles,
      media, notifications.
- [x] Launcher: All / Apps / Files / Actions, usage ranking, file search, island actions, a calculator.
- [x] Workspace switch toast with GNOME-style dots (`Switcher`, `Triggers.switcherToasts`).

- [x] Real Network (Quickshell.Networking) and Bluetooth (Quickshell.Bluetooth) views, plus Media,
      Battery, Clock, Power, Theme (+ wallpaper) and a Workspaces overview with live previews.
- [x] `Config` singleton: palettes, the island's look, fonts; Bar, components and views use it.
- [x] Launcher: ranking (prefix > word > substring > generic name/keywords > in-order letters), icons.
- [x] The best of the old shell's `Bar` and `dynamicGlacier`, merged into the island: pill/notch,
      anti-corners, frosted glass (now Hyprland's), capsule corners, strip handle, outside-click close, click to pin,
      privacy dots, follow the focused monitor, the dashboard peek, media in Compact (see
      [old-shell-notes.md](old-shell-notes.md)).

- [x] `Ipc` and `Triggers` are instantiated once in `shell.qml`.
- [x] Services module: `Audio`, `Backlight`, `Notifier`.
- [x] Views for every Registry entry: Volume, Brightness, and Notifications (`Notification.qml`: popups as a
      Toast, the center when Pinned).
- [x] Alert priority travels with the event (`Engine.alert(v, priority)`), so a critical notification is the
      same view alerted more urgently. The three notification views (`notify`, `critical`, center) became one.
- [x] `modules/components/qmldir` declares `module qs.modules.components`.
- [x] Timeouts long enough for IPC (5000/8000). `open compact` goes home instead of pinning forever.
- [x] Countdown no longer restarts on unrelated events: `rearm()` keeps the running timer object.
- [x] `Engine`'s initial snapshot uses `restView`.
- [x] Velocity-preserving morph (`SpringAnimation` per property). Later replaced by `Motion` (no springs).
- [x] Multi-monitor: one `Bar` per screen, a shared `Engine`, `Engine.activeScreen`, IPC `screen`/`screens`.
- [x] Keyboard: pinned views and the peek view get the keyboard, with default keys from `ViewLoader`
      (Tab/arrows, Enter/Space, Escape). No Registry flag. Hover holds the countdown; each keystroke
      restarts it (`Key` event, `Engine.key()`).
- [x] Cleanup after the hover/keyboard model settled: removed the `center` IPC and the y anchor (the island
      always hangs from the top), `engage`/`release` (nothing held the countdown but hover), `canGoBack`,
      and `Bar.retarget()` (identical to `snap()`).
- [x] Peek key: IPC `peek true`/`peek false` (bind to a key's press/release) is hover from the keyboard.
      `peeking` holds the peek like `hovered`; `enter()` clears it, so it never outlives the peek.
- [x] The peek key shows the rest view (Compact) while held and hides it on release, instead of peeking
      into Expanded. Hover still peeks.
- [x] `debug` lives on `Engine.debug`, toggled over IPC.
- [x] Compact shows a real clock (`SystemClock`). The launcher searches desktop entries.
- [x] `Debug.qml` reads `Engine.snapshot` (it used the removed `IslandState`). Toggled over IPC
      (`debug`, `toggleDebug`). `dump` prints the snapshot as JSON.
- [x] Node test harness for `Machine.js` (`node modules/tests/machine.test.js`).
