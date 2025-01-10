local options = {}

function options.setup()
  vim.g.mapleader = ","      -- 預設是 \

  vim.opt.expandtab = true   -- 使用空白代替Tab
  vim.opt.tabstop = 2        -- Tab鍵等於2個空白
  vim.opt.softtabstop = 2    -- 在插入模式下，Tab鍵也等於2空白
  vim.opt.shiftwidth = 2     -- 自動縮進時使用 2 個空白

  vim.opt.wrap = false       -- 禁止長行自動換行

  vim.wo.cursorcolumn = true -- 光標所在的整欄也會highlight

  -- vim.o.tabline = "%t" -- 用這個只會有當前的檔案名稱，不會看到其它的頁籤名稱
  vim.o.tabline = "%!v:lua.get_tabline()"

  -- 如果要摺行，可以在v下用 :'<,'>fold 的方式去摺
  -- :1200,1600fold 這種方式也可以摺行
  -- map: zc, zo 可以摺或展開
  -- vim.opt.foldmethod = "indent" -- expr, syntax
  -- vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
  -- vim.opt.foldenable = false

  -- 檢查是否有支援真彩色
  local supports_truecolor = vim.fn.getenv("COLORTERM") == "truecolor"
  if supports_truecolor then
    -- 真色彩
    -- vim.cmd("highlight CursorColumn ctermbg=236 guibg=#3a3a3a") -- 光標所在欄顏色(預設是無)
    -- 一次設定
    vim.cmd([[
        highlight CursorColumn ctermbg=236 guibg=#3a3a3a
        highlight StatusLine guifg=#fefefe guibg=#282a36
      ]])
    --[[
    highlight Visual guibg=#44475a
    highlight Search guibg=#ffcc00 guifg=#000000
    highlight DiagnosticError guifg=#ff5555
    ]] --
  else
    -- 回退到256色
    vim.cmd("highlight CursorColumn ctermbg=236")
  end

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

function _G.get_tabline() -- 給全局變數
  -- 獲取當前所有標籤頁的名稱
  local s = ""
  for tabnr = 1, vim.fn.tabpagenr('$') do
    local winnr = vim.fn.tabpagewinnr(tabnr)
    -- 獲取當前窗口的 buffer 名稱
    local buflist = vim.fn.tabpagebuflist(tabnr)[winnr]
    local bufname = vim.fn.bufname(buflist)
    local bufname_short = vim.fn.fnamemodify(bufname, ":t") -- 僅提取檔名名稱，不包含路徑

    if tabnr == vim.fn.tabpagenr() then
      s = s .. "%#TabLineSel#" .. " " .. tabnr .. ": " .. bufname_short .. " "
    else
      s = s .. "%#TabLine#" .. " " .. tabnr .. ": " .. bufname_short .. " "
    end
  end
  s = s .. "%#TabLineFill#"
  return s
end

return options
