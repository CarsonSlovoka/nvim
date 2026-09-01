if not vim.fn.executable('hs') then
  return
end

-- 用nvim來操控hammerspoon
vim.pack.add({ "https://github.com/CarsonSlovoka/nvim_hs" })
-- vim.cmd.packadd("nvim_hs")
require("nvim_hs.command").setup()
