local M = {
	list_win = nil,
	list_buf = nil,
	chat_win = nil,
	chat_buf = nil,
	avatars = {},
}

function M.close_all()
	for _, img in ipairs(M.avatars) do
		if img then
			img:clear()
		end
	end
	M.avatars = {}

	if M.list_win and vim.api.nvim_win_is_valid(M.list_win) then
		vim.api.nvim_win_close(M.list_win, true)
	end
	if M.chat_win and vim.api.nvim_win_is_valid(M.chat_win) then
		vim.api.nvim_win_close(M.chat_win, true)
	end
end

return M
