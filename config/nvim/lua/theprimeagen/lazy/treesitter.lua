return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        main = "nvim-treesitter.config",
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
                disable = function(lang, buf)
                    if lang == "html" then
                        print("disabled")
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

                additional_vim_regex_highlighting = { "markdown" },
            },
        }
    },
    {
        "nvim-treesitter/nvim-treesitter-context",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        config = function()
            require('treesitter-context').setup{
                enable = true,
                multiwindow = false,
                max_lines = 2,
                min_window_height = 0,
                line_numbers = true,
                multiline_threshold = 1,
                trim_scope = 'outer',
                mode = 'cursor',
                separator = nil,
                zindex = 20,
                on_attach = nil,
            }
        end
    }
}
