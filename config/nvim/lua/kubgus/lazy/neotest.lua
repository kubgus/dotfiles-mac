-- Test runner UI; configured here for Go via the neotest-golang adapter
return {
    "nvim-neotest/neotest",
    enabled = false,
    dependencies = {
        "nvim-neotest/nvim-nio",
        "nvim-lua/plenary.nvim",
        "antoinemadec/FixCursorHold.nvim",
        "nvim-treesitter/nvim-treesitter",
        "fredrikaverpil/neotest-golang", -- Go adapter
        "leoluz/nvim-dap-go", -- lets neotest debug Go tests via DAP
    },
    -- opts is a function because the adapter must be instantiated at load time
    opts = function()
        return {
            adapters = {
                require("neotest-golang")({
                    dap = { justMyCode = false }, -- step into dependencies while debugging
                }),
            },
        }
    end,
    keys = {
        {
            "<leader>tr",
            function()
                require("neotest").run.run({
                    suite = false,
                    testify = true,
                })
            end,
            desc = "Debug: Running Nearest Test",
        },
        {
            "<leader>tv",
            function()
                require("neotest").summary.toggle()
            end,
            desc = "Debug: Summary Toggle",
        },
        {
            "<leader>ts",
            function()
                require("neotest").run.run({
                    suite = true,
                    testify = true,
                })
            end,
            desc = "Debug: Running Test Suite",
        },
        {
            "<leader>td",
            function()
                require("neotest").run.run({
                    suite = false,
                    testify = true,
                    strategy = "dap",
                })
            end,
            desc = "Debug: Debug Nearest Test",
        },
        {
            "<leader>to",
            function()
                require("neotest").output.open()
            end,
            desc = "Debug: Open test output",
        },
        {
            "<leader>ta",
            function()
                require("neotest").run.run(vim.fn.getcwd())
            end,
            desc = "Debug: Run all tests",
        },
    },
}
