# Roadmap

## Open

- [x] Battery: a charge limit, on hardware that has `charge_control_end_threshold`.
- [x] Alerts at Peek ignore priority: hovering the hub, any alert replaces it under the pointer and the hub
      doesn't come back (Triggers.qml special-cases only the switcher). Route Peek's alert through
      `alertPinned`, so it waits while the pointer holds the island.
- [x] An alert blocked only by hover waits for the whole view: leaving a pinned, hovered view, a parked
      critical alert should show at once (as `alertPinned` would), not after the view's countdown.
- [x] The media view's "Playing next": MPRIS has no queue, so it lists outputs and other players instead (the Output and Players lists under the controls).
- [x] Keyboard, next steps: give each view real keyboard rules as it gets real content (the Settings pages' switches and segments have letters and digits now; the read-only views, Activity and System, and the toasts have nothing to act on, so the default is their rule).
