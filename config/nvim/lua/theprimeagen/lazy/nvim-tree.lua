return {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
        "kyazdani42/nvim-web-devicons",
    },
    config = function ()
        require("nvim-tree").setup({
            hijack_cursor = true,
            sort = {
                sorter = "case_sensitive",
            },
            view = {
                width = 48,
                float = {
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
                enable = true,
            },
            filters = {
                dotfiles = true,
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
        })
    end
}
