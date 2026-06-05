return {
    -- Lua utility library used as a dependency by many plugins
    {
        "nvim-lua/plenary.nvim",
        name = "plenary",
        init = function()
            -- Global helper to hot-reload a Lua module while debugging
            function R(name)
                require("plenary.reload").reload_module(name)
            end
        end,
    },
    -- Turns your code into Conway's Game of Life (`:CellularAutomaton`)
    {
        "eandrju/cellular-automaton.nvim",
        keys = {
            {
                "<leader>ca",
                function() require("cellular-automaton").start_animation("make_it_rain") end,
                desc = "Cellular Automaton: make it rain",
            },
        },
    },
}
