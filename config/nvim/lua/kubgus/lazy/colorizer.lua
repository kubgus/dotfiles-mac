-- Highlights color codes (e.g. #ff0000, rgb(...)) with their actual color
return {
    "norcalli/nvim-colorizer.lua",
    main = "colorizer", -- module name differs from the repo name
    event = "VeryLazy", -- load shortly after startup so colors attach automatically
    opts = {},
    keys = {
        { "<leader>cc", "<cmd>ColorizerToggle<CR>", desc = "Toggle Colorizer" },
    },
}
