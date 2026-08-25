-- Confirm the permission prompt Claude is currently showing.
--
-- Compiled by _setup.sh into ~/Applications/Claude Approve.app so the
-- keystroke is sent by an app with its own identity. Running this through
-- /usr/bin/osascript instead would mean granting Accessibility to osascript,
-- which lets any script on the machine synthesise keystrokes.

tell application "Claude" to activate

-- Give the window a moment to come forward before typing into it.
delay 0.2

tell application "System Events"
	tell process "Claude"
		set frontmost to true
		keystroke return using command down
	end tell
end tell
