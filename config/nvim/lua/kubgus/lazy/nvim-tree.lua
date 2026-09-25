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
        -- Keep <leader>ac working here. The tree is a listing, not a file, so
        -- the global mapping has no path to read off the buffer - it has to
        -- come from the node under the cursor. Supplying on_attach replaces
        -- nvim-tree's own mappings, hence re-applying the defaults first.
        on_attach = function(bufnr)
            local api = require("nvim-tree.api")
            api.config.mappings.default_on_attach(bufnr)

            local function copy_reference()
                local node = api.tree.get_node_under_cursor()
                require("kubgus.util.claude").copy_path(node and node.absolute_path)
            end

            -- No selection exists here, so the capitalised one has nothing
            -- extra to send and is deliberately the same key twice.
            for _, lhs in ipairs({ "<leader>ac", "<leader>aC" }) do
                vim.keymap.set("n", lhs, copy_reference, {
                    buffer = bufnr,
                    desc = "Copy Claude reference to this node",
                })
            end
        end,
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
            dotfiles = false, -- show dotfiles (toggle with H)
            git_ignored = false, -- show gitignored files (toggle with I)
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
