---@class DiscordData
local M = {}

---@class Constants
M.CONSTANTS = {
	LINES_PER_NOTIF = 4,
	PFP_SIZE_LINES = 3,
	PFP_SIZE_COLS = 8,
	-- Fallback image if download fails
	PFP_PATH = vim.fn.expand("~/code/lua/gg.nvim/pepe.png"),
}

-- Mocks and state data
-- Format: { ["Username"] = { { sender = "Moi", text = "Hello" }, ... } }
M.mock_data = {}

-- Format: { { name = "Alice", message = "Hi", channel_id = "123", pfp_path = "/path/to/img", unread = 1 } }
M.mock_notifications = {}

-- Maps Discord channel IDs to local display names
-- Format: { ["123456789"] = "Alice" }
M.channel_names = {}

return M
