---@class DiscordState
local M = {
	-- Left Panel (User list)
	list_win = nil,
	list_buf = nil,

	-- Top Right Panel (Chat history)
	chat_win = nil,
	chat_buf = nil,

	-- Bottom Right Panel (Message input)
	input_win = nil,
	input_buf = nil,

	-- Keep track of rendered images to clear them safely
	avatars = {},

	-- Currently focused conversation
	active_chat_user = nil,
}

---Safely close all windows and clear rendered images
function M.close_all()
	-- Clear images first to prevent ghost artifacts
	for _, img in ipairs(M.avatars) do
		if img then
			img:clear()
		end
	end
	M.avatars = {}

	-- Close all windows if they are still valid
	local windows = { M.list_win, M.chat_win, M.input_win }
	for _, win in ipairs(windows) do
		if win and vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	-- Reset state
	M.active_chat_user = nil
end

return M
