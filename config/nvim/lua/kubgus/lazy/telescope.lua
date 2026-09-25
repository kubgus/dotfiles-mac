-- Fuzzy finder for files, grep, help tags, and more
return {
    "nvim-telescope/telescope.nvim",
    branch = "master",
    dependencies = {
        "nvim-lua/plenary.nvim"
    },
    opts = {
        defaults = {
            -- ripgrep skips hidden and gitignored files unless told otherwise.
            -- --no-ignore-vcs drops .gitignore only, so a noisy project can
            -- still hide its build output with a .ignore file. The glob keeps
            -- .git's own contents out, which rg otherwise walks here.
            vimgrep_arguments = {
                "rg",
                "--color=never",
                "--no-heading",
                "--with-filename",
                "--line-number",
                "--column",
                "--smart-case",
                "--hidden",
                "--no-ignore-vcs",
                "--glob=!**/.git/*",
            },
            file_ignore_patterns = { "%.git/" },
        },
        pickers = {
            find_files = {
                hidden = true,
                -- telescope has no flag for --no-ignore-vcs, so the command is
                -- spelled out. It has to be a function: telescope appends
                -- --hidden to the table it is handed, and would append again on
                -- every subsequent call to a shared one.
                find_command = function()
                    return { "rg", "--files", "--color", "never", "--no-ignore-vcs", "--glob=!**/.git/*" }
                end,
            },
        },
    },
    keys = {
        -- Find files in the current directory
        {
            "<leader>pf",
            function() require("telescope.builtin").find_files() end,
            desc = "Telescope: Find files",
        },
        -- Find files tracked by git
        {
            "<C-p>",
            function() require("telescope.builtin").git_files() end,
            desc = "Telescope: Git files",
        },
        -- Grep for the word under the cursor
        {
            "<leader>pws",
            function()
                local word = vim.fn.expand("<cword>")
                require("telescope.builtin").grep_string({ search = word })
            end,
            desc = "Telescope: Grep word under cursor",
        },
        -- Grep for the WORD under the cursor (includes punctuation)
        {
            "<leader>pWs",
            function()
                local word = vim.fn.expand("<cWORD>")
                require("telescope.builtin").grep_string({ search = word })
            end,
            desc = "Telescope: Grep WORD under cursor",
        },
        -- Grep for a prompted search term
        {
            "<leader>ps",
            function()
                require("telescope.builtin").grep_string({ search = vim.fn.input("Grep > ") })
            end,
            desc = "Telescope: Grep prompt",
        },
        -- Search Neovim help tags
        {
            "<leader>vh",
            function() require("telescope.builtin").help_tags() end,
            desc = "Telescope: Help tags",
        },
    },
}
