vim.defer_fn(function()
  -- Tip: pack.del會直接刪除 `:lua vim.fn.setreg('a', vim.fn.stdpath('data') .. '/site/pack/core/opt/')` 底下所對應的文件夾
  -- vim.pack.del({ "helptoc.nvim" }) -- 可以更新 ../nvim-pack-lock.json 之後刪除重新下載. -- Note: 如果這個目錄沒有會直接報錯
  -- Note: 如果要直接抓最新版本的，也可以直接將 ../nvim-pack-lock.json 所對應的項目刪除, 預設會直接抓最後一版本然後更新
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

    -- lsp_kinds = {
    --   vim.lsp.protocol.SymbolKind.Function,
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
