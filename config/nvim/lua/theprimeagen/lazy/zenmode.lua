return {
  "folke/zen-mode.nvim",
  config = function()
    require("zen-mode").setup {
      window = {
        options = {},
      },

      plugins = {
        gitsigns = { enabled = true },
      },

      on_open = function()
        vim.diagnostic.enable(false)

        -- Note: Hard coded for nightfly colorscheme
        vim.api.nvim_set_hl(0, "ZenBg", { bg = "#051321", blend = 90 })
      end,

      on_close = function()
        vim.diagnostic.enable()
      end,
    }

    vim.keymap.set("n", "<leader>zz", function()
      require("zen-mode").toggle({
        window = { width = 160, options = {} },
      })
      vim.wo.wrap = false
      vim.wo.number = true
      vim.wo.rnu = true
    end)

    vim.keymap.set("n", "<leader>zZ", function()
      require("zen-mode").toggle({
        window = { width = 80, options = {} },
      })
      vim.wo.wrap = true
      vim.wo.number = false
      vim.wo.rnu = false
      vim.opt.colorcolumn = "0"
    end)
  end
}
