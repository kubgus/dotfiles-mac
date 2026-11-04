-- GitHub Copilot AI suggestions (Lua implementation, no Node host)

-- copilot.lua draws the suggestion as one extmark in this namespace
local SUGGESTION_NS = vim.api.nvim_create_namespace("copilot.suggestion")

-- Inline virtual text pushes the cursor past itself, so an overflowing suggestion scrolls the window right
local function fits_inline(width)
    local view = vim.fn.winsaveview()
    local text_width = vim.fn.winwidth(0) - vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].textoff
    local last_col = view.leftcol + text_width - 1 - vim.o.sidescrolloff
    return vim.fn.virtcol(".") - 1 + width <= last_col
end

-- 'scrolloff' counts virtual lines, so near EOF any line beyond the free rows scrolls the window down
local function count_fitting_virt_lines(row)
    local height = vim.fn.winheight(0)
    local scrolloff = math.min(vim.o.scrolloff, math.floor((height - 1) / 2))
    local cursor_line_end = vim.fn.winline() - 1 + vim.api.nvim_win_text_height(0, {
        start_row = row,
        end_row = row,
        start_vcol = vim.fn.virtcol(".") - 1,
    }).all
    local free_rows = height - cursor_line_end
    if row == vim.api.nvim_buf_line_count(0) - 1 then
        -- 'scrolloff' ignores the last line's virtual lines, so the ones below the free rows stay off-screen
        return free_rows
    end
    if free_rows >= scrolloff then
        return math.huge
    end
    local rows_after = vim.api.nvim_win_text_height(0, { start_row = row + 1 }).all
    return math.max(0, free_rows - rows_after)
end

-- Redraws the suggestion so that it never changes the window's topline or leftcol
local function fit_preview()
    local mark = vim.api.nvim_buf_get_extmarks(0, SUGGESTION_NS, 0, -1, { details = true })[1]
    if not mark then
        return
    end
    local id, row, col, details = unpack(mark)
    vim.api.nvim_buf_del_extmark(0, SUGGESTION_NS, id)

    local virt_text = details.virt_text
    local virt_lines = details.virt_lines
    if virt_lines then
        local fitting = count_fitting_virt_lines(row)
        if #virt_lines > fitting then
            local hidden = #virt_lines - fitting
            virt_lines = fitting > 0 and vim.list_slice(virt_lines, 1, fitting) or nil
            table.insert(virt_text, { " " })
            table.insert(virt_text, { ("+%d lines"):format(hidden), "CopilotAnnotation" })
        end
    end

    local width = 0
    for _, chunk in ipairs(virt_text) do
        width = width + vim.fn.strdisplaywidth(chunk[1])
    end
    local is_inline = details.virt_text_pos == "inline" and (vim.wo.wrap or fits_inline(width))

    vim.api.nvim_buf_set_extmark(0, SUGGESTION_NS, row, col, {
        id = id,
        virt_text = virt_text,
        virt_text_pos = is_inline and "inline" or "overlay",
        virt_lines = virt_lines,
        hl_mode = details.hl_mode,
    })
end

return {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    branch = "master",
    event = "InsertEnter", -- only needed once you start typing
    opts = {
        suggestion = {
            enabled = true,
            auto_trigger = true, -- show ghost-text suggestions as you type
            hide_during_completion = false,
            debounce = 25,
            keymap = {
                accept = false, -- disabled defaults; only the bindings below are active
                accept_word = false,
                accept_line = "<S-Tab>", -- accept the whole suggestion
                next = false,
                prev = false,
                dismiss = "<C-c>",
            },
        },
        filetypes = {
            ["*"] = true, -- enable for all filetypes
            -- markdown = false, -- disable for markdown files
        },
    },
    config = function(_, opts)
        require("copilot").setup(opts)
        -- Every redraw of the suggestion goes through this table field, so the wrapper sees all of them
        local suggestion = require("copilot.suggestion")
        local update_preview = suggestion.update_preview
        suggestion.update_preview = function(...)
            update_preview(...)
            fit_preview()
        end
    end,
}
