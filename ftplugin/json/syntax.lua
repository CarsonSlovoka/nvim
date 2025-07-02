-- vim.cmd([[syntax match jsonQuote /[{},]/ conceal]]) -- 將 {, }, , 都隱藏
-- vim.cmd([[syntax match jsonQuote /[{},]/ conceal]]) -- 不要將syntax寫在這邊, 可能會被覆蓋導致無效，要寫在 ../../after/syntax 之中 -- 不過 ensure_installed 的項目也會影響到，所以最保險的方式是自定義autocmd

-- vim.bo.conceallevel = 2 -- conceallevel 沒有buffer的設定，只有window能設，所以要用wo
vim.wo.conceallevel = 2
