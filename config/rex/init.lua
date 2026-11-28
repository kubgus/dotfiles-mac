-- Rex config. Docs: https://www.superlogical.com/rex/docs/customize/config

local home = os.getenv("HOME")

-- Shows the session named `label`, or creates it with a shell in `dir`.
-- Reusing it keeps a repeated key press from piling up duplicate sessions.
rex.action{
  name = "open_dir",
  title = "Open Directory Session",
  args = { dir = "string", label = "string" },
  run = function(_, args)
    local list, err = rex.call("session.list")
    if err ~= nil then error(err, 0) end
    for _, session in ipairs(list.sessions or {}) do
      if session.label == args.label then
        rex.client.queue("session.select", { session_id = session.session_id })
        return
      end
    end

    local created, create_err = rex.call("session.create", {
      label = args.label,
      initial_windows = { {
        layout = rex.layout.block{
          flavor = "com.superlogical.terminal.shell",
          options = { cwd = args.dir },
        },
      } },
    })
    if create_err ~= nil then error(create_err, 0) end
    rex.client.queue("session.select", { session_id = created.session_id })
  end,
}

-- Cmd+O, then a letter. Cmd+O has no default, so every letter after it is free.
rex.bind("cmd+o>w", "open_dir", { dir = home .. "/Documents/Workspaces", label = "workspaces" })
rex.bind("cmd+o>c", "open_dir", { dir = home .. "/Documents/Code", label = "code" })
