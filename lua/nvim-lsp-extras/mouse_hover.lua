local M = {}
local config = require("nvim-lsp-extras.config")

local function make_position_param(bufnr, mouse, offset_encoding)
    local line = vim.api.nvim_buf_get_lines(bufnr, mouse.line - 1, mouse.line, true)[1]
    if not line or #line < mouse.column then
        return { line = 0, character = 0 }
    end

    local col = vim.str_byteindex(line, offset_encoding, mouse.column, false)
    return { line = mouse.line - 1, character = col }
end

local make_params = function(mouse, bufnr)
    ---@param client vim.lsp.Client
    return function(client)
        return {
            textDocument = vim.lsp.util.make_text_document_params(bufnr),
            position = make_position_param(bufnr, mouse, client.offset_encoding),
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
            local mouse = vim.fn.getmousepos()
            local bufnr = vim.api.nvim_win_get_buf(mouse.winid)

            local orig_req_all = vim.lsp.buf_request_all
            -- HACK: Temporarily override `vim.lsp.buf_request_all` to support
            -- hover with mouse. Need to set ctx.bufnr for the handle for it not
            -- to fail hovering in a buffer where the cursor is not in
            ---@diagnostic disable-next-line: duplicate-set-field
            vim.lsp.buf_request_all = function(_, method, _, handler)
                local _handler = function(results, ctx)
                    ctx.bufnr = vim.api.nvim_get_current_buf()
                    handler(results, ctx)
                end
                orig_req_all(bufnr, method, make_params(mouse, bufnr), _handler)
            end

            vim.lsp.buf.hover({
                focusable = false,
                relative = "mouse",
                border = config.get("global").border or config.get("mouse_hover").border,
                silent = true,
                close_events = { "CursorMoved", "CursorMovedI", "InsertCharPre", "FocusLost", "FocusGained" },
            })

            vim.lsp.buf_request_all = orig_req_all
        end, 500)
        return "<MouseMove>"
    end, { expr = true })
end

return M
