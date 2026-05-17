---@class DiscordPlugin
local M = {}

local ui = require("discord.ui")

---@type table Default configuration
M.config = {}

---Initialize the plugin with user configuration
---@param opts table? User configuration
function M.setup(opts)
	opts = opts or {}
	M.config = vim.tbl_deep_extend("force", M.config, opts)
end

---Open the main Discord dashboard
function M.reply()
	ui.open_dashboard()
end

return M
