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


  vim.api.nvim_create_user_command("PrintBOM", -- 其實可以寫在autocmd中，但是我覺得不必要，除了老程式，目前用utf-8機乎是主流，不太需要寫入BOM來佔空間
    function(args)
      if args.fargs[1] == "-h" then
        cmdUtils.showHelpAtQuickFix({
          ':set fileencoding=utf-8',
          ':set fileencoding=utf-16       -- 這個可能有BOM, 也可能沒有, 如果有了話則用系統的讀法決定是le還是be',
          ':set fileencoding=utf-16le     -- 如果要確實改成le可以用這種方法',
          ':set fileencoding=utf-16be     -- 記得更改完後要存檔才會生效',
          ':set bomb',
          ':set nobomb',
        })
        return
      end
      local file = io.open(vim.fn.expand("%"), "rb") -- 用二進位方式來開始當前的文件
      if not file then
        return
      end

      local bytes = file:read(3) -- 看有多少byte就盡可能的讀取 -- 如果長度不夠不會出錯，會得到nil而已
      file:close()

      if bytes then
        if bytes:sub(1, 2) == '\255\254' then         -- FF FE
          vim.notify("utf-16le with BOM (FF FE)", vim.log.levels.INFO)
        elseif bytes:sub(1, 2) == '\254\255' then     -- FE FF
          vim.notify("utf-16be with BOM (FE FF)", vim.log.levels.INFO)
        elseif bytes:sub(1, 3) == '\239\187\191' then -- EF BB BF
          vim.notify("utf-8 with BOM (EF BB BF)", vim.log.levels.INFO)
        end
      end
    end,
    {
      nargs = "?",
      desc = "如果文件有BOM(utf-16le, utf-16be, utf-8)則顯示",
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
      -- https://stackoverflow.com/a/2183920/9935654
      -- :term git diff --name-only --cached; echo -e "\n\n 👇 Diff 👇\n\n"; git --no-pager diff --cached; exec bash
      local cached = ""
      if #args.fargs > 0 then
        cached = "--cached"
      end
      local files_cmd = "git diff --name-only " .. cached -- 整理出檔案名稱
      local sep = 'echo -e "\\n\\n 👇 diff 👇\\n\\n"'
      -- local diff_cmd = "git diff " .. cached -- 如果少了--no-pager，要慢慢往下才會所有東西都出來
      local diff_cmd = "git --no-pager diff " .. cached
      local git_status = "git status -s"
      local bash_cmd = "exec bash"
      if osUtils.IsWindows then
        bash_cmd = "exec cmd"
      end
      vim.cmd("term " .. table.concat({
        'echo -e "👇 file 👇\\n\\n"',
        files_cmd,
        'echo -e "\\n\\n 👇 diff 👇\\n\\n"',
        diff_cmd,
        'echo -e "\\n\\n 👇 status 👇\\n\\n"',
        git_status,
        'echo -e "\\n\\n 👇 cmd: 👇\\n\\n"',
        bash_cmd,
      }, ";"))
    end,
    {
      desc = "git diff --cached (staged) ",
      nargs = "?",
      complete = function(argLead, cmdLine, _)
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
      local terminal = os.getenv("TERM") -- :help term -- 所謂的:echo &term得到的名稱就是來至於TERM這個環境變數
      vim.cmd("!" .. terminal .. " git commit &")
      local bash_cmd = "exec bash"
      if osUtils.IsWindows then
        bash_cmd = "exec cmd"
      end
      vim.cmd("term " .. "git branch -av;" .. bash_cmd)
    end,
    {
      desc = "git commit",
    }
  )
end

return commands
