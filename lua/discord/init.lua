local M = {}
local ui = require("discord.ui")

M.config = {}

function M.setup(opts)
	opts = opts or {}
	M.config = vim.tbl_deep_extend("force", M.config, opts)
end

function M.reply()
	ui.open_dashboard()
end

return M
