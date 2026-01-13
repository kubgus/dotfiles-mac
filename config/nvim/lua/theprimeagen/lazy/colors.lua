function ColorMyPencils(color)
	color = color or "nightfly"
	vim.cmd.colorscheme(color)

	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    vim.api.nvim_set_hl(0, "ZenBg", { bg = "#000000", blend = 80 })
end

return {
    {
        "bluz71/vim-nightfly-colors",
        lazy = false,
        config = function ()
            ColorMyPencils()

            --vim.g.nightflyUnderlineMatchParen = true
            vim.g.nightflyVirtualTextColor = true
        end
    },
}
