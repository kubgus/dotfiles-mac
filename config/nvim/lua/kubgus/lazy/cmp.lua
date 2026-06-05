-- Autocompletion engine and its sources (LSP, buffer, path, cmdline)
return {
    "hrsh7th/nvim-cmp",
    dependencies = {
        "hrsh7th/cmp-nvim-lsp", -- completions from language servers
        "hrsh7th/cmp-buffer",   -- words from the current buffer
        "hrsh7th/cmp-path",     -- filesystem paths
        "hrsh7th/cmp-cmdline",  -- the `:` command line
    },
    config = function()
        local cmp = require("cmp")
        local cmp_select = { behavior = cmp.SelectBehavior.Select }

        cmp.setup({
            snippet = {},
            mapping = cmp.mapping.preset.insert({
                ["<C-k>"] = cmp.mapping.select_prev_item(cmp_select), -- previous item
                ["<C-j>"] = cmp.mapping.select_next_item(cmp_select), -- next item
                ["<C-l>"] = cmp.mapping.confirm({ select = true }),   -- accept
                ["<C-Space>"] = cmp.mapping.complete(),               -- trigger completion
            }),
            -- Sources are ranked by group: LSP/copilot first, buffer as fallback
            sources = cmp.config.sources({
                { name = "copilot", group_index = 2 },
                { name = "nvim_lsp" },
            }, {
                { name = "buffer" },
            })
        })
    end
}
