return {
    "norcalli/nvim-colorizer.lua",
    config = function ()
        require("colorizer").setup({
        })

        vim.keymap.set("n", "<leader>cc", "<cmd>ColorizerToggle<CR>")
    end
}
