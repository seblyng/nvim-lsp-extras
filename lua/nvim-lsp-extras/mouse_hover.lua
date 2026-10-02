local M = {}
local config = require("nvim-lsp-extras.config")

local function make_params(bufnr, pos, line)
    ---@param client vim.lsp.Client
    return function(client)
        local row, col = pos[1] - 1, pos[2]

        return {
            textDocument = { uri = vim.uri_from_bufnr(bufnr) },
            position = {
                line = row,
                character = vim.str_utfindex(line, client.offset_encoding, col),
            },
        }
    end
end

-- Disable hover when these filetypes is open in the window
local disable_filetypes = {
    "TelescopePrompt",
    "snacks_picker_input",
}

---@param client vim.lsp.Client
M.setup = function(client)
    if not client:supports_method("textDocument/hover") then
        return
    end
    local hover_timer = nil
    vim.o.mousemoveevent = true

    vim.keymap.set({ "", "i" }, "<MouseMove>", function()
        if hover_timer then
            hover_timer:close()
        end

        hover_timer = vim.defer_fn(function()
            hover_timer = nil
            for _, win in pairs(vim.fn.getwininfo()) do
                if vim.tbl_contains(disable_filetypes, vim.bo[win.bufnr].ft) then
                    return
                end
            end
            local pos = vim.fn.getmousepos()
            if pos.winid == 0 or pos.line == 0 or pos.column == 0 then
                return
            end
            if pos.wincol <= vim.fn.getwininfo(pos.winid)[1].textoff then
                return
            end
            local bufnr = vim.api.nvim_win_get_buf(pos.winid)

            -- getmousepos() reports one-based byte columns, including a column
            -- beyond the text when the mouse is in the blank part of a line.
            local line = vim.api.nvim_buf_get_lines(bufnr, pos.line - 1, pos.line, false)[1]
            if not line or pos.column > #line then
                return
            end

            local supports = vim.iter(vim.lsp.get_clients({ bufnr = bufnr })):any(function(c)
                return c:supports_method("textDocument/hover")
            end)
            if not supports then
                return
            end

            local orig_req_all = vim.lsp.buf_request_all
            -- HACK: Temporarily override `vim.lsp.buf_request_all` to support
            -- hover with mouse. Need to set ctx.bufnr for the handle for it not
            -- to fail hovering in a buffer where the cursor is not in.
            -- Also fake ctx.params.position to match current cursor so the
            -- ctx_is_valid() cursor-position check in vim.lsp.buf.hover passes.
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.lsp.buf_request_all = function(_, method, _, handler)
                local _handler = function(results, ctx)
                    ctx.bufnr = vim.api.nvim_get_current_buf()
                    local cursor = vim.api.nvim_win_get_cursor(0)
                    ctx.params = ctx.params or {}
                    ctx.params.position = {
                        line = cursor[1] - 1,
                        character = cursor[2],
                    }
                    handler(results, ctx)
                end
                orig_req_all(bufnr, method, make_params(bufnr, { pos.line, pos.column - 1 }, line), _handler)
            end

            vim.lsp.buf.hover({
                focusable = false,
                relative = "mouse",
                border = config.get("mouse_hover").border,
                silent = true,
                close_events = { "CursorMoved", "CursorMovedI", "InsertCharPre", "FocusLost", "FocusGained" },
            })

            vim.lsp.buf_request_all = orig_req_all
        end, 500)
        return "<MouseMove>"
    end, { expr = true })
end

return M
