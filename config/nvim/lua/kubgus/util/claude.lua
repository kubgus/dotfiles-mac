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
local function shortest_spelling(path)
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

-- Nil when there is nothing to point at, having said so.
local function reference(path, first, last)
  if path == nil or path == "" then
    vim.notify("Nothing here to reference", vim.log.levels.ERROR)
    return nil
  end

  local ref = shortest_spelling(path)
  if first then
    ref = ref .. "#L" .. first .. (last > first and "-" .. last or "")
  end
  return "@" .. quote(ref)
end

-- The file behind the current buffer, or nil when there is not one. Everything
-- that is not a file carries a buftype, and several of those are named after
-- the window rather than a path - a nvim-tree listing is NvimTree_1 - so
-- without this they would reference a file that does not exist.
local function current_file()
  if vim.bo.buftype ~= "" then
    return nil
  end
  return vim.api.nvim_buf_get_name(0)
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
  put(reference(current_file()))
end

function M.copy_range()
  put(reference(current_file(), take_selection()))
end

-- For somewhere that knows a path the buffer does not, such as the node under
-- the cursor in a file tree. Directories are as referenceable as files: Claude
-- stats the path and lists it rather than reading it.
function M.copy_path(path)
  put(reference(path))
end

-- The reference and the lines themselves, for a question that is easier to ask
-- with the code in front of it than with a pointer to it. The fence is grown
-- past the longest backtick run in the selection, so copying a markdown file
-- cannot close the block early.
function M.copy_range_with_lines()
  local first, last = take_selection()
  local ref = reference(current_file(), first, last)
  if not ref then
    return
  end

  local body = table.concat(vim.api.nvim_buf_get_lines(0, first - 1, last, false), "\n")
  local longest = 0
  for run in body:gmatch("`+") do
    longest = math.max(longest, #run)
  end
  local fence = string.rep("`", math.max(3, longest + 1))

  put(
    table.concat({ ref, "", fence .. vim.bo.filetype, body, fence }, "\n"),
    ref .. " with " .. (last - first + 1) .. " lines"
  )
end

return M
