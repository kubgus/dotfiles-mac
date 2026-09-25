-- Fuzzy finder for files, grep, help tags, and more
return {
    "nvim-telescope/telescope.nvim",
    branch = "master",
    dependencies = {
        "nvim-lua/plenary.nvim"
    },
    opts = {
        defaults = {
            -- ripgrep skips hidden and gitignored files unless told otherwise;
            -- the last glob keeps .git's own contents out of the results.
            vimgrep_arguments = {
                "rg",
                "--color=never",
                "--no-heading",
                "--with-filename",
                "--line-number",
                "--column",
                "--smart-case",
                "--hidden",
                "--no-ignore",
                "--glob=!**/.git/*",
            },
            file_ignore_patterns = { "%.git/" },
        },
        pickers = {
            find_files = {
                hidden = true,
                no_ignore = true,
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
