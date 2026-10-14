-- Treesitter: syntax-aware highlighting, indentation, and the sticky context
--
-- nvim-treesitter's `main` branch only installs parsers and queries; nothing
-- turns on by itself. The FileType autocmd below starts highlighting and
-- indentation per buffer, and installs a missing parser on first use.

-- One install per language, shared by every buffer waiting on it
local installing = {}

local function attach(buf, lang)
    -- Nvim's own ftplugins have already started lua, markdown, help and query,
    -- so the size guard only holds back what this file would start
    if not vim.treesitter.highlighter.active[buf] then
        local max_filesize = 100 * 1024 -- 100 KB
        local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
        if ok and stats and stats.size > max_filesize then
            vim.notify(
                "File larger than 100KB treesitter disabled for performance",
                vim.log.levels.WARN,
                {title = "Treesitter"}
            )
            return
        end
        vim.treesitter.start(buf, lang)
    end

    -- Run Vim's regex highlighting alongside treesitter for markdown
    if lang == "markdown" then
        vim.bo[buf].syntax = "ON"
    end

    -- Without indent queries the indentexpr has nothing to go on, and Vim's own
    -- indent script does better
    if #vim.treesitter.query.get_files(lang, "indents") > 0 then
        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
end

return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main", -- the rewrite; `master` is frozen and set up differently
        build = ":TSUpdate", -- recompile parsers on update
        lazy = false, -- `main` does not support lazy-loading
        config = function()
            local treesitter = require("nvim-treesitter")
            -- Includes the languages other files embed, which the autocmd below
            -- cannot see are missing
            treesitter.install({
                "vimdoc", "bash", "lua", "luadoc", "javascript", "jsdoc",
                "typescript", "html", "css", "markdown", "markdown_inline",
                "regex", "go", "python",
            })

            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("KubgusTreesitter", {}),
                callback = function(args)
                    local buf, ft = args.buf, args.match
                    local lang = vim.treesitter.language.get_lang(ft)
                    -- Treesitter stays off for html
                    if not lang or lang == "html" then
                        return
                    end

                    if vim.treesitter.language.add(lang) then
                        attach(buf, lang)
                        return
                    end

                    -- No parser yet: install it if nvim-treesitter has one, then attach
                    if not require("nvim-treesitter.parsers")[lang] then
                        return
                    end
                    installing[lang] = installing[lang] or treesitter.install(lang)
                    installing[lang]:await(vim.schedule_wrap(function()
                        if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == ft
                            and vim.treesitter.language.add(lang) then
                            attach(buf, lang)
                        end
                    end))
                end,
            })
        end,
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
