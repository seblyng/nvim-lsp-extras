local M = {}
local config = require("nvim-lsp-extras.config")

M.setup = function(opts)
    if vim.fn.has("nvim-0.11") == 0 then
        return vim.notify("This plugin requires at least nvim 0.11", vim.log.levels.WARN, { title = "nvim-lsp-extras" })
    end

    config.set(opts)

    for conf, _ in pairs(config.get_modules()) do
        if config.get(conf) then
            vim.api.nvim_create_autocmd("LspAttach", {
                pattern = "*",
                group = vim.api.nvim_create_augroup(string.format("%sLspExtra", conf), { clear = true }),
                callback = function(args)
                    local client = vim.lsp.get_client_by_id(args.data.client_id)
                    require(string.format("nvim-lsp-extras.%s", conf)).setup(client, args.buf)
                end,
            })
        end
    end
end

return M
