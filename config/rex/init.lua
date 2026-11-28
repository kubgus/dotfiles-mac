-- Rex config. Docs: https://www.superlogical.com/rex/docs/customize/config
-- Fonts and ligatures are app settings, not config - see Settings > Terminal.

-- Splits on Option, alongside the Cmd+D defaults.
-- This takes Option+D (kill-word) away from the shell.
rex.bind("alt+d", "pane.split.right")
rex.bind("alt+shift+d", "pane.split.down")
