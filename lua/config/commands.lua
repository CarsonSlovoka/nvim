local path = require("utils.path")
local cmdUtils = require("utils.cmd")
local osUtils = require("utils.os")
local completion = require("utils.complete")
local arrayUtils = require("utils.array")
local extmarkUtils = require("utils.extmark")
local utils = require("utils.utils")

vim.cmd("packadd cfilter") -- :help cfilter -- 可以使用Cfilter, Lfilter -- 它不是真得刪除，而是在創件新的列表，可以用:cnewer :colder 切換

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


  vim.api.nvim_create_user_command("Term",
    function(args)
      local para = utils.flag.parse(args.args)
      local direction = para.opts["direction"] or "sp"


      -- 獲取當前文件
      local filepath = para.params[1] or vim.fn.expand('%:p') -- 當前文件的完整路徑
      if filepath == '' then
        print("No file in the current buffer!")               -- 提示用戶當前緩存沒文件
        return
      end

      filepath = vim.fn.expand(filepath) -- 處理自輸入可能用~的清況
      local exists = vim.loop.fs_stat(filepath)
      if not exists then
        vim.notify("invalid work dir: " .. filepath, vim.log.levels.ERROR)
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
      nargs = "*",
      complete = function(arg_lead)
        if arg_lead:match("^%-%-") then
          return utils.cmd.get_complete_list(arg_lead, {
            direction = { "vsp", "sp" },
          })
        end
        return completion.getDirOnly(arg_lead)
      end,
      desc = "在當前路徑開啟terminal"
    }
  )
  vim.api.nvim_create_user_command("Cmd",
    function(args)
      if args.range == 0 then
        vim.cmd(args.fargs[1])
        return
      end

      --- @type table
      local cmds = utils.range.get_selected_text()
      for _, cmd in ipairs(cmds) do
        -- vim.cmd(cmd:match("^%s*:(.*)") or cmd) -- 空白、制表符: 都忽略. (注意連:都會忽略) <-- 不需要如此，指令有開始有多個:不影響，而且如果有Tab, 空白也沒事
        vim.cmd(cmd)
      end
    end,
    {
      nargs = "?",
      range = true,
      desc = "等同 vim.cmd(...) 如果你想要將一些vim的指令直接寫在腳本，在用手動選取的方式去一次執行，可以使用此命令"
      -- :Highlight YellowBold vim.api
      -- :Highlight Purple \v^\s*Bk:.*
    }
  )

  vim.api.nvim_create_user_command("Edit",
    function()
      local selected_text = table.concat(utils.range.get_selected_text(), "")
      if #selected_text == 0 then
        return
      end
      local parts = vim.split(selected_text, ":") -- grep -n就是用:分
      local filepath = parts[1]
      if #parts == 1 then
        vim.cmd("edit " .. filepath)
        return
      end

      local line_num = tonumber(parts[2])
      if line_num then
        vim.cmd("edit +" .. line_num .. " " .. filepath)
      else
        vim.cmd("edit " .. filepath)
      end
    end,
    {
      range = true,
      desc = "edit +123 <filepath> 可以對rg --vimgrep的項目直接選取後前往編輯",
    }
  )
  vim.api.nvim_create_user_command("Help",
    function()
      local selected_text = table.concat(utils.range.get_selected_text(), "")
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
  vim.api.nvim_create_user_command("R",
    function()
      local selected_text = table.concat(utils.range.get_selected_text(), "")
      if #selected_text == 0 then
        return
      end
      vim.cmd("r! " .. selected_text)
    end,
    {
      range = true,
      desc = ":r! :read!",
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
    vim.fn.setqflist({
      {
        text = cmd,
      },
    }, 'a')
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

  vim.api.nvim_create_user_command("Video2Gif",
    function(args)
      local para = utils.flag.parse(args.args)
      local input_file = vim.fn.expand(para.params[1])
      local width = tonumber(para.params[2]) or 320
      local fps = tonumber(para.params[3]) or 10

      local n_loop = tonumber(para.opts["loop"]) or 0

      if not input_file then
        vim.notify("Error: Input file is required!", vim.log.levels.ERROR)
        return
      end

      -- 檢查輸入檔案是否存在
      if vim.fn.filereadable(input_file) == 0 then
        vim.notify("Error: Input file '" .. input_file .. "' does not exist!", vim.log.levels.ERROR)
        return
      end

      -- 提取檔案名稱
      local base_name = vim.fn.fnamemodify(input_file, ":r") -- 檔案路徑不含副檔名

      local output_file_path = para.opts["o"]
      if output_file_path == nil then
        output_file_path = base_name .. ".gif"
      end
      output_file_path = vim.fn.expand(output_file_path)

      if vim.fn.filereadable(output_file_path) == 1 then
        if para.opts["force"] ~= "1" then
          vim.notify(string.format("Error '%s' already exists.", output_file_path), vim.log.levels.ERROR)
          return
        end
        os.remove(output_file_path)
      end

      -- 定義 ffmpeg 命令
      local palette_cmd = string.format(
        'ffmpeg -y -i "%s" -vf fps=%d,scale=%d:-1:flags=lanczos,palettegen "%s.png"',
        input_file,
        fps,
        width,
        base_name
      )

      local gif_cmd = string.format(
        'ffmpeg -i "%s" -i "%s.png" -filter_complex "fps=%d,scale=%d:-1:flags=lanczos[x];[x][1:v]paletteuse" -loop "%d" "%s"',
        input_file,
        base_name,
        fps,
        width,
        n_loop,
        output_file_path
      )
      local rm_cmd = string.format('%s.png', base_name) -- 刪除生成出來的調色盤檔案

      -- 執行轉換流程
      if not utils.os.execute_with_notify(palette_cmd, "Palette generated successfully", "Failed to generate palette") then
        return
      end

      if not utils.os.execute_with_notify(gif_cmd, "GIF generated successfully: " .. output_file_path, "Failed to generate GIF") then
        return
      end

      -- 清理調色盤檔案
      utils.os.remove_with_notify(rm_cmd, "Cleaned up palette file", "Failed to remove palette file")
    end,
    {
      desc = "convert video to gif",
      nargs = "+",
      complete = function(arg_lead, cmd_line)
        if arg_lead:match("^%-%-") then
          return utils.cmd.get_complete_list(arg_lead, {
            loop = {
              "0", -- 無限循環(預設)
              "1", -- 1次
              "5"  -- 播5次
            },
            o = {  -- output
              "temp.gif"
            },
            force = {
              "0",
              "1", -- 覆蓋，當輸出的檔案已存在
            }
          })
        end

        local argc = #(vim.split(cmd_line, "%s+")) - 1
        if argc == 1 then
          local video_extensions = { "%.mp4$", "%.mkv$", "%.avi$", "%.mov$", "%.flv$", "%.wmv$" }
          -- 取得所有檔案的補全清單
          local all_files = vim.fn.getcompletion(arg_lead, "file") -- 不需要expand(arg_lead)
          -- 過濾出影片檔案
          local video_files = {}
          for _, file in ipairs(all_files) do
            for _, ext in ipairs(video_extensions) do
              if file:match(ext) then
                table.insert(video_files, file)
                break
              end
            end
          end
          return video_files
        end

        if argc == 2 then -- width
          return {
            "320",
            "1000"
          }
        end

        if argc == 3 then -- fps
          return {
            "10",
            "25",
            "60",
          }
        end
      end
    }
  )

  vim.api.nvim_create_user_command("Video2Png",
    function(args)
      local para = utils.flag.parse(args.args)
      local input_file = vim.fn.expand(para.params[1])
      local fps = tonumber(para.params[2]) or -1

      local output = para.opts["o"] or "frame_%04d.png"
      local quality = tonumber(para.opts["q"]) or "1"

      if not input_file then
        vim.notify("Error: Input file is required!", vim.log.levels.ERROR)
        return
      end

      -- 檢查輸入檔案是否存在
      if vim.fn.filereadable(input_file) == 0 then
        vim.notify("Error: Input file '" .. input_file .. "' does not exist!", vim.log.levels.ERROR)
        return
      end

      -- "ffmpeg -i input.mp4 -vf fps=2 frame_%04d.png"  每秒2幀
      -- "ffmpeg -i input.mp4 frame_%04d.png" 保存每一幀
      local cmd = {
        -- "ffmpeg -i " .. input_file -- 在檔名有 - 的時候會有問題
        string.format("ffmpeg -i %q", input_file)
      }
      if fps ~= -1 then
        table.insert(cmd, string.format("-vf fps=%s", tonumber(fps)))
      end

      local ext = string.lower(vim.fn.fnamemodify(output, ":e"))
      if ext == "jpg" then
        -- 決定jpg出來的品質
        table.insert(cmd, "-q:v " .. quality)
      end

      table.insert(cmd, output)

      local cmd_str = table.concat(cmd, " ")
      print(cmd_str)

      utils.os.execute_with_notify(cmd_str, "generated successfully", "Failed to generate")
    end,
    {
      desc = "save each frame of video",
      nargs = "+",
      complete = function(arg_lead, cmd_line)
        if arg_lead:match("^%-%-") then
          local output = {
            "frame_%04d.png",
            "frame_%04d.jpg",
            "~/Downloads/frame_%04d.jpg",
          }
          if arg_lead:match("^%-%-o=") then
            -- 抓目前目錄
            for _, dir in ipairs(utils.complete.getDirOnly(string.sub(arg_lead, 5))) do -- 從--=開始算
              table.insert(output, dir .. "frame_%04d.png")
            end
          end

          return utils.cmd.get_complete_list(arg_lead, {
            o = output,
            q = {
              -- 1~31之間
              "1",  -- 幾乎無損, 檔案最大
              "5",  -- 視覺效果仍很好
              "10", -- 品質明顯下降
              "31", -- 最低品質
            }
          })
        end

        local argc = #(vim.split(cmd_line, "%s+")) - 1
        if argc == 1 then
          local video_extensions = { "%.gif$", "%.mp4$", "%.mkv$", "%.avi$", "%.mov$", "%.flv$", "%.wmv$" }
          local all_files = vim.fn.getcompletion(arg_lead, "file") -- 不需要expand(arg_lead)
          local video_files = {}
          for _, file in ipairs(all_files) do
            for _, ext in ipairs(video_extensions) do
              if file:match(ext) or
                  vim.fn.isdirectory(file) == 1 -- 目錄 (要是真實存在的目錄才會是1) -- :lua print(vim.fn.isdirectory("~/test")) -- 不吃~
              -- vim.fn.fnamemodify(file, ":e") == "" -- 目錄，這也行，但是比較不是那麼好
              then
                table.insert(video_files, file)
                break
              end
            end
          end
          return utils.table.sort_files_first(video_files)
        end

        if argc == 2 then -- fps
          return {
            "1",
            "5",
            "0.1",
            "0.5",
            "-1", -- 這是我自己定的，只是用來代表抓取每一幀
            "10",
            "25",
            "60",
          }
        end
      end
    }
  )

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

  vim.api.nvim_create_user_command("PrintBytes",
    -- 測試資料: U+25524 UTF-8: F0 A5 94 A4 GB18030: 0x96 0x39 0xA8 0x32
    function(args)
      if args.fargs[1] == "-h" then
        -- cmdUtils.showHelpAtQuickFix({
        utils.cmd.showHelpAtQuickFix({
          ':help encoding-values',
          'gb18030 test: U+25524 𥔤(0x9639 0xA832) https://www.unicode.org/cgi-bin/GetUnihanData.pl?codepoint=%F0%A5%94%A4',
          'https://www.cns11643.gov.tw/wordView.jsp?ID=682836',
          'https://encoding.spec.whatwg.org/gb18030.html',
          'sjis (shift-jis) test: U+ff71 ｱ (b1)  http://charset.7jp.net/sjis.html',
          'sjis (shift-jis) test: U+6a97 檗 (0x9f 0x40)',
          [[echo -ne '\xe4\xb8\x80' > temp.txt]],   -- 一的utf-8: e4 b8 80 -- -n表示不要寫入結尾的空行 -e 啟用反斜線轉義
          [[echo "e4b880" | xxd -r -p > temp.txt]], -- -r reverse(表示要環原, 即16進位轉成2進位格式) -- -p (plain hexdump) 即16進位資料是連續的、不帶格式的字串，沒有地址欄、空格或 ASCII 解釋等額外資訊 -- 不能寫成-rp
          [[xxd -c 1 temp.txt]],
        })
        return
      end
      local to_enc = args.fargs[1] -- ex gb18030
      local from_enc = args.fargs[2] or "utf-8"

      -- ❗
      -- lua用的是utf-8
      -- neovim不管當前你的文件是什麼編碼，就算實際文件儲的是gb18030的位元組資料，在開啟後不管你的fenc是什麼，你的畫面所呈現的都是utf-8所呈現出來的字符
      -- 即: neovim會嘗試將其轉換為utf-8來進行處理和顯示
      local char = table.concat(utils.range.get_selected_text(), "")

      local nr = 0
      if from_enc == "utf-8" or from_enc == "utf8" then
        nr = vim.fn.char2nr(char) -- Return Number value of the first char in {string}
        char = vim.fn.nr2char(nr) -- 只抓一個字，如此就不容易混淆, 如果真需要大的片段，可以直接 :SaveAsWithEnc 的方式去另儲
      end

      if #char == 0 then
        vim.notify("選取內容為空", vim.log.levels.ERROR)
        return
      end

      -- 將字符轉換為 target 編碼的字節
      local target_bytes = vim.fn.iconv(char, from_enc, to_enc)
      if target_bytes == "" then
        print(string.format("Cannot convert %s to %s", from_enc, to_enc))
        return
      end

      -- 將字節序列轉為十六進制表示
      local hex_target = {}
      for i = 1, #target_bytes do
        table.insert(hex_target, string.format("0x%02X", string.byte(target_bytes, i)))
      end

      local hex_utf8 = {}
      for i = 1, #char do
        local byte = string.byte(char, i);
        table.insert(hex_utf8, string.format("%02X", byte))
      end

      local unicode = string.format(", %s U+%04X", char, nr) -- 因為nvim中已經會將所有內容都以utf-8來處理，所以char本身就是utf-8的內容

      print("Character: " .. char,
        unicode,
        ", UTF-8 Bytes: " .. table.concat(hex_utf8, " "),
        string.format(", %s Bytes: %s", to_enc, table.concat(hex_target, " "))
      )
    end,
    {
      desc = ":PrintBytes enc_dsc enc_src 將來源為編碼(預設:utf-8)的選取內容，打印出其指定編碼所對應的字節",
      range = true,
      nargs = "+",
      complete = function(arg_lead, cmd_line)
        local argc = #(vim.split(cmd_line, "%s+")) - 1
        local matches = {}
        for _, enc in ipairs(utils.encoding.get_encoding_list()) do
          if enc:find('^' .. arg_lead:lower()) then -- 這種方法在arg_lead為空的時候也會匹配
            table.insert(matches, enc)
          end
        end
        if argc == 2 and arg_lead == "" then
          -- 這種時候將utf-8放到一開始，讓其曉得應該是來源
          return { "utf-8", unpack(matches) }
        end
        return matches
      end
    }
  )

  vim.api.nvim_create_user_command("InsertBytes",
    function(args)
      if args.fargs[1] == "-h" then
        utils.cmd.showHelpAtQuickFix({
          [[echo -ne '\xe4\xb8\x80' >> temp.txt]], -- 也可以用bash來寫byte進去 -- -n會接著寫，如果不加會從下一個列開始附加
          [[echo "e4b880" | xxd -r -p >> temp.txt]],
          [[set fenc=]],
          [[如果fileencoding不對，會不給儲檔, 會有錯誤E513: Write error, conversion failed (make 'fenc' empty to override), 此時可以用:set fenc= 來解決]],
          [[ 當fenc錯誤時用 :set fenc=binary 也可以，但是需要用w!才能儲檔, 但是用xxd的時候可能還是會遇到問題，所以還是用:set fenc= 會比較好 ]],
          [[ ⚠ 使用:set fenc= 或 binary以後，所有的文字其bytes會被轉成utf-8的bytes. 例如原本在enc=gb18030看到的𥔤(0x9639_a832) 會被改成(0xf0 0xa5 0x94 0xa4)而看到的還是unicode的形也就是𥔤，因此這時候再回到gb18030看到的內容就會不同了(因為是基於f0 a5 94 a4去換) ]],
          "'<,'>!xxd -c 1",
          'xxd -c 1 xxx.txt',
          '⚠ 此指令是插入所以不能在空列中使用, 會看到錯誤的結果',
          ':lua print(tonumber(0xe4))',
          ':lua print(tonumber(30, 16))',
          ':lua print(tonumber(0011, 2))',
        })
        return
      end
      local para = utils.flag.parse(args.args)
      local base = para.opts["base"] or ""
      for _, str in ipairs(para.params) do
        local num = 0
        if base == "16" or str:find("0x") then
          -- 將 16 進位字串轉為數字（支持 0x 格式或純數字）
          num = tonumber(str, 16)
        else
          num = tonumber(str, 10)
        end
        if not num then
          vim.notify("無效的 16 進位數值: " .. num, vim.log.levels.ERROR)
          return
        end
        -- 轉為字符
        local char = string.char(num)
        -- 獲取當前光標位置
        local pos = vim.api.nvim_win_get_cursor(0)
        local row = pos[1] - 1 -- 行數 (0-based)
        local col = pos[2]     -- 列數 (0-based)
        -- 插入字符到當前光標位置
        vim.api.nvim_buf_set_text(0, row, col, row, col, { char })
        -- 移動光標到插入後的位置
        vim.api.nvim_win_set_cursor(0, { row + 1, col + #char })
      end
    end,
    {
      desc = "插入位元組. 也可以用bash的echo -e, xxd -r -p來幫忙. 請查看 :InsertBytes -h ",
      nargs = "+",
      complete = function(arg_lead)
        if arg_lead:match("^%-%-") then
          return utils.cmd.get_complete_list(arg_lead, {
            base = { "16", "10" },
          })
        end
        return {
          "0xe4 0xb8 0x80",
          "0xe4 0xb8 128", -- :lua print(tonumber(0xe4))
          "e4 b8 80 --base=16",
        }
      end
    }
  )


  vim.api.nvim_create_user_command("SaveAsWithEnc",
    -- 🧙 `:w ++enc=gb18030` 新檔案名 可以轉換後並另存檔案
    function(args)
      if args.fargs[1] == "-h" then
        utils.cmd.showHelpAtQuickFix({
          "如果當前的文件其fenc未知或者內容無法與其匹配時，會沒有辦法執行",
          "如果是用byte(`:set fenc=`)來寫，想另儲可以直接用:w!之後用系統的cp來複製文件，或者直接用:EditWithEnc來查看也行",
        })
        return
      end
      local encoding = args.fargs[1] or "utf-8"
      local output_file_path = args.fargs[2]
      local is_bang = args.bang and "!" or ''
      vim.cmd(string.format('w%s ++enc=%s %s', is_bang, encoding, output_file_path))
    end,
    {
      desc = "用指定的encoding來另儲新檔",
      nargs = "+",
      bang = true, -- 如果檔案已經存在可以用 ! 來強制儲
      complete = function(arg_lead, cmd_line)
        local argc = #(vim.split(cmd_line, "%s+")) - 1

        if argc == 2 then
          return {
            vim.fn.expand("%"),                            -- 第一次放當前的檔案(相對路徑)
            unpack(vim.fn.getcompletion(arg_lead, "file")) -- 包含檔案和目錄 -- 記得unpack一定要在最後一項
          }
        end

        if argc == 1 then
          local matches = {}
          for _, enc in ipairs(utils.encoding.get_encoding_list()) do
            if enc:find('^' .. arg_lead:lower()) then
              table.insert(matches, enc)
            end
          end
          return matches
        end
      end
    }
  )

  vim.api.nvim_create_user_command("EditWithEnc",
    -- `:e ++enc=gb18030 myFile` 可以用該編碼來檢示文件(但不等於轉換編碼)
    function(args)
      local encoding = args.fargs[1] or "utf-8"

      local output_file_path = args.fargs[2] or "."
      if output_file_path == "." then           -- 視為用目前的檔案來開啟
        output_file_path = vim.fn.expand("%:p") -- cur abs path
      end
      vim.cmd(string.format('e ++enc=%s %s', encoding, output_file_path))
    end,
    {
      desc = "用指定的編碼來開啟文件" ..
          "⚠ 它不等於轉換編碼. 也就是說這僅當你確定檔案的編碼時，用此方法可以得到正確的識別." ..
          "如果要做編碼的轉換，請使用 `:SaveAsWithEnc`",
      nargs = "+",
      complete = function(arg_lead, cmd_line)
        local argc = #(vim.split(cmd_line, "%s+")) - 1

        if argc == 2 then
          return utils.complete.get_file_only(arg_lead)
        end

        if argc == 1 then
          local matches = {}
          for _, enc in ipairs(utils.encoding.get_encoding_list()) do
            if enc:find('^' .. arg_lead:lower()) then
              table.insert(matches, enc)
            end
          end
          return matches
        end
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

  vim.api.nvim_create_user_command("GitLog",
    function(args)
      local git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
      if vim.v.shell_error ~= 0 then
        vim.notify("Not in a Git repository", vim.log.levels.ERROR)
        return
      end

      local bash_cmd = "exec bash"
      local sep = ";"
      if osUtils.IsWindows then
        bash_cmd = "cmd"
        sep = " & "
      end

      if #args.fargs == 0 then
        -- git log 可以指定從哪一個sha1開始，如果省略就是從頭列到尾
        -- vim.cmd("term git log --reverse -- xxx.cpp")
        vim.cmd("term git --no-pager log" .. sep .. bash_cmd)
        return
      end

      local sha1 = ""
      if args.fargs[1] == "." or args.fargs[1] == "HEAD" then
        sha1 = ""
      else
        sha1 = vim.split(args.fargs[1], "　")[1] -- U+3000來拆分
      end

      local opt_reverse = ""
      for opt, val in args.fargs[2]:gmatch("--([a-zA-Z0-9_]+)=([^%s]+)") do
        if opt == "reverse" and (val == "true" or val == "1") then
          opt_reverse = "--reverse"
        end
      end

      local files = {}
      for i = 3, #args.fargs do
        files[#files + 1] = git_root .. "/" .. args.fargs[i]
      end

      -- table.concat(table, concat_what, start, end)
      -- local file_relative_path = table.concat(args.fargs, " ", 3) -- 接下來的每一個內容都是為檔案, 這可以，但是路徑是相對路徑，只能在root上使用
      local file_abs_paths = table.concat(files, " ")
      if #file_abs_paths > 0 then
        -- file_relative_path = "-- " .. file_relative_path -- 相對路徑會吃工作目錄，工作目錄不對結果就出不來
        file_abs_paths = "-- " .. file_abs_paths
      end
      local run_cmd = string.format("term git log %s %s %s", sha1, opt_reverse, file_abs_paths)
      -- print(run_cmd)
      -- vim.cmd(run_cmd) -- 這個不能再繼續打指令
      vim.cmd(run_cmd .. sep .. bash_cmd)
    end,
    {
      nargs = "*",
      complete = function(argLead, cmdLine)
        local parts = vim.split(cmdLine, "%s+")
        local argc = #parts - 1

        -- 先用git log找所有commit的sha1
        -- local cmg_git_log = 'git --no-pager log --pretty=format:"%H　%s　%ai"' -- 分隔符用U+3000來區分, %H 是長版本的sha1 (40個字母)
        local cmg_git_log = 'git --no-pager log --pretty=format:"%h　%s　%ai"' -- %h是短版本的sha1, 7個字母
        local commit_info = vim.fn.systemlist(cmg_git_log)
        if argc == 1 then
          if #argLead == 0 then
            -- 避免有多的空白. 遍歷 commit_info，每個項目中的換行和空白都替換成底線
            for i, v in ipairs(commit_info) do
              commit_info[i] = v:gsub("[%s\n]+", "_")
            end

            return commit_info
          end

          -- 篩選出argLead的項目就好
          -- local input_sha_txt = parts[2]
          local filtered_logs = {}
          for _, line in ipairs(commit_info) do
            if line:find(argLead) then
              table.insert(filtered_logs, line)
            end
          end
          for i, v in ipairs(filtered_logs) do
            filtered_logs[i] = v:gsub("[%s\n]+", "_")
          end
          return filtered_logs
        end


        if argc == 2 then
          return cmdUtils.get_complete_list(argLead, {
            reverse = {
              "true",
              "false",
            }
          })
        end

        -- local sha1 = string.sub(cmdLine, 8, 14) -- (#"GitLog" + 1) + 1(空格), 之後會接sha1 -- 這可行但有點麻煩
        local sha1 = ""
        if parts[2] == "." or parts[2] == "HEAD" then
          sha1 = ""
        else
          sha1 = string.sub(parts[2], 1, 7) -- parts[1] 是指令本身，這裡是GitLog
        end

        -- local files = vim.fn.systemlist("git --no-pager show --name-only --pretty=format: " .. sha1) -- 這個是取得當時後有異動的檔案
        local files = vim.fn.systemlist("git --no-pager log --name-only --diff-filter=A --pretty=format: " .. sha1) -- 這是那時候，所有曾經被commit過的檔案都會出來 (主要就是靠--diff-filter=A) A是指Added
        arrayUtils.remove_empty_items(files)

        -- 這邊的files路徑，可以不需要轉換成絕對路徑，因為只要能辨識即可，真正在執行git的時候再轉成絕對路徑即可

        if #argLead > 0 then
          local filtered_files = {}
          for i = 1, #files do
            if files[i]:find(argLead) then
              table.insert(filtered_files, files[i])
            end
          end
          return filtered_files
        end
        return files
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
      complete = function()
        return { string.format("%s", vim.fn.getline('.')) }
      end
    }
  )

  vim.api.nvim_create_user_command("QFAppend",
    function(args)
      local text = ""
      if #args.fargs > 0 then
        text = args.fargs[1]
      elseif args.range ~= 0 then
        text = table.concat(utils.range.get_selected_text(), '')
      else
        text = vim.fn.getline('.')
      end

      -- local filepath = vim.fn.expand('%') -- 預設是以相對路徑為考量
      local filepath = vim.fn.expand('%:.') -- 明確的告知是需要用相對路徑
      local line = vim.fn.line('.')
      local col = vim.fn.col('.')
      local cmd = string.format(
        [[ caddexpr '%s' .. ":" .. %d .. ":" .. %d .. ":".. '%s' ]],
        filepath, line, col, text
      )
      vim.cmd(cmd)
      utils.cmd.open_qflist_if_not_open()
    end,
    {
      desc = "將目前的內容附加到quickfix list清單中(成為最後一筆資料)",
      range = true,
      nargs = "?",
      complete = function()
        return { string.format("%s", vim.fn.getline('.')) }
      end
    }
  )

  for _, item in ipairs {
    { "QFInsertMany", "caddexpr" },
    { "LFInsertMany", "laddexpr", " (for location list)" },
  } do
    local cmdName = item[1]
    local qfExpr = item[2]
    local descExtra = item[3] or ""
    vim.api.nvim_create_user_command(cmdName,
      function(args)
        if args.range == 0 then
          vim.notify('only support range', vim.log.levels.ERROR)
          return
        end

        --- @type table
        local texts = utils.range.get_selected_text()
        for _, line in ipairs(texts) do
          local filepath, row, col, desc = string.match(line, "(.-):(%d+):(%d+):(.+)")
          if filepath and row and col and desc then
            local is_abspath = filepath:match('^/') or vim.fn.fnamemodify(filepath, ':p'):match('^/')
            if not is_abspath and not filepath:match('^~') then
              filepath = "./" .. filepath
            end

            -- local cmd = "./" .. line -- 這不行，要引號包起來才不會誤判
            local cmd = string.format(
              [[ %s '%s' .. ":" .. %d .. ":" .. %d .. ":".. '%s' ]], -- col如果沒有可以省略，預設為1
              qfExpr,
              filepath, row, col, desc
            )
            vim.cmd(cmd)
          else
            vim.notify(string.format("'%s' ", line) .. "not match (.-):(%d+):(%d+):(.+)", vim.log.levels.WARN)
          end
        end
      end,
      {
        desc = "選取 rg --vimgrep 的結果插入到quickfix表之中" .. descExtra,
        range = true,
      }
    )
  end


  vim.api.nvim_create_user_command("Ladd",
    function(args)
      local text
      if args.range == 0 then
        if #args.fargs > 0 then
          text = args.fargs[1]
        else
          text = vim.fn.getline('.')
        end
      else
        text = args.fargs[1] or table.concat(utils.range.get_selected_text(), "")
      end
      local filepath = vim.fn.expand('%')
      local cmd = string.format(
        [[ laddexpr '%s' .. ":" .. line(".") .. ":" .. %d .. ":" .. '%s' ]],
        filepath, vim.fn.col('.'), text
      )
      vim.cmd(cmd)
    end,
    {
      desc = "將目前的位置使用laddexpr插入",
      nargs = "?",
      range = true,
      complete = function()
        return {
          string.format("%s", vim.fn.getline('.'):gsub(" ", "")) -- 用目前這列的內容當成提示
        }
      end
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

  for _, item in ipairs {
    { "QFDeleteMany", vim.fn.getqflist, vim.fn.setqflist },
    -- { "LFDeleteMany", function() -- 不可行. 會被抱怨正在使用而無法進行
    --   return vim.fn.getloclist(0)
    -- end,
    --   vim.fn.setloclist, " (for location list)"
    -- },
  } do
    local cmdName = item[1]
    local getListFunc = item[2]
    local setListFunc = item[3]
    local descExtra = item[4] or ""
    vim.api.nvim_create_user_command(cmdName,
      function()
        -- local qf_list = vim.fn.getqflist()
        local qf_list = getListFunc()

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
            setListFunc(qf_list, 'r')
            -- vim.fn.setqflist(qf_list, 'r')
            -- vim.fn.setloclist(qf_list, 'r')
          else
            vim.notify("選中的 quickfix 項目無效或列表為空", vim.log.levels.ERROR)
          end
        else
          -- 沒有視覺選擇時，移除當前行（原邏輯）
          local cur_idx = vim.api.nvim_win_get_cursor(0)[1] - 1
          if next(qf_list) ~= nil and cur_idx >= 0 and cur_idx < #qf_list then
            table.remove(qf_list, cur_idx + 1)
            -- vim.fn.setqflist(qf_list, 'r')
            setListFunc(qf_list, 'r')
          else
            vim.notify("無效的 quickfix 項目或列表為空", vim.log.levels.ERROR)
          end
        end
      end,
      {
        desc = "刪除選中的quickfix項目 (支援多選, V-LINE)" .. descExtra,
        range = true,
      }
    )
  end


  vim.api.nvim_create_user_command("QFNew", function(args)
      local title = args.fargs[1]
      vim.fn.setqflist({}, ' ', -- If {action} is not present or is set to ' ', then a new list is created
        {
          title = title,
          user_data = {
            c_time = os.date("%Y/%m/%d %H:%M:%S", os.time())
          }
        }
      )
    end,
    {
      desc = "建立新的qflist",
      nargs = 1,
      complete = function()
        return {
          string.format("%s", vim.fn.getline('.'):gsub(" ", ""))
        }
      end
    }
  )

  vim.api.nvim_create_user_command("LNew", function(args)
      local title = args.fargs[1]
      vim.fn.setloclist(
        0,   -- nr can be the window number or the window-ID
        {},
        ' ', -- If {action} is not present or is set to ' ', then a new list is created
        {
          title = title,
          user_data = {
            c_time = os.date("%Y/%m/%d %H:%M:%S", os.time())
          }
        }
      )
    end,
    {
      desc = "Create the location list for current window",
      nargs = 1,
      complete = function()
        return {
          string.format("%s", vim.fn.getline('.'):gsub(" ", ""))
        }
      end
    }
  )

  vim.api.nvim_create_user_command('QFDestroy', function(args)
      local title = args.args
      local cur_qf = vim.fn.getqflist({ id = 0, all = 1 })
      local total_nr = vim.fn.getqflist({ nr = '$' }).nr
      local all_qf_list = {}                -- 先取得所有的qf_list
      pcall(vim.cmd, "colder " .. total_nr) -- 先回到開始, 超過也沒關係，就是到第一筆為此
      while true do
        local qf = vim.fn.getqflist({ id = 0, all = 1 })
        if qf.title ~= title and
            qf.nr ~= cur_qf.nr then -- 這筆如果要增，放到最後，這樣比較方便再換回去
          table.insert(all_qf_list, qf)
        else
          print("Destroyed qflist: " .. title)
        end
        if not pcall(vim.cmd, "cnewer") then
          break
        end
      end

      vim.fn.setqflist({}, 'f') -- 這個會所有的都清空，這也就是為什麼前面我們要先取的原因

      -- 重新添加
      for i = 1, #all_qf_list do
        -- vim.fn.setqflist(all_qf_list[i], " ") -- 不能這樣
        vim.fn.setqflist({}, " ", {
          -- id = i, -- 這個不要去改，系統會自動算, 即便已經-f了，id自動分配還是接續之前的流水號
          title = all_qf_list[i].title,
          items = all_qf_list[i].items,
          user_data = all_qf_list[i].user_data,
        })
      end

      if cur_qf.title ~= title then
        -- 將一開始的qf表插入到最下面
        vim.fn.setqflist({}, " ", {
          title = cur_qf.title,
          items = cur_qf.items,
          user_data = cur_qf.user_data,
        })
        pcall(vim.cmd, "cnewer " .. total_nr) -- 在移到最下面，如此qflist還是最原本的選中項
      end
    end,
    {
      desc = "刪除指定名稱的qflist",
      nargs = 1,
      complete = function(argLead)
        local chistory_output = vim.fn.execute("chistory") -- 🚀 算是一種取巧的方法，不能要再用corder, cnewer很麻煩. 利用解析其輸出，得到想要的資料
        local qf_title_list = {}
        for line in chistory_output:gmatch("[^\r\n]+") do
          local tail = line:match("errors%s+([^%s].+)$") -- 每一列結尾的文件就是title
          if tail then
            table.insert(qf_title_list, tail)
          end
        end

        if #argLead == 0 then
          return qf_title_list
        end
        local filtered = {}
        for _, item in ipairs(qf_title_list) do
          if item:find(argLead) then
            table.insert(filtered, item)
          end
        end
        return filtered
      end,
    })

  vim.api.nvim_create_user_command("QFCopy", function(args)
      local src_title = string.gsub(args.fargs[1], "　", " ")
      local dst_title = string.gsub(args.fargs[2], "　", " ")

      local total_nr = vim.fn.getqflist({ nr = '$' }).nr
      pcall(vim.cmd, "colder " .. total_nr) -- 先回到開始

      -- 獲取所有現有的 quickfix lists
      local src_qf
      while true do
        local qf = vim.fn.getqflist({ id = 0, all = 1 })
        if qf.title == src_title then
          src_qf = qf
          break
        end
        if not pcall(vim.cmd, "cnewer") then
          break
        end
      end

      if not src_qf then
        vim.notify("src qflist:" .. src_title .. " not found", vim.log.levels.ERROR)
        return
      end

      pcall(vim.cmd, "colder " .. total_nr) -- 再回到開始

      while true do
        local qf = vim.fn.getqflist({ id = 0, all = 1 })
        if qf.title == dst_title then
          local new_item = {
            title = qf.title,
            items = src_qf.items,
            user_data = src_qf.user_data,
          }
          if not new_item.user_data then
            new_item.user_data = {}
          end
          new_item.user_data.c_time = os.date("%Y/%m/%d %H:%M:%S", os.time())
          new_item.user_data.copied_from = src_qf.title
          vim.fn.setqflist({}, "r", new_item) -- 覆蓋該qf list
          vim.notify("已從 " .. src_qf.title .. " 複製到 " .. qf.title)
          return
        end
        if not pcall(vim.cmd, "cnewer") then
          break
        end
      end

      -- 如果dst_title沒有找到，表示還沒有創建，這時候就視為新增
      local new_item = {
        title = dst_title,
        items = src_qf.items,
        user_data = src_qf.user_data,
      }
      if not new_item.user_data then
        new_item.user_data = {}
      end
      new_item.user_data.c_time = os.date("%Y/%m/%d %H:%M:%S", os.time())
      new_item.user_data.copied_from = src_qf.title
      vim.fn.setqflist({}, " ", new_item) -- create
      vim.notify("已從 " .. src_qf.title .. " 複製到新建立的: " .. dst_title)
    end,
    {
      -- 因為vimgrep都是在固定的qf表，所以如果想要將其保存到其它地方，就可以使用這種方法
      desc = "複製指定的 quickfix list 到新的 quickfix list",
      nargs = "+", -- 需要兩個參數：來源標題和目標標題
      complete = function(argLead)
        local chistory_output = vim.fn.execute("chistory")
        local qf_title_list = {}
        for line in chistory_output:gmatch("[^\r\n]+") do
          local title = line:match("errors%s+([^%s].+)$")
          if title then
            local s = string.gsub(title, " ", "　")
            table.insert(qf_title_list, s) -- 將空白換成U+3000避免參數分割錯
          end
        end

        if #argLead == 0 then
          return qf_title_list
        end
        local filtered = {}
        for _, item in ipairs(qf_title_list) do
          if item:find(argLead) then
            table.insert(filtered, item)
          end
        end
        return filtered
      end,
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

        local result = utils.sway.set_window_opacity(pid, opacity)
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
          local nodes = utils.sway.get_tree()
          if #argLead > 0 then
            nodes = vim.tbl_filter(function(node)
              return string.find((node.name .. node.pid), argLead) ~= nil
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

  vim.api.nvim_create_user_command("SetOpacity",
    function(args)
      os.execute(string.format([[sway for_window [app_id=".*"] opacity %s]], args.fargs[1]))
    end,
    {
      desc = "設定Sway中所有app_id的透明度(舊有的視窗不影響，只會影響新開的視窗)",
      nargs = 1,
      complete = function(_, cmd_line)
        local argc = #(vim.split(cmd_line, "%s+")) - 1
        if argc == 1 then
          return {
            "0.85",
            "0.90",
            "0.95",
            "1.00",
            "0.8",
          }
        end
      end
    }
  )

  vim.api.nvim_create_user_command("SwayFocus",
    -- 📝 以pid，firefox的窗口都是相同的pid，所以跳轉可能不如預期
    function(args)
      local para = utils.flag.parse(args.args)
      local pid = para.opts["pid"]
      print(vim.inspect(para))
      if pid then -- 有pid時則優先
        os.execute(string.format("swaymsg [pid=%s] focus", pid))
        return
      end

      if #para.params == 0 then
        return
      end

      local name = para.params[1]
      if name then
        -- sway似乎沒有name或title的方式，只然透過name去找pid
        -- name = string.sub(name, 2, #name - 1) -- 去除開頭與結尾的"或'
        name = string.gsub(name, "　", " ")
        local nodes = utils.sway.get_tree()
        for _, node in ipairs(nodes) do
          if node.name == name then
            os.execute(string.format("swaymsg [pid=%s] focus", node.pid))
            return
          end
        end
        return
      end
    end,
    {
      desc = "swaymsg [pid=1234] focus 透過pid或name聚焦到指定的窗口",
      nargs = 1,
      complete = function(arg_lead, cmd_line)
        local argc = #(vim.split(cmd_line, "%s+")) - 1
        if argc > 1 then
          return {}
        end

        local cmp_pid = {}
        local cmp_name = {}

        local nodes = utils.sway.get_tree()
        for _, node in ipairs(nodes) do
          table.insert(cmp_pid, tostring(node.pid))
          local name, _ = string.gsub(node.name, " ", "　") -- string, count
          table.insert(cmp_name, name)
        end

        if arg_lead:match("^%-%-") then
          return utils.cmd.get_complete_list(arg_lead, {
            pid = cmp_pid,
          })
        end
        return cmp_name -- 預設使用名稱(比較容易識別)
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
        {
          -- -c:v libx264 使用H.264編碼器重新編碼視訊
          -- -c:a aac 用AAC編碼器重新編碼音訊
          text = string.format("ffmpeg -i %s -c:v libx264 -c:a aac %s  👈 如果有些播放器不行播可以嘗試使用此指令重新編碼視、音訊來解決",
            vim.fn.shellescape(output_mp4_path),                           -- input
            vim.fn.shellescape(output_mp4_path:gsub("%.mp4$", "_fix.mp4")) -- output
          )
        }
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

  vim.api.nvim_create_user_command("Voice",
    function(args)
      os.execute("amixer sset Master " .. args.fargs[1])
    end,
    {
      desc = "聲音調整",
      nargs = 1,
      complete = function(_, cmdLine)
        local parts = vim.split(cmdLine, "%s+")
        local argc = #parts - 1
        if argc == 1 then
          return {
            "5%+", -- 相對音量
            "5%-",
            "20%", -- 音量設定為某數值
          }
        end
      end
    }
  )
  vim.api.nvim_create_user_command("VoiceToggle",
    function()
      os.execute("amixer sset Master toggle")
    end,
    {
      desc = "靜音切換",
      nargs = 0,
    }
  )


  local highlight_map = {}
  vim.api.nvim_create_user_command('Highlight',
    -- match Search /\%>11l\%<22l/ -- 整列
    -- match Search /\%>11l\%<22l\vSearch_content/ -- 該範圍的指定內容, 後面要接\c(忽略大小寫)或者\v
    -- match Search /\%>11l\%<22lend/ -- 也可以不接\c, \v直接用搜尋文字
    function(args)
      local hl_group = args.fargs[1]

      -- 檢查高亮組是否存在
      if vim.fn.hlexists(hl_group) == 0 then
        if hl_group:match('#%x%x%x%x%x%x') then
          local fg_color = hl_group
          hl_group = "TMP_" .. string.sub(hl_group, 2) -- nvim_set_hl的group不能用#112233的方式(Invalid character in group name)
          local win_id = vim.api.nvim_get_current_win()
          local ns_id = vim.api.nvim_create_namespace("Highlight_" .. win_id)
          vim.api.nvim_set_hl(ns_id, hl_group, { fg = fg_color })
          vim.api.nvim_win_set_hl_ns(win_id, ns_id)
        else
          vim.notify('Highlight group "' .. hl_group .. '" does not exist', vim.log.levels.WARN)
          return
        end
      end

      -- 獲取當前光標行號和緩衝區最大行數
      local current_line = vim.fn.line('.')
      local max_lines = vim.fn.line('$')


      if args.range ~= 0 then -- 似乎只有0與2(range)
        -- local start_pos = vim.fn.getpos("v") -- 視覺模式的起點
        -- local end_pos = vim.fn.getpos(".")   -- 當前光標的位置當作終點, 這不行會與v同一行
        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")
        local line1, col1 = start_pos[2], start_pos[3] -- 1 開始 ~ 2147483647
        local line2, _ = end_pos[2], end_pos[3]
        -- local mode = vim.fn.mode() -- 得到的都是n沒有辦法區分出v或V
        if col1 ~= 1 then -- 因為如果是V一定是1, 雖然v也以是1，但是一般而言比較少(而且也可以避開，從2開始v就好)
          -- v mode
          local selected_text = table.concat(utils.range.get_selected_text(), "")
          args.fargs[2] = selected_text
        end
        args.fargs[3] = line1 .. "-" .. line2
        -- print(args.fargs[2], args.fargs[3])
      elseif #args.fargs < 3 then
        -- 如果省略，就會用全部的範圍
        -- :match Search /func.*)/
        args.fargs[3] = "1-" .. max_lines
      end

      -- 處理剩餘的行號參數
      local line_patterns = {}
      for i = 3, #args.fargs do
        local arg = args.fargs[i]
        -- 處理範圍格式 (例如 10-15, +10-+15, -5--2)
        if arg:match('^[+-]?%d+%-[+-]?%d+$') then
          local start_str, end_str = arg:match('^([+-]?%d+)%-([+-]?%d+)$')
          -- print("Range start: " .. start_str .. ", end: " .. end_str)
          local start_clean = start_str:gsub('[+-]', '')
          local end_clean = end_str:gsub('[+-]', '')
          local start_line = tonumber(start_clean)
          local end_line = tonumber(end_clean)
          if not start_line or not end_line then
            vim.notify('Invalid number in range: ' .. arg, vim.log.levels.WARN)
          else
            -- 處理相對位置
            if start_str:match('^+') then
              start_line = current_line + start_line
            elseif start_str:match('^-') then
              start_line = current_line - start_line
            end
            if end_str:match('^+') then
              end_line = current_line + end_line
            elseif end_str:match('^-') then
              end_line = current_line - end_line
            end
            if start_line < 1 or end_line < 1 then
              vim.notify('Range ' .. arg .. ' starts or ends before line 1', vim.log.levels.WARN)
            elseif start_line > max_lines or end_line > max_lines then
              vim.notify('Range ' .. arg .. ' exceeds buffer size (' .. max_lines .. ')', vim.log.levels.WARN)
            else
              if start_line > end_line then
                start_line, end_line = end_line, start_line -- 交換大小值
              end
              local pattern = string.format([[\%%>%dl\%%<%dl]], start_line - 1, end_line + 1)
              table.insert(line_patterns, pattern)
            end
          end
          -- 處理單一行號 (例如 5, +5, -5)
        elseif arg:match('^[+-]?%d+$') then
          local line_str = arg
          -- print("Single line: " .. line_str)
          local line_clean = line_str:gsub('[+-]', '')
          local line = tonumber(line_clean)
          if not line then
            vim.notify('Invalid number: ' .. arg, vim.log.levels.WARN)
          else
            -- 處理相對位置
            if line_str:match('^+') then
              line = current_line + line
            elseif line_str:match('^-') then
              line = current_line - line
            end
            if line < 1 then
              vim.notify('Line ' .. arg .. ' is before line 1', vim.log.levels.WARN)
            elseif line > max_lines then
              vim.notify('Line ' .. arg .. ' exceeds buffer size (' .. max_lines .. ')', vim.log.levels.WARN)
            else
              local pattern = [[\%]] .. line .. [[l]]
              table.insert(line_patterns, pattern)
            end
          end
        else
          vim.notify('Invalid line specification: ' .. arg, vim.log.levels.WARN)
        end
      end

      -- 檢查是否有有效的模式
      if #line_patterns == 0 then
        vim.notify('No valid line numbers provided', vim.log.levels.ERROR)
        return
      end

      -- 合併所有模式，使用 '|' 分隔
      local pattern = table.concat(line_patterns, [[\|]])
      -- print("Final pattern: " .. pattern)

      -- 應用 match 高亮
      local search_text = args.fargs[2]
      if search_text ~= "*" then
        pattern = pattern .. search_text
      end
      -- print(pattern)

      local m = vim.fn.matchadd(hl_group, pattern)
      -- :lua vim.fn.matchadd('Search', [[\%5l]])
      -- :lua vim.fn.matchadd('Search', '\\%>99l\\%<201l\\vim')
      -- :lua vim.fn.matchadd('Search', [[\%>99l\%<201l\vim]])
      -- :lua print([[\%>99l\%<201l\vim]])

      highlight_map[pattern] = m
    end,
    {
      desc = 'Highlight specified lines with a highlight group',
      range = true,
      nargs = '+',
      complete = function(arg_lead, cmd_line)
        local parts = vim.split(cmd_line, "%s+")
        local argc = #parts - 1
        if argc == 1 then
          local hl_groups = vim.fn.getcompletion('', 'highlight')
          if arg_lead ~= '' then
            hl_groups = vim.tbl_filter(function(hl)
              return hl:lower():find(arg_lead:lower(), 1, true) == 1
            end, hl_groups)
          end
          return hl_groups
        end

        if argc == 2 then
          return {
            "*",
            "print",
            "m_[^.]*",          -- 找成員，例如m_foo, ...
            [[m_\w]],           -- \w word(字母、數字、下劃線)
            "m_[^.\\ ]*",       -- 不含.和空白
            [[\d\d]],           -- 找兩個數字(含)以上
            [[\v\d{4}]],        -- 至少4個數字
            [[m_.*\.Set.*)]],   -- 例如m_foo.Set
            [[\cm_.*\.Set.*)]], -- m_foo.Set...), m_bar.set...)
            "func.*)",

            -- [[^\s*Bk.*]],    -- 這種匹配方法，前面的空白、制表符也都會被突顯，所以可以利用\zs來幫忙
            [[^\s*\zsBk.*]], -- \zs zero-width assertions 零寬度斷言，代表會從這裡開始匹配

            [[\v.*]],        -- very magic
            [[\V.]],         -- very nomagic 用這樣就可以找所有`.`
            [[\cuser]],      -- 忽略大小寫
            [[\s]],          -- space, tab
            [[\S]],          -- non space
            [[\w]],          -- 字母、數字、下劃線
            [[\W]],          -- 非\w
            [[\d]],          -- 數字
            [[\D]],          -- 非\d
          }
        end
        return {
          "-3-+7",         -- 相對位置
          "3 5 10-15",     -- 絕對位置
          "+3 +5 +10-+15", -- 正相對位置
          "3 +5 +10-+15",  -- 混合範例
          "-3 -5 -10--10"  -- 負相對位置
        }
      end
    }
  )
  vim.api.nvim_create_user_command("HighlightDelete",
    function(args)
      local pattern = args.fargs[1]
      local m = highlight_map[pattern]
      if m then
        vim.fn.matchdelete(m)
        highlight_map[pattern] = nil
      else
        vim.notify("沒有匹配的highlight項目", vim.log.levels.ERROR)
      end
    end,
    {
      desc = "刪除透過Highlight命令加入的產物",
      nargs = 1,
      complete = function(arg_lead, cmd_line)
        local parts = vim.split(cmd_line, "%s+")
        local argc = #parts - 1
        if argc == 1 then
          local patterns = {}
          for pattern in pairs(highlight_map) do
            if string.find(pattern, arg_lead) then
              table.insert(patterns, pattern)
            end
          end
          return patterns
        end
      end
    }
  )

  create_user_command_jumps_to_qf_list()


  --- 保存conceal的記錄，使得有辦法刪除
  local conceal_mappings = {}
  vim.api.nvim_create_user_command("Conceal",
    function(args)
      local random_ns_id = "conceal_" .. vim.fn.rand()
      local emoji = args.fargs[1] or "🫣"
      extmarkUtils.set_conceal( -- 要等ModeChanged才會生效，所以之後v再換回
        random_ns_id,
        {
          patterns = { table.concat(utils.range.get_selected_text(), "") },
          conceal = emoji
        }
      )
      conceal_mappings[emoji] = random_ns_id
      -- vim.cmd("redraw") -- 沒用
      vim.api.nvim_input("v<ESC>")
    end,
    {
      desc = "Hide selected text with conceal. 如果你已經有其它渲染(例如md)那麼隱藏的符號可能會看不到",
      range = true,
      nargs = 1,
      complete = function(arg_lead, cmd_line)
        local parts = vim.split(cmd_line, "%s+")
        local argc = #parts - 1

        if argc == 1 then
          return require("external.cmp-list.emoji").get_emoji(arg_lead)
        end
      end
    }
  )

  vim.api.nvim_create_user_command("ConcealDelete",
    function(args)
      local emoji = args.fargs[1]
      if not emoji then
        vim.notify("Error: Please provide an emoji to delete.", vim.log.levels.INFO)
        return
      end

      local ns_id = conceal_mappings[emoji]
      if ns_id then
        -- Clear the namespace for the current buffer
        vim.api.nvim_buf_clear_namespace(0, vim.api.nvim_create_namespace(ns_id), 0, -1)
        -- Remove the mapping after deletion
        conceal_mappings[emoji] = nil
        vim.notify("Conceal namespace for " .. emoji .. " deleted.", vim.log.levels.INFO)
      else
        vim.notify("Error: No conceal namespace found for " .. emoji .. ".", vim.log.levels.ERROR)
      end
    end,
    {
      desc = "Delete a conceal namespace by emoji.",
      nargs = 1,
      complete = function(arg_lead, cmd_line)
        local parts = vim.split(cmd_line, "%s+")
        local argc = #parts - 1
        if argc == 1 then
          local emojis = {}
          for emoji in pairs(conceal_mappings) do
            if vim.startswith(emoji, arg_lead) then
              table.insert(emojis, emoji)
            end
          end
          return emojis
        end
      end
    }
  )
end

return commands
