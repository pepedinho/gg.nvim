if vim.g.loaded_discord_nvim == 1 then
	return
end
vim.g.loaded_discord_nvim = 1

vim.api.nvim_create_user_command("Ds", function()
	require("discord").reply()
end, { desc = "Open discord window" })
