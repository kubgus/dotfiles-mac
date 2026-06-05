-- Language Server setup: Mason installs servers, lspconfig wires them up
return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "williamboman/mason.nvim",           -- installer for LSP servers/tools
        "williamboman/mason-lspconfig.nvim", -- bridge between mason and lspconfig
        "hrsh7th/cmp-nvim-lsp",              -- advertises completion capabilities to servers
        "j-hui/fidget.nvim",                 -- LSP progress notifications
        "folke/neodev.nvim",                 -- Lua LS support for the Neovim API
    },
    config = function()
        local cmp_lsp = require("cmp_nvim_lsp")

        -- Tell servers which completion features the client (cmp) supports
        local capabilities = vim.tbl_deep_extend(
            "force",
            {},
            vim.lsp.protocol.make_client_capabilities(),
            cmp_lsp.default_capabilities()
        )

        require("fidget").setup({})
        require("neodev").setup({}) -- must run before lua_ls is configured
        require("mason").setup({})
        require("mason-lspconfig").setup({
            ensure_installed = {},
            handlers = {
                -- Default handler: set up every installed server with our capabilities
                function(server_name)
                    require("lspconfig")[server_name].setup({
                        capabilities = capabilities
                    })
                end,
            }
        })

        vim.diagnostic.config({
            -- update_in_insert = true,
            virtual_text = true,   -- show diagnostics inline
            severity_sort = true,  -- most severe first
            float = {
                focusable = false,
                style = "minimal",
                border = "rounded",
                source = "always",
                header = "",
                prefix = "",
            },
        })

        -- C# LSP needs this to find dotnet installed via homebrew
        vim.env.DOTNET_ROOT = "/opt/homebrew/opt/dotnet/libexec"

        -- Global LSP mappings
        vim.keymap.set("n", "<leader>zig", "<cmd>LspRestart<cr>", { desc = "LSP: Restart server" })
        vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, { desc = "LSP: Format buffer" })

        -- Buffer-local mappings, set whenever a language server attaches
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("UserLspAttach", {}),
            callback = function(e)
                local opts = { buffer = e.buf }
                vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)        -- go to definition
                vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)              -- hover docs
                vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts) -- search workspace symbols
                vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)     -- show diagnostic
                vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)      -- code action
                vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)       -- list references
                vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)           -- rename symbol
                vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)         -- signature help
                vim.keymap.set("n", "]d", function() vim.diagnostic.goto_next() end, opts)              -- next diagnostic
                vim.keymap.set("n", "[d", function() vim.diagnostic.goto_prev() end, opts)              -- previous diagnostic
            end
        })
    end
}
