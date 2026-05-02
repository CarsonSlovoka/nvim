vim.pack.add({ "https://github.com/stevearc/oil.nvim" })
require("oil").setup()

-- Tip: `:verbose command Oil` 可以直接曉得這個指令實作在什麼位置

-- vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" }) -- 只用 - 會和往上移動N行衝突
vim.keymap.set("n", "<leader>e", "<CMD>Oil<CR>", { desc = "Open parent directory" })
-- vim.keymap.set("n", "<leader>e", "<CMD>Oil --float<CR>", { desc = "Oil Float" })
