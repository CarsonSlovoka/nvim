vim.defer_fn(function()
  vim.pack.add({ "https://github.com/hat0uma/csvview.nvim" })
  if not pcall(require, "csvview") then
    return
  end
  require("csvview").setup()
  -- USAGE:
  -- :CsvViewEnable
  -- :CsvViewDisable
  -- :CsvViewToggle
end, 1000)
