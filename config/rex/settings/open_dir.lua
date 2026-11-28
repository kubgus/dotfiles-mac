local home = os.getenv("HOME")

-- Returns "<prefix>-<n>" with the lowest n that no session uses.
local function next_label(sessions, prefix)
  local taken = {}
  for _, session in ipairs(sessions) do
    taken[session.label] = true
  end
  local n = 1
  while taken[prefix .. "-" .. n] do
    n = n + 1
  end
  return prefix .. "-" .. n
end

rex.action{
  name = "open_dir",
  title = "Open Directory Session",
  args = { dir = "string", prefix = "string" },
  run = function(_, args)
    local list, err = rex.call("session.list")
    if err ~= nil then error(err, 0) end

    local created, create_err = rex.call("session.create", {
      label = next_label(list.sessions or {}, args.prefix),
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

rex.bind("cmd+o>w", "open_dir", { dir = home .. "/Documents/Workspaces", prefix = "workspaces" })
rex.bind("cmd+o>c", "open_dir", { dir = home .. "/Documents/Code", prefix = "code" })
