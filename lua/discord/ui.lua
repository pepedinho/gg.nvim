---@class DiscordUI
local M = {}

local state = require("discord.state")
local data = require("discord.data")
local socket = require("discord.socket")
local ok, image = pcall(require, "image")

---Helper to create a floating window with standard options
---@param buf number
---@param title string
---@param w number
---@param h number
---@param col number
---@param row number
---@return number window_id
local function create_win(buf, title, w, h, col, row)
	return vim.api.nvim_open_win(buf, false, {
		relative = "editor",
		width = w,
		height = h,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded",
		title = " " .. title .. " ",
	})
end

---Refresh the right chat window with the history of a specific user
---@param name string Username to load
function M.open_chat(name)
	if not state.chat_buf or not vim.api.nvim_buf_is_valid(state.chat_buf) then
		return
	end

	state.active_chat_user = name
	local messages = data.mock_data[name] or {}
	local chat_lines = { "  Chat with " .. name, string.rep("─", 50), "" }

	for _, msg in ipairs(messages) do
		local prefix = msg.sender == "Moi" and " 🔵 Moi: " or " ⚪ " .. msg.sender .. ": "
		table.insert(chat_lines, prefix .. msg.text)
		table.insert(chat_lines, "")
	end

	vim.bo[state.chat_buf].modifiable = true
	vim.api.nvim_buf_set_lines(state.chat_buf, 0, -1, false, chat_lines)
	vim.bo[state.chat_buf].modifiable = false

	-- Scroll to bottom to show latest message
	local total_lines = vim.api.nvim_buf_line_count(state.chat_buf)
	if total_lines > 0 then
		vim.api.nvim_win_set_cursor(state.chat_win, { total_lines, 0 })
	end
end

---Redraw the left panel with users and avatars
function M.redraw_list()
	if not state.list_buf or not vim.api.nvim_buf_is_valid(state.list_buf) then
		return
	end

	-- Clean old avatars
	for _, img in ipairs(state.avatars) do
		if img then
			img:clear()
		end
	end
	state.avatars = {}

	-- Rebuild text lines
	local lines = {}
	for _, notif in ipairs(data.mock_notifications) do
		local badge = notif.unread > 0 and string.format("(%d)", notif.unread) or ""
		table.insert(lines, string.format("        👤 %s %s", notif.name, badge))
		table.insert(lines, string.format("        > %s", string.sub(notif.message, 1, 20) .. ".."))
		table.insert(lines, " ")
		table.insert(lines, "")
	end

	vim.bo[state.list_buf].modifiable = true
	vim.api.nvim_buf_set_lines(state.list_buf, 0, -1, false, lines)
	vim.bo[state.list_buf].modifiable = false

	-- Re-render avatars
	for i, notif in ipairs(data.mock_notifications) do
		local img_path = notif.pfp_path or data.CONSTANTS.PFP_PATH
		local img = image.from_file(img_path, {
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
end

---Setup all keybindings for the dashboard
function M.setup_mappings()
	local opts = { buffer = state.list_buf, silent = true }

	-- Jump logic for J/K in the left panel
	local function jump(direction)
		local max_idx = #data.mock_notifications
		if max_idx == 0 then
			return
		end

		local cursor = vim.api.nvim_win_get_cursor(state.list_win)
		local current_idx = math.floor((cursor[1] - 1) / data.CONSTANTS.LINES_PER_NOTIF) + 1

		if direction == "down" then
			current_idx = current_idx + 1
		else
			current_idx = current_idx - 1
		end

		current_idx = math.max(1, math.min(current_idx, max_idx))
		local target_row = (current_idx - 1) * data.CONSTANTS.LINES_PER_NOTIF + 1
		vim.api.nvim_win_set_cursor(state.list_win, { target_row, 0 })
	end

	-- Vim motions mapping
	vim.keymap.set("n", "j", function()
		jump("down")
	end, opts)
	vim.keymap.set("n", "k", function()
		jump("up")
	end, opts)

	-- Quit mappings
	local close_fn = function()
		state.close_all()
	end
	for _, buf in ipairs({ state.list_buf, state.chat_buf, state.input_buf }) do
		vim.keymap.set("n", "q", close_fn, { buffer = buf, silent = true })
		vim.keymap.set("n", "<Esc>", close_fn, { buffer = buf, silent = true })
	end

	-- Open chat and focus input window
	vim.keymap.set("n", "<CR>", function()
		local cursor = vim.api.nvim_win_get_cursor(state.list_win)
		local idx = math.floor((cursor[1] - 1) / data.CONSTANTS.LINES_PER_NOTIF) + 1
		local selected = data.mock_notifications[idx]

		if selected then
			M.open_chat(selected.name)
			vim.api.nvim_set_current_win(state.input_win)
			vim.cmd("startinsert")
		end
	end, opts)

	-- Focus cycle with TAB
	vim.keymap.set("n", "<Tab>", function()
		if vim.api.nvim_get_current_win() == state.list_win then
			vim.api.nvim_set_current_win(state.input_win)
			vim.cmd("startinsert")
		else
			vim.api.nvim_set_current_win(state.list_win)
		end
	end, opts)

	-- Send message from input window
	vim.keymap.set("i", "<CR>", function()
		local active_user = state.active_chat_user
		if not active_user then
			return
		end

		local channel_id = nil
		for _, notif in ipairs(data.mock_notifications) do
			if notif.name == active_user then
				channel_id = notif.channel_id
				break
			end
		end
		if not channel_id then
			return
		end

		local lines = vim.api.nvim_buf_get_lines(state.input_buf, 0, -1, false)
		local input = table.concat(lines, "\n"):gsub("^%s*(.-)%s*$", "%1")

		if input ~= "" then
			socket.send_msg(channel_id, input)
			vim.api.nvim_buf_set_lines(state.input_buf, 0, -1, false, { "" })
		end
	end, { buffer = state.input_buf, silent = true })
end

---Draw the layout and initialize connections
function M.open_dashboard()
	state.close_all()
	socket.connect()

	if not ok then
		return print("Error: Plugin '3rd/image.nvim' is required.")
	end

	-- Calculate geometry
	local w = math.floor(vim.o.columns * 0.8)
	local h = math.floor(vim.o.lines * 0.7)
	local col = math.floor((vim.o.columns - w) / 2)
	local row = math.floor((vim.o.lines - h) / 2)

	local list_w = math.floor(w * 0.35)
	local chat_w = w - list_w - 2
	local chat_h = h - 3 -- Leave space for input box

	-- 1. Left Panel (List)
	state.list_buf = vim.api.nvim_create_buf(false, true)
	state.list_win = create_win(state.list_buf, "Discord", list_w, h, col, row)

	-- 2. Top Right Panel (Chat)
	state.chat_buf = vim.api.nvim_create_buf(false, true)
	state.chat_win = create_win(state.chat_buf, "History", chat_w, chat_h, col + list_w + 2, row)

	-- 3. Bottom Right Panel (Input)
	state.input_buf = vim.api.nvim_create_buf(false, true)
	state.input_win = create_win(state.input_buf, "Message", chat_w, 1, col + list_w + 2, row + chat_h + 2)

	M.redraw_list()

	vim.bo[state.list_buf].modifiable = false
	M.setup_mappings()
	vim.wo[state.list_win].cursorline = true

	-- Focus list window by default
	vim.api.nvim_set_current_win(state.list_win)
end

return M
