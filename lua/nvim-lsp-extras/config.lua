local M = {}

local default = {
    global = {
        border = nil,
    },
    signature = {
        border = "rounded",
    },
    mouse_hover = {
        border = "rounded",
    },
    lightbulb = {
        icon = "",
        diagnostic_only = true,
    },
}

local config = {}

M.set = function(user_options)
    user_options = user_options or {}
    config = vim.tbl_extend("force", default, user_options)

    -- Set the global border option for each of the modules
    if config.global.border then
        config.signature.border = config.global.border
        config.mouse_hover.border = config.global.border
    end

    return config
end

M.get_modules = function()
    local modules = vim.deepcopy(config)
    modules["global"] = nil
    return modules
end

M.get = function(key)
    return config[key]
end

return M
