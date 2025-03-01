local path = require("utils.path")
local cmdUtils = require("utils.cmd")
local osUtils = require("utils.os")
local swayUtils = require("utils.sway")
local completion = require("utils.complete")

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


--- 這個指令比較麻煩，因為還會牽扯到自動完成的事件，所以包裝在此函數
local function create_user_command_jumps_to_qf_list()
  local function update_qf_list()
    local jumps, _ = unpack(vim.fn.getjumplist()) -- jumps, cur_idx
    local qf_list = {}

    -- for i, jump in ipairs(jumps) do
    for i = #jumps, 1, -1 do -- step: -1 -- 反過來取，讓最近異動的顯示再qflist的第一筆
      local jump = jumps[i]

      local text = "" -- string.format("%03d", i), -- 顯示跳轉編號 沒什麼意義
      if vim.api.nvim_buf_is_valid(jump.bufnr) then
        local lines = vim.api.nvim_buf_get_lines(jump.bufnr, jump.lnum - 1, jump.lnum, false)
        if #lines > 0 then
          text = lines[1] -- 獲取該行內容
        end
      end

      table.insert(qf_list, {
        bufnr = jump.bufnr, -- 緩衝區號
        lnum = jump.lnum,   -- 行號
        col = jump.col + 1, -- 列號 (注意：Vim 的 col 從 0 開始，quickfix 從 1 開始)
        text = text         -- (可選)
      })
    end

    vim.fn.setqflist(qf_list)
  end

  --- 讓當qflist開啟的時候，會持續以jumps的內容來更新其清單，這樣就不需要自己一直調用JumpsToQFlist來更新
  --- 如果不在需要自動加入的行為，請使用 :ccl, :cclose, 來將自動建立的autocmd移除
  local function setup_autocmd()
    -- vim.api.nvim_clear_autocmds({ group = "JumpsToQFlist" }) -- 如果group還沒有建立，這樣會錯

    -- 創建自動命令組
    vim.api.nvim_create_augroup("JumpsToQFlist", { clear = true }) -- clear為true會建立; 如果clear為false可以用來查詢已經建立的此id


    -- 當光標移動時檢查並更新（因為跳轉會觸發 CursorMoved）
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = "JumpsToQFlist",
      callback = function()
        if cmdUtils.is_qf_open() then
          update_qf_list()
        end
      end,
      desc = "Update qflist on jump change when qf is open",
    })

    -- 當 quickfix 視窗關閉時清理, 這個好像關不掉, 所以改用CmdlineLeave來幫忙
    -- vim.api.nvim_create_autocmd("WinClosed", {
    --   group = "JumpsToQFlist",
    --   callback = function()
    --     if not cmdUtils.is_qf_open() then
    --       local id = vim.api.nvim_create_augroup("JumpsToQFlist", { clear = false })
    --       vim.api.nvim_clear_autocmds({ group = id })
    --     end
    --   end,
    --   desc = "Clear autocmds when qf is closed",
    -- })

    -- 當執行 :cclose 時清理自動命令
    vim.api.nvim_create_autocmd("CmdlineLeave", {
      pattern = ":",
      group = "JumpsToQFlist",
      callback = function()
        local cmd = vim.fn.getcmdline() -- CmdlineEnter 如果是Enter事件，此時得到的都會是空值
        if cmd == "cclose" or cmd == "ccl" then
          vim.api.nvim_clear_autocmds({ group = "JumpsToQFlist" })
        end
      end,
      desc = "Clear autocmds when :cclose is executed",
    })
  end

  vim.api.nvim_create_user_command("JumpsToQFlist",
    function()
      -- init
      update_qf_list()

      cmdUtils.open_qflist_if_not_open()

      -- 設定自動更新
      setup_autocmd()
    end,
    {
      -- hop.nvim的跳轉剛好會觸發, jumps列表的更新，可以記錄到你準備要跳轉前的位置
      desc = "同步將jumps的內容寫入到qflist之中, 使用:ccl, :cclose可關閉同步的行為. 要配合hop.nvim使用會比較有感",
    }
  )
end

function commands.setup()
  -- 'foot', -- Invalid command name (must start with uppercase): 'foot'
  vim.api.nvim_create_user_command("Foot",
    openCurrentDirWithFoot, -- 執行的函數
    { desc = "使用 Foot 開啟當前文件所在的目錄" } -- 描述信息（可選）
  )


  vim.api.nvim_create_user_command("Cmd",
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

  vim.api.nvim_create_user_command("Edit",
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
  vim.api.nvim_create_user_command("Help",
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
        _                                     -- cursorPos在cmdLine上的位置(欄)
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

  vim.api.nvim_create_user_command("HexView",
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

  vim.api.nvim_create_user_command("GitDiff",
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

  vim.api.nvim_create_user_command("GitCommit",
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
      -- local bash_cmd = "exec bash"
      -- local sep = ";"
      -- if osUtils.IsWindows then
      --   bash_cmd = "cmd"
      --   sep = " & "
      -- end
      -- vim.cmd("term " .. "git branch -av" .. sep .. bash_cmd) -- 如果你目前已經在term，這個會蓋掉，雖然可以再透過<C-O>回去，但是點麻煩
      print("git branch -av") -- 改用成提示，如果有需要可以在自己用msg來查看
    end,
    {
      desc = "git commit; git branch -av",
    }
  )


  vim.api.nvim_create_user_command("GitShow",
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

  vim.api.nvim_create_user_command("QFAdd",
    function(args)
      local text = ""
      if #args.fargs > 0 then
        text = args.fargs[1]
      else
        text = vim.fn.getline('.')
      end
      local qflist = vim.fn.getqflist()
      local new_entry = {
        filename = vim.fn.expand('%'),
        lnum = vim.fn.line('.'),
        col = vim.fn.col('.'),
        ["text"] = text,
      }

      -- vim.fn.setqflist(new_entry, 'a') -- a表示append 這個是放在最後面
      table.insert(qflist, 1, new_entry)
      vim.fn.setqflist(qflist, 'r') -- 目前似乎沒有其他更高效的方法，只能全部重寫
      cmdUtils.open_qflist_if_not_open()
    end,
    {
      nargs = "?",
      desc = "將目前的內容插入到quickfix list清單中的第一筆",
      -- complete = function()
      --   return string.format("%s", vim.fn.getline('.')) -- ~~用目前這行的內容當成text訊息~~ 無效
      -- end
    }
  )

  vim.api.nvim_create_user_command("QFEmpty",
    function()
      vim.fn.setqflist({}, 'f') -- free
      cmdUtils.open_qflist_if_not_open()
    end,
    {
      nargs = 0,
      desc = "清空quickfix列表",
    }
  )
  vim.api.nvim_create_user_command("QFRemove",
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

  vim.api.nvim_create_user_command("QFDeleteMany",
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

  vim.api.nvim_create_user_command("SetWinOpacity",
    function(args)
      -- print(vim.inspect(args))
      if args.fargs[1] == "-h" then
        cmdUtils.showHelpAtQuickFix({
          ':SetWinOpacity <opacity> <PID>',
          ':SetWinOpacity <opacity> <PID> <opacity必需有小數點>     -- 就只是方便您設定，如果你不想再回到前面去調整opacity',
        })
        return
      end

      if #args.fargs < 2 then
        vim.notify("請提供 <透明度> 和 <PID>，例如：SetWinOpacity 0.8 1234", vim.log.levels.ERROR)
        return
      end

      -- 試圖從字串末尾匹配一個可能的浮點數(只能是浮點數(避免與pid衝突)
      local opacity2 = args.args:match("([%d]+%.[%d]+)%s*$")

      local input_args = ""
      if opacity2 then
        input_args = args.args:match("^(.-)%s*[%d]+%.[%d]+%s*$")
      else
        input_args = args.args
      end

      -- 匹配模式：(.*) 捕獲所有內容直到最後的數字，([%d%.]+) 捕獲結尾的數字（包括小數）
      -- args.args:match("^(.*)[%s　]+([%d%.]+)$")
      -- local arg1, opacity = args.args:match("^(.*)%s+([%d%.]+)$")
      local opacity, arg2 = input_args:match("^([%d%.]+)%s+(.*)$")
      -- print(opacity, arg2, opacity2)
      if opacity2 then
        opacity = tonumber(opacity2)
      end

      if arg2 and opacity then
        local item = vim.split(arg2, "　") -- U+3000
        local name = item[1]
        local pid = item[2]

        local result = swayUtils.set_window_opacity(pid, opacity)
        if result == 0 then
          vim.notify(string.format("已將 %q PID %s 的透明度設為 %.2f", name, pid, opacity), vim.log.levels.INFO)
        else
          vim.notify(string.format("執行 swaymsg 失敗: pid:%s opacity: %s", pid, opacity), vim.log.levels.ERROR)
        end
      else
        vim.notify("命令格式錯誤，請使用：SetWinOpacity <pid> <opacity>", vim.log.levels.ERROR)
      end
    end,
    {
      desc = "設定Sway中指窗口的透明度",
      nargs = "+",
      complete = function(argLead, cmdLine, _)
        local parts = vim.split(cmdLine, "%s+")
        local argc = #parts - 1

        -- 🧙 注意！如果argc1用的是PID, name的組合，可能就會導致之後的參數完成判斷不易(因為第幾個參數可能受到名稱之中有空白，導致參數推斷不如遇期)
        if argc == 1 then
          return {
            "0.8",
            "0.4",
            "1",
            "0",
          }
        end

        if argc == 2 then
          -- 此參數為PID, name的結合
          local nodes = swayUtils.get_tree()
          if #argLead > 0 then
            nodes = vim.tbl_filter(function(node)
              return string.find((node.name .. node.pid), argLead)
            end, nodes)
          end
          local cmp = {}

          -- 讓聚焦的窗口顯示在清單自動完成清單的上層
          for _, node in ipairs(nodes) do
            if node.focused then
              table.insert(cmp, string.format("%s　%s", node.name, node.pid))
            end
          end
          for _, node in ipairs(nodes) do
            if not node.focused then
              table.insert(cmp, string.format("%s　%s", node.name, node.pid))
            end
          end
          return cmp
        end
      end
    }
  )

  vim.api.nvim_create_user_command("NotifySend",
    function(args)
      if args.fargs[1] == "-h" then
        cmdUtils.showHelpAtQuickFix({
          'NotifySend title body <datetime> <duration?>                     -- 如果參數有空白，請用下劃線(_)取代',
          'NotifySend title body 08:00 3000',
          'NotifySend title line1\\nline2\\nline3 08:00 3000',
          '❌ NotifySend titleRow1\\nRow2 line1\\nline2\\nline3 08:00 3000  -- title的換行無效',
          '!atq          -- 查看排程',
          '!at -c 11     -- 查看任務編號為11所要做的內容',
          '!atrm 11      -- 刪除編號為11的排程',
        })
        return
      end

      if #args.fargs < 3 then
        vim.notify("參數不足", vim.log.levels.ERROR)
        vim.cmd("NotifySend -h")
        return
      end
      local title = string.gsub(args.fargs[1], "_", " ")
      local body = string.gsub(args.fargs[2], "_", " ")
      local datetime = string.gsub(
        vim.split(args.fargs[3], "　")[1], -- U+3000之後的當成註解，不取
        "_",
        " "
      )
      local duration = ""
      if #args.fargs >= 4 then
        local d = tonumber(args.fargs[4])
        if duration then
          duration = " -t " .. d
        end
      end
      local full_command = string.format('echo \'notify-send %s %q %q\' | at %s', duration, title, body, datetime)
      print(full_command)
      os.execute(full_command)
    end,
    {
      nargs = "+",
      desc = "notify-send",
      complete = function(_, cmdLine, _)
        local parts = vim.split(cmdLine, "%s+")
        local argc = #parts - 1

        if argc == 1 then
          return {
            "title",
          }
        end

        if argc == 2 then
          return {
            "body"
          }
        end

        if argc == 3 then
          local now = os.time()
          return {
            os.date("%H:%M"), -- HH:MM
            -- os.date("%H:%M_%m/%d/%Y　"), -- HH:MM_mm/dd/YYYY
            os.date("%H:%M_%m/%d/%Y　(%A)(today)"), -- HH:MM_mm/dd/YYYY -- %A是星期幾
            os.date("%H:%M_%m/%d/%Y　(%A)(tomorrow)", now + 86400),
            os.date("%H:%M_%m/%d/%Y　(%A)(next_week)", now + 86400 * 7),
            "08:00",
            "now_+_1_hour",
            "08:00_tomorrow",
            "22:30_01/11/2025",
          }
        end

        if argc == 4 then
          return {
            "3000",
            "8000",
            "12000",
          }
        end
      end
    }
  )

  vim.api.nvim_create_user_command("ColorPicker",
    function(args)
      local handle = io.popen("zenity --color-selection --show-palette 2>/dev/null")
      if not handle then
        vim.notify("無法執行 zenity --color-section --show-palette ", vim.log.levels.ERROR)
        return
      end

      if args.fargs[1] == "preview" then
        return
      end

      local result = handle:read("*a")
      handle:close()

      -- 移除換行符並檢查是否有效
      result = result:gsub("\n$", "")
      if not result or result == "" then
        vim.notify("未選擇任何顏色", vim.log.levels.INFO)
        return
      end

      if args.fargs[1] == "hex" then
        local function rgb_to_hex(rgb_str)
          local r, g, b = rgb_str:match("rgb%((%d+),(%d+),(%d+)%)")
          if r and g and b then
            return string.format("#%02X%02X%02X", tonumber(r), tonumber(g), tonumber(b))
          end
          return nil
        end
        vim.api.nvim_put({ rgb_to_hex(result) or "" }, "c", true, true)
        return
      elseif args.fargs[1] == "rgb" then
        vim.api.nvim_put({ result }, "c", true, true)
      end
    end,
    {
      nargs = 1,
      desc = "Open a color picker and insert the selected color",
      complete = function()
        return {
          "rgb",
          "hex",
          "preview"
        }
      end
    }
  )

  -- 失敗，連區域都不能選
  -- local rec_job_id = nil
  -- vim.api.nvim_create_user_command("RecSelection",
  --   function(args)
  --     -- if args.args:match("%.mp4$") == nil or args.args:match("%.mp4$") == nil then end
  --     -- local output_dir = vim.fn.fnamemodify('path/to/123.mkv', ":h")
  --
  --     local output_dir = args.args
  --
  --     -- 確保輸出目錄存在
  --     local output_dir_stat = vim.loop.fs_stat(output_dir)
  --     if output_dir_stat and output_dir_stat.type ~= "directory" then
  --       vim.notify("輸出的目錄不存在: " .. output_dir, vim.log.levels.ERROR)
  --       return
  --     end
  --
  --     local output_mkv_path = output_dir .. "/" .. 'recording.mkv'
  --     local output_mp4_path = output_mkv_path:gsub("%.mkv$", ".mp4")
  --
  --     -- 執行錄製
  --     -- local rec_cmd = 'wf-recorder -g "$(slurp)" --audio --file=' .. output_mkv_path -- 這個可能沒用，最好明確指名用shell
  --     local rec_cmd = {
  --       "sh", "-c",
  --       "wf-recorder -g \"$(slurp)\" --audio --file=" .. vim.fn.shellescape(output_mkv_path)
  --     }
  --     -- os.execute(rec_cmd) -- 這個沒辦法給stop的訊號
  --     print(table.concat(rec_cmd, " "))
  --
  --     rec_job_id = vim.fn.jobstart(rec_cmd, {
  --       env = { WAYLAND_DISPLAY = os.getenv("WAYLAND_DISPLAY") }, -- 確保 Wayland 環境
  --       on_exit = function(_, code)
  --         if code == 0 then
  --           print("錄製完成，開始轉換...")
  --           local mkv_to_mp4_cmd = string.format('ffmpeg -i %s -c:v copy -c:a copy %s',
  --             vim.fn.shellescape(output_mkv_path),
  --             vim.fn.shellescape(output_mp4_path)
  --           )
  --           os.execute(mkv_to_mp4_cmd)
  --           os.remove(output_mkv_path)
  --           print("轉換完成，已保存為 " .. output_mp4_path)
  --         else
  --           print("錄製失敗，退出碼：" .. code)
  --         end
  --       end
  --     })
  --     vim.notify("開始錄製，按 :StopRec 結束", vim.log.levels.INFO)
  --   end,
  --   {
  --     nargs = 1,
  --     desc = 'wf-recorder -g "$(slurp)" ...',
  --     complete = function(argLead, _, _)
  --       local dirs = completion.getDirOnly(argLead)
  --       return dirs
  --     end
  --   }
  -- )
  --
  -- -- 停止錄製
  -- vim.api.nvim_create_user_command('StopRec', function()
  --   if rec_job_id then
  --     vim.fn.jobstop(rec_job_id)
  --     rec_job_id = nil
  --   else
  --     print("沒有正在進行的錄製")
  --   end
  -- end, {
  --   desc = "僅在 :RecSelection 開始後有用. 用來結束錄製",
  --   nargs = 0
  -- })

  vim.api.nvim_create_user_command("RecSelection",
    -- man wf-recorder
    -- https://man.archlinux.org/man/extra/wf-recorder/wf-recorder.1.en
    -- -r, --framerate framerate (CFR, Constant Frame Rate) 如果實際的幀數不足，會重覆幀來達到指定的數值
    -- -D, --no-damage: 如果加了此選項，它會持續錄製新幀，即使螢幕沒變化
    -- -B, --buffrate buffrate (VFR, Variable Frame Rate 可以節省空間), 用來告訴編碼器預期的幀率，而不是直接控制輸出的FPS
    -- --buffrate 是用來幫助某些編碼器(例如: SVT-AV1) 解決FPS限制問題，並保留可變幀率。因此這個選項不會強製輸出成指定的FPS, 而是作為一種建議值，實際幀率仍取決於顯示器或錄製內容的更新頻率
    function(args)
      if args.fargs[1] == "-h" then
        cmdUtils.showHelpAtQuickFix({
          'man wf-recorder >> ~/temp.doc',
          'RecSelection <output_dir> <filename> <--framerate?> <--no-damage?> <--no-dmabuf?>',
          'RecSelection ~/Downloads/ my.mp4',
          'RecSelection ~/Downloads/ my.mp4 --framerate_N                    　指定的fps設定為N，其中N為一個整數',
          'RecSelection ~/Downloads/ my.mp4 default --no-damage --no-dmabuf  　fps用預設, 其中如果影變錄出來有破格後面兩個可選項可能有幫助. 30sec約3.6M(但實際的大小還是取決於錄置的內容，僅參考)',
          '執行的真實指令可以透過 :copen 去查看',
        })
        return
      end
      local output_dir = args.fargs[1]
      local output_filename = args.fargs[2] or "recording.mp4"

      -- 確保輸出目錄存在
      local output_dir_stat = vim.loop.fs_stat(output_dir)
      if output_dir_stat and output_dir_stat.type ~= "directory" then
        vim.notify("輸出的目錄不存在: " .. output_dir, vim.log.levels.ERROR)
        return
      end

      -- Ensure output filename ends with .mp4
      if not output_filename:match("%.mp4$") then
        output_filename = output_filename .. ".mp4"
      end

      local output_mkv_path = output_dir .. "/" .. 'recording.mkv'
      -- local output_mp4_path = output_mkv_path:gsub("%.mkv$", ".mp4")
      local output_mp4_path = output_dir .. "/" .. output_filename

      local mkv_exists = vim.loop.fs_stat(output_mkv_path)
      local mp4_exists = vim.loop.fs_stat(output_mp4_path)

      -- Check if MP4 file already exists
      if mkv_exists or mp4_exists then
        local msg = ""
        if mkv_exists then
          msg = output_mkv_path .. "\n"
        end
        if mp4_exists then
          msg = msg .. output_mp4_path
        end
        local choice = vim.fn.confirm(
          "File " .. msg .. " already exists. Overwrite?",
          "&Yes\n&No",
          2                 -- 默認的選擇, 也就是No
        )
        if choice ~= 1 then -- If not Yes, terminate
          vim.notify("Recording cancelled", vim.log.levels.INFO)
          return
        end
        -- 如果檔案已經存在，在錄置沒看到錯誤，但是實際上會得不到結果，所以之前需要先判斷檔案是否存在
        -- 如果你是自己用終端機跑，其實wl-recorder也會問是否要取代，我在猜因為用term來跑，尋問的地方會有問題
        -- 導致可以錄，但是結果出不來。總之如果要覆蓋，直接在這邊先刪除
        -- Delete existing files if they exist
        if mkv_exists then
          os.remove(output_mkv_path)
        end
        if mp4_exists then
          os.remove(output_mp4_path)
        end
      end

      local framerate_opt = args.fargs[3] or ""
      if framerate_opt == 'default' then
        framerate_opt = ""
      end
      if #framerate_opt > 0 then
        framerate_opt = string.gsub(framerate_opt, "_", " ")
      end

      local no_damage_opt = args.fargs[4] or ""
      if no_damage_opt == 'default' then
        no_damage_opt = ""
      end

      local no_dmabuf_opt = args.fargs[5] or ""
      if no_dmabuf_opt == 'default' then
        no_dmabuf_opt = ""
      end

      local rec_cmd = string.format(
        'wf-recorder %s %s %s -g "$(slurp)" --audio --file=%s',
        framerate_opt, no_damage_opt, no_dmabuf_opt,
        output_mkv_path
      )

      -- -- debug
      -- print(rec_cmd) -- 用print還需要按Enter才能繼續 (所以寫到qflist)
      -- if vim.fn.confirm("debug", "&Yes\n&No", 2) ~= 1 then
      --   vim.notify("Recording cancelled", vim.log.levels.INFO)
      --   return
      -- end

      -- 將指令寫入到quickFix的列表，幫助之後如果有需要可以查看實際運行的內容
      vim.fn.setqflist({
        {
          text = rec_cmd,
        },
      }, 'a')

      vim.cmd('term ' .. rec_cmd)

      -- 設置自動命令，在終端退出後轉換
      vim.api.nvim_create_autocmd("TermClose", {
        pattern = "*",
        once = true,
        callback = function()
          os.execute('ffmpeg -i ' ..
            vim.fn.shellescape(output_mkv_path) .. ' -c:v copy -c:a copy ' .. vim.fn.shellescape(output_mp4_path))
          os.remove(output_mkv_path)
          vim.notify("轉換完成，已保存為 " .. output_mp4_path, vim.log.levels.INFO)
        end,
      })
    end,
    {
      nargs = "+",
      desc = 'wf-recorder -g "$(slurp)" ...',
      complete = function(argLead, cmdLine, _)
        local parts = vim.split(cmdLine, "%s+")
        local argc = #parts - 1
        if argc == 1 then
          local dirs = completion.getDirOnly(argLead) -- 取得當前工作目錄下可用的目錄

          -- Add common directories
          local home = os.getenv("HOME")
          table.insert(dirs, home .. "/Documents")
          table.insert(dirs, home .. "/Downloads")

          -- Filter duplicates and sort
          local unique_dirs = {}
          for _, dir in ipairs(dirs) do
            unique_dirs[dir] = true -- 同個內容都在同一個key
          end
          dirs = vim.tbl_keys(unique_dirs)
          table.sort(dirs)
          return dirs
        end

        if argc == 2 then
          return {
            "recording.mp4"
          }
        end

        if argc == 3 then
          return {
            "default",
            "--framerate_60",
            "--framerate_25",
            "--framerate_10",
            "--framerate_5"
          }
        end

        if argc == 4 then
          return {
            "default", -- by default, wf-recorder will request a new frame from the compositor only when screen updates.
            "--no-damage",
          }
        end

        if argc == 5 then
          return {
            "default", -- by default, wf-recorder will try to sue only GPU buffers and copies if using a GPU encorder.
            "--no-dmabuf"
          }
        end
      end
    }
  )

  create_user_command_jumps_to_qf_list()
end

return commands
