local utils = require("utils.utils")

-- require("dap").adapters.custome = {
--   type = 'executable',
--   command = "echo", -- 找一個不重要的指令, 為了通過require("dap")而已 -- 這個工具在 Linux / macOS / Windows shell 都有
-- }

-- -@type vim.SystemCompleted r

---@param exe_name string
---@param param table
---@param ok_lines table 成功後的前導輸出文字
---@param opts table
local function show_run_result(exe_name, param, ok_lines, opts)
  if vim.fn.executable(exe_name) == 0 then
    return
  end
  local r = vim.system({ exe_name, unpack(param) }):wait()
  if r.code ~= 0 then
    vim.notify(string.format("❌ [%s] err code: %d err msg: %s", exe_name, r.code, r.stderr),
      vim.log.levels.WARN)
    return
  end

  vim.cmd("tabnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
  -- local text = {
  --   "file: " .. fontpath,
  --   "result: ",
  --   " ",
  --   unpack(vim.split(r.stdout, "\n"))
  -- }
  local lines = ok_lines
  for _, line in ipairs({
    '',
    string.format("cmd: %s %s", exe_name, table.concat(param, " ")),
    '',
  }) do
    table.insert(lines, line)
  end

  table.insert(lines, "stdout:")
  for _, line in ipairs(vim.split(r.stdout, "\n")) do
    table.insert(lines, line)
  end

  table.insert(lines, "stderr:") -- 有些訊息也會寫在這邊，所以也有納入
  for _, line in ipairs(vim.split(r.stderr, "\n")) do
    table.insert(lines, line)
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  for _, cmd in ipairs(opts.cmds) do
    -- vim.cmd([[call matchadd('@label', '\v^\w*:')]]) -- 預設的作用域是當前的window, 不過可以透過 :call clearmatches() 來全部清除
    -- vim.cmd([[call matchadd('@label', '\v\w*:', 10, -1, {'window': 1013})]]) -- 可以透過這種方式指定成其它的window
    vim.cmd(cmd)
  end
  vim.cmd(string.format([[call matchadd('MiniIconsOrange', '%s')]], exe_name))
  vim.cmd("file " .. exe_name) -- 設定為有意義的名稱，不要使用No Name
end

local function program_otparser()
  -- 確保執行檔存在
  -- otparser.exe: https://github.com/CarsonSlovoka/otparser.nvim/blob/28c84b9320725582290a56d7c4af06c998d5495a/main.go#L59-L79
  if vim.fn.executable("otparser") == 0 then
    return
  end

  local fontPath = vim.fn.expand("%:p")
  local fontname = "♻️" .. vim.fn.expand("%:t") -- 為了盡量避免與當前的buf同名，前面加上♻️ (如果要完全避免誤判，要額外記錄buffer id)
  -- :echo expand("%:t") -- xxx.lua
  -- :echo expand("%:e") -- lua

  local exists, buf = utils.api.get_buf(vim.fn.getcwd() .. "/" .. fontname)
  if not exists then
    -- vim.api.nvim_command("vsplit enew")
    vim.api.nvim_command("enew")
    buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf }) -- 設定為nofile就已經是不能編輯，但這只是代表可以編輯但是無法保存當前的檔案，但是可以用:w ~/other.txt 的方式來另儲
    -- vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf }) -- 不在buffer中記錄

    -- vim.api.nvim_buf_set_name(buf, bufName) -- 注意！要給檔名就好
    vim.api.nvim_buf_set_name(buf, fontname) -- 如果name是No Name時，使用vimgrep會遇到錯誤: E499: Empty file name for '%' or '#', only works with ":p:h" 因此為了能使vimgrep還是能有一個檔案的參照，需要設定其名稱
    -- note: 使用nofile時再使用nvim_buf_set_name仍然有效，它會限制此檔案不能被保存
    -- note: nvim_buf_set_name 的文件名稱，是在當前的工作目錄下建立此名稱
    -- note: 如果buffer已經存在，會得到錯誤: Vim:E95: Buffer with this name already exists

    vim.bo.filetype = "opentype"
  elseif buf then
    vim.api.nvim_set_current_buf(buf)
  end

  -- local output = vim.fn.system("otparser " .. vim.fn.shellescape(curFile)) -- 也行，但是建議用vim.system更明確
  --- @type table
  local r = vim.system({ "otparser", fontPath }):wait()
  if r.code ~= 0 then -- 用回傳的code來當是否有錯的基準
    vim.notify(string.format("❌ otparser error. err code: %d %s", r.code, r.stderr), vim.log.levels.WARN)
    return
  end

  if buf then
    -- -- vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(r.stdout, "\n")) -- 是可以直接寫在原本的地方，但是如果對原始的二進位有興趣，直接取代就不太好，所以另外開一個buffer寫
    -- -- vim.api.nvim_buf_set_lines(0, 0, -1, false, { "hello", "world" })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(r.stdout, "\n"))

    -- vim.api.nvim_set_option_value("modifiable", false, { buf = buf }) -- readonly, 會直接連Insert都無法使用. 記得要放在nvim_buf_set_lines之後
  end

  if vim.fn.executable("xxd") == 0 then
    return
  end

  -- 再建立一個新的buf來放xxd的結果
  -- vim.cmd("vnew")
  vim.cmd("vnew ++bin") -- 要補上++bin才可以讓%!xxd -r時得到原始的內容
  vim.cmd("wincmd L")   -- 放到最右邊

  -- { text = "head | 436 | 54" },
  -- lua print(string.format("%x", 436)) -- 起始從00開始
  -- lua print(string.format("%x", 436+54-1)) -- 不包含最後一個
  buf = vim.api.nvim_get_current_buf()
  local helps = {
    'Tag  | Offset | Length',
    'head | 436    | 54',
    '436+',
    'V53+',
    '',
    -- 可行，但是start, end輸入會被影響
    -- 'let start = printf("%08x", 436)',
    -- 'let end = printf("%08x", 436+53)',
    -- "let cmd = printf('/%s/,/%s/yank', start, end)",
    'let start = 436',
    'let end = 436+53',
    "let cmd = printf('/%s/,/%s/yank', printf('%08x', start), printf('%08x', end))",
    ':execute cmd',
    ':tabnew ++bin',
    ':pu=@"',
    '',
    '',
    ':lua print(string.format("%x", 436))',
    ':lua print(string.format("%x", 436+53))',
    ':/1b4/,/1e9/yank',
    '',
    '',
    [[:call matchadd("Yellow", '\v^\d+.*')]], -- 需要\v才可以用^ -- ⚠️ 在vim上用單引號，雙引號會不行
    [[:let m = matchadd("Blue", '\v^\d+')]],
    ':call matchdelete(m)',
    '',
    '',
    "'<,'>Highlight YellowBold *",
    ":copen 5",
    "%!xxd -r",
    "54GoSelect 437",
    ' ', -- 這個用來放xxd的內容
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, helps)
  local ns_id = vim.api.nvim_create_namespace("hightlight_comment")
  vim.hl.range(buf, ns_id, "Comment", { 0, 0 }, { #helps, -1 }) -- ns_id不可以用0，一定要建立
  vim.cmd("normal! G")

  -- vim.cmd("r !xxd -c 1 " .. fontPath) -- 這個會有:mes的訊息，如果不想要，可以用vim.fn.systemlist來代替
  local output = vim.fn.systemlist("xxd -c 1 " .. fontPath)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row, row, false, output)

  -- vim.fn.setloclist(0, {
  vim.fn.setqflist({ -- 這有可能在其它的buffer也需要參考，所以用qflist會比較好點
    { text = "vnew ++bin" },
    { text = "r !xxd -c 1 " .. fontPath },
    { text = "r !xxd -c 16 " .. fontPath },
    { text = "%!xxd -r" },
  }, 'a')

  vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
end

local function program_convert2ttx()
  if vim.fn.executable("python") == 0 then
    return
  end

  local fontpath = vim.fn.expand("%:p") -- 獲取當前檔案的完整路徑

  -- 因為已經是確定filetype是自定的opentype所以就不做附檔名的判斷了
  -- local ext = vim.fn.expand("%:e"):lower() -- 獲取副檔名（小寫）
  -- -- 檢查是否為 ttf 或 otf 檔案
  -- if ext ~= "ttf" and ext ~= "otf" then
  --   return
  -- end

  local python_code = string.format([[
import io
import sys

from fontTools.misc.xmlWriter import XMLWriter
from fontTools.ttLib import TTFont

font = TTFont("%s")

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
writer = XMLWriter(sys.stdout, newlinestr="\n")
font._saveXML(writer)
]], fontpath)

  local r = vim.system({ "python3", "-c", python_code }):wait()
  if r.code ~= 0 then
    vim.notify(string.format("❌ fontTools.TTFont.saveXML error. err code: %d %s", r.code, r.stderr),
      vim.log.levels.WARN)
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_set_option_value("filetype", "ttx", { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(r.stdout, "\n"))
  return ""
end

---@param fontpath string opentype fontpath
---@param glyph_indice string `"[]"`, "[[start, end]...]" '[["737", "737"], ["814", "939"]]'
---@param show_outline boolean draw outline (kgs)
---@param options {mimetype: string, precision: number, width: number, height: number}
---@return table
local function get_show_glyph_py_cmd(fontpath, glyph_indice, show_outline, options)
  local cur_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
  local blocks_txt_path = vim.fn.fnamemodify(cur_dir .. "/../../ucd/db/Blocks.txt", ":p")
  if not vim.fn.filereadable(blocks_txt_path) == 1 then
    error("Blocks.txt not exists: " .. blocks_txt_path)
  end

  -- local script = require("py").read_script("show_glyph.py")
  -- local cmd = { "python3", "-c", script, -- 👈 這種方式可行(也能適用arg傳遞, 但是如果用nvim_input一個一個打出來就會有問題)，且既然已經有了實體檔案，就不需要如此
  local script_path = require("py").get_script_path("show_glyph.py")

  local cmd         = { "python3", script_path,
    fontpath,
    "--glyph_indice", glyph_indice,
    -- show_outline and "--show_outline" or "", -- 這樣會有一個空的參數，會抱錯
    "--blocks_txt_path", blocks_txt_path,
    "--mimetype", options["mimetype"] or "image/svg+xml",
    "--precision", 1,
    "-w", options["width"] or 48,
    "--height", options["height"] or 48,
  }
  if show_outline then
    table.insert(cmd, "--show_outline")
  end
  return cmd
end


--- 使用python -c 以及py樣版的方式參考: `git show d4631c61 -L218,340:opentype.lua -L,:../../py/show_glyph.py`
--- @param include_outline boolean
local function program_show_glyph(include_outline)
  if vim.fn.executable("python") == 0 then
    return
  end

  local fontpath = vim.fn.expand("%:p")
  local font_basename = vim.fn.expand("%:t")

  local cmd = get_show_glyph_py_cmd(fontpath, '"[]"', include_outline or false, {})
  vim.fn.setqflist({ { text = table.concat(cmd, " ") }, }, 'a') -- 輸出執行的cmd, 可用來除錯
  local r = vim.system(cmd):wait()
  if r.code ~= 0 then
    vim.notify(string.format("❌ program_show_glyph err code: %d %s", r.code, r.stderr),
      vim.log.levels.WARN)
    return
  end
  vim.cmd("tabnew | setlocal buftype=nofile bufhidden=wipe")
  vim.cmd("file glyph: " .. font_basename)
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_set_option_value("filetype", "csv", { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(r.stdout, "\n"))
  vim.fn.setqflist({
    { text = [['<,'>!csvsql --query "SELECT * FROM stdin LIMIT 5;"                           📝 直接在原檔案異動]] },
    { text = [[:%w !csvsql --query "SELECT * FROM stdin LIMIT 5;"                            📝 最多5筆]] },
    { text = [[:%w !csvsql --query "SELECT * FROM stdin GROUP BY block;"                     📝 print顯示結果]] },
    { text = [['<,'>w !csvsql --query "SELECT * FROM stdin GROUP BY block"                   📝 同上 (range模式)]] },
    { text = [[:%w !csvsql --query "SELECT * FROM stdin GROUP BY block;" > /tmp/temp.csv     📝 將結果另儲到其它地方]] },
    { text = [['<,'>w !csvsql --query "SELECT * FROM stdin GROUP BY block;" >> /tmp/temp.csv 📝 附加到檔案之後]] },
    { text = [['<,'>w !csvsql --no-header-row --query "SELECT * FROM stdin GROUP BY f;"      📝 --no-header-row範例, 自動欄位:{a, b, ...}]] },
    { text = [['<,'>w !csvsql --no-header-row --query "$(cat /tmp/query.sql)"                📝 (no header)利用外部的sql檔案來查詢]] },
    { text = [[%w !csvsql --query "$(cat /tmp/query.sql)"                                    📝 利用外部的sql檔案來查詢]] },
    { text = 'cexpr [] 📝 clear quickfix list' },
  }, 'a')
  -- :help wincmd
  -- vim.cmd("vert botright split | edit /tmp/query.sql") -- 垂直分割，且將新的視窗放到右邊，並且focus過去
  vim.cmd("vert botright split | enew | setlocal buftype=nofile noswapfile") -- 開一個tmp視窗
  local win_id_sql = vim.api.nvim_get_current_win()
  vim.cmd("set filetype=sql")


  -- 直接在暫存器寫上實用的指令
  -- vim.cmd([[let @j="'<,'>join | y s | let sql = @s | u"]])
  -- vim.cmd([[let @j="vip:join | y s | let sql = @s | u"]]) -- 更方便, 透過vip來選取, 但是只是把指令貼到command非真的巨集
  -- vim.cmd([[let @j="vip:join | y s | :let sql=@s | u \<CR>"]]) -- 最後面會有^@東西跑出來
  -- vim.cmd([[let @h="vip:join | y s | :let sql=substitute(@s, '\\0', '', '') | u \<CR>"]])  -- 這也沒用還是有^@
  vim.cmd([[let @j="vip:join | y s | :let sql=@s[:-2] | u \<CR>"]]) -- 直接將最後一個字符移除, 即從導數第二個字符開始
  vim.cmd([[let @r="vip:join | y s | :let sql=@s[:-2] | u"]])       -- 不CR，如果要改變數的名稱，會比較方便
  -- NOTE: 不要用join!不然列與列中的間距會被移掉(空白)
  -- NOTE: 目前這樣會有一個瑕疵，如果原本已經只有一列，則會異常


  -- vim.cmd([[let @a="'<,'>!csvsql --query '  '"]]) -- 可以直接將' '裡面的內容用某一個變數取代
  -- vim.cmd('let sql=""')
  -- vim.cmd([[let @a=printf("%!csvsql --query '%s'", sql)]]) -- ❌ 需要初始化sql變數，而且它不會隨著sql變數的值改變，首次判斷完之後就是固定的常數
  -- vim.cmd([[let @a=printf("%%!csvsql --query '%s'", "g:sql")]]) -- ❌ 需要初始化sql變數，而且它不會隨著sql變數的值改變，首次判斷完之後就是固定的常數
  vim.cmd([[let @a=':exe printf("%%!csvsql --query %s%s%s", "\"", g:sql, "\"")']])

  -- 以下兩種也是一開始完之後就是常數
  -- vim.cmd([[let @b=printf("'<,'>!csvsql --query '%s'", @j)]])
  -- vim.cmd([[let @b=printf("'<,'>!csvsql --query '%s'", sql)]])
  vim.cmd([[let @b=':exe printf("%s<,%s>!csvsql --query %s%s%s", "\x27", "\x27", "\"", g:sql, "\"")']]) -- 注意！因為:exe不能接受range, 所要可以先選之後取消，再用此命令，還是可以曉得range

  -- vim.cmd([[let saveAs=printf("%w !csvsql --query '%s' > /tmp/my.csv", sql)]]) -- ❌ 這是常數
  vim.cmd([[let saveAs=':exe printf("%%w !csvsql --query %s%s%s > /tmp/my.csv", "\x22", g:sql, "\x22")']])
  vim.cmd(
    [[let saveAsAndOpen=':exe printf("%%w !csvsql --query %s%s%s > /tmp/my.csv", "\x22", g:sql, "\x22") | tabnew | e /tmp/my.csv']])

  vim.cmd([[let preview=':exe printf("%%w !csvsql --query %s%s%s", "\x22", g:sql, "\x22")']])
  -- vim.cmd( [[let previewRedirZ=':redir @+ | exe printf("%%w !csvsql --query %s%s%s", "\x22", g:sql, "\x22") | redir END']]) -- ❌ 這是錯的，會崩潰
  vim.cmd([[
  let previewRedirZ=':let @z=execute(printf("%%w !csvsql --query %s%s%s", "\x22", g:sql, "\x22"))'
  ]]) -- 可將stdout的內容直接放到"z 而不需要透過redir來幫忙
  -- substitute(g:sql, "%", "%%", "g") -- 這個也沒辦法解決%的問題

  vim.cmd([[let @c="%y | tabnew | setlocal buftype=nofile noswapfile filetype=csv | 0pu"]])
  vim.cmd([[let clone=@c]])
  -- '<,'>!csvsql --query '@j'
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    [[-- 對選取內容使用`@j`, 之後可用`@a`, `@b`, `saveAs`, `saveAsAndOpen`等變數來輔助]],
    [[-- j  '<,'>join | y s | let sql = @s | u     -- 複製指令成一列給s，也設定sql和s相同, 用於--query之後貼上此內容]],
    "",
    [[-- a  %!csvsql --query ""      👈 在原buffer異動]],
    [[-- b  '<,'>!csvsql --query ""  👈 在原buffer異動]],
    [[--  在`%`或'<,'>之後加上w可以變成print的效果 ]],
    [[--  有w時就是一種輸出的導向(預設是stdout, 也可以指定檔案) ]],
    "",
    "-- :NewTmp | set filetype=csv",
    "",
    "-- saveAs",
    -- [[-- saveAs  %w!csvsql --query '' > /tmp/my.csv     👈 另儲新檔]], -- ❌ %w!csvsql之間要有空格！ 且%w! csvsql也是錯誤，要是%w !csvsql
    [[-- saveAs  %w !csvsql --query '' > /tmp/my.csv     👈 另儲新檔]],
    "",
    "其它參考",
    [[-- csvsql --query 'SELECT * FROM temp WHERE block LIKE "Math%"' /tmp/temp.csv"]],
    "",
    [[-- c  %y | tabnew | setlocal buftype=nofile noswapfile filetype=csv | 0pu  -- 複製當前的內容貼在新的頁籤]],
    "",
    "",
    "SELECT * FROM stdin LIMIT 5",
    ";",
    "",
    "",
    "SELECT *",
    "FROM stdin",
    "GROUP BY block",
    "ORDER BY gid ASC",
    ";",
    -- 不能這樣，每列中不可以有換行符
    -- [[
    -- SELECT *
    -- FROM stdin;
    -- ]]
    "",
    "-- 🟧 查看block共有哪些",
    "",
    "SELECT block",
    "FROM stdin",
    "GROUP BY block",
    ";",
    "",
    "-- 🟧 找指定的block內容",
    "",
    "SELECT *",
    "FROM stdin",
    "WHERE isUnicode=1",
    "AND block == 'Basic Latin'",
    "OR block == 'Mathematical Operators'",
    "OR block IN ('Enclosed Alphanumerics', 'Number Forms')",
    "-- OR unicode_ch IN ('我')",
    "",
    "-- %不能用，會衝突",
    "-- OR block LIKE Math%",
    "-- 字串用單引號'，因為previewRedirZ中用的是雙引號",
    ";",
    "",
    "",
    "-- 🟧",
    "",
  })

  -- vim.cmd("w") -- 如此不需要真的寫入檔案
  vim.cmd("copen 5 | cbo") -- 開始後移動到底部
  vim.cmd("wincmd J")      -- move qflist at the very bottom


  vim.api.nvim_set_current_win(win_id_sql) -- focus sql的視窗

  return ""
end



local function program_show_glyph_with_kitty()
  if vim.fn.executable("python") == 0 then
    return
  end

  local font_basename = vim.fn.expand("%:t")

  local input = vim.fn.input("glyph_index (ex: 1..200 500..600)") -- 一開始給一個空白，避免str.split分離錯
  local ranges = {}
  local groups = vim.split(input or "", " ")
  for _, g in ipairs(groups) do
    local start, finish = g:match("(%d+)%.%.(%d+)") -- 不要取start, end (end是保留字)
    if start and finish then
      table.insert(ranges, { start, finish })
    end
  end
  local json_str_glyph_index = vim.fn.json_encode(ranges)

  local fontpath = vim.fn.expand("%:p")
  -- local file, err = io.open("/tmp/show_glyph", "w")
  -- if not file then error(err) end
  -- file:write("hello")
  -- file:close()

  local input_wxh = vim.fn.input("width x height (ex: 48x48, 96x96, ...)")
  local width, height = input_wxh:match("(%d+)x(%d+)")

  local cmd = get_show_glyph_py_cmd(fontpath, string.format("'%s'", json_str_glyph_index), true,
    { mimetype = "kgp", width = width or 48, height = height or 48, precision = 1 })

  vim.cmd("tabnew | setlocal buftype=nofile | term")
  -- 以下設定了關閉了該buffer還是在，暫時先不處理
  -- vim.cmd("tabnew | setlocal buftype=nofile bufhidden=wipe | term")
  -- vim.cmd("setlocal bufhidden=wipe")

  vim.cmd("file glyph: " .. font_basename)
  vim.cmd("startinsert")
  -- vim.api.nvim_input([[kitty --hold python /tmp/show_glyph <CR>]])
  vim.api.nvim_input(string.format([[kitty --hold %s <CR>]], table.concat(cmd, " "))) -- hold可以讓終端機保持，不會執行完腳本後就關閉
  vim.fn.setqflist({
    { text = ":r! python /tmp/show_glyph                       📝 可以得到輸出的結果", },
    { text = ":r! python /tmp/show_glyph > /tmp/show_glyph.csv 📝 另儲新檔", },
    { text = ":!kitty --hold cat /tmp/show_glyph.csv &         📝 接著在kitty使用cat也可以看到圖片", },
  }, 'a')
end

local function program_font_validator()
  if vim.fn.executable("font-validator") == 0 then
    vim.notify(
      "font-validator not found.\n" ..
      "wget https://github.com/HinTak/Font-Validator/releases/download/FontVal-2.1.6/FontVal-2.1.6-ubuntu-18.04-x64.tgz\n" ..
      "tar -xvzf FontVal-2.1.6-ubuntu-18.04-x64.tgz\n" ..
      'sudo ln -siv "$HOME/FontVal-2.1.6-ubuntu-18.04-x64/FontValidator-ubuntu-18.04-x64" /usr/bin/font-validator'
      ,
      vim.log.levels.WARN
    )
    return
  end

  local fontPath = vim.fn.expand("%:p")
  local fontname = "♻️" .. vim.fn.expand("%:t")
  local exists, buf = utils.api.get_buf(vim.fn.getcwd() .. "/" .. fontname)
  if not exists then
    vim.api.nvim_command("enew")
    buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
    vim.api.nvim_buf_set_name(buf, fontname)
    -- vim.bo.filetype = "opentype"
  elseif buf then
    vim.api.nvim_set_current_buf(buf)
  end

  local r = vim.system({ "font-validator", "-file", fontPath, "-stdout" }):wait()
  -- if r.code ~= 0 then -- 它回的可能都不會是0, 所以乾脆不判斷
  --   vim.notify(string.format("❌ font-validator error. err code: %d %s", r.code, r.stderr), vim.log.levels.WARN)
  --   return
  -- end

  if buf then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(r.stdout, "\n"))
  end
end

local function program_ots_sanitize()
  local fontpath = vim.fn.expand("%:p")
  local ok_lines = {
    "file: " .. fontpath,
  }
  show_run_result("ots-sanitize", { fontpath },
    ok_lines,
    {
      cmds = {
        [[call matchadd('@label', '\v^\w*:')]]
      }
    }
  )
  return ""
end

local function program_ots_idempotent()
  local fontpath = vim.fn.expand("%:p")
  local ok_lines = {
    "file: " .. fontpath,
  }
  show_run_result("ots-idempotent", { fontpath },
    ok_lines,
    {
      cmds = {
        [[call matchadd('@label', '\v^\w*:')]]
      }
    }
  )
end

local function program_ots_validator()
  local fontpath = vim.fn.expand("%:p")
  local ok_lines = {
    "file: " .. fontpath,
  }
  show_run_result("ots-validator-checker", { fontpath },
    ok_lines,
    {
      cmds = {
        [[call matchadd('@label', '\v^\w*:')]]
      }
    }
  )
end

local function program_ots_side_by_side()
  local fontpath = vim.fn.expand("%:p")
  local ok_lines = {
    "file: " .. fontpath,
  }
  show_run_result("ots-side-by-side", { fontpath },
    ok_lines,
    {
      cmds = {
        [[call matchadd('@label', '\v^\w*:')]]
      }
    }
  )
end

local function program_ots_perf()
  local fontpath = vim.fn.expand("%:p")
  local ok_lines = {
    "file: " .. fontpath,
  }
  show_run_result("ots-perf", { fontpath },
    ok_lines,
    {
      cmds = {
        [[call matchadd('@label', '\v^\w*:')]]
      }
    }
  )
end

local function program_ots_batch_run()
  local org_tab = vim.api.nvim_get_current_tabpage()
  program_ots_sanitize()
  vim.api.nvim_set_current_tabpage(org_tab)
  program_ots_idempotent()
  vim.api.nvim_set_current_tabpage(org_tab)
  program_ots_validator()
  vim.api.nvim_set_current_tabpage(org_tab)
end

require("dap").configurations.opentype = {
  {
    name = "otparser",
    type = "custom",
    request = "launch",
    program = program_otparser,
  },
  {
    name = "convert to fontTools:ttx format",
    type = "custom",
    request = "launch",
    program = program_convert2ttx,
  },
  {
    name = "show glyph",
    type = "custom",
    request = "launch",
    program = program_show_glyph,
  },
  {
    name = "show glyph (include outline)",
    type = "custom",
    request = "launch",
    program = function()
      program_show_glyph(true)
    end,
  },
  {
    name = "show glyph (with kitty)",
    type = "custom",
    request = "launch",
    program = program_show_glyph_with_kitty,
  },
  {
    name = "font-validator",
    type = "custom",
    request = "launch",
    program = program_font_validator,
  },
  {
    name = "ots-sanitize 字型驗證器",
    type = "custom",
    request = "launch",
    program = program_ots_sanitize,
  },
  {
    name = "ots-idempotent 字型轉碼穩定性檢查器",
    type = "custom",
    request = "launch",
    program = program_ots_idempotent,
  },
  {
    name = "ots-validator-checker 惡意字型驗證測試工具",
    type = "custom",
    request = "launch",
    program = program_ots_validator,
  },
  {
    name = "ots-side-by-side 渲染比對工具",
    type = "custom",
    request = "launch",
    program = program_ots_side_by_side,
  },
  {
    name = "ots-perf 轉碼效能測試工具",
    type = "custom",
    request = "launch",
    program = program_ots_perf,
  },
  {
    name = "ots batch run: {sanitize, idempotent, validator}",
    type = "custom",
    request = "launch",
    program = program_ots_batch_run,
  },
}
