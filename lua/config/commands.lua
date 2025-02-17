local path = require("utils.path")

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
      -- # 注意，如果你新增其它的路徑在runtimepath下，就算生成了tags檔案，也還是沒辦法正常使用幫助
      -- # :set runtimepath+=/path/to/your/runtime
      -- vim.opt.runtimepath:append('/path/to/your/runtime') -- runtimepath有成功，但是doc一樣會出不來
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
end

return commands
