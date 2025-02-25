local path = require("utils.path")
local cmdUtils = require("utils.cmd")
local osUtils = require("utils.os")

local commands = {}

local function openCurrentDirWithFoot()
  local current_file_path = vim.fn.expand("%:p:h") -- 獲取當前文件所在的目錄
  if current_file_path ~= "" then
    -- 調用 'foot' 來執行
    vim.loop.spawn("foot", {
      args = { "--working-directory", current_file_path } -- 使用 foot 的 `--working-directory` 選項
    }, function(code, signal)
      if code ~= 0 then
        vim.schedule(function()
          print("Foot 打開失敗：錯誤代碼:", code, "信號:", signal)
        end)
      end
    end)
  else
    print("無法獲取當前文件所在的目錄")
  end
end

function commands.setup()
  vim.api.nvim_create_user_command(
  -- 'foot', -- Invalid command name (must start with uppercase): 'foot'
    "Foot",
    openCurrentDirWithFoot, -- 執行的函數
    { desc = "使用 Foot 開啟當前文件所在的目錄" } -- 描述信息（可選）
  )


  vim.api.nvim_create_user_command(
    "Cmd",
    function(args)
      local direction = "sp"
      if #args.fargs > 0 and args.fargs[1] == "v" then
        direction = "vsp"
      end

      -- 獲取當前文件
      local filepath = vim.fn.expand('%:p')     -- 當前文件的完整路徑
      if filepath == '' then
        print("No file in the current buffer!") -- 提示用戶當前緩存沒文件
        return
      end
      local cwd
      if vim.fn.isdirectory(filepath) == 1 then
        cwd = filepath                           -- 如果是目錄，直接設為 cwd
      else
        cwd = vim.fn.fnamemodify(filepath, ":h") -- 獲取檔案的目錄作為 cwd
      end
      vim.cmd(string.format('cd %s | %s | terminal', cwd, direction))
      vim.cmd('startinsert') -- 自動切換到 Insert 模式
    end,
    {
      nargs = "?",
      complete = function()
        return {
          "v"
        }
      end,
      desc = "在當前路徑開啟terminal"
    }
  )

  vim.api.nvim_create_user_command(
    "Edit",
    function()
      local selected_text = require("utils.range").get_selected_text()
      if #selected_text == 0 then
        return
      end
      vim.cmd("edit " .. selected_text)
    end,
    {
      range = true,
      desc = "edit",
    }
  )
  vim.api.nvim_create_user_command(
    "Help",
    function()
      local selected_text = require("utils.range").get_selected_text()
      if #selected_text == 0 then
        return
      end
      vim.cmd("help " .. selected_text)
    end,
    {
      range = true,
      desc = "edit",
    }
  )

  vim.api.nvim_create_user_command("SavePNG",
    function(args)
      local outputPath = ""
      if #args.fargs > 0 then
        outputPath = args.fargs[1]
      else
        local timestamp = os.date("%Y-%m-%d_%H-%M-%S")
        local saveDir = vim.fn.expand("%:p:h")
        outputPath = path.join(saveDir, timestamp .. ".png")
      end

      -- 確保輸出的目錄存在
      local outputDir = vim.fn.fnamemodify(outputPath, ":h")
      if vim.fn.isdirectory(outputDir) == 0 then
        vim.fn.mkdir(outputDir, "p")
      end

      -- 使用 ws-paste 來保存
      local cmd = 'wl-paste --type image/png > "' .. outputPath .. '"'
      local result = os.execute(cmd)

      if result == 0 then
        print("圖片保存成功: " .. outputPath)
      else
        print("圖片保存失敗")
      end
    end,
    {
      nargs = "?",
      desc = "保存剪貼簿的圖片(依賴ws-paste)"
    }
  )

  vim.api.nvim_create_user_command("SaveWebp", function(args)
    local outputPath = ""
    -- print(vim.inspect(args))
    if #args.fargs > 0 then
      outputPath = args.fargs[1]
    else
      -- 根據時間戳生成輸出檔案名稱
      local timestamp = os.date("%Y-%m-%d_%H-%M-%S")
      local saveDir = vim.fn.expand("%:p:h")
      outputPath = path.join(saveDir, timestamp .. ".webp")
    end

    -- 設定預設品質
    local quality = 11
    if #args.fargs > 1 then
      local q = tonumber(vim.split(args.fargs[2], "　")[1]) -- 用U+3000全形空白來拆開取得實際要的數值
      if q then
        quality = q
      end
    end

    -- print(outputPath)
    -- print(quality)
    -- if 1 then return end

    -- 確保輸出目錄存在
    local outputDir = vim.fn.fnamemodify(outputPath, ":h")
    if vim.fn.isdirectory(outputDir) == 0 then
      vim.fn.mkdir(outputDir, "p")
    end

    -- 直接透過管道，將剪貼簿的 PNG 內容透過 cwebp 轉換成 Webp 並保存
    local cmd = string.format('wl-paste --type image/png | cwebp -q %d -o "%s" -- -', quality, outputPath)
    local result = os.execute(cmd)
    if result == 0 then
      print("Webp 圖片保存成功: " .. vim.fn.fnamemodify(outputPath, ":p"))
    else
      print("轉換為 Webp 圖片失敗")
    end
  end, {
    nargs = "*",
    complete = function(
        argLead,                              -- 當你打上某些關鍵字後使用tab時，它會記錄你的關鍵字
        cmdLine,                              -- 當前cmdLine上所有字串內容
        cursorPos                             -- cursor在cmdLine上的位置(欄)
    )
      local parts = vim.split(cmdLine, "%s+") -- %s 匹配空白、製表符等
      local argc = #parts - 1                 -- 減去命令本身

      if argc == 1 then
        -- 種類可以是file, buffer, command, help, tag等
        return vim.fn.getcompletion(argLead, "file") -- 出現檔案自動補全，清單讓使用者選來表達輸出的路徑
      elseif argc == 2 then
        -- return { 11, 50, 75, 100 } -- 只能是字串, 非字串補全清單不會出來
        -- return { "11", "50", "75", "100" } -- 這個可行，但是使用者可能不曉得這個代表quality

        -- 以下只能在insert模式下用
        -- return vim.fn.complete(cursorPos, {
        --   { word = '50', info = '低質量 (50%)' },
        --   { word = '75', info = '中等質量 (75%)' },
        --   { word = '90', info = '高質量 (90%)' },
        -- })

        -- 這個方法也沒用
        -- vim.ui.select(
        --   { '50', '75', '90', '100' }, -- 此為用數字選擇後所對應的真實選擇內容
        --   {
        --     prompt = '選擇圖片質量:',
        --     format_item = function(item) -- item為真實選擇內容
        --       local qualityMap = {
        --         ['50'] = '低質量 - 檔案小，但畫質較差',
        --         ['75'] = '中等質量 - 平衡檔案大小和畫質',
        --         ['90'] = '高質量 - 接近原始畫質',
        --       }
        --       return item .. '% - ' .. qualityMap[item]
        --     end
        --   }, function(choice) -- choice為真實選擇內容
        --     if choice then
        --       return { choice }
        --     end
        --   end)

        -- 可以這樣，但是fargs數量也會影響，要自己去解args的參數, 為了不增加麻煩, 我們使用全形空白U+3000來當成分隔符
        return {
          "11　低質量(11%)(預設)",
          "50　中等質量(75%)",
          "75　一般webp所用的預設值",
        }
      end
    end,
    desc = "保存剪貼簿中的圖片，儲成webp格式"
  })

  vim.api.nvim_create_user_command("AddLocalHelp",
    function(args)
      -- :help add-local-help
      -- # :set runtimepath+=/path/to/your/ -- 注意your下應該會有一個doc的目錄
      -- vim.opt.runtimepath:append('/path/to/your/') -- 你也可以選擇在init進行永久添加的設定
      -- :helptags ALL -- 如果你的tags還沒有生成，可以直接設定為ALL, 它會自己將所有runtimepath底下的doc都去生成tags，就不需要各別設定
      --
      -- :!mkdir -p ~/.local/share/nvim/site/doc # 注意，在doc底下在建立子目錄，是找不到的
      -- :!cp my-plutin/my-plugin-doc.txt ~/.local/share/nvim/site/doc/
      -- :helptags ~/.local/share/nvim/site/doc/
      local localHelpDir = vim.fn.fnamemodify("~/.local/share/nvim/site/doc/", ":p")

      -- 確保目錄存在
      vim.fn.mkdir(localHelpDir, "p")

      for _, txtPath in ipairs(args.fargs) do
        if vim.fn.fnamemodify(txtPath, ":e") ~= "txt" then
          vim.notify("[skip file. ext ~= txt]: " .. txtPath, vim.log.levels.INFO)
        else
          local destPath = vim.fn.fnamemodify(localHelpDir .. vim.fn.fnamemodify(txtPath, ":t"), ":p")
          os.execute("cp -v " .. txtPath .. " " .. destPath)
          vim.cmd("helptags " .. localHelpDir)
          vim.notify("[copied file]: " .. txtPath .. " -> " .. destPath, vim.log.levels.INFO)
        end
      end
    end,
    {
      nargs = "+",
      complete = function(argLead, _, _)
        -- 原始的文件和目錄列表
        local all_files = vim.fn.getcompletion(argLead, "file")

        -- 僅篩選出 .txt 文件
        local txt_files = vim.tbl_filter(function(item)
          return item:match("%.txt$")
        end, all_files)

        return txt_files
      end,
      desc = "添加自定義的vim help"
    }
  )


  vim.api.nvim_create_user_command("PrintBOM",
    function(args)
      if args.fargs[1] == "-h" then
        cmdUtils.showHelpAtQuickFix({
          -- https://neovim.io/doc/user/mbyte.html
          ':set fileencoding=utf-8        -- 32 bit UTF-8 encoded Unicode (ISO/IEC 10646-1)',
          ':set fileencoding=utf-16       -- ucs-2 extended with double-words for more characters',
          ':set fileencoding=utf-16le     -- like utf-16, little endian',
          ':set fileencoding=unicode      -- same as ucs-2',
          ':set fileencoding=ucs2be       -- same as ucs-2 (big endian)',
          ':set fileencoding=ucs-2be      -- same as ucs-2 (big endian)',
          ':set fileencoding=ucs-4        -- 32 bit UCS-4 encoded Unicode (ISO/IEC 10646-1)',
          ':set fileencoding=ucs-4le      -- like ucs-4, little endian',
          ':set fileencoding=utf-32       -- same as ucs-4',
          ':set fileencoding=utf-32le     -- same as ucs-4le',
          ':set fileencoding=ucs-4be      -- same as ucs-4 (big endian)',
          ':set bomb',
          ':set nobomb',
        })
        return
      end
      local file = io.open(vim.fn.expand("%"), "rb") -- 用二進位方式來開始當前的文件
      if not file then
        return
      end

      local bytes = file:read(4) -- 看有多少byte就盡可能的讀取 -- 如果長度不夠不會出錯，會得到nil而已
      file:close()

      if bytes then
        -- 注意! UTF-32 的檢查要放在前面，因為它的 BOM 是 4 bytes，如果放在 UTF-16 後面會被誤判（因為 UTF-32LE 的前兩位也是 FF FE）
        if bytes:sub(1, 4) == '\255\254\000\000' then     -- FF FE 00 00
          vim.notify("utf-32le with BOM (FF FE 00 00)", vim.log.levels.INFO)
        elseif bytes:sub(1, 4) == '\000\000\254\255' then -- 00 00 FE FF
          vim.notify("utf-32be with BOM (00 00 FE FF)", vim.log.levels.INFO)
        elseif bytes:sub(1, 2) == '\255\254' then         -- FF FE
          vim.notify("utf-16le with BOM (FF FE)", vim.log.levels.INFO)
        elseif bytes:sub(1, 2) == '\254\255' then         -- FE FF
          vim.notify("utf-16be with BOM (FE FF)", vim.log.levels.INFO)
        elseif bytes:sub(1, 3) == '\239\187\191' then     -- EF BB BF
          vim.notify("utf-8 with BOM (EF BB BF)", vim.log.levels.INFO)
        end
      end
    end,
    {
      nargs = "?",
      desc = "如果文件有BOM(utf-8, utf-16le, utf-16be, utf-32le, utf-32be)則顯示",
      complete = function()
        return "-h"
      end
    }
  )

  vim.api.nvim_create_user_command(
    "HexView",
    function(args)
      if args.fargs[1] == "-h" then
        cmdUtils.showHelpAtQuickFix({
          "'<,'>!xxd                       -- ⭐ 只對選取的內容做xxd, 如果你的文件很大，用這種方式速度會很快，而且undo回來也快",
          "'<,'>!xxd -c 1",
          'HexView',
          'HexView 1                       -- 每一列用1byte來呈現 xx',
          'HexView 2                       -- 每一列用2byte來呈現 xxxx',
          'HexView 3                       -- 每一列用3byte來呈現 xxxx xx',
          'HexView 4                       -- 每一列用4byte來呈現 xxxx xxxx',
          'HexView 16',
          ':!xxd my.otf > ~/my_temp.hex    -- 💡 將結果放到其它的文件',
          ':1,2!xxd > ~/my_temp.hex        -- ❗ 只轉換部份資料覆蓋到某一個某件, 注意！當前的文件1~2列也會被截掉，如果要不變要用undo',
          ':5!xxd                          -- 💡只對第5列做轉換',
          ':5!xxd -r                       -- 💡還原第5列',
          ':20,100!xxd                     -- 💡只對部份的列做xxd',
          'xxd my.otf | less               -- xxd與less其實都是外部工具, less可以用▽之後才呈現之後的內容',
          '> [!TIP] 如果要恢復可以用undo',
          '> [!TIP] 切換可以善用undo, redo',
          '> [!TIP] 不建用 :%!xxd -r 來恢復(如果原始文件編碼非utf-8可能會錯)',
          ':set fileencoding=utf-8',
          ':set fileencoding=utf-16le',
          ':set fileencoding=utf-16be',
          ':set bomb',
          ':set nobomb',
          ':set binary   -- 不會解析文件的換行符、終止符或編碼',
          ':set nobinary',
        })
        return
      end

      vim.cmd("PrintBOM")

      if #args.fargs == 0 then
        vim.cmd("%!xxd") -- hex dump, -c 預設使用預設(16) -- %只的是目前的文件
        return
      end

      vim.cmd("%!xxd -c " .. args.fargs[1])
    end,
    {
      nargs = "?",
      desc = "用16進位來檢視",
      complete = function(_, cmdLine, _)
        local parts = vim.split(cmdLine, "%s+")
        local argc = #parts - 1
        if argc == 1 then
          return {
            "1",
            "2",
            "3",
            "4",
            "16",
          }
        end
      end
    }
  )

  vim.api.nvim_create_user_command(
    "GitDiff",
    function(args)
      local git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
      if vim.v.shell_error ~= 0 then
        vim.notify("Not in a Git repository", vim.log.levels.ERROR)
        return
      end

      -- https://stackoverflow.com/a/2183920/9935654
      -- :term git diff --name-only --cached; echo -e "\n\n 👇 Diff 👇\n\n"; git --no-pager diff --cached; exec bash         -- linux
      -- :term git diff --name-only --cached & echo. & echo. & echo 👇 & echo. & echo. & git --no-pager diff --cached & cmd  -- 這個可以在windows終端機為cmd使用
      -- ❌ :term git diff --name-only --cached & echo `n`n👇`n`n & git --no-pager diff --cached & cmd  -- powersehll之中可用`n`n來換行，但是終端機換成powrsehll之後會怪怪的. 此外linux的foot終端機的&不是接下去，雖然也可以跑，但是他的&會是當成邏輯運算，執行順序會變
      local cached = ""
      if #args.fargs > 0 then
        cached = "--cached"
      end
      local files_cmd = "git diff --name-only " .. cached -- 整理出檔案名稱
      local files = vim.fn.systemlist("git diff --name-only " .. cached)
      local abs_files = {}
      for _, file_relativepath in ipairs(files) do
        table.insert(abs_files, cmdUtils.echoMsg(0, git_root .. "/" .. file_relativepath, 0))
      end

      -- local diff_cmd = "git diff " .. cached -- 如果少了--no-pager，要慢慢往下才會所有東西都出來
      local diff_cmd = "git --no-pager diff " .. cached
      local git_status = "git status -s"
      local bash_cmd = "exec bash"
      local sep = ";"
      if osUtils.IsWindows then
        bash_cmd = "cmd"
        sep = " & "
      end
      local run_cmd = "term " .. table.concat({
        cmdUtils.echoMsg(0, "👇 filepath: relative 👇", 2),
        -- table.concat(abs_files, sep), -- ❗ 寫到這邊底下的內容可能會被截掉，不太曉得是為什麼
        files_cmd, -- 因此這邊還是維持寫相對路徑
        cmdUtils.echoMsg(2, "👇 diff 👇", 2),
        diff_cmd,
        cmdUtils.echoMsg(1, "👇 filepath: absolute 👇", 2),
        table.concat(abs_files, sep), -- 這邊再給出絕對路徑
        cmdUtils.echoMsg(2, "👇 status 👇", 2),
        git_status,
        cmdUtils.echoMsg(2, "👇 cmd: 👇", 2),
        bash_cmd,
      }, sep)
      vim.cmd(run_cmd)
    end,
    {
      desc = "git diff --cached (staged) ",
      nargs = "?",
      complete = function(_, cmdLine, _)
        local parts = vim.split(cmdLine, "%s+")
        local argc = #parts - 1
        if argc == 1 then
          return {
            "--cached", --  相當於已經被git add進去的內容
            -- "--staged", -- 效果同上
          }
        end
      end
    }
  )

  vim.api.nvim_create_user_command(
    "GitCommit",
    function()
      -- :!foot git commit &
      local terminal = ""
      if osUtils.IsWindows then
        vim.notify("not support windows.", vim.log.levels.ERROR)
        return
        -- terminal = "start cmd /k "
        -- :!start cmd /k git show -- 這個可行, 但是如果換成git commit換不行
      end
      terminal = os.getenv("TERM") or "" -- :help term -- 所謂的:echo &term得到的名稱就是來至於TERM這個環境變數
      vim.cmd("!" .. terminal .. " git commit &")
      local bash_cmd = "exec bash"
      local sep = ";"
      if osUtils.IsWindows then
        bash_cmd = "cmd"
        sep = " & "
      end
      -- vim.cmd("term " .. "git branch -av" .. sep .. bash_cmd) -- 如果你目前已經在term，這個會蓋掉，雖然可以再透過<C-O>回去，但是點麻煩
      print("git branch -av") -- 改用成提示，如果有需要可以在自己用msg來查看
    end,
    {
      desc = "git commit; git branch -av",
    }
  )


  vim.api.nvim_create_user_command(
    "GitShow",
    function(args)
      local git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
      if vim.v.shell_error ~= 0 then
        vim.notify("Not in a Git repository", vim.log.levels.ERROR)
        return
      end

      local sha1 = ""
      if #args.fargs > 0 then
        sha1 = vim.split(args.fargs[1], "　")[1]
      end
      local sep = " ; "
      local bash_cmd = "exec bash"
      if osUtils.IsWindows then
        bash_cmd = "cmd"
        sep = " & "
      end

      -- git --no-pager show --name-only -- 這個還會有commit的訊息, 加上--pretty可以撈指定的資料
      local files = vim.fn.systemlist("git --no-pager show --name-only --pretty=format: " .. sha1)
      local abs_files = {}
      for _, file_relativepath in ipairs(files) do
        -- file_relativepath:gsub("%s+$", "")
        table.insert(abs_files, cmdUtils.echoMsg(0, git_root .. "/" .. file_relativepath, 0)) -- echo本身就會換一次行，因此如果沒有要多換，可以省略
      end

      local run_cmd = "term " .. table.concat({
        cmdUtils.echoMsg(0, " 👇 filepath: relative 👇 ", 1),
        "git --no-pager show --name-only " .. sha1, -- 顯示文件名稱
        cmdUtils.echoMsg(1, "👇 git show 👇", 2),
        "git --no-pager show " .. sha1,
        -- "git show " .. sha1, -- 如果要一口氣呈現，可以用End即可，離開還要再按下q
        cmdUtils.echoMsg(1, " 👇 filepath: absolute 👇 ", 1),
        table.concat(abs_files, sep),
        cmdUtils.echoMsg(1, "👇 cmd: 👇", 1),
        bash_cmd,
      }, sep)
      -- vim.cmd("vsplit | echo 'hello world'") -- 這個會被term蓋掉
      vim.cmd(run_cmd)

      -- 以下可以考慮用vsplit把檔案放到另一個視窗，但是我覺得放一起，如果有需要自己再分割就好
      -- vim.cmd("vsplit | term " .. table.concat({
      -- vim.cmd("leftabove vsplit | term " .. table.concat({ -- 同上
      --   cmdUtils.echoMsg(2, " 👇 file 👇 ", 2),
      --   -- "git --no-pager show --name-only " .. sha1,
      --   table.concat(abs_files, sep),
      -- }, sep))
    end,
    {
      desc = "git --no-pager show <sha1>",
      nargs = "?",
      complete = function(argLead, cmdLine, _)
        -- local parts = vim.split(cmdLine, "%s+")
        -- local argc = #parts - 1 -- 第幾個參數

        local cmdLogCmd = 'git --no-pager log --pretty=format:"%H　%s　%ai"' -- %H為sha1, %s為提交的訊息 %ai是提交的時間, 分隔符用U+3000來區分
        local git_logs = vim.fn.systemlist(cmdLogCmd)
        if #argLead == 0 then
          return git_logs
        end

        local input_sha_txt = string.sub(cmdLine, 9) -- (#"GitShow" + 1) + 1(空格)
        local filtered_logs = {}
        for _, line in ipairs(git_logs) do
          -- if line:find(argLead) then -- 因為提交的訊息中間可能會有空行，這樣要再tab就要再整個刪除，所以用cmdLine來區分
          if line:find(input_sha_txt) then
            table.insert(filtered_logs, line)
          end
        end
        return filtered_logs
      end
    }
  )

  vim.api.nvim_create_user_command(
    "QFAdd",
    function(args)
      local text = ""
      if #args.fargs > 0 then
        text = args.fargs[1]
      else
        text = vim.fn.getline('.')
      end
      vim.fn.setqflist({
        {
          filename = vim.fn.expand('%'),
          lnum = vim.fn.line('.'),
          col = vim.fn.col('.'),
          ["text"] = text,
        },
      }, 'a') -- a表示append

      -- 檢查是否有 quickfix 視窗開啟
      local is_qf_open = false
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
        if buftype == "quickfix" then
          is_qf_open = true
          break
        end
      end

      -- 如果 quickfix 視窗未開啟，則執行 copen
      if not is_qf_open then
        vim.cmd("copen")
      end
    end,
    {
      nargs = "?",
      desc = "將目前的內容附加到quickfix list清單中",
      -- complete = function()
      --   return string.format("%s", vim.fn.getline('.')) -- ~~用目前這行的內容當成text訊息~~ 無效
      -- end
    }
  )
  vim.api.nvim_create_user_command(
    "QFRemove",
    function()
      local qf_list = vim.fn.getqflist()

      -- 獲取當前光標所在的行號（從 1 開始），轉為索引（從 0 開始）
      local cur_idx = vim.api.nvim_win_get_cursor(0)[1] - 1

      -- 檢查列表非空且索引有效
      if next(qf_list) ~= nil and cur_idx >= 0 and cur_idx < #qf_list then
        -- 移除當前項目
        table.remove(qf_list, cur_idx + 1) -- table.remove 是 1-based，所以要 +1
        vim.fn.setqflist(qf_list, 'r')     -- 'r' 表示替換整個列表
      else
        vim.notify("無效的 quickfix 項目或列表為空", vim.log.levels.ERROR)
      end
    end,
    {
      desc = "刪除當前的quickfix的選中項目",
    }
  )

  vim.api.nvim_create_user_command(
    "QFDeleteMany",
    function()
      local qf_list = vim.fn.getqflist()

      -- 檢查是否有視覺選擇
      local start_pos = vim.fn.getpos("'<") -- 視覺選擇的起始位置
      local end_pos = vim.fn.getpos("'>")   -- 視覺選擇的結束位置

      -- 如果有有效的視覺選擇 (visual mode)
      if start_pos[2] > 0 and end_pos[2] > 0 then
        local start_idx = start_pos[2] - 1 -- 轉為 0-based 索引
        local end_idx = end_pos[2] - 1     -- 轉為 0-based 索引

        -- 確保索引在有效範圍內
        if next(qf_list) ~= nil and start_idx >= 0 and end_idx < #qf_list then
          -- 從後向前移除，避免索引偏移問題
          for i = end_idx, start_idx, -1 do
            table.remove(qf_list, i + 1) -- table.remove 是 1-based
          end
          vim.fn.setqflist(qf_list, 'r')
        else
          vim.notify("選中的 quickfix 項目無效或列表為空", vim.log.levels.ERROR)
        end
      else
        -- 沒有視覺選擇時，移除當前行（原邏輯）
        local cur_idx = vim.api.nvim_win_get_cursor(0)[1] - 1
        if next(qf_list) ~= nil and cur_idx >= 0 and cur_idx < #qf_list then
          table.remove(qf_list, cur_idx + 1)
          vim.fn.setqflist(qf_list, 'r')
        else
          vim.notify("無效的 quickfix 項目或列表為空", vim.log.levels.ERROR)
        end
      end
    end,
    {
      desc = "刪除選中的quickfix項目（支援多選, V-LINE",
      range = true,
    }
  )
end

return commands
