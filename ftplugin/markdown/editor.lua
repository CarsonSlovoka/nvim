--[[ 加了會無法觸發熱鍵
if vim.b.did_ftplugin_markdown then
    return
end
vim.b.did_ftplugin_markdown = true
--]]

-- 快捷鍵映射
-- local opts = { buffer = false } -- buffer預設為true，表示對所有項目都能生效

local keymap = require("utils.keymap").keymap
local function map(mode, key, cmd, opts)
  opts = opts or {}
  opts.buffer = true -- 改為ture可以避免當你使用markdown之後用緩衝區開啟其他檔案屬性時也被套用此熱鍵
  keymap(mode, key, cmd, opts)
end
-- local map = function

-- 標題相關
-- map('n', '<Leader>h1', 'i# <ESC>a', opts) -- h按鍵很重要，不要隨便分配，不然用到的時候會有等待時間
map('n', '<C-H>1', 'i# <ESC>a') -- ctrl+h不區分大小寫
map('n', '<C-H>2', 'i## <ESC>a')
map('n', '<C-H>3', 'i### <ESC>a')
map('n', '<C-H>4', 'i#### <ESC>a')
map('n', '<C-H>5', 'i##### <ESC>a')
map('n', '<C-H>6', 'i###### <ESC>a')

-- 格式化文本
map('n', '<leader>b', 'ciw**<C-r>"**<ESC>', { desc = "Bold" }) -- 加粗 -- ciw會剪下一個詞放到暫存器`"` 並進入編輯模式，在編輯模式下<C-r>可以指定要貼上哪一個暫存器的內容
map('n', '<leader>i', 'ciw*<C-r>"*<ESC>', { desc = "Italic" }) -- 斜體
map('v', '<leader>b', 'c**<C-r>"**<ESC>', { desc = "視覺模式下加粗" })
map('v', '<leader>i', 'c*<C-r>"*<ESC>', { desc = "視覺模式下斜體" })
map('v', '<leader>dw', 'c~~<C-r>"~~<ESC>', { desc = "刪除線" })

-- 代碼塊
-- map('n', '<Leader>c', 'I```<ESC>o```<ESC>O', { desc = "插入代碼塊, 可以先打上區塊代碼的名稱" })
-- map('n', '<Leader>c', 'I```<CR>```<C-o>O', { desc = "插入代碼塊, 可以先打上區塊代碼的名稱" })
map('n', '<Leader>`',
  function()
    local name = vim.fn.input("codeblock name: ")
    if name == "" then
      -- 如果用戶未輸入名稱，插入空的代碼塊
      name = ""
    end
    -- 插入代碼塊模板到當前行
    local codeblock = {
      "```" .. name,
      "",
      "```"
    }
    vim.api.nvim_put(codeblock,
      "l", -- (linewise mode) 插入整列(一個新的列)
      true, -- 先標之後插入
      true -- follow, true會將光標移動到新插入的最後一列
    )
    -- 將游標移動到代碼塊的中間，方便用戶輸入代碼
    vim.api.nvim_command("normal! kkI")
    vim.cmd("startinsert")
  end,
  { desc = "插入代碼塊, 可以先打上區塊代碼的名稱" }
)
