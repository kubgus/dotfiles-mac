-- Debug Adapter Protocol: debugging support, its UI, and adapter installation.
-- Module-level autocmd group, shared by the dap-ui spec below.
vim.api.nvim_create_augroup("DapGroup", { clear = true })

-- Jump the cursor to the window already showing the given buffer
local function navigate(args)
    local buffer = args.buf

    local wid = nil
    local win_ids = vim.api.nvim_list_wins() -- Get all window IDs
    for _, win_id in ipairs(win_ids) do
        local win_bufnr = vim.api.nvim_win_get_buf(win_id)
        if win_bufnr == buffer then
            wid = win_id
        end
    end

    if wid == nil then
        return
    end

    vim.schedule(function()
        if vim.api.nvim_win_is_valid(wid) then
            vim.api.nvim_set_current_win(wid)
        end
    end)
end

local function create_nav_options(name)
    return {
        group = "DapGroup",
        pattern = string.format("*%s*", name),
        callback = navigate
    }
end

return {
    -- The debugger core: stepping, breakpoints, and run control
    {
        "mfussenegger/nvim-dap",
        enabled = false,
        lazy = false,
        keys = {
            { "<F8>", function() require("dap").continue() end, desc = "Debug: Continue" },
            { "<F10>", function() require("dap").step_over() end, desc = "Debug: Step Over" },
            { "<F11>", function() require("dap").step_into() end, desc = "Debug: Step Into" },
            { "<F12>", function() require("dap").step_out() end, desc = "Debug: Step Out" },
            { "<leader>b", function() require("dap").toggle_breakpoint() end, desc = "Debug: Toggle Breakpoint" },
            {
                "<leader>B",
                function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end,
                desc = "Debug: Set Conditional Breakpoint",
            },
        },
        config = function()
            require("dap").set_log_level("DEBUG")
        end
    },
    -- The debugger UI: scopes, watches, repl, stacks, breakpoints panels.
    -- Each panel gets its own single-element layout so it can be toggled solo.
    {
        "rcarriga/nvim-dap-ui",
        enabled = false,
        dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
        config = function()
            local dap = require("dap")
            local dapui = require("dapui")
            local function layout(name)
                return {
                    elements = {
                        { id = name },
                    },
                    enter = true,
                    size = 40,
                    position = "right",
                }
            end
            local name_to_layout = {
                repl = { layout = layout("repl"), index = 0 },
                stacks = { layout = layout("stacks"), index = 0 },
                scopes = { layout = layout("scopes"), index = 0 },
                console = { layout = layout("console"), index = 0 },
                watches = { layout = layout("watches"), index = 0 },
                breakpoints = { layout = layout("breakpoints"), index = 0 },
            }
            local layouts = {}

            for name, config in pairs(name_to_layout) do
                table.insert(layouts, config.layout)
                name_to_layout[name].index = #layouts
            end

            local function toggle_debug_ui(name)
                dapui.close()
                local layout_config = name_to_layout[name]

                if layout_config == nil then
                    error(string.format("bad name: %s", name))
                end

                local uis = vim.api.nvim_list_uis()[1]
                if uis ~= nil then
                    layout_config.size = uis.width
                end

                pcall(dapui.toggle, layout_config.index)
            end

            vim.keymap.set("n", "<leader>dr", function() toggle_debug_ui("repl") end, { desc = "Debug: toggle repl ui" })
            vim.keymap.set("n", "<leader>ds", function() toggle_debug_ui("stacks") end,
                { desc = "Debug: toggle stacks ui" })
            vim.keymap.set("n", "<leader>dw", function() toggle_debug_ui("watches") end,
                { desc = "Debug: toggle watches ui" })
            vim.keymap.set("n", "<leader>db", function() toggle_debug_ui("breakpoints") end,
                { desc = "Debug: toggle breakpoints ui" })
            vim.keymap.set("n", "<leader>dS", function() toggle_debug_ui("scopes") end,
                { desc = "Debug: toggle scopes ui" })
            vim.keymap.set("n", "<leader>dc", function() toggle_debug_ui("console") end,
                { desc = "Debug: toggle console ui" })

            vim.api.nvim_create_autocmd("BufEnter", {
                group = "DapGroup",
                pattern = "*dap-repl*",
                callback = function()
                    vim.wo.wrap = true
                end,
            })

            vim.api.nvim_create_autocmd("BufWinEnter", create_nav_options("dap-repl"))
            vim.api.nvim_create_autocmd("BufWinEnter", create_nav_options("DAP Watches"))

            dapui.setup({
                layouts = layouts,
                enter = true,
            })

            -- Close the UI automatically when the debug session ends
            dap.listeners.before.event_terminated.dapui_config = function()
                dapui.close()
            end
            dap.listeners.before.event_exited.dapui_config = function()
                dapui.close()
            end

            dap.listeners.after.event_output.dapui_config = function(_, body)
                if body.category == "console" then
                    dapui.eval(body.output) -- Sends stdout/stderr to Console
                end
            end
        end,
    },
    -- Installs and wires up debug adapters via Mason
    {
        "jay-babu/mason-nvim-dap.nvim",
        enabled = false,
        dependencies = {
            "williamboman/mason.nvim",
            "mfussenegger/nvim-dap",
            "neovim/nvim-lspconfig",
        },
        opts = {
            ensure_installed = {
                "delve", -- Go debugger
            },
            automatic_installation = true,
            handlers = {
                -- Default handler: set up each adapter with Mason's defaults
                function(config)
                    require("mason-nvim-dap").default_setup(config)
                end,
                -- Go: prepend launch configs that prompt for program args
                delve = function(config)
                    table.insert(config.configurations, 1, {
                        args = function() return vim.split(vim.fn.input("args> "), " ") end,
                        type = "delve",
                        name = "file",
                        request = "launch",
                        program = "${file}",
                        outputMode = "remote",
                    })
                    table.insert(config.configurations, 1, {
                        args = function() return vim.split(vim.fn.input("args> "), " ") end,
                        type = "delve",
                        name = "file args",
                        request = "launch",
                        program = "${file}",
                        outputMode = "remote",
                    })
                    require("mason-nvim-dap").default_setup(config)
                end,
            },
        },
    },
}
