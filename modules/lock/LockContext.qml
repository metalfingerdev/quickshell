import QtQuick
import Quickshell
import Quickshell.Services.Pam

Scope {
	id: root
	signal unlocked()
	signal failed()

	// These properties are in the context and not individual lock surfaces
	// so all surfaces can share the same state.
	property string currentText: ""
	property bool unlockInProgress: false
	property bool showFailure: false
	// Apple's lock screen: only the picture and the time, until a key or the pointer wants in. Here, so
	// waking one screen wakes them all.
	property bool awake: false
	// unlocked, and fading to the island's black before the lock lets go (Lock.qml)
	property bool leaving: false

	onCurrentTextChanged: {
		showFailure = false;
		if (currentText !== "") wake();
	}

	// A while with nothing typed and the sign-in goes again; anything typed keeps it.
	function wake() {
		if (leaving) return;
		awake = true;
		rest.restart();
	}
	Timer {
		id: rest
		interval: 15000
		onTriggered: if (root.currentText === "" && !root.unlockInProgress) root.awake = false; else restart();
	}

	function reset() {
		currentText = "";
		showFailure = false;
		awake = false;
	}

	function tryUnlock() {
		if (currentText === "") return;

		root.unlockInProgress = true;
		pam.start();
	}

	PamContext {
		id: pam

		// A config of its own: the system one might not be what this interface expects, and break in some way.
		// It only supports passwords.
		configDirectory: "pam"
		config: "password.conf"

		onPamMessage: {
			if (this.responseRequired) {
				this.respond(root.currentText);
			}
		}

		// pam_unix won't send any important messages so all we need is the completion status.
		onCompleted: result => {
			if (result == PamResult.Success) {
				// Don't keep the password: the next lock would start with it already typed.
				root.currentText = "";
				root.unlocked();
			} else {
				root.currentText = "";
				root.showFailure = true;
			}

			root.unlockInProgress = false;
		}
	}
}