-- Distraction-free writing mode: centers the buffer and hides UI clutter
return {
    "folke/zen-mode.nvim",
    opts = {
        window = {
            options = {},
        },

        plugins = {
            gitsigns = { enabled = true }, -- keep git signs visible in zen mode
        },

        on_open = function()
            vim.diagnostic.enable(false) -- silence diagnostics while focused

            -- Note: Hard coded for nightfly colorscheme
            vim.api.nvim_set_hl(0, "ZenBg", { bg = "#051321", blend = 90 })
        end,

        on_close = function()
            vim.diagnostic.enable() -- restore diagnostics on exit
        end,
    },
    keys = {
        -- Wide window, with line numbers (good for code)
        {
            "<leader>zz",
            function()
                require("zen-mode").toggle({
                    window = { width = 160, options = {} },
                })
                vim.wo.wrap = false
                vim.wo.number = true
                vim.wo.rnu = true
            end,
            desc = "Zen Mode (code)",
        },
        -- Narrow window, no numbers or wrapping (good for prose)
        {
            "<leader>zZ",
            function()
                require("zen-mode").toggle({
                    window = { width = 80, options = {} },
                })
                vim.wo.wrap = true
                vim.wo.number = false
                vim.wo.rnu = false
                vim.opt.colorcolumn = "0"
            end,
            desc = "Zen Mode (prose)",
        },
    },
}
