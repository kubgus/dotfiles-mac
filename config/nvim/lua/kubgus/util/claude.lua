-- The @-references Claude Code parses out of a prompt, built from the current
-- buffer so a path never has to be read off the screen and retyped.
--
-- Two details are load-bearing, both taken from how Claude Code itself writes
-- and reads a mention: a path is quoted exactly when it holds whitespace, and
-- the #L range sits inside those quotes, because the parser strips the quotes
-- before splitting the range off the end. Quoting the path alone loses the line
-- numbers silently; leaving a spaced path bare truncates it at the space, just
-- as silently, into a reference to a file that does not exist.
local M = {}

-- Claude resolves @-paths against its own cwd, so a cwd-relative path is the
-- useful spelling. Try the buffer name and its symlink target and keep
-- whichever lands inside the cwd: reaching a dotfile through ~/.config finds it
-- under a name that does not, and the repo it really lives in is where Claude
-- is running. fnamemodify hands back the absolute path unchanged when it cannot
-- relativise, so the shorter of the two is the one that worked.
local function buffer_path()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    return nil
  end

  local best = path
  for _, candidate in ipairs({ path, vim.fn.resolve(path) }) do
    local rel = vim.fn.fnamemodify(candidate, ":.")
    if #rel < #best then
      best = rel
    end
  end
  return best
end

-- Any whitespace ends an unquoted mention, not only the space Claude Code's own
-- completion tests for, so quote on all of it. A path holding both a space and
-- a quote has no spelling the parser accepts, so say so rather than hand over
-- something that will not resolve.
local function quote(path)
  if not path:find("%s") then
    return path
  end
  if path:find('"') then
    vim.notify("Claude cannot parse a path holding both a space and a quote", vim.log.levels.WARN)
  end
  return '"' .. path .. '"'
end

-- Nil when the buffer has no file behind it, having said why.
local function reference(first, last)
  local path = buffer_path()
  if not path then
    vim.notify("Buffer has no file to reference", vim.log.levels.ERROR)
    return nil
  end

  if first then
    path = path .. "#L" .. first .. (last > first and "-" .. last or "")
  end
  return "@" .. quote(path)
end

-- The lines the visual selection covers, ordered, and the selection dropped the
-- way a yank would drop it. Read from the live anchor and cursor because '< and
-- '> only settle on leaving visual mode, and a Lua callback mapping behaves
-- like <Cmd> and never leaves it.
local function take_selection()
  local first, last = vim.fn.line("v"), vim.fn.line(".")
  vim.cmd("normal! \27")
  return math.min(first, last), math.max(first, last)
end

local function put(text, shown)
  if not text then
    return
  end
  vim.fn.setreg("+", text)
  vim.notify("Copied " .. (shown or text))
end

function M.copy_reference()
  put(reference())
end

function M.copy_range()
  put(reference(take_selection()))
end

return M
