-- Nightfly colorscheme, applied as the active theme
return {
    {
        "bluz71/vim-nightfly-colors",
        lazy = false, -- a colorscheme should load at startup, not on demand
        init = function ()
            -- Globals must be set before the colorscheme loads
            --vim.g.nightflyUnderlineMatchParen = true
            vim.g.nightflyVirtualTextColor = true
        end,
        config = function()
            -- Re-assert nightfly on every buffer enter so nothing overrides it
            vim.api.nvim_create_autocmd("BufEnter", {
                group = vim.api.nvim_create_augroup("Nightfly", {}),
                callback = function()
                    vim.cmd.colorscheme("nightfly")
                end,
            })
        end,
    },
}
