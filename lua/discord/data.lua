local M = {}

M.CONSTANTS = {
	LINES_PER_NOTIF = 4,
	PFP_SIZE_LINES = 3,
	PFP_SIZE_COLS = 8,
	PFP_PATH = vim.fn.expand("~/code/lua/gg.nvim/pepe.png"),
}

M.mock_data = {
	Alice = {
		{ sender = "Alice", text = "Tu as vu la dernière PR ?" },
		{ sender = "Moi", text = "Pas encore, je regarde ça après le café." },
		{ sender = "Alice", text = "Ça marche, c'est assez urgent pour la prod." },
	},
	Bob_Le_Dev = {
		{ sender = "Bob_Le_Dev", text = "Ok ça marche pour moi 👍" },
	},
	Charlie = {
		{ sender = "Charlie", text = "Le serveur de prod est down !!!" },
		{ sender = "Charlie", text = "Imad, réveille-toi !" },
	},
	GhosttyFan = {
		{ sender = "GhosttyFan", text = "Le rendu GPU est incroyable." },
	},
}

M.mock_notifications = {
	{ name = "Alice", message = "Tu as vu la dernière PR ?", unread = 2 },
	{ name = "Bob_Le_Dev", message = "Ok ça marche pour moi 👍", unread = 0 },
	{ name = "Charlie", message = "Le serveur de prod est down !!!", unread = 9 },
	{ name = "GhosttyFan", message = "Le rendu GPU est incroyable.", unread = 1 },
}

return M
