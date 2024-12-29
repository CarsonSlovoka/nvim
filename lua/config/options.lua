local options = {}

function options.setup()
  vim.g.mapleader = "," -- 預設是 \

  vim.opt.expandtab = true  -- 使用空白代替Tab
  vim.opt.tabstop = 2       -- Tab鍵等於2個空白
  vim.opt.softtabstop = 2   -- 在插入模式下，Tab鍵也等於2空白
  vim.opt.shiftwidth = 2    -- 自動縮進時使用 2 個空白

  vim.opt.wrap = false -- 禁止長行自動換行

  vim.g.editorconfig = false -- 預設是啟用的, 如果沒有禁用會得到: Error executing lua callback: root must be either "true" or "false"

  -- set list
  -- set nolist
  vim.opt.list = true
  vim.opt.listchars = {
    -- tab = '🡢', -- 之後一定要再給一個空白，不然會錯
    tab = '🡢 ', -- Tab 符號
    -- space = '•',
    trail = '·', -- 行尾多餘的空格
    -- extends = '>', -- 行末的截斷符顯示為 >
    -- precedes = '<', -- 行首的截斷符顯示為 <
    -- eol = '⏎', -- 行結束位置
    nbsp = ' ' -- U+00A0   non-breaking space
  }
end

return options
