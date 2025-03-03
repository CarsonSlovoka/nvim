require("config.neovide")

local options = {}

function options.setup()
  vim.g.mapleader = "," -- 預設是 \

  -- :lua vim.opt.fileencoding = "cp950" -- 當你先開啟文件，再用此方法去換，看到的可能還是錯的，因為開啟的時候，會由fileencodings依次去轉，直到沒有錯的，
  -- 它如果轉到了最後一個(latin1)那麼這種情況再由latin1轉到cp950看到的就不對
  -- :e ++enc=cp950 filename.txt -- 可以用這種方式來確保一開始開啟時，就是用正確的編碼
  -- :set fileencodings? -- 這個可以查看當前的設定
  vim.opt.fileencodings = "ucs-bom,utf-8,default,cp950,big5,gbk,latin1"
  -- :set bomb -- 如果想要將檔案加上bom, 可以使用 https://stackoverflow.com/a/7204424/9935654
  -- :set nobomb -- 不保存bom

  -- :set fileformat=dos -- 這是\r\n
  vim.o.fileformat = "unix" -- 讓windows上的換行符號也同unix都是用\n  -- 目前已透過autocmd的FileType事件強制調整(除了bat以外都是unix)
  -- fileformat有沒有影響你可以直接用 nvim 一進來的空檔案，去檢查就會曉得了 :set fileformat?

  -- vim.opt.relativenumber = false -- :set nornu
  vim.opt.relativenumber = true -- :set rnu 這樣用+, -找行的時候會比較簡單，尤其是區塊選取多行的時候
  -- :set nonu   -- 🧙 當你不想要看到列號的時候可以使用, 但是如果目前已經啟用relativenumber, 則要先用 :set nornu再用:set nonu才會真得看不到
  -- :set number -- 此為絕對列號 (為預設)
  vim.opt.backup = false

  -- vim.opt.hlsearch = true   -- 等同 :set hls
  vim.opt.hlsearch = false -- 等同 :nohls -- 我認為不需要特別標示，而且如果高亮往往在結束搜尋的時候，還要自己在用:nohls有點麻煩


  -- vim.opt.incsearch = false  -- :set noincsearch
  vim.opt.incsearch = true -- :set incsearch 邊搜尋的時候，就會出現結果，而不需要等到enter才會有結果

  -- vim.opt.colorcolumn = 120 -- :set colorcolumn=120 -- 欄的輔助線，用來提示該列已經太長，可能不易閱讀
  vim.opt.termguicolors = true

  vim.opt.expandtab = true   -- 使用空白代替Tab
  vim.opt.tabstop = 2        -- Tab鍵等於2個空白
  vim.opt.softtabstop = 2    -- 在插入模式下，Tab鍵也等於2空白
  vim.opt.shiftwidth = 2     -- 自動縮進時使用 2 個空白

  vim.opt.wrap = false       -- 禁止長行自動換行

  vim.wo.cursorcolumn = true -- 光標所在的整欄也會highlight

  -- vim.o.tabline = "%t" -- 用這個只會有當前的檔案名稱，不會看到其它的頁籤名稱
  vim.o.tabline = "%!v:lua.get_tabline()"

  -- 如果要摺行，可以在v下用 :'<,'>fold 的方式去摺
  -- :1200,1600fold 這種方式也可以摺行 foldmethod為manual可用
  -- map: zc, zo 可以摺或展開
  -- vim.opt.foldmethod = "manual" -- 此為預設. 手動設定. 如果你在程式碼中可以自己用set改成indent或者其它的項目
  vim.opt.foldmethod = "indent" -- expr, syntax -- :set foldmethod=indent
  -- vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
  -- vim.opt.foldenable = false
  vim.opt.foldcolumn = "auto" -- 0-9也可以，如果有fold的清況下可以看到旁邊+-的摺顯示
  vim.opt.foldlevel = 2       -- 💡 這個很有用！表示從第幾層後就可以摺疊，如果是0就是全部摺疊, 可以隨時用:set foldlevel?來觀察目前設定的數值

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
    nbsp = ' ', -- U+00A0   non-breaking space (通常的用法是為了保持在同一列，但此列太長，所以讓UI利用此位做出拆行的顯示)
    -- ['U+3000'] = '⬜' -- CJK的全形空白, 使用 U+2B1C (White Large Square) 表示 <-- 目前不支持這種方法，只有特殊名稱可以被使用: https://stackoverflow.com/a/79432341/9935654
  }

  -- 不建議windows換終端機, 還是用cmd會比較好
  -- vim.opt.shell = "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe"
  -- vim.g.terminal_emulator='powershell'
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
