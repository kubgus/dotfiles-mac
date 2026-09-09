-- Markdown onto the system clipboard as rich text, so pasting into a document
-- or a mail client keeps the formatting instead of arriving as source. Needs
-- pandoc for the conversion; only the clipboard call is platform-specific.
local M = {}

local function copy(markdown)
  local html = vim.fn.system("pandoc -f markdown -t html", markdown)
  if vim.v.shell_error ~= 0 then
    vim.notify("pandoc failed: " .. html, vim.log.levels.ERROR)
    return
  end

  local sysname = vim.loop.os_uname().sysname

  if sysname == "Darwin" then
    local hex = vim.fn.system("hexdump -ve '1/1 \"%.2x\"'", html)
    local script = string.format(
      'set the clipboard to {text:" ", «class HTML»:«data HTML%s»}',
      hex
    )
    vim.fn.system({ "osascript", "-" }, script)
  elseif sysname == "Linux" then
    if vim.env.WAYLAND_DISPLAY then
      vim.fn.system({ "wl-copy", "--type", "text/html" }, html)
    else
      vim.fn.system({ "xclip", "-selection", "clipboard", "-t", "text/html" }, html)
    end
  else
    vim.notify("Unsupported platform: " .. sysname, vim.log.levels.ERROR)
    return
  end

  if vim.v.shell_error ~= 0 then
    vim.notify("Clipboard copy failed", vim.log.levels.ERROR)
  else
    vim.notify("Copied as rich text")
  end
end

-- Read out of the buffer rather than off disk, so an unsaved edit still counts.
function M.copy_buffer()
  copy(table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"))
end

function M.copy_selection()
  vim.cmd('normal! "ry')
  copy(vim.fn.getreg("r"))
end

return M
