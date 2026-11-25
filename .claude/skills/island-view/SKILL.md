---
name: island-view
description: Add or retrofit a panel view in the island: enum value, Registry entry, tokens, Header + EmptyState + KeyHints, lint and tests.
---

Follow `docs/adding-a-view.md` (don't copy it here). In short: file in `modules/island/views/`; enum value at the END of
`Engine.View`; a `Registry.qml` entry; reachable from Tabs, the launcher or IPC; spacing and durations from
`Config` tokens; `Header`, a scrolling body, `EmptyState` when it lists things (say why when a service is absent),
`KeyHints`, shortcuts; gate anything the agent provides on the agent's `features` list. Then run
`node modules/tests/lint-views.js` and `node modules/tests/machine.test.js`. Restart the shell after enum or
`modules/parts/` changes.
