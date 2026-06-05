-- File explorer sidebar
return {
    "nvim-tree/nvim-tree.lua",
    lazy = false,
    dependencies = {
        "kyazdani42/nvim-web-devicons", -- file type icons
    },
    keys = {
        { "<leader>pv", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file explorer" },
    },
    opts = {
        hijack_cursor = true, -- keep the cursor on the filename, not the start of the line
        sort = {
            sorter = "case_sensitive",
        },
        view = {
            width = 48,
            float = { -- open the tree as a floating window
                enable = true,
                open_win_config = {
                    row = 0,
                    col = 999,
                    width = 48,
                    height = 38,
                },
            },
        },
        update_focused_file = {
            enable = true, -- highlight the current file in the tree
        },
        filters = {
            dotfiles = true, -- hide dotfiles by default (toggle with H)
        },
        renderer = {
            group_empty = false,
            icons = {
                git_placement = "after",
                glyphs = {
                    folder = {
                        arrow_closed = " ",
                        arrow_open = " ",
                    },
                },
            },
        },
    },
}
