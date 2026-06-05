-- Highlights trailing whitespace and can strip it on demand
return {
    "johnfrankmorgan/whitespace.nvim",
    main = "whitespace-nvim", -- module name differs from the repo name
    opts = {
        highlight = "SpellLocal", -- highlight group used to flag trailing whitespace
    },
}
