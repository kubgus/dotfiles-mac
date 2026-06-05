-- Git wrapper: run git commands and view status from inside Neovim
return {
    "tpope/vim-fugitive",
    keys = {
        { "<leader>gs", vim.cmd.Git, desc = "Fugitive: Git status" },
    },
    config = function()
        local Kubgus_Fugitive = vim.api.nvim_create_augroup("Kubgus_Fugitive", {})

        local autocmd = vim.api.nvim_create_autocmd

        -- Add push/pull mappings only inside the fugitive status buffer
        autocmd("BufWinEnter", {
            group = Kubgus_Fugitive,
            pattern = "*",
            callback = function()
                if vim.bo.ft ~= "fugitive" then
                    return
                end

                local bufnr = vim.api.nvim_get_current_buf()
                local opts = {buffer = bufnr, remap = false}
                vim.keymap.set("n", "<leader>p", function()
                    vim.cmd.Git("push")
                end, opts)

                vim.keymap.set("n", "<leader>P", function()
                    vim.cmd.Git("pull")
                end, opts)

                -- NOTE: It allows me to easily set the branch i am pushing and any tracking
                -- needed if i did not set the branch up correctly
                vim.keymap.set("n", "<leader>gg", ":Git push -u origin ", opts);
            end,
        })
    end
}
