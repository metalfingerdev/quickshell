import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.modules.services
import qs.modules.components

// Try it in a window first, without locking anything: qs -p lock-test.qml
Scope {
	id: root

	readonly property bool locked: session.locked

	// `animated`: the island covers the screen first, for a lock someone asked for. Idle and logind
	// (before sleep) lock at once: the screen mustn't wait to be hidden.
	function lock(animated) {
		if (session.locked || cover.running) return;
		lockContext.reset();
		confirmed = false;
		Session.covering = true;
		if (animated) cover.start();
		else session.locked = true;
	}
	Timer { id: cover; interval: Config.motionMs + 50; onTriggered: session.locked = true }
	// A lock the compositor never confirms would leave the island holding every input with nothing
	// to unlock: let the island go. Only the island: the lock request stands (it may still be confirmed),
	// and once a lock has been confirmed this never acts, so nothing here can unlock without a password.
	property bool confirmed: false
	Connections { target: session; function onSecureChanged() { if (session.secure) root.confirmed = true; } }
	Timer {
		interval: 3000
		running: Session.covering && !root.confirmed && !cover.running && !lockContext.leaving
		onTriggered: Session.covering = false;
	}
	SequentialAnimation {
		id: leave
		PropertyAction { target: lockContext; property: "leaving"; value: true }
		PauseAnimation { duration: Config.motionMs }
		ScriptAction { script: { session.locked = false; Session.covering = false; lockContext.leaving = false; } }
	}

	LockContext {
		id: lockContext

		// Release the lock here, while the client still holds it: if quickshell let go any other
		// way (quitting, crashing), the compositor would show its fallback lock, which can't be unlocked.
		// The picture fades to the island's black first, so the island is what's left, and it shrinks away.
		onUnlocked: leave.start();
	}

	Binding { target: Idle; property: "secure"; value: session.secure }

	// Locked, the shell went (a crash, a restart): the new one locks again as it starts, and
	// Hyprland (misc.allow_session_lock_restore) hands it the session. Only within the same Hyprland:
	// the runtime folder outlives a logout when you log back in quickly (systemd keeps the user's manager
	// a moment), and the next session must start unlocked, not ask for the password a second time after
	// the greeter. "unlocked" is written out, not an empty file, which was never written.
	readonly property string instance: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") ?? ""
	FileView {
		id: marker
		path: (Quickshell.env("XDG_RUNTIME_DIR") ?? "") !== "" ? Quickshell.env("XDG_RUNTIME_DIR") + "/island-locked" : ""
		printErrors: false
		onLoaded: if (root.instance !== "" && text().trim() === "locked " + root.instance) root.lock(false);
	}
	onLockedChanged: if (marker.path !== "") marker.setText((locked ? "locked " + instance : "unlocked") + "\n");

	WlSessionLock {
		id: session

		WlSessionLockSurface {
			LockSurface {
				anchors.fill: parent
				context: lockContext
				animate: !Idle.screensOff
			}
		}
	}

	Connections {
		target: Session
		function onLockRequested() { root.lock(true); }
	}

	Connections {
		target: Idle
		function onLockRequested() { root.lock(false); }
	}

	IpcHandler {
		target: "lock"

		function screen(): void { root.lock(true); }
		function image(path: string): string { return LockConfig.setPicture("image", path); }
		function avatar(path: string): string { return LockConfig.setPicture("avatar", path); }
		function avatarShape(shape: string): string {
			if (shape !== "circle" && shape !== "square") return `unknown shape: ${shape} (circle, square)`;
			LockConfig.avatarShape = shape;
			return "";
		}
		function name(text: string): void { LockConfig.name = text; }
		function info(text: string): void { LockConfig.info = text; }
		function status(): string {
			return JSON.stringify({
				locked: root.locked,
				image: LockConfig.image,
				avatar: LockConfig.avatar,
				avatarShape: LockConfig.avatarShape,
				name: LockConfig.shownName,
				info: LockConfig.shownInfo
			}, null, 2);
		}
	}
}
