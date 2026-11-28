local home = os.getenv("HOME")

rex.action{
  name = "open_dir",
  title = "Open Directory Session",
  args = { dir = "string" },
  run = function(_, args)
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

rex.bind("cmd+o>w", "open_dir", { dir = home .. "/Documents/Workspaces" })
rex.bind("cmd+o>c", "open_dir", { dir = home .. "/Documents/Code" })
