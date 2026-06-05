-- Leader key (set before plugins load so their <leader> mappings resolve)
vim.g.mapleader = " "

-- Move the visual selection up/down a line and re-indent it
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")       -- join line below, keeping cursor in place
vim.keymap.set("n", "<C-d>", "<C-d>zz") -- half page down, recenter cursor
vim.keymap.set("n", "<C-u>", "<C-u>zz") -- half page up, recenter cursor
vim.keymap.set("n", "n", "nzzzv")       -- next search match, centered and unfolded
vim.keymap.set("n", "N", "Nzzzv")       -- previous search match, centered and unfolded
vim.keymap.set("n", "=ap", "ma=ap'a")   -- reindent paragraph, restoring cursor position

--vim.keymap.set("n", "<leader>vwm", function()
--    require("vim-with-me").StartVimWithMe()
--end)
--vim.keymap.set("n", "<leader>svwm", function()
--    require("vim-with-me").StopVimWithMe()
--end)

-- greatest remap ever: paste over a selection without losing the yanked text
vim.keymap.set("x", "<leader>p", [["_dP]])

-- next greatest remap ever : asbjornHaland -- yank to the system clipboard
vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- Delete into the black hole register (don't overwrite the yank register)
vim.keymap.set({"n", "v"}, "<leader>d", "\"_d")

-- This is going to get me cancelled
--vim.keymap.set("i", "<C-c>", "<Esc>")

--vim.keymap.set("n", "Q", "<nop>")
--vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

--vim.keymap.set("n", "<C-n>", "<cmd>cnext<CR>zz")
--vim.keymap.set("n", "<C-p>", "<cmd>cprev<CR>zz")
--vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
--vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

--vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
--vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })
--
--vim.keymap.set(
--    "n",
--    "<leader>ee",
--    "oif err != nil {<CR>}<Esc>Oreturn err<Esc>"
--)
--
--vim.keymap.set(
--    "n",
--    "<leader>ea",
--    "oassert.NoError(err, \"\")<Esc>F\";a"
--)
--
--vim.keymap.set(
--    "n",
--    "<leader>ef",
--    "oif err != nil {<CR>}<Esc>Olog.Fatalf(\"error: %s\\n\", err.Error())<Esc>jj"
--)
--
--vim.keymap.set(
--    "n",
--    "<leader>el",
--    "oif err != nil {<CR>}<Esc>O.logger.Error(\"error\", \"error\", err)<Esc>F.;i"
--)

-- Re-source the current file
vim.keymap.set("n", "<leader><leader>", function()
    vim.cmd("so")
end)

-- Professional vim keymaps -- drop in eslint-disable comments
vim.keymap.set("n", "<leader>fuckyou", "O/* eslint-disable-next-line */<Esc>j")
vim.keymap.set("n", "<leader>fuckthis", "ggO/* eslint-disable */<Esc>o<Esc><C-o>")
