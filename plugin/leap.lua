vim.go.ignorecase = true
require('leap').setup({
  -- cd pack/motion/start/leap.nvim && git show f19d4359:lua/leap/main.lua | bat -l lua -P -r 79:83
  case_sensitive = false, -- 第一鍵不區分大小寫, 第二個按鍵還是會分, 如果要第二鍵不分要讓vim.go.ignorecase為true
})

vim.keymap.set({ 'n', 'x', 'o' }, 's', '<Plug>(leap)')
vim.keymap.set('n', 'S', '<Plug>(leap-from-window)')
