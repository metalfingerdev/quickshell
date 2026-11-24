# IPC

Target: `island`. View names come from `Registry.qml`. Unknown names are rejected, never replaced with a
default.

| Command | Effect |
|---|---|
| `qs ipc call island open <name>` | pin a view, centred horizontally at the top gap. Opening the open view closes it |
| `qs ipc call island launch <filter>` | the launcher on a filter: `all`, `apps`, `files`, `actions`, `clipboard`, `emoji` (Super+.) |
| `qs ipc call island cycle <name> <1\|-1>` | as Alt+Tab, with Super held: the first call opens the view, the next ones move on (`-1`: back), and letting go of Super picks what was reached. `workspaces`, `wallpapers` and `clipboard` take part (`Held.qml`, which hears Super through Hyprland's global shortcut `quickshell:island-super`) |
| `qs ipc call island alert <name>` | raise the view as a toast (priority and queue rules apply) |
| `qs ipc call island peek <true\|false>` | show the rest view (Compact) until `peek false`, then hide it (auto-hide) |
| `qs ipc call island togglePeek` | `peek true` if the peek isn't on, else `peek false`: the peek key as one binding |
| `qs ipc call island screen <name>` | show the island on that screen (e.g. `DP-1`); unknown names are ignored |
| `qs ipc call island screens` | list screen names, one per line |
| `qs ipc call island close` | close the current view |
| `qs ipc call island back` | go back one step in history |
| `qs ipc call island autohide <true\|false>` | set auto-hide |
| `qs ipc call island toggleAutohide` | toggle auto-hide |
| `qs ipc call island palette <name>` | a preset palette; `palettes` lists them |
| `qs ipc call island colours <preset\|accent\|wallpaper>` | where colours come from |
| `qs ipc call island accent <#rrggbb>` | a scheme generated around that colour, which is its primary (lighter on dark, darker on light, only if it wouldn't read at 4.5:1 on the surface) |
| `qs ipc call island tint <0..100>` | how much of their own hue a generated scheme's surfaces take, in percent (0: grey) |
| `qs ipc call island surface <0..360>` | the surfaces' hue, in degrees: their own, apart from the accent's |
| `qs ipc call island mode <dark\|light>` | a generated scheme's dark or light version |
| `qs ipc call island size <80..140>` | the whole island's size, in percent |
| `qs ipc call island style <pill\|notch>` | the island's shape |
| `qs ipc call island handle <strip\|none>` | auto-hide: what stays at the top edge while hidden |
| `qs ipc call island activateLinux <true\|false>` | the "Activate Linux" text in each screen's corner |
| `qs ipc call island debug <true\|false>` | show the debug overlay and the proxy box |
| `qs ipc call island toggleDebug` | toggle debug |
| `qs ipc call island dump` | the full machine snapshot as JSON, with view names instead of numbers |
| `qs ipc call island status` | prints `phase / view / screen`, plus ` / autohide` when it is on |

`open compact` (the rest view) goes home, the same as `close`. `alert compact` is ignored.

Every view opened this way is Pinned, so it has the keyboard (Tab/arrows, Enter, Escape, each
control's shortcut key) until it closes, and each keystroke restarts its timeout. It opens in keyboard
mode: focus rings and shortcut keycaps show until the pointer moves. Names: `tabs` (the hub, also
what hovering shows), `dashboard` (everything), `launcher`, `network`, `bluetooth`, `media`, `mixer`,
`notifications` (`open` = the center, `alert` = the popups), `workspaces` (the overview), `clock`,
`battery`, `power`, `theme` (colours and the wallpaper), `settings` (the shell, idle and the lock screen),
`clipboard` (the history), `activity` (what's running), and the toasts `switcher`
(`alert switcher` shows the workspace dots) and `mic`.

`peek` is meant for a key's press and release: `peek true` on press, `peek false` on release. When
auto-hide has hidden the island, the press reveals the rest view (Compact) and the release hides it
again at once, with no linger. If the pointer is on the island when you release, it stays until the
pointer leaves (then it lingers `hideMs`, as usual). The rest view never takes the keyboard, so holding
the key doesn't steal typing. Without auto-hide the rest view is always up and the key changes nothing
visible. While a hover peek, a pinned view or a toast is up, `peek` does nothing. Hovering the island
still peeks into `Engine.peekView`; for the hub from the keyboard, use `open tabs`.

`togglePeek` is the same from a single binding on the key's press: the first press is `peek true`,
the next `peek false`. It reads the snapshot's `peeking`, so it never gets out of step: when something else
clears the peek (a hover peek, a view opening), the next press shows it again.

## Wallpaper

`Wallpaper.qml` has its own target, `wallpaper` (awww; images in `~/Pictures/Wallpapers`):

| Command | Effect |
|---|---|
| `qs ipc call wallpaper next` / `prev` / `random` | change it |
| `qs ipc call wallpaper set <path>` | show that image |
| `qs ipc call wallpaper reload` | re-read the folder |
| `qs ipc call wallpaper current` | print the path showing now |

## Lock screen

`Lock.qml` has its own target, `lock`. Everything but `screen` and `status` is remembered across
restarts and shows at once, even while locked.

| Command | Effect |
|---|---|
| `qs ipc call lock screen` | lock now |
| `qs ipc call lock image <path>` | the background picture (`""`: the wallpaper) |
| `qs ipc call lock avatar <path>` | the profile picture, GIFs play (`""`: a person glyph) |
| `qs ipc call lock avatarShape <circle\|square>` | the profile picture's frame |
| `qs ipc call lock name <text>` | the name shown (`""`: the full name in the passwd entry, or the user name) |
| `qs ipc call lock info <text>` | the line under the name (`""`: `user@host`) |
| `qs ipc call lock status` | all of the above as JSON, plus whether it is locked |

The Settings view's Lock section sets the same things. `image` and `avatar` need an absolute path: anything else prints an error and changes nothing. A picture
that can't be loaded isn't an error until it shows: the background falls back to the wallpaper, the
avatar to the glyph.

## Idle

`Idle.qml` (in `modules/lock`) does hypridle's job and has its own target, `idle`. Each step counts from
the last input, and everything set here is remembered across restarts.

| Command | Effect |
|---|---|
| `qs ipc call idle enable <true\|false>` | run the steps or not (the lock before sleep stays either way) |
| `qs ipc call idle toggle` | flip that |
| `qs ipc call idle set <step> <seconds>` | when a step runs, `0` = never: `dim` (150), `lock` (300), `off` (330), `suspend` (1800) |
| `qs ipc call idle dimTo <percent>` | how far `dim` goes (10) |
| `qs ipc call idle status` | all of the above as JSON, whether media is holding the steps back, and the steps that have run since the last input |

The Settings view's Idle section sets the same things.

`dim` and `off` undo themselves on input; `lock` waits for the password. A step doesn't run while a
Wayland idle inhibitor is active or logind has an `idle` inhibitor (Caffeine is one). One skipped this
way waits for the next time the session goes idle.

Media counts as input, for all four steps: starting it undoes `dim` and `off`, nothing counts down while
it plays, and the wait starts over when it stops. Media is any MPRIS player that's playing, or an unmuted
app stream that has been sending sound to an output for 10 s (so a chime doesn't count). An app holding a
stream open on silence looks like media too: mute it in the Mixer to let the steps run.

Separately from the steps, the screen locks before any sleep (logind's `PrepareForSleep`, held back with
a delay inhibitor until the lock is up) and on `loginctl lock-session`.

If the shell goes while locked (a crash), systemd starts it again (the `quickshell` user service) and it
locks again at once: `Lock.qml` keeps `$XDG_RUNTIME_DIR/island-locked` while locked, and Hyprland's
`misc.allow_session_lock_restore` lets the new lock take the session over. Super+Z works while locked, as
the last resort.

## Activities

`Activities.qml` has its own target, `activity`: work that takes a while, shown in Compact while it runs
(a bar, or a stretch going back and forth when it doesn't say how far) and as a toast when it ends.
Browser downloads (a growing `*.part` or `*.crdownload` in the downloads folder) are one on their own.

| Command | Effect |
|---|---|
| `qs ipc call activity start <id> <label>` | begin one, with no idea yet how far it is |
| `qs ipc call activity progress <id> <0..1>` | how far it has got (below 0: unknown again) |
| `qs ipc call activity done <id>` / `failed <id>` | end it, with a toast and a sound |
| `qs ipc call activity clear <id>` | end it quietly |
| `qs ipc call activity list` | the running ones, as JSON |

```sh
qs ipc call activity start rebuild "Rebuilding NixOS"
nixos-rebuild switch ... && qs ipc call activity done rebuild || qs ipc call activity failed rebuild
```

## Clipboard

`ClipHistory.qml` keeps every copy with cliphist in `$XDG_RUNTIME_DIR/island-clipboard` (memory only: it
goes with the session), never what a password manager marks secret. `open clipboard` (Super+Shift+V)
shows it, and the launcher's Clipboard filter searches it. Enter pastes into the window you were in: one
line of text is typed there (wtype), so it works in a terminal too; more lines and pictures are only
copied. `qs ipc call clipboard wipe` forgets everything.

## Agent

`Agent.qml` (shown by `views/Conversation.qml`, `open agent`, Super+/, or `?question` in the launcher)
talks to the local model through Ollama, streamed; with Internet on it reads SearXNG's first results
and cites them. The conversation stays in memory while the shell runs. Its target is `agent`:

| Command | Effect |
|---|---|
| `qs ipc call agent ask <text>` | ask (an answer that ends with the view closed peeks as a toast) |
| `qs ipc call agent stop` | stop the answer |
| `qs ipc call agent reset` | a new conversation |
| `qs ipc call agent last` | the latest answer, as Markdown |

In the view: Enter asks, Ctrl+C stops, Ctrl+N starts over, Escape closes and the answer goes on.

## Recording

`Toggles.qml` has its own target, `record` (also the launcher's actions: Record the screen, with the
microphone, Voice memo). Compact shows each while it runs, with its time.

| Command | Effect |
|---|---|
| `qs ipc call record screen <true\|false>` | start or stop a screen recording (wf-recorder, into Videos/Recordings); `true`: with the microphone |
| `qs ipc call record memo` | start or stop a voice memo (pw-record, into Music/Voice memos, FLAC) |
| `qs ipc call record status` | what's recording, as JSON |

## Sounds

`Sounds.qml` plays the freedesktop sound theme with `pw-play`: a notification, a critical one, the charger
in and out, a battery warning, an activity done or failed. Its target is `sounds`; both settings are remembered.

| Command | Effect |
|---|---|
| `qs ipc call sounds enable <true\|false>` / `toggle` | sounds on or off |
| `qs ipc call sounds volume <0..100>` | how loud (50) |
| `qs ipc call sounds play <name>` | play one from the theme, e.g. `message-new-instant` |

## Notifications

`Notifier.qml` has its own target, `notifications`, modelled on `dunstctl`:

| Command | Effect |
|---|---|
| `qs ipc call notifications close` | close the top popup (it stays in the center) |
| `qs ipc call notifications closeAll` | close all popups |
| `qs ipc call notifications action` | run the top popup's default action |
| `qs ipc call notifications pop` | pop the newest closed notification up again |
| `qs ipc call notifications clear` | dismiss everything |

The center keeps the last 50 (`historySize`). Notifications with the same `x-dunst-stack-tag` (or
`x-canonical-private-synchronous`) from the same app replace each other, and a picture sent as a bare
path (`-h string:image-path:/a.png`) shows.

## Compositor binding examples

Hyprland:

```ini
bind = SUPER, Space, exec, qs ipc call island open launcher
bind = SUPER, O, exec, qs ipc call island open mixer          # every app's volume
bind = SUPER, G, exec, qs ipc call island open dashboard
bind = SUPER, H, exec, qs ipc call island open tabs
bind  = SUPER, B, exec, qs ipc call island peek true          # hold Super+B to show the clock
bindr = SUPER, B, exec, qs ipc call island peek false
bind = SUPER, Z, exec, qs ipc call island togglePeek          # or: Super+Z shows it, Super+Z again hides it
bind = SUPER, Escape, exec, qs ipc call island close
bind = SUPER, N, exec, qs ipc call island open notifications
```

Note: a view opened over IPC isn't hovered, so its Registry `timeout` starts right away, and each
keystroke starts it over. The timeout is the longest pause allowed between keys, so give views you open
from keybinds one long enough to read and decide (the hub's is 8000 ms).

## Adding a command

Add a typed function to `Ipc.qml` that resolves strings with `Registry.byName` and calls one `Engine`
method. Keep string handling in this file only. A Registry entry's `aliases` are other names
`byName` accepts.
