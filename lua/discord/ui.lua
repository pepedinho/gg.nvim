local state = require("discord.state")
local data = require("discord.data")
local ok, image = pcall(require, "image")

local M = {}

function M.open_chat(name)
	if not state.chat_buf or not vim.api.nvim_buf_is_valid(state.chat_buf) then
		return
	end

	local messages = data.mock_data[name] or {}
	local chat_lines = { "  Chat with " .. name, string.rep("─", 50), "" }

	for _, msg in ipairs(messages) do
		local prefix = msg.sender == "Me" and " 🔵 Me: " or " ⚪ " .. msg.sender .. ": "
		table.insert(chat_lines, prefix .. msg.text)
		table.insert(chat_lines, "")
	end

	vim.bo[state.chat_buf].modifiable = true
	vim.api.nvim_buf_set_lines(state.chat_buf, 0, -1, false, chat_lines)
	vim.bo[state.chat_buf].modifiable = false
end

function M.setup_mappings()
	local opts = { buffer = state.list_buf, silent = true }

	local function jump(direction)
		local cursor = vim.api.nvim_win_get_cursor(state.list_win)
		local current_idx = math.floor((cursor[1] - 1) / data.CONSTANTS.LINES_PER_NOTIF) + 1
		local max_idx = #data.mock_notifications

		if direction == "down" then
			current_idx = current_idx + 1
		else
			current_idx = current_idx - 1
		end

		if current_idx < 1 then
			current_idx = 1
		end
		if current_idx > max_idx then
			current_idx = max_idx
		end

		local target_row = (current_idx - 1) * data.CONSTANTS.LINES_PER_NOTIF + 1
		vim.api.nvim_win_set_cursor(state.list_win, { target_row, 0 })
	end

	vim.keymap.set("n", "j", function()
		jump("down")
	end, opts)
	vim.keymap.set("n", "<Down>", function()
		jump("down")
	end, opts)
	vim.keymap.set("n", "k", function()
		jump("up")
	end, opts)
	vim.keymap.set("n", "<Up>", function()
		jump("up")
	end, opts)

	vim.keymap.set("n", "q", function()
		state.close_all()
	end, opts)
	vim.keymap.set("n", "<Esc>", function()
		state.close_all()
	end, opts)
	vim.keymap.set("n", "q", function()
		state.close_all()
	end, { buffer = state.chat_buf, silent = true })
	vim.keymap.set("n", "<Esc>", function()
		state.close_all()
	end, { buffer = state.chat_buf, silent = true })

	vim.keymap.set("n", "<CR>", function()
		local cursor = vim.api.nvim_win_get_cursor(state.list_win)
		local idx = math.floor((cursor[1] - 1) / data.CONSTANTS.LINES_PER_NOTIF) + 1
		local selected = data.mock_notifications[idx]
		if selected then
			M.open_chat(selected.name)
		end
	end, opts)

	vim.keymap.set("n", "<Tab>", function()
		if vim.api.nvim_get_current_win() == state.list_win then
			vim.api.nvim_set_current_win(state.chat_win)
		else
			vim.api.nvim_set_current_win(state.list_win)
		end
	end, opts)
	vim.keymap.set("n", "<Tab>", function()
		vim.api.nvim_set_current_win(state.list_win)
	end, { buffer = state.chat_buf, silent = true })
end

function M.open_dashboard()
	state.close_all()
	if not ok then
		return print("Error : Plugin '3rd/image.nvim' is needed.")
	end

	local w = math.floor(vim.o.columns * 0.8)
	local h = math.floor(vim.o.lines * 0.7)
	local col = math.floor((vim.o.columns - w) / 2)
	local row = math.floor((vim.o.lines - h) / 2)
	local list_w = math.floor(w * 0.35)

	state.list_buf = vim.api.nvim_create_buf(false, true)
	state.list_win = vim.api.nvim_open_win(state.list_buf, true, {
		relative = "editor",
		width = list_w,
		height = h,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded",
		title = " 💬 Discord ",
	})

	state.chat_buf = vim.api.nvim_create_buf(false, true)
	state.chat_win = vim.api.nvim_open_win(state.chat_buf, false, {
		relative = "editor",
		width = w - list_w - 2,
		height = h,
		col = col + list_w + 2,
		row = row,
		style = "minimal",
		border = "rounded",
		title = " Discussion ",
	})

	local lines = {}
	for _, notif in ipairs(data.mock_notifications) do
		local badge = notif.unread > 0 and string.format("(%d)", notif.unread) or ""
		table.insert(lines, string.format("        👤 %s %s", notif.name, badge))
		table.insert(lines, string.format("        > %s", string.sub(notif.message, 1, 20) .. ".."))
		table.insert(lines, " ")
		table.insert(lines, "")
	end
	vim.api.nvim_buf_set_lines(state.list_buf, 0, -1, false, lines)

	for i = 1, #data.mock_notifications do
		local img = image.from_file(data.CONSTANTS.PFP_PATH, {
			window = state.list_win,
			buffer = state.list_buf,
			y = (i - 1) * data.CONSTANTS.LINES_PER_NOTIF,
			x = 0,
			width = data.CONSTANTS.PFP_SIZE_COLS,
			height = data.CONSTANTS.PFP_SIZE_LINES,
		})
		if img then
			vim.schedule(function()
				img:render()
			end)
			table.insert(state.avatars, img)
		end
	end

	vim.bo[state.list_buf].modifiable = false
	M.setup_mappings()
	vim.wo[state.list_win].cursorline = true
end

return M
