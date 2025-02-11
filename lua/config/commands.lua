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
end

return commands
