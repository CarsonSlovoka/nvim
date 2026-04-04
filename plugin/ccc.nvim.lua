--- 色彩選擇器
local function install_ccc()
  -- -- vim.opt.termguicolors = true

  local ok, ccc = pcall(require, "ccc")
  if not ok then
    vim.notify("Failed to load ccc", vim.log.levels.WARN)
    return
  end
  -- local mapping = ccc.mapping

  ccc.setup({
    highlighter = {
      auto_enable = true,
      lsp = true,
    },
  })
end

vim.defer_fn(function()
  vim.pack.add({ "https://github.com/uga-rosa/ccc.nvim" })
  install_ccc()
end, 1000)
