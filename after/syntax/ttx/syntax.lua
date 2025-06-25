-- if vim.b.current_syntax then -- 這些已經有在xml.vim之中實作了
--   return
-- end

-- https://github.com/neovim/neovim/blob/684be736c15f9ec60d71d5c7fd3ee1dd8083d84e/runtime/syntax/xml.vim#L1-L361
vim.cmd("runtime! syntax/xml.vim")

-- vim.b.current_syntax = 'ttx'
