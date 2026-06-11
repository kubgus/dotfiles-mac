-- GitHub Copilot AI suggestions (Lua implementation, no Node host)
return {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    branch = "master",
    event = "InsertEnter", -- only needed once you start typing
    opts = {
        suggestion = {
            enabled = true,
            auto_trigger = true, -- show ghost-text suggestions as you type
            hide_during_completion = false,
            debounce = 25,
            keymap = {
                accept = false, -- disabled defaults; only the bindings below are active
                accept_word = false,
                accept_line = "<S-Tab>", -- accept the whole suggestion
                next = false,
                prev = false,
                dismiss = "<C-c>",
            },
        },
        filetypes = {
            ["*"] = true, -- enable for all filetypes
            -- markdown = false, -- disable for markdown files
        },
    },
}
