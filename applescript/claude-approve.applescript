-- Confirm the permission prompt Claude is currently showing.
--
-- Compiled by _setup.sh into ~/Applications/Claude Approve.app so the
-- keystroke is sent by an app with its own identity. Running this through
-- /usr/bin/osascript instead would mean granting Accessibility to osascript,
-- which lets any script on the machine synthesise keystrokes.

on reportNoAccess()
	-- A background app is not offered the usual "wants to control this
	-- computer" prompt, so the entry has to be added by hand. Open the pane
	-- rather than describing where it lives.
	display alert "Claude Approve cannot type" message "Add \"Claude Approve\" to Privacy & Security > Accessibility and switch it on.

If it is already listed, select it, remove it with the minus button, and add it again from ~/Applications - a rebuilt app reads as a different one and the old entry no longer matches it." as critical
	do shell script "open 'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility'"
end reportNoAccess

tell application "Claude" to activate

-- Give the window a moment to come forward before typing into it.
delay 0.2

try
	tell application "System Events"
		tell process "Claude"
			set frontmost to true
			keystroke return using command down
		end tell
	end tell
on error errMsg number errNum
	-- -1002 is a refused keystroke, -1743 a refused Apple event. Without this
	-- an applet answers a failure with a dialog offering to open its own
	-- source in Script Editor, which is no use when the cause is a missing
	-- permission.
	if errNum is -1002 or errNum is -1743 then
		reportNoAccess()
	else
		display alert "Claude Approve failed" message errMsg as critical
	end if
end try
