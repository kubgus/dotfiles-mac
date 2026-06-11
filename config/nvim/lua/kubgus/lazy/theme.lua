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
            -- Apply the colorscheme once at startup; it persists across buffer switches
            vim.cmd.colorscheme("nightfly")
        end,
    },
}
