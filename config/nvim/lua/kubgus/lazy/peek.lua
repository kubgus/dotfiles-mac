-- Live Markdown preview in the browser (rendered via Deno)
return {
    "toppair/peek.nvim",
    event = { "VeryLazy" },
    build = "deno task --quiet build:fast", -- compile the preview app with Deno
    config = function()
        require("peek").setup()
        -- peek exposes no commands by default, so create our own
        vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
        vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
    end,
}
