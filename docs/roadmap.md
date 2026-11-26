# Roadmap

## Open

- [ ] Battery: a charge limit, on hardware that has `charge_control_end_threshold`.
- [ ] Alerts at Peek ignore priority: hovering the hub, any alert replaces it under the pointer and the hub
      doesn't come back (Triggers.qml special-cases only the switcher). Route Peek's alert through
      `alertPinned`, so it waits while the pointer holds the island.
- [ ] An alert blocked only by hover waits for the whole view: leaving a pinned, hovered view, a parked
      critical alert should show at once (as `alertPinned` would), not after the view's countdown.
- [ ] The media view's "Playing next": MPRIS has no queue, so it lists outputs and other players instead.
- [ ] Keyboard, next steps: give each view real keyboard rules as it gets real content.
