-- ThePrimeagen's AI assistant: fills in functions and edits selections,
-- driven by AGENT.md / SKILL.md rule files in your project
return {
    "ThePrimeagen/99",
    main = "99",
    event = "VeryLazy", -- load after startup so its cmp source registers
    opts = {
        --logger = { },

        --- A new feature that is centered around tags
        completion = {
            --- Defaults to .cursor/rules
            -- I am going to disable these until i understand the
            -- problem better.  Inside of cursor rules there is also
            -- application rules, which means i need to apply these
            -- differently
            -- cursor_rules = "<custom path to cursor rules>"

            --- A list of folders where you have your own SKILL.md
            --- Expected format:
            --- /path/to/dir/<skill_name>/SKILL.md
            ---
            --- Example:
            --- Input Path:
            --- "scratch/custom_rules/"
            ---
            --- Output Rules:
            --- {path = "scratch/custom_rules/vim/SKILL.md", name = "vim"},
            --- ... the other rules in that dir ...
            ---
            custom_rules = {
            },

            --- What autocomplete do you use.  We currently only
            --- support cmp right now
            source = "cmp",
        },

        --- WARNING: if you change cwd then this is likely broken
        --- ill likely fix this in a later change
        ---
        --- md_files is a list of files to look for and auto add based on the location
        --- of the originating request.  That means if you are at /foo/bar/baz.lua
        --- the system will automagically look for:
        --- /foo/bar/AGENT.md
        --- /foo/AGENT.md
        --- assuming that /foo is project root (based on cwd)
        md_files = {
            "AGENT.md",
        },
    },
    keys = {
        -- Create your own short cuts for the different types of actions
        {
            "<leader>9f",
            function() require("99").fill_in_function() end,
            desc = "99: Fill in function",
        },
        -- take extra note that i have visual selection only in v mode
        -- technically whatever your last visual selection is, will be used
        -- so i have this set to visual mode so i dont screw up and use an
        -- old visual selection
        --
        -- likely ill add a mode check and assert on required visual mode
        -- so just prepare for it now
        {
            "<leader>9v",
            function() require("99").visual() end,
            mode = "v",
            desc = "99: Act on visual selection",
        },
        --- if you have a request you dont want to make any changes, just cancel it
        {
            "<leader>9s",
            function() require("99").stop_all_requests() end,
            mode = "v",
            desc = "99: Stop all requests",
        },
        --- Example: Using rules + actions for custom behaviors
        --- Create a rule file like ~/.rules/debug.md that defines custom behavior.
        --- For instance, a "debug" rule could automatically add printf statements
        --- throughout a function to help debug its execution flow.
        {
            "<leader>9fd",
            function() require("99").fill_in_function() end,
            desc = "99: Fill in function (debug rule)",
        },
    },
}
