return {
    "johnfrankmorgan/whitespace.nvim",
    config = function ()
        require('whitespace-nvim').setup({
            highlight = 'SpellLocal',
        })
    end
}
