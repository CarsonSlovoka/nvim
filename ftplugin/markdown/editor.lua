--[[ 加了會無法觸發熱鍵
if vim.b.did_ftplugin_markdown then
    return
end
vim.b.did_ftplugin_markdown = true
--]]

-- 快捷鍵映射
-- local opts = { buffer = false } -- buffer預設為true，表示對所有項目都能生效
local opts = { buffer = true } -- 改為ture可以避免當你使用markdown之後用緩衝區開啟其他檔案屬性時也被套用此熱鍵

-- 標題相關
-- vim.keymap.set('n', '<Leader>h1', 'i# <ESC>a', opts) -- h按鍵很重要，不要隨便分配，不然用到的時候會有等待時間
vim.keymap.set('n', '<C-H>1', 'i# <ESC>a', opts) -- ctrl+h不區分大小寫
vim.keymap.set('n', '<C-H>2', 'i## <ESC>a', opts)
vim.keymap.set('n', '<C-H>3', 'i### <ESC>a', opts)

-- 格式化文本
vim.keymap.set('n', '<leader>b', 'ciw**<C-r>"**<ESC>', opts) -- 加粗
vim.keymap.set('n', '<leader>i', 'ciw*<C-r>"*<ESC>', opts)   -- 斜體
vim.keymap.set('v', '<leader>b', 'c**<C-r>"**<ESC>', opts)   -- 視覺模式下加粗
vim.keymap.set('v', '<leader>i', 'c*<C-r>"*<ESC>', opts)     -- 視覺模式下斜體

-- 代碼塊
vim.keymap.set('n', '<Leader>c', 'i```<CR>```<ESC>ko', opts) -- 插入代碼塊
