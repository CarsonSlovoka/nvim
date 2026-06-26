vim.defer_fn(function()
  vim.pack.add({ "https://github.com/CarsonSlovoka/helptoc.nvim" })
  -- vim.cmd.packadd("helptoc.nvim") -- 地端開發

  require("helptoc").setup()
  -- require("helptoc").setup({
  --   indent_size = 'auto', -- tree, auto
  --   position = "right"
  -- })

  local group = "HelpToc"
  vim.api.nvim_create_augroup(group, {})
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = {
      "markdown",
      "sh", "zsh",
      "lua"
    },
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      vim.keymap.set("n", "<leader>h", "<cmd>Helptoc<CR>", { noremap = true, silent = true, buf = buf })
    end
  })
end, 50)
