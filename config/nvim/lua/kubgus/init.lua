require("kubgus.set")
require("kubgus.remap")
require("kubgus.lazy_init")

-- DO.not
-- DO NOT INCLUDE THIS

-- If i want to keep doing lsp debugging
-- function restart_htmx_lsp()
--     require("lsp-debug-tools").restart({ expected = {}, name = "htmx-lsp", cmd = { "htmx-lsp", "--level", "DEBUG" }, root_dir = vim.loop.cwd(), });
-- end

-- DO NOT INCLUDE THIS
-- DO.not

local augroup = vim.api.nvim_create_augroup
local KubgusGroup = augroup('Kubgus', {})

local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup('HighlightYank', {})

-- Briefly highlight text that was just yanked
autocmd('TextYankPost', {
    group = yank_group,
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch',
            timeout = 40,
        })
    end,
})

-- Strip trailing whitespace on every save
autocmd('BufWritePre', {
    group = KubgusGroup,
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

-- netrw (the built-in file explorer) appearance
vim.g.netrw_browse_split = 0 -- open selected files in the current window
vim.g.netrw_banner = 0       -- hide the help banner at the top
vim.g.netrw_winsize = 25     -- take up 25% of the window width
