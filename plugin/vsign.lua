-- vim.cmd.packadd("vsign.nvim")
vim.pack.add({ "https://github.com/CarsonSlovoka/vsign.nvim" })
require("vsign").setup({
  -- live_visual = true,
  -- sign_define = {
  --   vis_bound_lt = {
  --     dict = { text = "<", texthl = "Comment" },
  --   }
  -- }
})
