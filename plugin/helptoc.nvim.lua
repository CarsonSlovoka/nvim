vim.defer_fn(function()
  vim.pack.add({ "https://github.com/CarsonSlovoka/helptoc.nvim" })
  -- vim.cmd.packadd("helptoc.nvim") -- 地端開發
  local m = require("helptoc")

  -- m.setup()
  m.setup({
    -- indent_size = 'auto', -- tree, auto
    -- position = "right"
    highlight = {
      -- cursor_line = { link = "@Label" }
      cursor_line = { bg = vim.g.terminal_color_4 or "#00c6ff", fg = "#003b4f" }
    },
    -- enable = {
    --   kind_icon = true,
    -- symbol_highlight = true,
    -- }
  })

  -- local group = "HelpToc"
  -- vim.api.nvim_create_augroup(group, {})
  vim.api.nvim_create_autocmd("FileType", {
    group = m.group,
    -- pattern = {
    --   "markdown",
    --   "sh", "zsh",
    --   "lua"
    -- },
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      vim.keymap.set("n", "<leader>h", "<cmd>Helptoc<CR>", { noremap = true, silent = true, buf = buf })
    end
  })
end, 50)
