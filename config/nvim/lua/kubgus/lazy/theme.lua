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
            -- Nightfly links parameter semantic tokens to `@parameter`, a capture
            -- since renamed to `@variable.parameter` and left undefined, so every
            -- parameter the LSP marks loses its highlight. Restore Nvim's default
            -- link; nightfly's README asks for overrides through this autocmd.
            vim.api.nvim_create_autocmd("ColorScheme", {
                group = vim.api.nvim_create_augroup("KubgusNightfly", {}),
                pattern = "nightfly",
                callback = function()
                    vim.api.nvim_set_hl(0, "@lsp.type.parameter", { link = "@variable.parameter" })
                end,
            })
            -- Apply the colorscheme once at startup; it persists across buffer switches
            vim.cmd.colorscheme("nightfly")
        end,
    },
}
