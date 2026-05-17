---@class DiscordSocket
local M = {}

local uv = vim.uv or vim.loop
local state = require("discord.state")
local data = require("discord.data")

---@type userdata? UV Pipe handle
M.pipe = nil

---Connect to the Rust daemon via Unix Domain Socket
function M.connect()
	if M.pipe then
		return
	end

	M.pipe = uv.new_pipe(false)
	local socket_path = "/tmp/discord-nvim.sock"

	uv.pipe_connect(M.pipe, socket_path, function(err)
		if err then
			vim.schedule(function()
				print("❌ Failed to connect to Rust daemon: " .. err)
			end)
			M.pipe = nil
			return
		end

		-- Start reading from the socket continuously
		uv.read_start(M.pipe, function(read_err, chunk)
			if read_err or not chunk then
				M.disconnect()
				return
			end
			-- Process data in the main Neovim thread
			vim.schedule(function()
				M.handle_incoming_data(chunk)
			end)
		end)
	end)
end

---Parse raw JSON lines chunk from Rust
---@param chunk string
function M.handle_incoming_data(chunk)
	for line in string.gmatch(chunk, "[^\r\n]+") do
		local ok, decoded = pcall(vim.json.decode, line)
		if ok and decoded then
			if decoded.type == "new_message" then
				M.process_new_message(decoded.data)
			elseif decoded.type == "system" then
				print("🤖 " .. decoded.data.msg)
			end
		end
	end
end

---Update data structures and trigger UI redraw
---@param msg table
function M.process_new_message(msg)
	local channel_id = msg.channel_id
	local author = msg.author
	local is_me = msg.is_me
	local pfp = (msg.profile_picture and msg.profile_picture ~= "") and msg.profile_picture or data.CONSTANTS.PFP_PATH

	local chat_name

	-- Logic to link messages to the correct conversation
	if is_me then
		chat_name = data.channel_names[channel_id] or "Unknown"
		author = "Moi"
	else
		chat_name = author
		data.channel_names[channel_id] = chat_name
	end

	-- Initialize conversation if it doesn't exist
	if not data.mock_data[chat_name] then
		data.mock_data[chat_name] = {}
		table.insert(data.mock_notifications, {
			name = chat_name,
			message = msg.content,
			channel_id = channel_id,
			pfp_path = pfp,
			unread = (state.active_chat_user == chat_name or is_me) and 0 or 1,
		})
	else
		-- Update existing conversation snippet and unread count
		for _, notif in ipairs(data.mock_notifications) do
			if notif.name == chat_name then
				notif.message = msg.content
				if not is_me then
					notif.pfp_path = pfp
				end
				if state.active_chat_user ~= chat_name and not is_me then
					notif.unread = notif.unread + 1
				end
				break
			end
		end
	end

	-- Store message history
	table.insert(data.mock_data[chat_name], {
		sender = author,
		text = msg.content,
	})

	-- Trigger UI updates
	local ui = require("discord.ui")
	ui.redraw_list()
	if state.active_chat_user == chat_name then
		ui.open_chat(chat_name)
	end
end

---Send a message to Rust to be forwarded to Discord
---@param channel_id string
---@param content string
function M.send_msg(channel_id, content)
	if not M.pipe then
		return
	end

	local payload = vim.json.encode({
		action = "send_message",
		channel_id = channel_id,
		content = content,
	})

	-- Must append newline for JSON Lines protocol
	uv.write(M.pipe, payload .. "\n")
end

---Safely disconnect the socket
function M.disconnect()
	if M.pipe then
		uv.read_stop(M.pipe)
		uv.close(M.pipe)
		M.pipe = nil
		print("🔌 Disconnected from Discord daemon.")
	end
end

return M
