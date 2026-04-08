require("config.neovide")

local options = {}

--- custom_global_options 自定義全域變數
local function custom_global_options()
  -- vim.g.qffiletype = nil  -- 初值設定為nil有一個壞處，在使用 :let g: 的時候使用tab不會出來，設定成""就可以讓tab有它的選單出來
  vim.g.qffiletype = "" -- 實際用途: https://github.com/CarsonSlovoka/nvim/blob/896395082cbf5a/after/syntax/qf.lua#L17-L26
  -- let g:qffiletype="cpp"
  -- :lua print(vim.g:qffiletype) -- 查看
end

-- nvim中其它的變數
-- g: global
-- t: tab     書架 一個tab可以有許多buffer
-- b: buffer  書      :e 或者 :Telescope buffers 的跳轉都是再換buffer
--    :lua print(vim.api.nvim_get_current_buf())
--    💡用 :ls 其實就能看到bufferID了
-- w: window  第幾頁. :split 等相關都可以從該buffer之中再分離出window, 拆分出來的是不同windowID
--   🧙 不同的buffer是可能對應到相同的windowsID, 例如用 :e 去開啟編輯其它文件，也是相同的winID
--   以下兩個方法都可以查詢windowID
--   :echo win_getid()
--   :lua print(vim.api.nvim_get_current_win())

function options.setup()
  -- vim.o 與 vim.opt 是相同的只是數值的表達方式不同, vim.o是純字串 :help vim.opt

  -- vim.g.mapleader = "," -- 預設是 \ -- , 在f, F, t, T的時候會當成另一個方向的重覆
  vim.g.mapleader = "\\"

  vim.opt.scrolloff = 999 -- 距離當前畫面的頂部或者底部還有多少列的時候，可以進行scroll的動作 (預設是0, 也就是游標一定要移動到最下面才能捲動), 999讓其在畫面中間，也就是只要j, k動一定會連帶往下或往上移

  -- :set history?
  vim.opt.history = 10000 -- 10000預設
  -- 查看某一個類別的history
  -- 請參考 :hist-names
  -- :history ":" -- 查看所有cmd記錄
  -- :history "/" -- search
  -- ...
  --
  -- :call histdel({history}. [, {item}])
  -- :call histdel(":") -- cmd 刪除所有cmd記錄
  -- :call histdel("/") -- search 刪除所有搜尋記錄
  -- :call histdel("=") -- expr
  -- :call histdel("@") -- input
  -- :call histdel(">") -- debug
  -- :call histdel("")  -- empty the current or last used history
  --
  -- :call histdel("cmd", '^help') -- 刪除開頭是help的項目
  -- :call histdel(":", 'www') -- 只要cmd中有包含www就會被刪除

  -- :h options.txt
  -- 這個可以當成依據每個專案來設定自己的shadafile 👉 https://github.com/oysandvik94/dotfiles/blob/6be70e59b5545e44940982db52b06e24f5e251d9/dotfiles/.config/nvim/lua/langeoys/set.lua#L89-L96
  -- :echo stdpath('data')
  -- :pu =stdpath('data') -- put
  -- /home/carson/.local/share/nvim
  -- fd -t f shada ~ -H /
  -- .local/state/nvim/shada/main.shada
  -- vim.opt.shadafile = vim.fn.stdpath("data") .. "/carson_nvim.shada" -- 😢 用nvim可以解析裡面的二進位資料，不過編輯後存檔仍不行
  -- set shada="NONE" -- https://vi.stackexchange.com/a/9571/31859 -- https://neovim.io/doc/user/options.html#'shada'
  -- set shada='50,<1000,s100,:0,n~/nvim/shada -- https://neovim.io/doc/user/options.html#'sd'

  -- :lua vim.opt.fileencoding = "cp950" -- 當你先開啟文件，再用此方法去換，看到的可能還是錯的，因為開啟的時候，會由fileencodings依次去轉，直到沒有錯的，
  -- 它如果轉到了最後一個(latin1)那麼這種情況再由latin1轉到cp950看到的就不對
  -- :e ++enc=cp950 filename.txt -- 可以用這種方式來確保一開始開啟時，就是用正確的編碼
  -- :set fileencodings? -- 這個可以查看當前的設定
  vim.opt.fileencodings = "ucs-bom,utf-8,default,cp950,big5,gbk,binary" -- 🧙 如果是binary需要用:w!才可以保存
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

  -- :lua print(vim.o.swapfile)
  -- https://www.reddit.com/r/neovim/comments/qsw3lm/eli5_swap_files/
  -- swapfile 用途: 突然中斷時能復原
  vim.o.swapfile = false -- 預設 true 如果有用autocmd來自動儲檔，應該是用不太到swapfile, 但如果是用ssh來連線編輯，會建議打開，畢竟比較可能因為網路問題而突然中斷

  -- vim.opt.hlsearch = true   -- 等同 :set hls  若要關閉 :set nohls
  vim.opt.hlsearch = true -- :noh (:nohlsearch) 可以在結束搜尋時不要高亮


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
  vim.api.nvim_set_hl(0, "CursorColumn", { bg = "#3a3a3a" })
  vim.o.cursorline = true    -- 游標所在的列，整列(橫向)的會高亮
  -- vim.wo.cursorline = true -- 僅當前窗口
  -- vim.o.cursorlineopt = "both" -- both為預設, 如果用line, 那麼number(列號)不會突顏
  vim.api.nvim_set_hl(0, "CursorLine", { bg = "#2f3e54" })

  -- vim.o.tabline = "%t" -- 用這個只會有當前的檔案名稱，不會看到其它的頁籤名稱
  vim.o.tabline = "%!v:lua.get_tabline()"

  -- 如果要摺行，可以在v下用 :'<,'>fold 的方式去摺
  -- :1200,1600fold 這種方式也可以摺行 foldmethod為manual可用
  -- map: zc, zo 可以摺或展開
  -- vim.opt.foldmethod = "manual" -- 此為預設. 手動設定. 如果你在程式碼中可以自己用set改成indent或者其它的項目
  vim.opt.foldmethod = "indent"                   -- expr, syntax -- :set foldmethod=indent
  vim.opt.foldexpr = "nvim_treesitter#foldexpr()" -- 當foldmethod為expr的時候，此屬性就會有作用
  -- vim.opt.foldenable = false
  vim.opt.foldcolumn = "auto"                     -- 0-9也可以，如果有fold的清況下可以看到旁邊+-的摺顯示
  vim.opt.foldlevel = 2                           -- 💡 這個很有用！表示從第幾層後就可以摺疊，如果是0就是全部摺疊, 可以隨時用:set foldlevel?來觀察目前設定的數值

  -- filetype.add 可以等同用autocmd: https://github.com/CarsonSlovoka/nvim/blob/9f43fb676491df176ed4551a50e77e3ea704261e/lua/config/autocmd.lua#L209-L219
  vim.filetype.add({      -- :help vim.filetype
    extension = {         -- 這個是指，如果檔案的附檔名為key, 就將它的filetype設定為value
      gs = "javascript",
      jxa = "javascript", -- JavaScript for Automation (JXA) scripts on macOS
      strings = "strings",
      gotmpl = "gotmpl",
      gohtml = "gotmpl",

      ttc = "opentype",

      ttx = "ttx",

      ksy = "yaml",    -- https://github.com/kaitai-io/kaitai_struct

      tape = "elixir", -- https://github.com/charmbracelet/vhs/blob/517bcda0fa/.gitattributes#L5

      birdfont = function()
        vim.opt_local.expandtab = false
        -- return ""    -- 錯誤，可以傳nil或者不傳讓它自動判斷
        return "xml" -- filetype -- 也可以直接指定
      end,
    }
  })

  vim.g.zipPlugin_ext =
  '*.aar,*.apk,*.celzip,*.crtx,*.docm,*.docx,*.dotm,*.dotx,*.ear,*.epub,*.gcsx,*.glox,*.gqsx,*.ja,*.jar,*.kmz,*.odb,*.odc,*.odf,*.odg,*.odi,*.odm,*.odp,*.ods,*.odt,*.otc,*.otg,*.oth,*.oti,*.otp,*.ots,*.ott,*.oxt,*.potm,*.potx,*.ppam,*.ppsm,*.ppsx,*.pptm,*.pptx,*.sldx,*.thmx,*.vdw,*.war,*.whl,*.wsz,*.xap,*.xlam,*.xlsb,*.xlsm,*.xlsx,*.xltm,*.xltx,*.xpi,*.zip'

  -- :help spell
  -- 當有spell建議時，可以使用 z= 去挑可能項
  -- vim.opt.spelllang = "en_us"
  -- vim.opt.spelllang = "en_us,zh" -- 可以設定多個語言
  -- vim.opt.spell = true
  vim.opt.spelloptions = "camel" -- 駝峰式的名稱HelloWorld就會會有警告
  -- :setlocal spelloptions=     -- 使用預設
  --
  -- 也可以用:set做全域的調整
  -- :setlocal spell spelllang=en_us      -- 也可以透過這樣來設定
  -- :setlocal spell spelllang=           -- 雖然有設定spell但是沒有spelllang就相當於看不到效果
  -- :lua vim.opt.spell = false           -- 也可以將整個spell都關閉
  -- :setlocal spelloptions=noplainbuffer -- 這個也可以做到類似關閉的效果
  -- :let spelllang=en_us

  -- 檢查是否有支援真彩色
  local supports_truecolor = vim.fn.getenv("COLORTERM") == "truecolor"
  if supports_truecolor then
    -- 真色彩
    -- vim.cmd("highlight CursorColumn ctermbg=236 guibg=#3a3a3a") -- 光標所在欄顏色(預設是無)
    -- 一次設定
    vim.cmd([[
        "highlight CursorColumn ctermbg=236 guibg=#3a3a3a
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
    -- Tip: `set listchars=multispace:\ ,nbsp:␣,tab:\|\ ,trail:·` 預設tab會自動給出當前的設定
    -- tab = '🡢', -- ~~之後一定要再給一個空白，不然會錯~~ 不一定是要空白 `:help lcs-tab`
    -- tab = '🡢 ', -- Tab 符號
    tab = '| ',       -- ▸ (U+25B8), ␉, -->
    multispace = ' ', -- ---+  |---+ `set listchars=multispace:---+` 也可以不要，用: `set listchars=multispace:\ ` 這樣就表示用空白
    -- space = '•',
    trail = '·',      -- 行尾多餘的空格
    -- extends = '>', -- 行末的截斷符顯示為 >
    -- precedes = '<', -- 行首的截斷符顯示為 <
    -- eol = '⏎', -- 行結束位置
    -- nbsp = ' ', -- U+00A0   non-breaking space (通常的用法是為了保持在同一列，但此列太長，所以讓UI利用此位做出拆行的顯示)
    nbsp = '␣', -- 使用U+2423來代替
    -- ['U+3000'] = '⬜' -- CJK的全形空白, 使用 U+2B1C (White Large Square) 表示 <-- 目前不支持這種方法，只有特殊名稱可以被使用: https://stackoverflow.com/a/79432341/9935654
  }

  -- 不建議windows換終端機, 還是用cmd會比較好
  -- vim.opt.shell = "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe"
  -- vim.g.terminal_emulator='powershell'


  -- :h quickfix-window-function
  -- :h quickfixtextfunc
  -- vim.opt.qftf = function(info) end -- 要改字串才行(此字串為一個function的名稱)
  vim.o.quickfixtextfunc = "{info -> v:lua._G.qftf(info)}"

  vim.o.completeopt = "menu,menuone,noselect" -- noselect要選, 不然太自動補反而不好用

  -- conceal 分兩種
  -- 1. 隱藏: syntax match MyName /regex/ conceal 這種方式是藏起來
  -- 2. 替代: 例如使用 vim.api.nvim_buf_set_extmark 之中的可選項使用conceal = conceal_char 此時用該char(只能是1個char)取代指定的區域

  -- conceallevel
  -- ⚠️ 如果發現設定了之後, 結果不如預期，有可能是受到autocmd的影響。例如在md上請用 :RenderMarkdown disable
  -- ⚠️ conceal 也會受到已定義的syntax影響: 例如: `syntax match FloatToInt /\.\d\+/ conceal` 在xml就會無效
  --    - 可以先用 :syntax off 來將當前的syntax都清除後(注意！它是清除，所以之後還是要再做自己要的synatx)，再用syntax match設定一次自己要的內容
  -- 0 隱藏X   替代X  =====>  能真的看到原始文件內容. 也就是所有conceal的項目都無效, 包含 nvim_buf_set_extmark 的取代都無效
  -- 1 隱藏V   替代V  隱藏的位置: V保留
  -- 2 隱藏V   替代V  隱藏的位置: X不保留
  -- 3 隱藏V   替代〆 隱藏的位置: X不保留. ===> 即: 完全隱藏 (對syn-cchar的對像也隱藏, 即: nvim_buf_set_extmark 的內容無效)
  --               〆(有替代，但是所有的替代都變成了空字串(隱藏))
  -- vim.opt_local.conceallevel = 2 -- 不特別調整，避免影響到 RenderMarkdown toggle 後的設定
  -- concealcursor = nc -- (常用在help文檔)只有在visual時才會看到原本的文字，除此之外都會用conceal藏起來
  vim.opt_local.concealcursor = "" -- 空白(預設),與v都會用conceal包起來而如果是光標所在列，則會顯示原文, 至於visual下，則都會顯示原文

  vim.o.scrollback = 100000        -- Minimum is 1, maximum is 100000. only in terminal buffers. default 10000

  custom_global_options()
end

function _G.qftf(info)
  -- print(vim.inspect(info))
  local items
  local ret = {}

  -- 根據 quickfix 或 location list 獲取項目
  if info.quickfix == 1 then
    items = vim.fn.getqflist({ id = info.id, items = 0 }).items
  else
    items = vim.fn.getloclist(info.winid, { id = info.id, items = 0 }).items
  end
  -- print(vim.inspect(items))

  -- 設定文件名長度限制
  -- local limit = 31
  -- local fname_fmt1 = string.format("%%-%ds", limit) -- 左對齊
  -- local fname_fmt2 = string.format("…%%.%ds", limit - 1) -- 截斷並加…
  -- local valid_fmt = "%s | %-3d | %-2d | %s %s"
  -- local valid_fmt = "%s:%-3d:%-2d:%s %s"
  -- local valid_fmt = "%s:%s %s" -- 也可以不要顯示行，列號 -- 也可新增qf.vim去藏列行號 https://vi.stackexchange.com/a/18359/31859
  local valid_fmt = "%s:%d:%d:%s %s" -- 格式：文件名 | 行號 | 列號 | 類型 | 訊息

  -- 遍歷項目
  for i = info.start_idx, info.end_idx do
    local e = items[i]
    local fname = ""
    local str

    if e.valid == 1 then
      if e.bufnr > 0 then
        fname = vim.fn.bufname(e.bufnr)
        if fname == "" then
          fname = "[No Name]"
        else
          fname = fname:gsub("^" .. vim.env.HOME, "~") -- 將家目錄替換為 ~
        end

        -- 處理文件名長度
        -- if #fname <= limit then
        --   fname = fname_fmt1:format(fname)
        -- else
        --   fname = fname_fmt2:format(fname:sub(1 - limit))
        -- end
      end
      local lnum = e.lnum
      local col = e.col
      local qtype = e.type == "" and "" or " " .. e.type:sub(1, 1):upper() -- 錯誤類型
      -- str = valid_fmt:format(fname, qtype, e.text) -- 不顯示行，列號
      str = valid_fmt:format(fname, lnum, col, qtype, e.text)
    else
      str = e.text -- 無效項目直接顯示文本
    end
    table.insert(ret, str)
  end

  return ret
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
