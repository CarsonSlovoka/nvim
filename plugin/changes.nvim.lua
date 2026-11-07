vim.pack.add({ "https://github.com/CarsonSlovoka/changes.nvim" })
-- vim.cmd.packadd("changes.nvim")

require("changes").setup()

vim.keymap.set("n", "<leader>cs", ':Changes<CR>G', { desc = "changes" })
