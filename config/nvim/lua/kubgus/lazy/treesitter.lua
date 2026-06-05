-- Treesitter: syntax-aware highlighting, indentation, and the sticky context
return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate", -- recompile parsers on update
        main = "nvim-treesitter.config", -- setup lives in this submodule
        lazy = false,
        opts = {
            ensure_installed = {
                "vimdoc", "bash",
            },
            -- Install parsers synchronously (only applied to `ensure_installed`)
            sync_install = false,
            -- Automatically install missing parsers when entering buffer
            auto_install = true,
            indent = {
                enable = true
            },
            highlight = {
                enable = true,
                -- Turn highlighting off for html and for very large files
                disable = function(lang, buf)
                    if lang == "html" then
                        return true
                    end

                    local max_filesize = 100 * 1024 -- 100 KB
                    local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
                    if ok and stats and stats.size > max_filesize then
                        vim.notify(
                            "File larger than 100KB treesitter disabled for performance",
                            vim.log.levels.WARN,
                            {title = "Treesitter"}
                        )
                        return true
                    end
                end,

                -- Run Vim's regex highlighting alongside treesitter for markdown
                additional_vim_regex_highlighting = { "markdown" },
            },
        }
    },
    -- Pins the enclosing scope (function/class) to the top of the window
    {
        "nvim-treesitter/nvim-treesitter-context",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        main = "treesitter-context",
        opts = {
            enable = true,
            multiwindow = false, -- only show context in the current window
            max_lines = 2,       -- cap the context to 2 lines
            min_window_height = 0,
            line_numbers = true,
            multiline_threshold = 1,
            trim_scope = "outer", -- drop outer scopes first when over max_lines
            mode = "cursor",
            separator = nil,
            zindex = 20,
            on_attach = nil,
        }
    }
}
