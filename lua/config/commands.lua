local path = require("utils.path")
local cmdUtils = require("utils.cmd")
local osUtils = require("utils.os")
local completion = require("utils.complete")
local arrayUtils = require("utils.array")
local extmarkUtils = require("utils.extmark")
local utils = require("utils.utils")

-- https://github.com/neovim/neovim/tree/a167800/runtime/pack/dist/opt
vim.cmd("packadd cfilter") -- :help cfilter -- 可以使用Cfilter, Lfilter -- 它不是真得刪除，而是在創件新的列表，可以用:cnewer :colder 切換

local commands = {}

local CR = "\r" -- 或 "\x0d" 或 string.char(13), 只有這樣字串中才會真得顯示CR的符號(🔚)

local BAT_EXE_NAME = vim.uv.os_uname().sysname == "Darwin" and "bat" or "batcat"
local COPY_EXE = vim.uv.os_uname().sysname == "Darwin" and "pbcopy" or "wl-copy"

local function openCurrentDirWithFoot()
  local current_file_path = vim.fn.expand("%:p:h") -- 獲取當前文件所在的目錄
  if current_file_path ~= "" then
    -- 調用 'foot' 來執行
    vim.uv.spawn("foot", {
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

--- 二進位轉換函數
--- @param num string|number
--- @return string|nil
--- @return string|nil error
local function to_binary(num)
  if not tonumber(num) then
    return nil, "Invalid number: " .. tostring(num)
  end
  num = math.floor(tonumber(num) or 0)
  if num == 0 then
    return "0", nil
  end
  local bin = ""
  while num > 0 do
    bin = (num % 2) .. bin
    num = math.floor(num / 2)
  end
  -- return bin == "" and "0" or bin -- 等同 bin == "" ? "0" : bin
  return bin, nil
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

      -- local buftype = vim.api.nvim_get_option_value("buftype", { buf = 0 }) -- 這個對No Name也是一樣為空白, 用這判斷不準

      -- 獲取當前文件
      local filepath = para.params[1] or vim.fn.expand('%:p') -- 當前文件的完整路徑

      local cmds = {}
      if args.range ~= 0 then
        cmds = utils.range.get_selected_text()
      end

      while 1 do
        if filepath == '' then
          vim.cmd("split | term")
          break
        end

        filepath = vim.fn.expand(filepath) -- 處理自輸入可能用~的清況
        local exists = vim.uv.fs_stat(filepath)
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
        break
      end

      vim.cmd('startinsert') -- 自動切換到 Insert 模式
      for _, line in ipairs(cmds) do
        -- vim.api.nvim_input(line .. "<ESC>")
        vim.api.nvim_input(line .. "<CR>")
      end
    end,
    {
      nargs = "*",
      range = true,
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

  vim.api.nvim_create_user_command("InspectRange",
    -- 內建的:Inspect只能夠看當前的位置
    -- 如果有的樣式在選中與非選中的時候是不同的，此時會需要非選中也能觀看的方法，就可以利用此指令
    function(args)
      if args.range == 0 then
        return vim.cmd("Inspect")
      end
      -- args.range = 1 表示 :3InspectRange
      -- args.range = 2 表示 :3,11InspectRange

      -- vim.show_pos({bufnr}, {row: 0-based}, {col: 0-based}, {filter})
      -- :lua print(vim.show_pos(0, 0)) -- 不好！ 如果省略了col會用當前cursor的位置，就連row的列號都不是指定的
      -- :lua print(vim.show_pos(0, 查看的列號+1, 0)) -- 👍

      if args.range == 1 then
        return vim.show_pos(0, args.line1 - 1, 0)
      end

      if args.range == 2 then
        for line = args.line1, args.line2 do
          vim.show_pos(0, line - 1, 0)
        end
        return
      end
    end,
    {
      desc = "Inspect, vim.show_pos({bufnr}, {row: 0-based}, {col: 0-based}, {filter})",
      range = true,
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
      local preview_img_cmd = (vim.fn.executable('swayimg') == 1 and "swayimg" or "firefox") .. " " .. outputPath
      vim.fn.setloclist(0, { { text = cmd }, }, 'a')
      -- local result = os.execute(cmd) -- 改用jobstart

      vim.cmd("tabnew | setlocal buftype=nofile")
      local buf = vim.api.nvim_get_current_buf()
      if vim.fn.jobstart(
            table.concat(
              {
                cmd,
                "echo -e '\n\n🟧 file'",
                "file " .. outputPath,
                "echo '🟧 ls'",
                "ls -lh " .. outputPath,
                "echo -e '\n\n'",
                preview_img_cmd,
              },
              ";"
            ), { term = true }) <= 0 then
        print("圖片保存失敗, see location list :lopen")
        vim.api.nvim_buf_delete(buf, { force = true })
      else
        print("圖片保存成功: " .. outputPath)
      end
    end,
    {
      nargs = "?",
      desc = "保存剪貼簿的圖片(依賴ws-paste)"
    }
  )

  --- 這樣保存的svg大小不會比存成webp來得小
  vim.api.nvim_create_user_command("SaveSVG", function(args)
      if vim.fn.executable("vtracer") == 0 then
        vim.api.nvim_echo({
          { "❌ `vtracer` not exists\n install from: ", "Normal" },
          { "https://github.com/visioncortex/vtracer", "@label" },
        }, true, {})
        return
      end
      local outputPath = ""
      local timestamp = os.date("%Y-%m-%d_%H-%M-%S")
      if #args.fargs > 0 then
        outputPath = args.fargs[1]
      else
        local saveDir = vim.fn.expand("%:p:h")
        outputPath = path.join(saveDir, timestamp .. ".svg")
      end

      local tmpFilePath = "/tmp/" .. timestamp .. ".png"

      -- 確保輸出的目錄存在
      local outputDir = vim.fn.fnamemodify(outputPath, ":h")
      if vim.fn.isdirectory(outputDir) == 0 then
        vim.fn.mkdir(outputDir, "p")
      end

      -- 使用 ws-paste 來保存
      local cmd = 'wl-paste --type image/png > "' .. tmpFilePath .. '"'
      local cmd2 = string.format('vtracer --input %s --output %s', tmpFilePath, outputPath)
      local preview_img_cmd = (vim.fn.executable('swayimg') == 1 and "swayimg" or "firefox") .. " " .. outputPath
      vim.fn.setloclist(0, {
        { text = cmd },
        { text = cmd2 },
      }, 'a')

      vim.cmd("tabnew | setlocal buftype=nofile")
      local buf = vim.api.nvim_get_current_buf()
      if vim.fn.jobstart(
            table.concat(
              {
                cmd,
                cmd2,
                "echo -e '\n\n🟧 file'",
                "file " .. outputPath,
                "echo '🟧 ls'",
                "ls -lh " .. outputPath,
                "echo -e '\n\n'",
                "rm " .. tmpFilePath,
                preview_img_cmd,
              },
              ";"
            ), { term = true }) <= 0 then
        print("圖片保存失敗, see location list :lopen")
        vim.api.nvim_buf_delete(buf, { force = true })
      else
        print("圖片保存成功: " .. outputPath)
      end
    end,
    {
      nargs = "?",
      desc = "保存剪貼簿的圖片(需要有: vtracer)"
    }
  )

  vim.api.nvim_create_user_command("SaveWebp", function(args)
    local outputPath = ""

    local startIndex = 2
    if args.range ~= 0 then
      outputPath = table.concat(utils.range.get_selected_text(), "")
      startIndex = 1
    else
      if #args.fargs > 0 then
        outputPath = args.fargs[1]
      else
        -- 根據時間戳生成輸出檔案名稱
        local timestamp = os.date("%Y-%m-%d_%H-%M-%S")
        local saveDir = vim.fn.expand("%:p:h")
        outputPath = path.join(saveDir, timestamp .. ".webp")
      end
    end

    -- 設定預設品質
    local quality = 11
    if #args.fargs >= startIndex then
      local q = tonumber(vim.split(args.fargs[startIndex], "　")[1]) -- 用U+3000全形空白來拆開取得實際要的數值
      if q then
        quality = q
      end
    end

    -- 確保輸出目錄存在
    local outputDir = vim.fn.fnamemodify(outputPath, ":h")
    if vim.fn.isdirectory(outputDir) == 0 then
      vim.fn.mkdir(outputDir, "p")
    end

    -- 直接透過管道，將剪貼簿的 PNG 內容透過 cwebp 轉換成 Webp 並保存

    local paste_image_from_clipboard_cmd
    local preview_img_cmd
    if vim.uv.os_uname().sysname == "Darwin" then
      paste_image_from_clipboard_cmd =
      [[osascript -e "get the clipboard as «class PNGf»" | sed "s/«data PNGf//; s/»//" | xxd -r -p ]]
      preview_img_cmd = "open -a Preview " .. outputPath
    else
      paste_image_from_clipboard_cmd = "wl-paste --type image/png"
      -- wayland
      -- swayimg: https://github.com/artemsen/swayimg
      preview_img_cmd = (vim.fn.executable('swayimg') == 1 and "swayimg" or "firefox") .. " " .. outputPath
    end
    local cmd = string.format('%s | cwebp -q %d -o "%s" -- -',
      paste_image_from_clipboard_cmd,
      quality, outputPath)
    vim.fn.setqflist({
      { text = cmd },
      { text = preview_img_cmd },
    }, 'a')
    -- local result = os.execute(cmd) -- 用os.execute有可能會執行失敗
    -- if result == 0 then print("ok") end

    vim.cmd("tabnew | setlocal buftype=nofile")
    local buf = vim.api.nvim_get_current_buf()

    local job_id = vim.fn.jobstart(
    -- 以下這樣不行，要把它當成字串，中間用;分隔
    -- { cmd1, cmd2, cmd3}
      table.concat(
        {
          cmd,
          "echo -e '\n\n🟧 file'",
          "file " .. outputPath,
          "echo '🟧 ls'",
          "ls -lh " .. outputPath,
          "echo -e '\n\n'",
          preview_img_cmd,
        },
        ";"
      ),
      {
        on_exit = function(_, _, _) -- job_id, exit_code, event_type
          -- 如果term中的訊息不需要別的處理，就不用抓取, 不關閉視窗即可
          -- local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
          -- lines = vim.tbl_filter(function() return lines ~= "" end, lines)
          -- vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines) -- term中是不可修改的，所以這樣會錯
          -- vim.api.nvim_buf_delete(buf, { force = true }) -- 就不主動關了，讓使用者自己看輸出的訊息
          -- if exit_code == 0 then
          --   vim.api.nvim_chan_send(job_id, "file " .. outputPath) -- can't send close chan
          --   vim.api.nvim_chan_send(job_id, "ls -lh " .. outputPath)
          -- end
        end,
        term = true
      }
    )
    if job_id <= 0 then
      vim.notify("Failed to start terminal", vim.log.levels.ERROR)
      vim.api.nvim_buf_delete(buf, { force = true })
      return
    end
  end, {
    nargs = "*",
    range = true,                             -- 使得用markdown寫好路徑之後，就可以不用再輸入一次要保存的位置
    complete = function(
        argLead,                              -- 當你打上某些關鍵字後使用tab時，它會記錄你的關鍵字
        cmdLine,                              -- 當前cmdLine上所有字串內容
        _                                     -- cursorPos在cmdLine上的位置(欄)
    )
      local parts = vim.split(cmdLine, "%s+") -- %s 匹配空白、製表符等
      local argc = #parts - 1                 -- 減去命令本身
      local has_range = cmdLine:match("^'<,'>.*") ~= nil
      if has_range then
        argc = argc + 1 -- 直接跳過第一個參數，因為準備將第一個參數用選取的內容來替代
      end

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
        --       return qualityMap[item] and item .. '% - ' .. qualityMap[item] or item
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

  vim.api.nvim_create_user_command("Video2Gif", -- 🤔 目前已知道似乎nvim執行一次之後，下一次再跑一次檔案會出來，但是內容會有問題，重啟nvim後再跑一次會正常
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
      vim.fn.setqflist({ { text = palette_cmd, }, }, 'a') -- 將過程寫入到 qflist 方便失敗的時候，可以直接用終端機來貼上指令
      if not utils.os.execute_with_notify(palette_cmd, "Palette generated successfully", "Failed to generate palette") then
        return
      end

      vim.fn.setqflist({ { text = gif_cmd, }, }, 'a')
      if not utils.os.execute_with_notify(gif_cmd, "GIF generated successfully: " .. output_file_path, "Failed to generate GIF") then
        return
      end

      -- 清理調色盤檔案
      vim.fn.setqflist({ { text = "rm " .. rm_cmd, }, }, 'a')
      utils.os.remove_with_notify(rm_cmd, "Cleaned up palette file", "Failed to remove palette file")
    end,
    {
      desc = "convert video to gif",
      nargs = "+",
      complete = function(arg_lead, cmd_line)
        if arg_lead:match("^%-%-") then
          local output = { "temp.gif" }
          if arg_lead:match("^%-%-o=") then
            arg_lead = "--o=" .. vim.fn.expand(string.sub(arg_lead, 5))                 -- 5為--o=
            for _, dir in ipairs(utils.complete.getDirOnly(string.sub(arg_lead, 5))) do -- 從--o=開始算
              table.insert(output, dir .. "output.gif")
            end
          end
          return utils.cmd.get_complete_list(arg_lead, {
            loop = {
              "0", -- 無限循環(預設)
              "1", -- 1次
              "5"  -- 播5次
            },
            o = output,
            force = {
              "0",
              "1", -- 覆蓋，當輸出的檔案已存在
            }
          })
        end

        local argc = #(vim.split(cmd_line, "%s+")) - 1
        if argc == 1 then
          -- 取得所有檔案的補全清單
          local all_files = vim.fn.getcompletion(vim.fn.expand(arg_lead), "file")
          -- 過濾出影片檔案
          local cmp_files = {}
          local regex_video = vim.regex([[\c\.\(mp4\|mkv\|avi\|mov\|flv\|wmv\)$]])
          for _, file in ipairs(all_files) do
            -- 如果是目錄還是推送，而如果是檔案就要匹配相同的附檔名
            if vim.uv.fs_stat(file).type == "directory" then
              table.insert(cmp_files, file)
            else
              if regex_video:match_str(file) then
                table.insert(cmp_files, file)
              end
            end
          end

          return utils.table.sort_files_first(cmp_files)
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
            arg_lead = "--o=" .. vim.fn.expand(string.sub(arg_lead, 5))
            for _, dir in ipairs(utils.complete.getDirOnly(string.sub(arg_lead, 5))) do -- 從--o=開始算
              table.insert(output, dir .. "frame_%04d.png")
            end
          end

          return utils.cmd.get_complete_list(arg_lead, { -- 如果路徑用arg_lead展開，這邊也要跟著才可以匹配到
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
          local all_files = vim.fn.getcompletion(vim.fn.expand(arg_lead), "file")
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

  vim.api.nvim_create_user_command("Download",
    function(args)
      local downloadLink = args.fargs[1]
      if not downloadLink:match("^http[s]?://") then
        vim.notify("invalid url format", vim.log.levels.ERROR)
        return
      end
      local outputPath = args.fargs[2] or vim.fn.expand("%:p:h")
      -- if vim.uv.fs_stat(outputPath).type == "directory" then -- 如果fs_stat得到nil則無法用nil.type會錯誤
      if vim.fn.fnamemodify(outputPath, ":e") == "" then
        -- 避免只給dir而沒有檔名
        outputPath = path.join(outputPath, os.date("%Y-%m-%d_%H-%M-%S"))
      end
      local outputDir = vim.fn.fnamemodify(outputPath, ":h")
      if vim.fn.isdirectory(outputDir) == 0 then
        local choice = vim.fn.confirm(
          string.format("directory: %q not exits. create?", vim.fn.fnamemodify(outputDir, ":p")),
          "&Yes\n&No",
          2
        )
        if choice ~= 1 then
          vim.notify("cancelled", vim.log.levels.INFO)
          return
        end
        vim.fn.mkdir(outputDir, "p")
      end
      local cmd = string.format("wget %s -O %s", downloadLink, outputPath)
      vim.fn.setloclist(0, { { text = cmd } }, 'a')
      print(cmd)

      utils.os.execute_with_notify(cmd,
        "Download ok: " .. vim.fn.fnamemodify(outputPath, ":p"), -- 下載檔案的絕對路徑
        "Download failed: " .. downloadLink
      )
    end,
    {
      desc = "download file",
      nargs = "+",
      complete = function(arg_lead, cmd_line)
        local argc = #(vim.split(cmd_line, "%s+")) - 1
        if argc == 1 then
          return { "https://" }
        elseif argc == 2 then
          local output = {}

          if #arg_lead == 0 then
            table.insert(output, "output.type")
          end
          for _, dir in ipairs(utils.complete.getDirOnly(vim.fn.expand(arg_lead))) do
            table.insert(output, dir)
          end
          return output
        end
      end
    }
  )


  vim.api.nvim_create_user_command("FfmpegGenGif",
    -- -vf為簡單濾鏡
    -- ffmpeg -f concat -safe 0 -r 2 -i input.txt -vf "scale=-1:-1" -loop 0 output.gif
    --
    -- -lavfi為複雜濾鏡
    -- flag=lanczos 是高品質縮放演算法 圖片尺寸較小或不需要高品質縮放，可以考慮使用更快的 flags=bilinear
    -- 🤔 ffmpeg -f concat -safe 0 -r 2 -i input.txt                -vf    "scale=-1:-1:flags=lanczos,palettegen" palette.png
    -- 🤔 ffmpeg -f concat -safe 0 -r 2 -i input.txt                -vf    "scale=-1:-1"                                        -loop 0 output.gif
    -- 🤔 ffmpeg -f concat -safe 0      -i input.txt -i palette.png -lavfi "scale=-1:-1:flags=lanczos [x]; [x][1:v] paletteuse" -loop 0 output.gif
    function(args)
      local para = utils.flag.parse(args.args)
      local input_file = vim.fn.expand(para.params[1])

      -- check input_file
      if not input_file then
        vim.notify("Error: Input file is required!", vim.log.levels.ERROR)
        return
      end
      if vim.fn.filereadable(input_file) == 0 then
        vim.notify("Error: Input file '" .. input_file .. "' does not exist!", vim.log.levels.ERROR)
        return
      end
      -- :lua print(os.date("%Y%m%d_%H%M%S")) -- YYYYMMDD_HHMMSS
      local output_file_path = para.opts["o"] or os.date("%Y%m%d_%H%M%S") .. ".gif"


      if vim.fn.fnamemodify(output_file_path, ":e") ~= "gif" then
        output_file_path = output_file_path .. ".gif"
      end
      if vim.fn.filereadable(output_file_path) == 1 then
        local choice = vim.fn.confirm(
          "File " .. output_file_path .. " already exists. Overwrite?",
          "&Yes\n&No",
          2 -- default, select opt 2 == No
        )
        if choice ~= 1 then
          vim.notify("cancelled", vim.log.levels.INFO)
          return
        end
        os.remove(output_file_path)
      end

      local r = tonumber(para.opts["r"]) or nil -- 預設的太快, 如果input.txt裡面有duration那麼就不應該有-r的選項
      local width = tonumber(para.opts["width"]) or -1
      local height = tonumber(para.opts["height"]) or -1
      local loop = tonumber(para.opts["loop"]) or 0
      -- local paletteuse = para.opts["paletteuse"] == 1 -- 錯誤，一定都是字串
      local paletteuse = para.opts["paletteuse"] == "1"

      local platte_file_path = "palette" .. os.date("%Y%m%d_%H%M%S") .. ".png"

      if paletteuse then
        local palette_cmd_str = string.format(
        -- 'ffmpeg -f concat -safe 0 -r %f -i %s -vf "scale=-1:-1:flags=lanczos,palettegen" %s',
          'ffmpeg -f concat -safe 0 -i %s -vf "scale=-1:-1:flags=lanczos,palettegen" %s',
          -- r,
          input_file,
          platte_file_path
        )
        vim.fn.setloclist(0, { { text = palette_cmd_str }, }, 'a')
        if not utils.os.execute_with_notify(palette_cmd_str, "generated palette successfully", "Failed to generate palette") then
          return
        end
      end

      local cmd = {
        "ffmpeg -f concat -safe 0"
      }
      if r then
        table.insert(cmd, string.format("-r %f", r))
      end

      table.insert(cmd, "-i " .. input_file)

      if paletteuse then
        table.insert(cmd, "-i " .. platte_file_path) -- -i palette.png
        table.insert(cmd, string.format('-lavfi "scale=%d:%d:flags=lanczos [x]; [x][1:v] paletteuse"', width, height))
      else
        table.insert(cmd, string.format('-vf "scale=%d:%d"', width, height))
      end
      table.insert(cmd, string.format("-loop %d", loop))
      table.insert(cmd, output_file_path)

      local cmd_str = table.concat(cmd, " ")
      print(cmd_str)
      vim.fn.setloclist(0, {
        { text = "input.txt example: " .. "https://superuser.com/a/1902822/1093221" },
        { text = cmd_str },
      }, 'a')

      utils.os.execute_with_notify(cmd_str, "generated successfully", "Failed to generate")

      if paletteuse then
        os.remove(platte_file_path)
      end
    end,
    {
      desc = "generate gif with ffmpeg",
      nargs = "+",
      complete = function(arg_lead, cmd_line)
        if arg_lead:match("^%-%-") then
          local output = {
            "output.gif",
            "~/Downloads/output.gif",
          }
          if arg_lead:match("^%-%-o=") then
            arg_lead = "--o=" .. vim.fn.expand(string.sub(arg_lead, 5))
            for _, dir in ipairs(utils.complete.getDirOnly(string.sub(arg_lead, 5))) do
              table.insert(output, dir .. "output.gif")
            end
          end

          return utils.cmd.get_complete_list(arg_lead, {
            o = output,
            r = {
              "1.33", -- ≈ 0.75s/frame
              "2",    -- 0.5s/frame
              "4",
              "10",
              "20", -- 0.05s/frame
            },
            width = {
              "-1",
              "320",
            },
            height = {
              "-1",
              "600"
            },
            loop = {
              "0", -- 無限循環(預設)
              "1", -- 1次
              "5"  -- 播5次
            },
            paletteuse = {
              "1", -- TODO 目前使用它，生成的gif會不完整
              "0",
            }
          })
        end

        local argc = #(vim.split(cmd_line, "%s+")) - 1
        if argc == 1 then
          local all_files = vim.fn.getcompletion(vim.fn.expand(arg_lead), "file")
          return {
            "input.txt", -- 提示輸入的檔案通常而言是txt
            unpack(
              vim.tbl_filter(function(name) return name:match("%.txt$") end,
                utils.table.sort_files_first(all_files) -- 其實是其它的類型也無仿，只要內容相符仍可執行
              )
            )
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
      -- vim.fn.system 可以得到命令的返回值(stdout), os.execute只有數字(退出碼)
      -- vim.fn.system 非阻塞; os.execute 阻塞(需等待完成)
      -- vim.fn.system 不影響終端畫面; os.execute 可能清屏或顯示命令輸出！
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

  -- 舊版參考: `git show 56ea05b7:./commands.lua | bat -l lua -P -r 1591,1714` (這個沒什麼用，直接開term打指令比較直接)
  vim.api.nvim_create_user_command('Gitlog', function(args)
    if args.fargs[1] == "-h" then
      cmdUtils.showHelpAtQuickFix({
        -- git log -L1594,1599:commands.lua -w --ignore-blank-lines --no-patch
        ':Gitlog -2 20b7508f --name-only --oneline',
        ':Gitlog -2 20b7508f',
        ':Gitlog -2 ',
        ':Gitlog -2 -p',
        ':Gitlog -2 -p -U3', -- 上下文長度
        [[:'<,'>Gitlog -2]],
        [[:'<,'>Gitlog -2 -w]],
        [[:'<,'>Gitlog -2 -w -b]], -- -b --ignore-blank-lines
      })
      return
    end
    vim.cmd("cd %:h") -- 先切換到當前該檔案的目錄

    -- 檢查是否在 git 倉庫中
    local _ = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
    if vim.v.shell_error ~= 0 then
      vim.notify('Not in a git repository', vim.log.levels.ERROR)
      return
    end

    local line_range = ""
    if args.range ~= 0 then
      local start_line = vim.fn.line("'<")
      local end_line = vim.fn.line("'>")
      line_range = string.format("-L%d,%d:", start_line, end_line)
    end

    local filename = vim.fn.expand("%:t")

    local git_args = args.args or ''
    -- Note: 如果用 git log -2 commands.lua 那麼-2必須在檔案之前，所以將可選參數往前放
    local cmd = string.format('git log %s %s%s', git_args, line_range, filename) -- 如果用--name-only不能用這種行式
    for _, arg in ipairs(args.fargs) do
      if arg == "--name-only" then
        cmd = string.format('git log %s', git_args) -- 可以考慮加--oneline
        break
      end
    end

    -- 在新的 terminal buffer 中執行命令
    vim.cmd('topleft new')
    -- vim.cmd('botright new')
    -- vim.cmd('vertical new')
    -- vim.cmd("term " .. cmd) -- 可行，但是如果想利用這個結果，再去修改，就沒有辦法，之後按下enter就離開了
    vim.cmd("term")
    vim.cmd("startinsert")
    -- vim.api.nvim_input([[echo -e '\033[37m可以使用\033[0m \033[42m<C-W>T\033[0m \033[37m將視窗移動到新的Tab\033[0m']] .. "<CR>") -- < > 會出不來
    vim.api.nvim_input([[echo -e '\033[37m可以使用\033[0m \033[42m\x3cC-W\x3eT\033[0m \033[37m將視窗移動到新的Tab\033[0m']] .. "<CR>")
    vim.api.nvim_input(cmd .. "<CR>")
  end, {
    range = true,
    nargs = '*',
    desc = 'Run git log -L on selected lines'
  })

  vim.api.nvim_create_user_command('Comm', function(args)
    if #args.fargs ~= 2 then
      vim.api.nvim_echo({ { ':Comm file1 file2', "@ERROR" }, }, false, {})
      return
    end
    vim.cmd('topleft new')
    vim.cmd("term")
    vim.cmd("startinsert")

    local cmd = string.format([[comm -3 <lt>(sort %s) <lt>(sort %s)<CR>]],
      vim.fn.shellescape(vim.fn.expand(args.fargs[1])),
      vim.fn.shellescape(vim.fn.expand(args.fargs[2]))
    )
    -- vim.api.nvim_input("cmd -3 <(sort file1) <(sort file2)<CR>") -- ❌ < 會輸出不了，要用<lt>
    -- vim.api.nvim_input("cmd -3 <lt>(sort file1) <lt>(sort file2)<CR>")
    vim.api.nvim_input(cmd)
  end, {
    nargs = '*',
    desc = 'comm – select or reject lines common to two files',
    complete = function(arg_lead)
      return vim.fn.getcompletion(vim.fn.expand(arg_lead), "file")
    end
  })

  vim.api.nvim_create_user_command('DiffRegs', function(args)
    if args.fargs[1] == "-h" then
      cmdUtils.showHelpAtQuickFix({
        'DiffRegs a b',
        'DiffRegs a +',
        'DiffRegs a         -- comp a and "',
        '💡 可以搭配: `:%sort u`'
      })
      return
    end
    local left_reg = args.fargs[1]
    local right_reg = args.fargs[2] or '"'

    local left_content = vim.fn.getreg(left_reg)
    local right_content = vim.fn.getreg(right_reg)

    vim.cmd('tabnew')

    -- left buffer
    vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(left_content, '\n'))
    vim.bo.buftype = 'nofile'
    vim.bo.buflisted = false
    vim.bo.swapfile = false
    vim.cmd('diffthis')

    -- right buffer（垂直分割）
    vim.cmd('vnew')
    vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(right_content, '\n'))
    vim.bo.buftype = 'nofile'
    vim.bo.buflisted = false
    vim.bo.swapfile = false
    vim.cmd('diffthis')

    -- 回到左邊視窗
    vim.cmd('wincmd h')
  end, {
    nargs = '+',
    desc = 'Diff two registers in new tab',
    complete = function(arg_lead)
      local candidates = {}
      for _, reg in ipairs(utils.register.get_registers()) do
        if reg:find(arg_lead, 1, true) == 1 then
          table.insert(candidates, reg)
        end
      end
      return candidates
    end
  })

  vim.api.nvim_create_user_command('RustExplain', function(args)
    local err_code = args.fargs[1]
    vim.cmd('topleft new')
    vim.cmd("term")
    vim.cmd("startinsert")
    vim.api.nvim_input(string.format([[rustc --explain %s | bat -l rust -P <CR>]], err_code))
  end, {
    nargs = 1,
    desc = 'rustc --explain E0308 | bat -l rust -P',
    complete = function()
      return { "E0308" }
    end
  })

  vim.api.nvim_create_user_command('Rustrun', function(args)
    -- Note: 也有一個 :RustRun 的指令，但是它是print的方式，而不是額外開一個term
    -- 我們這個額外開一個term，可以方便修改會額外加上一些命令

    local rspath = vim.fn.expand(args.fargs[1])
    local basename = vim.fn.fnamemodify(rspath, ':t:r')

    vim.cmd('topleft new')
    vim.cmd("term")

    -- local cargo_path = vim.fs.root(0, 'Cargo.toml') -- Tip: 這個會往上找，直到找到有Cargo.toml
    -- if cargo_path then
    --   vim.cmd("startinsert")
    --   vim.api.nvim_input([[cargo run<CR>]])
    --   return
    -- end

    -- 單檔模式
    local cmd = string.format('rustc -g %s -o %s && ./%s', -- 編譯後直接運行
      vim.fn.shellescape(rspath),
      vim.fn.shellescape(basename),
      vim.fn.shellescape(basename)
    )
    -- vim.fn.feedkeys('i' .. cmd .. '<CR>', 'n')
    vim.cmd("startinsert")
    vim.api.nvim_input(string.format([[%s <CR>]], cmd))
  end, {
    nargs = 1,
    desc = 'rustc -g my.rs && ./my',
    complete = function(arg_lead)
      return vim.fn.getcompletion(vim.fn.expand(arg_lead), "file")
    end
  })

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
            -- https://www.lua.org/pil/22.1.html
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
  --     local output_dir_stat = vim.uv.fs_stat(output_dir)
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
      local output_dir_stat = vim.uv.fs_stat(output_dir)
      if output_dir_stat and output_dir_stat.type ~= "directory" then
        vim.notify("輸出的目錄不存在: " .. output_dir, vim.log.levels.ERROR)
        return
      end

      -- Ensure output filename ends with .mp4
      if not output_filename:match("%.mp4$") then
        output_filename = output_filename .. ".mp4"
      end
      -- local output_mp4_path = output_mkv_path:gsub("%.mkv$", ".mp4")
      local output_path = output_dir .. "/" .. output_filename

      -- Check if file already exists
      if vim.uv.fs_stat(output_path) then
        local choice = vim.fn.confirm(
          "File " .. output_path .. " already exists. Overwrite?",
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
        if output_path then
          os.remove(output_path)
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
        output_path
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
          -- -c:v libx264 使用H.264編碼器重新編碼視訊 adfj jifdsa   ddd
          -- -c:a aac 用AAC編碼器重新編碼音訊
          text = string.format("ffmpeg -i %s -c:v libx264 -c:a aac %s  👈 如果有些播放器不行播可以嘗試使用此指令重新編碼視、音訊來解決",
            vim.fn.shellescape(output_path),                           -- input
            vim.fn.shellescape(output_path:gsub("%.mp4$", "_fix.mp4")) -- output
          )
        }
      }, 'a')

      vim.cmd('term ' .. rec_cmd)

      -- ~~設置自動命令，在終端退出後轉換~~ 不需要先變mkv再轉mp4，在一開始直接用mp4即可
      vim.api.nvim_create_autocmd("TermClose", {
        pattern = "*",
        once = true,
        callback = function()
          -- os.execute('ffmpeg -i ' ..
          --   vim.fn.shellescape(output_mkv_path) .. ' -c:v copy -c:a copy ' .. vim.fn.shellescape(output_mp4_path))
          -- os.remove(output_mkv_path)
          -- vim.notify("轉換完成，已保存為 " .. output_mp4_path, vim.log.levels.INFO)

          -- 自動開啟輸出的目錄
          if vim.fn.executable('thunar') == 1 then
            vim.cmd("!thunar " .. vim.fn.fnamemodify(output_path, ":h") .. " & ")
          end

          if vim.fn.executable('vlc') == 1 then
            vim.fn.system("vlc " .. output_path)
          else
            vim.ui.open(output_path) -- 用系統預設的工具來開啟檔案
          end
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
          table.insert(dirs, ".") -- 使用當前的工作目錄
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
        -- if hl_group:match('#%x%x%x%x%x%x') -- 可行，但是只有一種顏色
        -- local fg, bg = hl_group:match("(#%x%x%x%x%x%x)_(#%x%x%x%x%x%x)") -- 只有都存在才有效
        local colors = {}
        for color in hl_group:gmatch("#%x%x%x%x%x%x") do
          table.insert(colors, color)
        end

        if #colors > 0 then
          local fg = colors[1]
          local bg = colors[2] or nil
          -- print(fg, bg)
          local win_id = vim.api.nvim_get_current_win()
          local ns_id = vim.api.nvim_create_namespace("Highlight_" .. win_id)
          hl_group = string.format("Highlight_%d_%s_%s", win_id,
            string.sub(fg, 2), -- nvim_set_hl的group不能用#112233的方式(Invalid character in group name)
            string.sub(bg or "", 2)
          )
          vim.api.nvim_set_hl(ns_id, hl_group, { fg = fg, bg = bg })
          vim.api.nvim_win_set_hl_ns(win_id, ns_id)
        else
          vim.notify('Highlight group "' .. hl_group .. '" does not exist', vim.log.levels.WARN)
          return
        end
      end

      -- 獲取當前光標行號和緩衝區最大行數
      local current_line = vim.fn.line('.')
      local max_lines = vim.fn.line('$')


      if args.range ~= 0 then -- 0 一般, 1: 30:MyCommand, 2 '<,'>MyCommand 或 2,5MyCommand
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
          return {
            "#ff0000_#ffff00",
            unpack(hl_groups),
          }
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

  vim.api.nvim_create_user_command("Let",
    function(args)
      if args.fargs[1] == "-h" then
        vim.fn.setloclist(0, {
          { text = "Let aa" },
          { text = "Let aa +" },
          { text = "5Let aa" },
          { text = "+5Let aa" },
          { text = "-5Let aa" },
          { text = "5,8Let aa" },
          { text = "+0,+2Let aa" },
          -- { text = "-0,-3Let aa" }, -- 會被提示是否要swap
          { text = "-3,-0Let aa" },
        }, 'a')
        vim.cmd("lopen 8")
        return
      end
      -- print(vim.inspect(vim.fn.mode())) -- 都是n

      local varName = args.fargs[1]
      local op = args.fargs[2] or ""
      if op == "_" then
        op = ""
      end
      if args.range == 0 then
        return vim.cmd(string.format('let %s%s=[getline(".")]', varName, op))
      end
      if args.range == 1 then -- :5Let
        return vim.cmd(string.format('let %s%s=[getline(%d)]', varName, op, args.line1))
      end
      if args.range == 2 then -- :'<,'>Let  或 :5,8Let
        if args.line1 ~= args.line2 and args.fargs[3] ~= 'v' then
          return vim.cmd(string.format('let %s%s=getline(%d, %d)', varName, op, args.line1, args.line2))
        end

        -- 以下其實也可以做跨列，只是如此就會讓:5,8Let這種的方式失敗
        local lines = utils.range.get_selected_text()
        local linesWithQuotes = {}
        for _, line in ipairs(lines) do
          table.insert(linesWithQuotes, string.format("%q", line))
        end
        return vim.cmd(string.format('let %s%s=[%s]', varName, op, table.concat(linesWithQuotes, ",")))
      end
    end,
    {
      desc = 'let myVar=[getline(".")] 📝 使用 echo myVar[0] 可查看變數',
      nargs = "+",
      range = true,
      complete = function(arg_lead, cmd_line)
        local argc = #(vim.split(cmd_line, "%s+")) - 1
        if argc == 1 then
          return {
            "myVar",
            "aa"
          }
        end
        if argc == 2 then
          return {
            "+", -- append
            "_", -- default
          }
        end
        if argc == 3 then
          return {
            "v",
          }
        end
      end
    }
  )
  vim.api.nvim_create_user_command("Mes",
    function(args)
      if args.fargs[1] == "-h" then
        vim.fn.setloclist(0, {
          { text = ":Mes 放置所有mes的內容" },
          { text = "1:Mes  放置最後一筆mes的記錄" },
          { text = "1:Mes aa  將最後一筆mes的記錄，保存在自定義的變數aa之中，可以使用:pu=aa 放置結果" },
          { text = ":mes clear 清空所有mes內容" },
        }, 'a')
        vim.cmd("lopen 5")
        return
      end
      local count = ""
      if args.count > 0 then -- 如果沒有給count, 是為-1
        count = tostring(args.count)
      end
      if #args.fargs == 0 then
        vim.cmd('redir @"')
        vim.cmd(count .. "mes")
        vim.cmd("redir END")
        vim.cmd('pu=@"')
        return
      end

      local varName = args.fargs[1]
      vim.cmd("redir => " .. varName)
      vim.cmd(count .. "mes")
      vim.cmd("redir END")
      -- vim.notify(":pu=" .. varName, vim.log.levels.INFO)
    end,
    {
      desc = '可以直接輸出:mes的內容或者將其保存在變數之中',
      nargs = "?",
      range = true, -- :{count}Mes 一個數字可以當成列號，也可以當成count
    }
  )
  vim.api.nvim_create_user_command("GoSelect",
    function(args)
      if args.fargs[1] == "-h" then
        vim.fn.setloclist(0, {
          { text = ":{count}GoSelect n" },
          { text = "Tag | Offset | Length" },
          { text = "head | 436 | 54" },
          { text = "54:GoSelect 437    📝 offset從436開始，所以下一個開始讀的是437，往後取54byte" },
        }, 'a')
        vim.cmd("lopen 4")
        return
      end
      local startByte = args.fargs[1]
      local count = args.count
      if count < 0 then
        count = 1
      end
      -- normal! 加上! 表示略過 key mapping
      -- v 表示visaul
      -- l 往右移動
      vim.cmd(string.format("go %d | normal! v%dl", startByte, count))
    end,
    {
      desc = '從第n byte開始選取count個',
      nargs = 1,
      range = true, -- :{count}Mes 一個數字可以當成列號，也可以當成count
    }
  )

  vim.api.nvim_create_user_command("Printf",
    function(args)
      local fmt = args.fargs[1]
      local values = vim.list_slice(args.fargs, 2)

      -- 以下處理%b的情況
      local new_fmt = fmt
      local new_values = {}
      local value_index = 1
      for i = 1, #fmt do -- i: [s, e] 有包含尾
        if fmt:sub(i, i) == "%" and i + 1 <= #fmt then
          local specifier = fmt:sub(i + 1, i + 1)
          if specifier == "b" then
            -- 處理 %b
            if value_index > #values then
              vim.notify("Format error: not enough arguments for %b", vim.log.levels.WARN)
              return
            end
            local bin, err = to_binary(values[value_index])
            if not bin then
              vim.notify(string.format("to_binary error: %s value: %s", err, values[value_index]),
                vim.log.levels.WARN)
              return
            end
            table.insert(new_values, bin)
            -- 將 %b 替換為 %s，因為二進位結果是字符串
            new_fmt = new_fmt:sub(1, i - 1) .. "%s" .. new_fmt:sub(i + 2)
          else
            -- 其他格式化動詞直接保留
            table.insert(new_values, values[value_index])
          end
          value_index = value_index + 1
        end
      end

      -- local ok, result = pcall(string.format, fmt, unpack(values))
      local ok, result = pcall(string.format, new_fmt, unpack(new_values))
      -- print(string.format(new_fmt, unpack(new_values))) -- 可行，但是如果有錯，是用系統的錯誤
      if ok then
        print(result)
        vim.fn.setreg('"', result) -- 保存在 " 使得有辦法貼上
      else
        vim.notify(string.format("Format error: %s | fmt: %s %s [確認format如果有個是否有短少\\]", result,
            new_fmt, table.concat(new_values, " ")),
          vim.log.levels.WARN)
      end
    end,
    {
      desc = 'Printf %s\\ %d abc 123',
      nargs = "+",
      complete = function(arg_lead, cmd_line)
        local argc = #(vim.split(cmd_line, "%s+")) - 1
        if argc == 1 then
          return {
            "%x",
            "%d",
            "%s",
            "%s\\ %0.2f", -- %s\ %d -- 如果想要用空白可以善用 \ 如此之後的內容也會視為是同一個參數
            "%f\\ %b",    -- lua的string.format沒有支持%b，要自己寫
          }
        end

        return {
          "abc",
          "5",
          "3.5",
          "0xb7",
        }
      end
    }
  )

  vim.api.nvim_create_user_command("WhichFlag",
    function(args)
      local num = tonumber(args.fargs[1])
      if num < 0 then
        vim.notify("Negative numbers are not supported", vim.log.levels.ERROR)
        return
      end

      -- 獲取進位制參數，默認為 10
      local base = tonumber(args.fargs[2]) or 10
      if base ~= 2 and base ~= 8 and base ~= 10 and base ~= 16 then
        vim.notify("Base must be 2, 8, 10, or 16", vim.log.levels.ERROR)
        return
      end

      local flags = {}
      local bit = 0
      while num > 0 do
        if num % 2 == 1 then
          local flag_value = 2 ^ bit
          -- 根據進位制格式化輸出
          if base == 2 then
            -- table.insert(flags, string.format("0b%s", string.format("%b", flag_value))) -- invalid option '%b' to 'format'
            table.insert(flags, string.format("0b%s", to_binary(flag_value)))
          elseif base == 8 then
            table.insert(flags, string.format("0o%o", flag_value))
          elseif base == 16 then
            table.insert(flags, string.format("0x%X", flag_value))
          else
            table.insert(flags, flag_value)
          end
        end

        num = math.floor(num / 2)
        bit = bit + 1
      end
      local msg = vim.inspect(flags)
      print(msg)
      vim.fn.setreg('"', msg)
    end,
    {
      desc = "know which flags are lit",
      nargs = "+",
      complete = function(_, cmd_line)
        local argc = #(vim.split(cmd_line, '%s+')) - 1
        if argc == 1 then
          return { "33" }
        elseif argc == 2 then
          return { "2", "8", "10", "16" }
        end
      end
    }
  )

  vim.api.nvim_create_user_command("NewTmp",
    function(args)
      local fargs = vim.split(args.args:gsub("=", " "), " ") -- 因為補全完成都是用-xx=的方式，將=改為空白再拆分，方便之後的shift

      -- 此parse_args類似bash寫function時用的shift的處理方式
      local opts = {
        filetype = nil,
        bufhidden = nil,
      }
      local pos_args = {} -- 記錄按位置輸入的參數
      local i = 1
      local help = table.concat({
        "Usage:",
        ":NewTmp [-t|--filetype] [bufname]",
      }, "\n")
      while i <= #fargs do
        local arg = fargs[i]
        if arg == "-h" or arg == "--help" then
          vim.notify(help, vim.log.levels.INFO)
          return
        elseif arg == "-t" or arg == "--filetype" then
          i = i + 1
          opts.filetype = fargs[i]
        elseif arg == "--bufhidden" then
          i = i + 1
          opts.bufhidden = fargs[i]
        elseif arg:sub(1, 1) == "-" then
          vim.notify("Unknown options:" .. arg, vim.log.levels.ERROR)
          vim.notify(help, vim.log.levels.INFO)
          return
        else
          table.insert(pos_args, arg)
        end
        i = i + 1
      end
      local bufname = pos_args[1]

      vim.cmd(":enew | setlocal buftype=nofile noswapfile")
      if bufname then
        vim.cmd("file " .. bufname)
      end

      if opts.filetype then
        vim.cmd("set filetype=" .. opts.filetype)
      end

      if opts.bufhidden then
        vim.cmd("set bufhidden=" .. opts.bufhidden)
      end
    end,
    {
      desc = ":enew | setlocal buftype=nofile noswapfile",
      nargs = "?",
      complete = function(arg_lead)
        -- 可行，但是每一項的補全不好設計
        local options = {
          { "-h", "--help", nil },
          { "-t", "--filetype", { "c++", "csv", "xml", "json", "markdown", "..." } },
          { "", "--bufhidden", { "wipe" } } -- 離開後buf也不要記錄
        }
        return utils.flag.get_complete(arg_lead, options) or
            vim.fn.getcompletion(arg_lead, "file")
      end
    }
  )

  vim.api.nvim_create_user_command("Glow",
    -- https://github.com/charmbracelet/glamour
    function(args)
      if vim.fn.executable("glow") == 0 then
        vim.fn.setloclist(0, {
          { text = "go install github.com/charmbracelet/glow@latest" },
        }, 'a')
        vim.notify("exe: glow not found. \n go install github.com/charmbracelet/glow@latest", vim.log.levels.WARN)
        return
      end

      local mdfile = args.fargs[1]
      local style = args.fargs[2] or "dracula"
      local basename = vim.fn.fnamemodify(mdfile, ":r") -- 不含附檔名
      local filename = "glow:" .. basename .. ":s:" .. style

      vim.cmd("tabnew | setlocal buftype=nofile | term")
      vim.cmd("file " .. filename)
      vim.cmd("startinsert")
      vim.api.nvim_input(string.format("glow %s -s %s<CR>", mdfile, style))
    end,
    {
      desc = "render markdown. :tabnew | term | glow my.md -s dracula",
      nargs = "+",
      complete = function(arg_lead, cmd_line)
        local argc = #(vim.split(cmd_line, "%s+")) - 1
        if argc == 1 then
          local all_files = vim.fn.getcompletion(vim.fn.expand(arg_lead), "file")
          return vim.tbl_filter(function(filepath)
              return filepath:match("%.md$") or
                  vim.fn.isdirectory(filepath) == 1 -- 目錄 (使得子目錄md也可以) <Ctrl-Y> 選擇後可以再tab
            end,
            utils.table.sort_files_first(all_files)
          )
        end

        if argc == 2 then
          -- https://github.com/charmbracelet/glamour/tree/c9af045/styles
          return vim.tbl_filter(function(style)
            return string.find(style, arg_lead:lower(), 1, true) ~= nil -- 1 開始索引, plain不使用正則式
          end, {
            "ascii",
            "dark",
            "dracula",
            "light",
            "dark",
            "notty",
            "pink",
            "tokyo-night",
          })
        end
      end
    }
  )

  vim.api.nvim_create_user_command("Spf",
    -- https://github.com/yorukot/superfile
    function()
      if vim.fn.executable("spf") == 0 then
        vim.fn.setloclist(0, {
          { text = "https://github.com/yorukot/superfile/blob/ac240dbaf5878901c9f71dfdbbe41ede949be545/README.md?plain=1#L95-L135" },
        }, 'a')
        vim.notify("exe: spf not found.", vim.log.levels.WARN)
        vim.cmd("lopen 2")
        return
      end

      local dirname = vim.fn.expand("%:p:h:t")
      vim.cmd("cd %:p:h | tabnew | setlocal buftype=nofile | term spf")
      vim.cmd("file spf:" .. dirname)

      vim.cmd("startinsert")
    end,
    {
      desc = "tabnew | setlocal buftype=nofile | term spf",
      nargs = 0,
    }
  )

  vim.api.nvim_create_user_command("Yazi",
    function(args)
      if vim.fn.executable("yazi") == 0 then
        vim.fn.setloclist(0, {
          { text = "https://yazi-rs.github.io/docs/installation/" },
        }, 'a')
        vim.notify("exe: yazi not found.", vim.log.levels.WARN)
        vim.cmd("lopen 2")
        return
      end

      local target = ""
      if args.range ~= 0 then
        target = table.concat(utils.range.get_selected_text(), '')
      else
        target = vim.fn.expand("%:p:h:t")
      end
      if vim.uv.os_uname().sysname == "Linux" then
        vim.cmd("!foot yazi " .. target .. " & ")
        -- open -na /Applications/Ghostty.app --args -e yazi
      elseif vim.uv.os_uname().sysname == "Darwin" then
        -- 如果在nvim中的終端機如ghostty, 也可以用yazi, 不過看到的圖片類似用Sixel graphics的方式，要單獨在ghostty不進入nvim才會正常
        -- Tip: 也可以先複製工作目錄，再用New Window的方式來啟動yazi

        target = vim.fn.expand("%:p:h")
        -- vim.cmd("!open -na /Applications/Ghostty.app --args -e yazi " .. target) -- 可行
        vim.cmd("!open -na /Applications/kitty.app --args -e yazi " .. target) -- 也行
      else
        -- 不確定windows能不能
        vim.cmd("!kitty yazi " .. target .. " & ")
      end
    end,
    {
      desc = "!foot yazi fileOrDir",
      nargs = 0,
      range = true,
    }
  )

  vim.api.nvim_create_user_command("Viu",
    function(args)
      if args.fargs[1] == "-h" then
        vim.fn.setloclist(0, {
          { text = ":Viu % 用當前的文件來執行" },
        }, 'a')
        vim.cmd("lopen 2")
        return
      end

      if vim.fn.executable("viu") == 0 then
        vim.fn.setloclist(0, {
          { text = "https://github.com/atanunq/viu" },
          { text = "cargo install viu" },
        }, 'a')
        vim.notify("exe: viu not found. cargo install viu", vim.log.levels.WARN)
        vim.cmd("lopen 3")
        return
      end

      local filepath = vim.fn.expand(args.fargs[1]) -- expand 可以將 % 當成當前的檔案路徑
      local filename = vim.fs.basename(vim.fn.fnamemodify(filepath, ":p:r"))
      -- vim.cmd("tabnew | setlocal buftype=nofile | term viu") -- 方便離開terminal重新用不同的size再次運行
      vim.cmd("tabnew | setlocal buftype=nofile | term")
      vim.cmd("file viu:" .. filename)

      vim.cmd("startinsert")
      vim.api.nvim_input(string.format("viu %s<CR>", filepath))
      if vim.fn.executable("ls") ~= 0 then
        vim.api.nvim_input(
        -- 這樣與分開寫的結果是一樣的
        -- string.format("ls -lh %q\n" ..
        --   "file %q\n" ..
        --   "<CR>",
        --   vim.fn.trim(filepath, " ", 2),
        --   vim.fn.trim(filepath, " ", 2)
          string.format("ls -lh %q &&" ..
            "file %q" ..
            "<CR>",
            vim.fn.trim(filepath, " ", 2), -- trimRight space
            vim.fn.trim(filepath, " ", 2)
          )
        )
      end
      -- 提示也可以使用icat來查看，但是不能直接在terminal進行
      -- Error: Terminal does not support reporting screen sizes in pixels, use a terminal such as kitty, WezTerm, Konsole, etc. that does.
      -- vim.cmd("tabnew | setlocal buftype=nofile | term kitty +kitten icat " .. filepath)
      -- vim.fn.setloclist(0, { -- ⚠️ 不能用這個因為在terminal而且是nofile沒有loclist可用
      vim.fn.setqflist({
        { text = "kitty +kitten icat " .. filepath },
      }, 'a')
    end,
    {
      desc = "Terminal image viewer. tabnew | setlocal buftype=nofile | term viu <imgfile>",
      nargs = 1,
      complete = function(arg_lead, cmd_line)
        local argc = #(vim.split(cmd_line, "%s+")) - 1
        if argc == 1 then
          local accept_ext = vim.regex([[\c\.\(gif\|png\|jpeg\|jpg\|webp\)$]])
          local all_files = vim.fn.getcompletion(vim.fn.expand(arg_lead), "file")
          return vim.tbl_filter(
            function(filepath)
              return (accept_ext:match_str(filepath) or 0) > 0 or
                  vim.fn.isdirectory(filepath) == 1
            end,
            utils.table.sort_files_first(all_files)
          )
        end
      end
    }
  )
end

vim.api.nvim_create_user_command("DownloadDiscordAttachments", function(args)
    -- local output_dir = args.fargs[1]
    -- local channel_id = args.fargs[2] or os.getenv("CHANNEL_ID")
    -- local message_id = args.fargs[3]

    local config = {}
    for _, arg in ipairs(args.fargs) do
      local key, value = arg:match('^(.-)=(.*)$')
      if key then
        config[key] = value
      end
    end
    local output_dir = config["output_dir"]
    local channel_id = config["channel_id"] or os.getenv("CHANNEL_ID") or ""
    local message_id = config["message_id"]

    require("discord.download").download_attachments(output_dir, channel_id, { message_id })
  end,
  {
    desc = "Download Discord attachments to specified directory (need token)",
    nargs = "+",
    complete = function(arg_lead, cmd_line)
      local comps = {}

      local argc = #(vim.split(cmd_line, '%s+')) - 1

      -- 分割 arg_lead，檢查是否有等號
      -- arg_lead = "output="
      local prefix, suffix = arg_lead:match('^(.-)=(.*)$')
      if not prefix then
        suffix = arg_lead
        prefix = ''
      end
      -- print("prefix:", prefix)
      -- print("suffix:", suffix)


      local need_add_prefix = true
      if argc == 0 or not arg_lead:match('=') then
        comps = { 'output_dir=', 'channel_id=', 'message_id=' }
        need_add_prefix = false
        -- elseif arg_lead:match('^output_dir=$') then
      elseif prefix == "output_dir" then
        comps = {
          ".", -- 也提示可以直接放在當前的目錄
          unpack(completion.getDirOnly(suffix))
        }
      elseif prefix == "channel_id" then
        comps = { '118456055842734083' }
      elseif prefix == "message_id" then
        comps = { '1374023144347533414' }
      end

      if need_add_prefix then
        for i, comp in ipairs(comps) do
          comps[i] = prefix .. "=" .. comp
        end
      end

      -- 過濾補全結果，只返回以當前輸入開頭的選項
      return vim.tbl_filter(
        function(item)
          return vim.startswith(item, suffix)
        end,
        comps
      )
    end
  }
)

vim.api.nvim_create_user_command("Sum", function()
  -- Please refer to: https://vi.stackexchange.com/a/47003/31859

  -- Get VISUAL BLOCK
  local start_pos = vim.fn.getpos("'<") -- Visual selected start position
  local end_pos = vim.fn.getpos("'>")   -- Visual selected end position
  local start_line = start_pos[2]
  local end_line = end_pos[2]
  local start_col = start_pos[3]
  local end_col = end_pos[3]

  -- Make sure start_col and end_col are in the correct order.
  if start_col > end_col then
    start_col, end_col = end_col, start_col
  end

  -- Get the contents of the selected rows
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  -- Extraction of Visual Block column ranges
  local block_content = {}
  for i, line in ipairs(lines) do
    -- Ensure that only start_col to end_col are extracted.
    local len = #line
    local col_start = math.min(start_col, len)
    local col_end = math.min(end_col, len)
    local prefix = " + "
    if i == 1 then
      prefix = ""
    end
    if col_start <= col_end then
      table.insert(block_content, prefix .. string.sub(line, col_start, col_end))
    else
      table.insert(block_content, "") -- if the row has no content, insert an empty row
    end
  end

  -- Creating a new buffer
  vim.cmd("new | setlocal buftype=nofile noswapfile")

  -- Paste Visual Block content to new buffer

  -- vim.api.nvim_buf_set_lines(0, 0, -1, false, block_content)
  local joined_content = table.concat(block_content, " ")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { joined_content }) -- 直接寫上一整列，不再拆列

  -- use bc get result
  vim.cmd("%!bc")

  -- copy result to reg "
  vim.cmd("%y")

  -- show result
  print(joined_content .. "\n"
    .. "="
    .. vim.fn.getreg('"')
    .. "\n"
    .. "use `p` to paste if you want"
  )

  -- delete the temp buffer (really delete the buffer)
  vim.cmd("bw")
end, {
  desc = "Calculate the sum of the columns of a visual block using bd and save it to the clipboard",
  range = true,
})

vim.api.nvim_create_user_command("CloneSession", function(args)
  local session_path = args.fargs[1] or "~/mySession.vim"
  session_path = vim.fn.fnameescape(session_path)
  vim.cmd("mksession! " .. session_path)
  vim.notify("The session has been saved and opened in a new terminal: " .. session_path, vim.log.levels.INFO)

  local cmd = "nvim -S " .. session_path
  -- vim.cmd(string.format("!foot nvim -S %s &", session_path))
  vim.fn.setreg('+', cmd) -- 直接將要啟動的指令保存在剪貼簿

  local term = vim.env.TERM or "unknown"
  local launchers = {
    foot = function()
      vim.fn.system({ "foot", cmd, "&" })
    end,

    -- 不太曉得其它終端機的做法
    -- ["xterm-kitty"] = function() end,
    -- wezterm = function() end,
    -- alacritty = function() end,
    -- ["xterm-ghostty"] = function() end,

    _default = function() end,
  }

  local handler = launchers[term] or launchers._default
  handler()
  vim.api.nvim_echo({
    { 'You can open a new terminal and paste the contents of the clipboard: ', "Normal" },
    { cmd,                                                                     'YellowBold' },
  }
  , true, {})
end, {
  desc = "mksession! ~/mySession.vim",
  nargs = "?",
  complete = function()
    return { "~/mySession.vim" }
  end
})

vim.api.nvim_create_user_command("Clear",
  function()
    vim.cmd('startinsert')
    vim.api.nvim_input("clear" .. "<CR>")
    local org_scrollback = vim.opt_local.scrollback._value
    vim.cmd("set scrollback=1") -- Minimum is 1
    vim.cmd("set scrollback=" .. org_scrollback)
  end,
  {
    desc = "Clears the terminal's screen and can no longer use scrollback to find the previous input",
  }
)

vim.api.nvim_create_user_command("Gitfiles", function(args)
    --- NOTE: 有關於: nvim自動開啟終端機，並且能補獲所有stdout的內容，可參考: https://gist.github.com/CarsonSlovoka/e228da4f10f61e448f3bbba953b0e638
    local config = utils.cmd.get_cmp_config(args.fargs)

    vim.cmd("cd %:h") -- 先cd到該檔案目錄，執行git後看有沒有git

    -- 替tab命名
    local git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
    if vim.v.shell_error ~= 0 then
      vim.notify("Not in a Git repository", vim.log.levels.ERROR)
      return
    end
    local cd_git_root = config["cdToGitRoot"] or "1"
    if cd_git_root == "1" then
      vim.cmd("cd " .. git_root)
    end

    local tabnew = config["tab"] or "1"
    if tabnew == "1" then
      -- vim.cmd("tabnew | setlocal buftype=nofile | term") -- 👈 如果後面用的是 vim.fn.jobstart 且指定了 term = true, 就先當於是如此
      vim.cmd("tabnew | setlocal buftype=nofile")
    else
      -- new 會分割一個視窗, enew會用當前的視窗
      vim.cmd("enew | setlocal buftype=nofile")
    end

    local git_dirname = vim.fs.basename(vim.fn.fnamemodify(git_root, ":r"))
    vim.cmd("file search git files:" .. git_dirname)


    -- 檢查 fzf-preview.sh 路徑
    local preview_cmd
    --- fzf-preview.sh有一些協議可以在終端機呈現圖像 https://github.com/junegunn/fzf/blob/a0a334fc8d/bin/fzf-preview.sh#L60-L86
    --- chafa 可以foot啟動的nvim中的terminal中呈現圖像
    local fzf_preview_path = vim.fn.expand(vim.fn.getenv("FZF_PREVIEW_SH_PATH"))
    if fzf_preview_path ~= vim.NIL and vim.fn.filereadable(fzf_preview_path) == 1 then
      preview_cmd = string.format([[--preview "%s {}"]], fzf_preview_path)
    elseif vim.fn.filereadable(vim.fn.expand("~/fzf/bin/fzf-preview.sh")) == 1 then
      preview_cmd = string.format([[--preview "%s {}"]], vim.fn.expand("~/fzf/bin/fzf-preview.sh"))
    else
      preview_cmd = string.format([[--preview "%s --color=always --style=numbers {}"]], BAT_EXE_NAME)
    end

    -- CAUTION: 以下是用於輸入，但是用於 vim.fn.jobstart 之前 不能有 \ 出現，要所有的內容都變一行
    -- local cmd_str = string.format([[
    -- git ls-files --exclude-standard --cached | \
    -- fzf --style full \
    --     %s \
    --     %s  \
    --     %s && printf " [%%s] " {}' \
    --     --bind 'focus:+transform-header:file --brief {} || echo "No file selected"' \
    --     --bind 'ctrl-r:change-list-label( Reloading the list )+reload(sleep 2; git ls-files)' \
    --     --color 'border:#aaaaaa,label:#cccccc' \
    --     --color 'preview-border:#9999cc,preview-label:#ccccff' \
    --     --color 'list-border:#669966,list-label:#99cc99' \
    --     --color 'input-border:#996666,input-label:#ffcccc' \
    --     --color 'header-border:#6699cc,header-label:#99ccff' \
    --     --bind "enter:execute(echo "$(pwd)/{}" && echo "$(pwd)/{}" | wl-copy )+abort" \
    --     --bind 'ctrl-/:change-preview-window(down|hidden|)' \
    --     --bind "alt-p:preview-up,alt-n:preview-down"
    -- <CR>
    -- ]],
    --   "",                                                 -- --input-label ' Input ' --header-label ' File Type '
    --   preview_cmd,
    --   "--bind 'focus:transform-preview-label:[[ -n {} ]]" -- Previewing
    -- )
    local cmd = {
      "git ls-files --exclude-standard --cached |",
      -- "fzf --style full",
      "fzf --style full --multi",
      preview_cmd,
      [[--bind 'ctrl-q:select-all+accept']],                                                -- 如此ctrl+q可以輸出所有的項目, 需要配合fzf --multi
      "--bind 'focus:transform-preview-label:[[ -n {} ]] " .. [[ && printf " [%s] " {}' ]], -- Previewing
      [[--bind 'focus:+transform-header:file --brief {} || echo "No file selected"' ]],
      [[--bind 'ctrl-r:change-list-label( Reloading the list )+reload(sleep 2; git ls-files)' ]],
      [[--color 'border:#aaaaaa,label:#cccccc' ]],
      [[--color 'preview-border:#9999cc,preview-label:#ccccff' ]],
      [[--color 'list-border:#669966,list-label:#99cc99' ]],
      [[--color 'input-border:#996666,input-label:#ffcccc' ]],
      [[--color 'header-border:#6699cc,header-label:#99ccff' ]],
      string.format([[--bind "enter:execute(echo "$(pwd)/{}" && echo "$(pwd)/{}" | %s )+abort" ]], COPY_EXE), -- echo結果, 也將結果複製到剪貼簿
      [[--bind 'ctrl-/:change-preview-window(down|hidden|)' ]],                                               -- 透過 ctrl-/ 可以切換
      [[--bind "alt-p:preview-up,alt-n:preview-down"]],                                                       -- alt:{p,n} 可以控制preview up, down
      string.format([[--bind 'ctrl-y:execute-silent(%s <<< {})']], COPY_EXE),                                 -- 複製但不離開(不加abort), 如果沒有用silent畫面會閃
    }

    -- 使用 termopen 開啟一個互動式 terminal
    -- local job_id = vim.fn.jobstart(vim.o.shell, { -- 可以用o.shell, 但是這樣輸入完指令後不會馬上離開，要手動使用exit
    local cmd_str = table.concat(cmd, " ")
    local buf = vim.api.nvim_get_current_buf()
    local job_id = vim.fn.jobstart(cmd_str, {
      on_exit = function(_, exit_code)
        -- 當 terminal 退出時，提取 buffer 內容
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        -- print(vim.inspect(lines))
        for _, filepath in ipairs(lines) do
          if vim.fn.filereadable(filepath) == 1 then
            vim.fn.setqflist(
              {
                {
                  filename = filepath, -- 真實要跳轉的路徑
                  text = filepath,     -- 顯示的名稱
                },
              },
              'a'
            )
          end
        end
        lines = vim.tbl_filter(function() return lines ~= "" end, lines) -- 忽略空行

        -- 打開選擇的檔案
        vim.cmd("e " .. lines[1])

        -- 關閉 terminal 窗口
        vim.api.nvim_buf_delete(buf, { force = true })
      end,
      term = true -- 如果遇到requires unmodified buffer的錯誤，請確認當前的buf不是在term下
    })
    -- 檢查是否成功啟動 terminal
    if job_id <= 0 then
      print("Failed to start terminal")
      vim.api.nvim_buf_delete(buf, { force = true })
      return
    end

    -- 可以設置自動命令, 在某些情況時觸發一些自定義的動作
    -- vim.api.nvim_buf_attach(buf, false, {
    --   on_lines = function()
    --     vim.fn.jobstop(job_id)
    --   end
    -- })

    vim.cmd("startinsert")
    -- vim.api.nvim_input(cmd_str) -- 是用vim.o.shell時，自動輸入一開始的指令, 是可行，但是最後要手動用 exit 才能離開

    -- 可以考慮cd回原本的工作目錄
  end,
  {
    desc = string.format([[搜尋git commit過的檔案 git ls-files | fzf --preview "%s ..."]], BAT_EXE_NAME),
    nargs = "*",
    complete = function()
      return {
        "tab=0", -- 在新的tab開啟, 否則在當前的window開啟
        "cdToGitRoot=1",
      }
    end
  }
)

vim.api.nvim_create_user_command("Rg", function(args)
    if args.range == 0 and #args.fargs == 0 then
      vim.notify("Please enter at least the keywords you are looking for.", vim.log.levels.ERROR)
      return
    end
    if args.fargs[1] == "-h" then
      vim.fn.setqflist({
        { text = ':Rg search_word                             " 預設會用git_root來當成工作目錄，在開始找內文' },
        { text = ':Rg search_word init.lua                    " 在init.lua之中，找關鍵字' },
        { text = ':Rg require ~/.config/nvim/init.lua         " 可以直接指定工作目錄' },
        { text = ':Rg require init.lua wd=~/.config/nvim      " 可以使用wd來指定工作目錄 (好處是出來的內容路徑會比較乾淨)' },
        { text = ':Rg search_word main.go wd=.' },
        { text = ':Rg type -i -g *.sh -g *.toml               " 找sh, toml的檔案' },
        { text = ':Rg word -i                                 " ignore-case' },
        { text = ':Rg --files ~/.config/nvim                  " 也可以找檔案' },
        { text = ':Rg --files . wd=~/.config/nvim             " 同上(路徑較乾淨)' },
        { text = ':Rg --files . wd=~/.config/nvim -uu         " ignore-file, findHidden (-.) 即:忽略gitignore, 顯示隱藏檔案. 第三個u是binary時可用' },
        { text = ':Rg --files . wd=/usr/share/icons/          " 找圖標, 圖檔(svg, png)' },
        { text = ':Rg -g *.png --files . wd=/usr/share/icons/ " 找系統圖標檔: png' },
        { text = ':Rg -g **/*.sh --files                      " 如果只有用*.sh只能當前的目錄，不會找子目錄' },
      }, 'a')
      -- vim.cmd("copen | cbo | 4cp") -- 要真的enter之後才會在最後一個項目，此時cp才會有用
      vim.cmd("copen | cbo")
      return
    end

    local opts = utils.cmd.get_cmp_config(args.fargs, true)

    if args.range ~= 0 then
      local selected_text = table.concat(utils.range.get_selected_text(), "")
      table.insert(args.fargs, 1, selected_text)
    end

    if opts["wd"] and opts["wd"] ~= "<git_root>" then
      -- 以下這些都可行
      -- :lua print(vim.fn.fnamemodify("~/.config/nvim/lua/config/commands.lua", ":p"))
      -- :lua print(vim.fn.fnamemodify(".", ":p"))
      -- :lua print(vim.fn.fnamemodify("../..", ":p"))
      vim.cmd("cd " .. vim.fn.fnamemodify(opts["wd"], ":p"))
    elseif vim.api.nvim_buf_get_name(0) ~= '' then -- 避免有No Name的情況，沒有辦法cd %:h
      vim.cmd("cd %:h")                            -- 先cd到該檔案目錄，執行git後看有沒有git -- 順便當沒有指定 cdToGitRoot 就用當前的檔案目錄當成工作目錄

      local git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
      if vim.v.shell_error == 0 then
        vim.cmd("cd " .. git_root)
      end
    end

    vim.cmd("tabnew | setlocal buftype=nofile")

    local is_files = false
    for _, para in ipairs(args.fargs) do
      if para == "--files" then
        is_files = true
        break
      end
    end

    local cmd = {}
    if is_files then
      -- 會使用fzf-preview.sh https://github.com/junegunn/fzf/blob/0e67c5aa7a7c98bc9c8b0f8bed23579136db54da/bin/fzf-preview.sh#L1-L86
      -- 如此如果檔案是圖片，可以看到該內容

      local preview_cmd
      local fzf_preview_path = vim.fn.expand(vim.fn.getenv("FZF_PREVIEW_SH_PATH"))
      if fzf_preview_path ~= vim.NIL and vim.fn.filereadable(fzf_preview_path) == 1 then
        preview_cmd = string.format([[--preview "%s {}"]], fzf_preview_path)
      elseif vim.fn.filereadable(vim.fn.expand("~/fzf/bin/fzf-preview.sh")) == 1 then
        preview_cmd = string.format([[--preview "%s {}"]], vim.fn.expand("~/fzf/bin/fzf-preview.sh"))
      else
        preview_cmd = string.format([[--preview "%s --color=always --style=numbers {}"]], BAT_EXE_NAME)
      end
      cmd = {
        "rg " .. table.concat(args.fargs, " ") .. " | ",
        "fzf --style full --multi",
        preview_cmd,
        [[--bind 'ctrl-q:select-all+accept']],                                                -- 需要fzf有--multi才可用
        "--bind 'focus:transform-preview-label:[[ -n {} ]] " .. [[ && printf " [%s] " {}' ]], -- Previewing
        [[--bind 'focus:+transform-header:file --brief {} || echo "No file selected"' ]],
        [[--bind 'ctrl-r:change-list-label( Reloading the list )+reload(sleep 2; git ls-files)' ]],
        [[--color 'border:#aaaaaa,label:#cccccc' ]],
        [[--color 'preview-border:#9999cc,preview-label:#ccccff' ]],
        [[--color 'list-border:#669966,list-label:#99cc99' ]],
        [[--color 'input-border:#996666,input-label:#ffcccc' ]],
        [[--color 'header-border:#6699cc,header-label:#99ccff' ]],
        string.format([[--bind "enter:execute(echo "{}" && echo "{}" | %s )+abort" ]], COPY_EXE),
        [[--bind 'ctrl-/:change-preview-window(down|hidden|)' ]],
        [[--bind "alt-p:preview-up,alt-n:preview-down"]],
        string.format([[--bind 'ctrl-y:execute-silent(%s <<< {})']], COPY_EXE),
      }
    else
      cmd = {
        "rg --vimgrep " .. table.concat(args.fargs, " ") .. " | ",
        [[fzf -d ':' --preview-window 'right:+{2}' --multi]],
        string.format([[--preview '%s --color=always --style=numbers --highlight-line {2} {1}']], BAT_EXE_NAME),
        [[--bind 'ctrl-q:select-all+accept']], -- 如此ctrl+q可以輸出所有的項目, 需要配合fzf --multi
        "--bind 'focus:transform-preview-label:[[ -n {} ]] " .. [[ && printf " [%s] " {}' ]],
        [[--bind 'focus:+transform-header:file --brief {1} || echo "No file selected"' ]],
        [[--bind 'ctrl-r:change-list-label( Reloading the list )+reload(sleep 2; git ls-files)' ]],
        [[--color 'border:#aaaaaa,label:#cccccc' ]],
        [[--color 'preview-border:#9999cc,preview-label:#ccccff' ]],
        [[--color 'list-border:#669966,list-label:#99cc99' ]],
        [[--color 'input-border:#996666,input-label:#ffcccc' ]],
        [[--color 'header-border:#6699cc,header-label:#99ccff' ]],
        -- [[--bind "enter:execute(echo "$(pwd)/{}" && echo "$(pwd)/{}" | wl-copy )+abort" ]], -- 👈 用這樣會導致當rg使用工作路徑時會有重複的問題
        string.format([[--bind "enter:execute(echo "{}" && echo "{}" | %s )+abort" ]], COPY_EXE),
        [[--bind 'ctrl-/:change-preview-window(down|hidden|)' ]],
        [[--bind "alt-p:preview-up,alt-n:preview-down"]],
        string.format([[--bind 'ctrl-y:execute-silent(%s <<< {})']], COPY_EXE),
      }
    end

    local cmd_str = table.concat(cmd, " ")
    local buf = vim.api.nvim_get_current_buf()
    local job_id = vim.fn.jobstart(cmd_str, {
      on_exit = function(_, exit_code)
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        lines = vim.tbl_filter(function() return lines ~= "" end, lines)
        if not lines[1] then
          return
        end

        if is_files then
          -- 沒有lnum, col
          for _, filepath in ipairs(lines) do
            if vim.fn.filereadable(filepath) == 1 then
              -- vim.fn.setqflist({ { filename = filepath:gsub("||", "") } }, 'a') -- 其實可以不需要置換到，如果是 `:e ~/.config/nvim/init.lua||` 後面的||可以不需要拿掉，也可以跳轉，只是不好看
              vim.fn.setqflist({ { filename = filepath } }, 'a') -- 奇怪的事置換掉了，但是qflist中還是會看到 || 所以乾脆不gsub
            end
          end
          -- 直接是完整的路徑不用像--vimgrep去拆
          vim.cmd("e " .. lines[1])
          return
        end

        -- 將所有內容加到qflist之中
        for i in ipairs(lines) do
          -- local filepath, lnum, col = lines[i]:match("^(.+):(%d+):(%d+):(.*)$") -- 可行，但是診斷會有: Undefined field `match`
          local filepath, lnum, col = tostring(lines[i]):match("^(.+):(%d+):(%d+):(.*)$")

          if vim.fn.filereadable(filepath) == 1 then
            vim.fn.setqflist(
              {
                {
                  filename = filepath,
                  lnum = lnum or 1,
                  col = col or 1,
                }
              },
              'a'
            )
          end
        end


        -- 用最後一筆當成要跳轉的對像
        -- if lines[1]:match("^.+:%d+:%d+:.*$") -- path/to/file.txt:1234:45:some content
        local filepath, lnum, col = tostring(lines[1]):match("^(.+):(%d+):(%d+):(.*)$")
        if filepath and lnum then
          if col then
            vim.cmd("e " .. filepath)
            vim.api.nvim_win_set_cursor(0, { tonumber(lnum), tonumber(col) - 1 })
            -- lua vim.api.nvim_win_set_cursor(0, { tonumber(lnum), tonumber(col) - 1 })
          else
            vim.cmd("e +" .. lnum .. " " .. filepath)
          end
          vim.api.nvim_buf_delete(buf, { force = true })
        elseif vim.uv.fs_stat(lines[1]) then
          -- 此情況可能是用--files找檔案會發生
          vim.cmd("e " .. lines[1])
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end,
      term = true
    })
    if job_id <= 0 then
      vim.notify("Failed to start terminal", vim.log.levels.ERROR)
      vim.api.nvim_buf_delete(buf, { force = true })
      return
    end

    vim.cmd("startinsert")
  end,
  {
    desc = [[rg | fzf --preview 'batcat' ...]],
    range = true,
    nargs = "*",
    complete = function(arg_lead, cmd_line)
      local comps, argc, prefix, suffix = utils.cmd.init_complete(arg_lead, cmd_line)
      local exist_comps = argc > 1 and utils.cmd.get_exist_comps(cmd_line) or {}
      local need_add_prefix = true
      if not arg_lead:match('=') then
        comps = vim.tbl_filter(
          function(item) return not exist_comps[item] end,
          { 'wd=' }
        )
        need_add_prefix = false
      elseif prefix == "wd" then
        local all_files = vim.fn.getcompletion(vim.fn.expand(suffix), "file")
        comps = {
          "<git_root>",
          unpack(vim.tbl_filter(
            function(filepath)
              return vim.fn.isdirectory(filepath) == 1
            end,
            all_files
          ))
        }
      end
      if need_add_prefix then
        for i, comp in ipairs(comps) do
          comps[i] = prefix .. "=" .. comp
        end
      end
      local input = need_add_prefix and prefix .. "=" .. suffix or arg_lead
      return vim.tbl_filter(function(item) return item:match(input) end, comps)
    end
  }
)


vim.api.nvim_create_user_command("PrintUcdblock",
  function(args)
    local config = utils.cmd.get_cmp_config(args.fargs)

    local unicodes
    if args.range > 0 then
      local text = table.concat(utils.range.get_selected_text(), "")
      unicodes = {}
      for unicode in utils.utf8.codes(text) do
        table.insert(unicodes, unicode)
      end
    else
      unicodes = config["unicode"] or ""
      if unicodes == "" then
        -- error("請提供unicode", vim.log.levels.WARN)
        vim.notify("請提供unicode. ex: `unicode=0x4e00`", vim.log.levels.WARN)
        return
      end
      unicodes = vim.split(unicodes, ",")
    end

    local lang = config["lang"] or "en"
    local ub = require("ucd").UnicodeBlock.new()

    local result = {}
    for _, unicode in ipairs(unicodes) do
      local block_name = ub:get_ucd_block(tonumber(unicode), lang)
      table.insert(result, {
        ch = vim.fn.nr2char(tonumber(unicode) or 0),
        codepoint = string.format("0x%X ( %d )", unicode, unicode),
        block_name = block_name,
      })
    end
    print(vim.inspect(result))
  end,
  {
    desc = [[顯示該unicode碼點位於blocks.txt的哪一段]],
    nargs = "*",
    range = true,
    complete = function(arg_lead, cmd_line)
      local comps = {}

      local argc = #(vim.split(cmd_line, '%s+')) - 1

      -- 檢查是否有等號
      local prefix, suffix = arg_lead:match('^(.-)=(.*)$')
      if not prefix then
        suffix = arg_lead
        prefix = ''
      end

      local need_add_prefix = true
      if argc == 0 or not arg_lead:match('=') then
        comps = { 'unicode=', 'lang=', }
        need_add_prefix = false
      elseif prefix == "unicode" then
        comps = {
          "0x4e00",
          "0x4e00,0x1fa00",
        }
      elseif prefix == "lang" then
        comps = { "en", "zh" }
      end

      if need_add_prefix then
        for i, comp in ipairs(comps) do
          comps[i] = prefix .. "=" .. comp
        end
      end

      -- 過濾補全結果，只返回以當前輸入開頭的選項
      return vim.tbl_filter(
        function(item)
          return vim.startswith(item, suffix)
        end,
        comps
      )
    end
  }
)

vim.api.nvim_create_user_command('GetImgDataURL', function(args)
  -- NOTE: 可以得到base64編碼的內容, 對象可為{選取得內容(通常用於svg) 該檔案本身(路徑) }

  local config = utils.cmd.get_cmp_config(args.fargs)
  local mimeType = config["mimeType"] or ""

  local cmd = ""
  if args.range ~= 0 and mimeType == "image/svg+xml" then
    -- 讀取當前緩衝區內容
    -- local svg_txt = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '')
    local svg_txt = table.concat(utils.range.get_selected_text(), "")
    -- echo -n  do not output the trailing newline
    cmd = string.format([[echo -n %s | base64]], vim.fn.shellescape(svg_txt)) -- 利用linux的工具，取得base64編碼的結果
  else
    local abs_path = vim.fn.expand(("%:p"))
    cmd = string.format([[base64 -w 0 '%s' ]], abs_path) -- -w 0 -- disable line wrapping
  end

  local base64 = vim.fn.system(cmd)
  base64 = base64:gsub('\n', '')

  local data_url = (mimeType ~= "" and "data:" .. mimeType .. ';base64,' or "") .. base64

  -- vim.api.nvim_put({ data_url }, 'l', true, true) -- 👈 可以考慮直接貼上
  --
  -- 將結果放入暫存器" 讓使用者自己貼上
  vim.fn.setreg('"', data_url)

  -- 提示使用者
  vim.api.nvim_echo({
    { 'press ',                                                       "Normal" },
    { 'p',                                                            'YellowBold' },
    { ' to get result ',                                              "Normal" },
    { mimeType ~= "" and "data:" .. mimeType .. ';base64,... ' or "", '@label' },
  }
  , false, {})
end, {
  desc = "get data URL: data:image/svg+xml;base64,...  for inline encoded image",
  nargs = "?",
  range = true,
  complete = function(arg_lead, cmd_line)
    local comps = {}
    local argc = #(vim.split(cmd_line, '%s+')) - 1
    local prefix, suffix = arg_lead:match('^(.-)=(.*)$')
    if not prefix then
      suffix = arg_lead
      prefix = ''
    end
    local need_add_prefix = true
    if argc == 0 or not arg_lead:match('=') then
      comps = { 'mimeType=' }
      need_add_prefix = false
    elseif prefix == "mimeType" then
      comps = {
        "image/svg+xml",
        "image/png",
      }
    end
    if need_add_prefix then
      for i, comp in ipairs(comps) do
        comps[i] = prefix .. "=" .. comp
      end
    end
    return vim.tbl_filter(function(item) return vim.startswith(item, suffix) end, comps)
  end
})

vim.api.nvim_create_user_command("Chafa",
  function(args)
    if vim.fn.executable("chafa") == 0 then
      vim.notify("chafa not found. sudo apt install chafa", vim.log.levels.WARN)
      return
    end

    local cfg = utils.cmd.get_cmp_config(args.fargs)

    local img_path
    if args.fargs[1] == "." then
      vim.cmd("cd %:h")
      img_path = vim.fn.expand("%:p")
    else
      img_path = args.fargs[1]
    end

    vim.cmd("tabnew")

    local ext = vim.fn.fnamemodify(img_path, ':e')
    local cmd = ""
    if ext == "ico" and vim.fn.executable("convert") then
      -- chafa沒辦法直接處理ico, 用 imagemagick 提供的工具 convert 轉成png再進行
      cmd = string.format("convert %q PNG:- | chafa -", img_path)
    else
      cmd = "chafa " .. img_path
    end
    -- 可選項
    if cfg["size"] then
      cmd = cmd .. " -s " .. cfg["size"]
    end
    if cfg["color"] then
      cmd = cmd .. " -c " .. cfg["color"]
    end
    vim.cmd("term " .. cmd)
    vim.cmd("startinsert")

    -- 在qflist中寫上可以透過-s和-c去調整大小和顏色
    vim.fn.setqflist({
      { text = cmd },
      { text = cmd .. " -s 10x10" },
      { text = cmd .. " -s 10x10 -c 2" },
      { text = cmd .. " -s 10x10 -c 256" },
    }, 'a')
  end,
  {
    desc = "使用chafa來檢視圖片(適用於foot所開啟的nvim中的終端機)",
    nargs = "+",
    complete = function(arg_lead, cmd_line)
      local comps = {}
      local argc = #(vim.split(cmd_line, '%s+')) - 1
      local prefix, suffix = arg_lead:match('^(.-)=(.*)$')

      if argc == 1 then
        local accept_ext = utils.table.get_mapping_table({ "png", "webp", "ico", "jpg", "jpeg" })
        local accept_files = vim.tbl_filter(
          function(file)
            if vim.fn.isdirectory(file) == 1 then
              -- 是目錄就繼續
              return true
            end
            local ext = string.lower(vim.fn.fnamemodify(file, ':e'))
            return accept_ext[ext] == true
          end,
          vim.fn.getcompletion(arg_lead, "file")
        )

        if arg_lead == "" then
          return {
            ".",                 -- 在實作直接客製成`.`視為 vim.fn.expand("%:p") 即可 -- 將目前的檔案放在第一個(不管這個附檔名對不對)
            unpack(accept_files) -- 之後的會挑附檔名
          }
        else
          return accept_files
        end
      end

      local exist_comps = argc > 2 and utils.cmd.get_exist_comps(cmd_line) or {}

      local need_add_prefix = true
      if argc == 0 or not arg_lead:match('=') then
        comps = vim.tbl_filter(
          function(item) return not exist_comps[item] end, -- 過濾已輸入過的選項
          { 'size=', 'color=', }                           -- 全選項
        )
        need_add_prefix = false
      elseif prefix == "size" then
        comps = {
          "3x3",
          "10x10",
          "10x15",
        }
      elseif prefix == "color" then
        comps = {
          "none",
          "2", "8", "16/8", "16", "240", "256", "full"
        }
      end
      if need_add_prefix then
        for i, comp in ipairs(comps) do
          comps[i] = prefix .. "=" .. comp
        end
      end
      local input = need_add_prefix and prefix .. "=" .. suffix or arg_lead
      return vim.tbl_filter(function(item) return item:match(input) end, comps) -- 改用match比較自由
    end
  }
)

vim.api.nvim_create_user_command("Align",
  function(args)
    -- vim.fn.setreg('"', "02f#100i 30|dwj")
    -- 0 回到一開始
    -- 2f# 找第二個#
    -- 100i 輸入100個空白
    --  ESC 離開insert
    -- 30| 跳到第30欄
    -- dw 刪除多餘的空白
    -- j 往下到下一列

    if args.fargs[1] == "-h" then
      cmdUtils.showHelpAtQuickFix({
        [[:'<,'>Align findSepExpr=0/key alignCol=75]],

        -- 以下三種方法都無法呈現CR
        -- [[let @a='0/word\x0d100i 80|dwj']],
        -- [[let @a='0/word\r100i 80|dwj']],
        -- [[let @a='0/word<CR>100i 80|dwj']],

        -- string.format([[let @a='0/word%s100i 80|dwj']], string.char(0xd)), -- 也行
        string.format([[let @a='0/word%s100i 80|dwj']], CR),
        "👇 If the separator has only one character, you can also consider using external tools.",
        [[:!column -t -s'\#' -o'\#']],      -- linux預設的column可以用-o, mac的沒有
        [[:!column -t -s'\#' -o'\#' -l 3]], -- 限制最多三欄
        [[:!gcolumn -t -s'\#' -o'\#']],     -- https://github.com/util-linux/util-linux # brew install util-linux 當中有column 可以rename成gcolumn
      })
      return
    end

    local config = utils.cmd.get_cmp_config(args.fargs)

    for _, require_key in ipairs({ "findSepExpr" }) do
      if not config[require_key] then
        vim.api.nvim_echo({
          { '⚠️ missing para: ', "Normal" },
          { require_key, '@label' },
          { "\n", 'Normal' },
          { "Example:\n", 'Normal' },
          { "'<,'>Align findSepExpr=02f# alignCol=30\n", '@label' },

          { "'<,'>Align findSepExpr=$4F#B alignCol=80", '@label' },
          { "  從結尾找\n", 'Normal' },

          { "'<,'>Align findSepExpr=0/--ttl alignCol=80", '@label' },
          { "  用搜尋的方式\n", 'Normal' },

          { "let @a='0/word<CR>100i dwj'", '@label' },
          { "  自己用巨集\n", 'Normal' },
        }, true, {})
        return
      end
    end

    local autoSaveState = require("config.autocmd").autoSave
    if autoSaveState then
      require("config.autocmd").autoSave = false
    end

    --local cur_col = vim.fn.col('.') -- vim.api.nvim_win_get_cursor(0)[2] -- :echo col('.') -- vim.fn.col('.') -- 這些都等價

    local alignCol = tonumber(config["alignCol"] or vim.fn.col('.')) -- IMPORTANT:  必需要下到上來選取時vim.fn.col('.')才會有用


    if alignCol < 1 then
      error("alignCol must >= 1")
    elseif alignCol == 1 then
      vim.notify("Please consider selecting from bottom to top in visual mode", vim.log.levels.WARN)
    end

    if config["showTick"] == "1" then
      local cur_line = vim.api.nvim_win_get_cursor(0)[1]
      local spaces = string.rep(" ", alignCol - 1)
      local new_line_content = spaces .. "I" .. spaces -- 創建新行內容：N 個空格 + "I" + N 個空格
      -- -- 在當前行的上方插入一行
      vim.api.nvim_buf_set_lines(0, cur_line - 1, cur_line - 1, false, { new_line_content })
      -- vim.cmd("normal! OIgccV<End>:'<,'>right 120") -- 沒用
      -- vim.cmd(string.format("normal! %dGgcc", cur_line)) -- 這也不能變成註解
      --
      vim.api.nvim_echo({
        { '💡 橫刻度也可以考慮使用以下方法生成\n', "@label" },
        { 'iX\n', "@label" },
        { ":right ", '@keyword' },
        { "120", 'Normal' },
      }, false, {})
    end

    local fillWidth = (tonumber(config["fillWidth"]) or 100) + alignCol -- 至少要大於alignCol
    for _ = 0, args.line2 - args.line1 do
      -- local prefix, search_part, suffix = config["findSepExpr"]:match("(.-)(/.-[\r\n])(.*)") -- 不曉得\r該怎麼弄，先假設搜尋就是結尾
      local prefix, search_part = config["findSepExpr"]:match("(.-)(/.-)$")
      if search_part then
        -- vim.cmd(string.format("normal! %dG", args.line1 + i)) -- 先跳到指定的行 <== 這不是必要的, vim.fn.search就會從range找起
        if prefix ~= "" then
          vim.cmd(string.format("normal! %s", prefix))
        end
        -- -- vim.cmd("/word")  -- Caution: 這樣的搜尋是無效的
        vim.fn.search(search_part:sub(2), "w") -- w 往前, b往後搜
        vim.cmd(string.format("normal! %di %d|dwj", fillWidth, alignCol))
      else
        -- vim.cmd(string.format("normal! 02f#100i 30|dwj")) -- 先找到分隔符`#`, 接著插入100個空白: 100i, ESC離開, 30| 移動到第30欄的位置(:help |), dwj刪除之後的空白
        vim.cmd(string.format("normal! %s%di %d|dwj",
          config["findSepExpr"],
          fillWidth,
          alignCol
        ))
      end
    end
    if autoSaveState then
      require("config.autocmd").autoSave = true
    end
  end,
  {
    desc = "Align to the specified char",
    nargs = "+",
    range = true,
    complete = function(arg_lead, cmd_line)
      local comps, argc, prefix, suffix = utils.cmd.init_complete(arg_lead, cmd_line)

      local exist_comps = argc > 1 and utils.cmd.get_exist_comps(cmd_line) or {}

      local need_add_prefix = true
      if argc == 0 or not arg_lead:match('=') then
        comps = vim.tbl_filter(
          function(item) return not exist_comps[item] end,
          { 'findSepExpr=', 'alignCol=', 'showTick=' }
        )
        need_add_prefix = false
      elseif prefix == "findSepExpr" then
        comps = {
          "0f#",
          "02f#",
        }
      elseif prefix == "alignCol" then
        comps = {
          "20",
          "30",
          "50",
        }
      elseif prefix == "showTick" then
        comps = {
          "1",
          "0",
        }
      end
      if need_add_prefix then
        for i, comp in ipairs(comps) do
          comps[i] = prefix .. "=" .. comp
        end
      end
      local input = need_add_prefix and prefix .. "=" .. suffix or arg_lead
      return vim.tbl_filter(function(item) return item:match(input) end, comps)
    end
  }
)


vim.api.nvim_create_user_command("Column",
  function(args)
    local sep = args.fargs[1]
    -- vim.fn.setreg('a', [[ :'<,'>s/\v([^,]*)/\=printf("%-10s", submatch(1)) ]]) -- 這可行，但是還是要主動使用這個暫存器
    local lines = utils.range.get_selected_text()
    if #lines == 0 then
      return
    end

    local range = ""
    if args.range ~= 0 then
      local start = vim.api.nvim_buf_get_mark(0, "<")[1]
      local finish = vim.api.nvim_buf_get_mark(0, ">")[1]
      range = start .. "," .. finish
    end

    local header = lines[1] -- 以第一列為主
    local _, count = header:gsub(sep, "")

    local groups = string.rep(string.format("([^%s].*)%s", sep, sep), count + 1) -- 2個sep表示有3欄
    groups = string.sub(groups, 1, #groups - 1)                                  -- 移除最後的sep

    local submatchs = ""
    for i = 1, count + 1 do
      submatchs = submatchs .. string.format([[submatch(%d), ]], i)
    end
    submatchs = string.sub(submatchs, 1, #submatchs - 2) -- 移除最後的 ` ,`


    local config = utils.cmd.get_cmp_config(args.fargs)
    local widths = vim.split(config["widths"] or "", ",")
    local out_sep = config["out_sep"] and config["out_sep"] .. " " or ""
    local s = ""
    for i = 1, count + 1 do
      s = s .. string.format("%%-%ss %s", tostring(widths[i] or ""), out_sep)
    end
    s = string.sub(s, 1, #s - 1) -- 移除最後的 ` `

    -- local cmd = string.format([[:'<,'>s/\v%s/\=printf("%s", %s)]], -- 沒有辦法輸出'<,'>因此，只能用列號來取代
    local cmd = string.format([[:%ss/\v%s/\=printf("%s", %s)]],
      range,
      groups,
      s,
      submatchs
    )
    -- vim.fn.setreg('a', cmd)
    vim.api.nvim_input(cmd)
    vim.fn.setqflist({
      {
        text = string.format("'<,'>!column -t -s'%s' -o' '", sep),
      },
    }, 'a')
  end,
  {
    desc = "固定欄寬. '<,'>!column -t -s',' -o' | '",
    nargs = "+",
    range = true,
    complete = function(arg_lead, cmd_line)
      local comps, argc, prefix, suffix = utils.cmd.init_complete(arg_lead, cmd_line)
      local exist_comps = argc > 1 and utils.cmd.get_exist_comps(cmd_line) or {}

      if argc == 1 then
        return { ",", "|" }
      end
      local need_add_prefix = true
      if not arg_lead:match('=') then
        comps = vim.tbl_filter(
          function(item) return not exist_comps[item] end,
          { 'out_sep=', 'widths=' }
        )
        need_add_prefix = false
      elseif prefix == "out_sep" then
        comps = {
          ",",
          "|",
        }
      elseif prefix == "widths" then
        -- TODO: 如果要自動抓，需要由cmd_line抓出輸入的sep
        -- local cur_line_text = vim.api.nvim_get_current_line()
        -- local _, count = cur_line_text:gsub(sep, "")
        -- 每一欄的寬
        comps = {
          "10,20",
          "10,5,30",
          "10,5,30,...",
        }
      end
      if need_add_prefix then
        for i, comp in ipairs(comps) do
          comps[i] = prefix .. "=" .. comp
        end
      end
      local input = need_add_prefix and prefix .. "=" .. suffix or arg_lead
      return vim.tbl_filter(function(item) return item:match(input) end, comps)
    end
  }
)

vim.api.nvim_create_user_command("PrintUnicodes",
  function(args)
    local opts        = utils.cmd.get_cmp_config(args.fargs, true)

    local script_path = require("py").get_script_path("print_unicodes.py")
    local fontpath    = args.fargs[1]
    if not vim.uv.fs_stat(fontpath) then
      vim.notify("The fontpath doesn't exist", vim.log.levels.ERROR)
      return
    end
    local col          = opts["col"] or 10

    local cmd          = { "python3", script_path,
      fontpath,
      "--col", col,
    }
    local output_lines = {}
    local job_id       = vim.fn.jobstart(table.concat(cmd, " "), {
      stdout_buffered = true, -- 緩衝 stdout, 直到 job 完成 (需實作on_stdout)
      on_stdout = function(_, data, _)
        if not data then
          return
        end
        for _, line in ipairs(data) do
          if line ~= "" then
            local txt = string.gsub(line, "\n", "")
            table.insert(output_lines, txt) -- 在nvim_buf_set_lines中的每一列裡面不可以在有\n
          end
        end
      end,
      on_exit = function(_, code, _)
        if code ~= 0 then
          vim.notify(
            "exit code: " .. code .. "\n" ..
            table.concat(output_lines, ""), vim.log.levels.ERROR)
          return
        end
        -- local buf          = vim.api.nvim_get_current_buf()
        -- vim.api.nvim_buf_set_lines(buf, -1, -1, false, output_lines) -- 在最後一列插入
        -- local lnum = vim.fn.line('.')
        -- vim.api.nvim_buf_set_lines(buf, lnum, -1, false, output_lines) -- 這會取代掉之後所有的文本
        -- vim.fn.appendbufline(buf, lnum, table.concat(output_lines, "\n")) -- 只能一列
        -- vim.api.nvim_buf_set_lines(buf, lnum, lnum + #output_lines - 1, false, output_lines)
        -- 👆 使用nivm_put會比較簡單
        vim.api.nvim_put(output_lines, "l", false, true) -- after: false等同P, true: p ; 最後follow, 為true時會將游標放到文本後
      end
    })
    if job_id <= 0 then
      vim.notify("Failed to start job:\n" .. vim.inspect(cmd), vim.log.levels.ERROR)
    end
  end,
  {
    desc = "Print out all unicode codes for the specified font file",
    nargs = "+",
    complete = function(arg_lead, cmd_line)
      local argc = #(vim.split(cmd_line, "%s+")) - 1
      if argc == 1 then
        local all_files = vim.fn.getcompletion(vim.fn.expand(arg_lead), "file")
        local regex_video = vim.regex([[\c\.\(ttf\|otf\|ttc\|woff\|woff2\)$]])
        local cmp_files = {}
        for _, file in ipairs(all_files) do
          if vim.uv.fs_stat(file).type == "directory" then
            table.insert(cmp_files, file)
          else
            if regex_video:match_str(file) then
              table.insert(cmp_files, file)
            end
          end
        end
        return utils.table.sort_files_first(cmp_files)
      end
      if argc == 2 then
        return {
          "col=10",
          "col=20",
          "col=60",
        }
      end
    end
  }
)

local function get_font_map()
  local font_map = {}
  -- 執行 fc-list 命令
  local handle = io.popen('fc-list : file family ')
  if handle == nil then
    return {}
  end
  -- fc-list : family style file spacing -- 可以有這四個, 序順是固定的(即: 某個屬性如果有它一定是排在某個位置，與輸入的順序無關)
  local output = handle:read("*a")
  handle:close()

  -- 解析輸出，每行以冒號分隔，順序分別為 family style file spacing
  for line in output:gmatch("[^\r\n]+") do
    local parts = {}
    local j = 1
    for part in line:gmatch("[^:]+") do
      parts[j] = part:gsub("^%s*(.-)%s*$", "%1") -- 去除前後空格
      j = j + 1
    end
    if #parts >= 2 and parts[1] ~= "" then
      local filepath = parts[1]
      local family = parts[2]
      if not font_map[filepath] then
        font_map[filepath] = family
      end
    end
  end
  return font_map
end

vim.api.nvim_create_user_command("ViewWithFont", function(args)
    local config = utils.cmd.get_cmp_config(args.fargs)

    if config["familyname"] == nil and config["fontpath"] == nil then
      vim.notify("need familyname or fontpath", vim.log.levels.WARN)
      return
    end

    local familyname = config["familyname"] or get_font_map()[config["fontpath"]]

    if familyname == nil then
      vim.notify("Can't find the corresponding familyname.", vim.log.levels.WARN)
      return
    end

    familyname = vim.split(familyname, ",")[1] -- 會給多個familyname 每一個都可當成查找的對像, 例如: "全字庫說文解字,EBAS,䕂䅓,ꗾ꙲깷뮡ꓥ룑꙲:size=52"
    -- CAUTION: 全放也是可以，但是後面的size就會沒有作用了

    -- local fontpath = vim.fn.fnamemodify(config["fontpath"], ":p"):gsub("-", "\\-") -- foot的字型路徑有 - 要變成 \- 才可以
    local size = tonumber(config["size"]) or 32
    local src = config["src"] or vim.fn.expand("%:p")
    local line_height = config["line_height"] or 24

    local cmd = string.format([[foot --font="%s:size=%d" --override=main.line-height=%d bash -c 'nvim %s ']],
      familyname, size, line_height, src)

    vim.fn.setqflist({ { text = cmd }, }, 'a')

    -- vim.cmd("!" .. cmd .. ) -- 這會互動
    -- vim.fn.system(cmd) -- 這需要等待結束
    vim.fn.jobstart(cmd) -- 非同步作業
  end,
  {
    desc = "Use the specified font file for the specified document (require: fc-list)",
    nargs = "+",
    complete = function(arg_lead, cmd_line)
      local comps, argc, prefix, suffix = utils.cmd.init_complete(arg_lead, cmd_line)
      local exist_comps = argc > 1 and utils.cmd.get_exist_comps(cmd_line) or {}
      local need_add_prefix = true
      if not arg_lead:match('=') then
        comps = vim.tbl_filter(
          function(item) return not exist_comps[item] end,
          {
            'familyname=',
            'src=',
            'fontpath=', -- foot只能是安裝的字型，只吃familyname
            'size=',
            'line_height=',
          }
        )
        need_add_prefix = false
      elseif prefix == "familyname" then
        comps = {}
        for _, familyname in pairs(get_font_map()) do
          table.insert(comps, familyname)
        end
      elseif prefix == "src" then
        comps = {
          vim.fn.expand("%"),
          unpack(vim.fn.getcompletion(arg_lead, "file"))
        }
      elseif prefix == "fontpath" then
        comps = {}
        -- 只能是已安裝的路徑
        -- local opentype_extensions = { "%.ttf$", "%.otf$", "%.ttc$", "%.woff$", "%.woff2$" }
        -- local all_files = vim.fn.getcompletion(vim.fn.expand(arg_lead), "file")
        -- comps = {}
        -- for _, file in ipairs(all_files) do
        --   for _, ext in ipairs(opentype_extensions) do
        --     if string.lower(file):match(ext) or
        --         vim.fn.isdirectory(file) == 1 -- 目錄 (要是真實存在的目錄才會是1)
        --     then
        --       table.insert(comps, file)
        --       break
        --     end
        --   end
        -- end

        for fontpath, _ in pairs(get_font_map()) do
          table.insert(comps, fontpath)
        end
      elseif prefix == "size" then
        comps = {
          12,
          24,
          48,
          96,
        }
      elseif prefix == "line_height" then
        comps = {
          24,
          48,
        }
      end
      if need_add_prefix then
        for i, comp in ipairs(comps) do
          comps[i] = prefix .. "=" .. comp
        end
      end
      local input = need_add_prefix and prefix .. "=" .. suffix or arg_lead
      return vim.tbl_filter(function(item) return item:match(input) end, comps)
    end
  }
)
vim.api.nvim_create_user_command("LmsChat", function(args)
    -- 首版: `git log -1 -p 4dd0a674 | pbcopy`

    local config = utils.cmd.get_cmp_config(args.fargs)
    local mode = config.mode or "append"
    local model = config.model
    if not model then
      vim.api.nvim_echo({
        { "❌ `model` not found\n", "Normal" },
        { ":Lms model=", "@label" },
      }, true, {})
      return
    end

    local lines = utils.range.get_selected_text()
    local content = table.concat(lines, "\n")
    -- local result = "aaa\nbbb\nccdasdf" -- debug時可用
    local result = utils.lmstudio.chat(model, content, {
      -- attachments = config["attachments"],
      port  = config.port or "1234",
      debug = config.debug == "1"
    })
    if not result then
      vim.notify("nil result", vim.log.levels.INFO)
      return
    end

    local result_table = {}

    if mode == "append" then
      -- 在前面多新增兩個空列方便區別
      result_table = {
        "", "",
        unpack(vim.split(result, "\n", { trimempty = false })) -- trimempty false 保留最後的空行
      }
    else
      result_table = vim.split(result, "\n", { trimempty = false })
    end

    -- vim.api.nvim_buf_set_lines(0, 0, -1, true, vim.split(result, "\n")) -- 整份文件重寫

    -- local cur_line = vim.api.nvim_win_get_cursor(0)[1]
    -- vim.api.nvim_buf_set_lines(0, cur_line - 1, cur_line - 1, false, result_table) -- 在當前行的上方插入結果

    -- 取得選取區域的行號（1‑index）
    local start_line = vim.fn.line("'<") -- 起始行號
    local end_line   = vim.fn.line("'>") -- 結束行號（包含）

    -- 把 1‑index 轉成 0‑index
    start_line       = start_line - 1

    -- 如果是反向選取（上往下 vs 下往上），要交換
    if start_line > end_line then
      start_line, end_line = end_line, start_line
    end

    if config.mode == "replace" then
      vim.api.nvim_buf_set_lines(0, start_line, end_line, false, result_table)
    else -- append
      -- Tip: nvim_put 有個缺點，如果是選取多列，put的結果會放在中間, 可以先用 nvim_win_set_cursor 移動到想追加的地方再使用`nvim_put`即可
      vim.api.nvim_win_set_cursor(0, { end_line, 0 })

      -- vim.api.nvim_put(result_table, "l", false, true) -- after: false等同P, true: p ; 最後follow, 為true時會將游標放到文本後
      -- vim.api.nvim_put(result_table, "b", true, true) -- b可以用在區塊選取(C-V時用)
      vim.api.nvim_put(result_table, "l", true, true) -- 輸出放在尋問的下方
    end
  end,
  {
    desc = "與在本機啟動的lmstudio服務器互動",
    nargs = "+",
    range = true,
    complete = function(arg_lead, cmd_line)
      local comps, argc, prefix, suffix = utils.cmd.init_complete(arg_lead, cmd_line)
      local exist_comps = argc > 1 and utils.cmd.get_exist_comps(cmd_line) or {}
      -- exist_comps["attachments="] = nil -- 此項允許重複輸入

      local need_add_prefix = true
      if not arg_lead:match('=') then
        comps = vim.tbl_filter(
          function(item) return not exist_comps[item] end,
          {
            'model=',
            'mode=',

            -- 'attachments=',

            'port=',
            'debug=',
          }
        )
        need_add_prefix = false
      elseif prefix == "model" then
        comps = {
          "openai/gpt-oss-20b",
          "qwen/qwen3-vl-8b",
        }
      elseif prefix == "mode" then
        comps = {
          "append", -- default
          "replace",
        }
      elseif prefix == "port" then
        comps = { "1234" }
      elseif prefix == "debug" then
        comps = { "1" }
        -- elseif prefix == "attachments" then
        --   -- 只列出檔案(只有一層)，忽略資料夾
        --   comps = vim.fn.globpath(".", "*", false, true)
      end
      if need_add_prefix then
        for i, comp in ipairs(comps) do
          comps[i] = prefix .. "=" .. comp
        end
      end
      local input = need_add_prefix and prefix .. "=" .. suffix or arg_lead
      return vim.tbl_filter(function(item) return item:match(input) end, comps)
    end
  }
)

vim.api.nvim_create_user_command("CsvToMarkdownTable", function(args)
  local config = utils.cmd.get_cmp_config(args.fargs)
  local sep = config.sep or "\t"
  local clipboard_content
  local after = true
  if args.range ~= 0 then
    clipboard_content = table.concat(utils.range.get_selected_text(), "\n")
    after = false -- 直接置換range的內容, 等同P
  else
    clipboard_content = vim.fn.getreg("+")
  end

  local markdown_tbl = {}
  local split_by_newline_pattern = "[^\n]+"
  local match_text_between_bars_pattern = "[^|]+"

  local is_header = true
  for line in clipboard_content:gmatch(split_by_newline_pattern) do
    line = string.format("| %s |", line:gsub(sep, " | "))
    markdown_tbl[#markdown_tbl + 1] = line
    if is_header then
      local separator = line:gsub(match_text_between_bars_pattern, "---")
      markdown_tbl[#markdown_tbl + 1] = separator
      is_header = false
    end
  end
  vim.api.nvim_put(markdown_tbl, "l", after, true)
end, {
  desc = "Convert csv to markdown table",
  range = true,
  nargs = "?",
  complete = function(_, cmd_line)
    local argc = #(vim.split(cmd_line, "%s+")) - 1
    print(argc)
    if argc == 1 then
      return {
        "sep=\t",
        "sep=,",
      }
    end
  end
})

vim.api.nvim_create_user_command('Qfa',
  function(args)
    if args.fargs[1] == "-h" then
      cmdUtils.showHelpAtQuickFix({
        [[:'<,'>g/\vya?ml/Qfa]],
        [[:'<,'>g/\v\~.*ya?ml/Qfa]],
        [[:'A,'Bg/\vya?ml/Qfa -h]],
        [[:10,100g/key/caddexpr expand("%") . ":" . line(".") . ":" . getline(".")]], -- 可行，但是後面要打上太多東西
        [[/\%V]],                                                                     -- 這可以找, 但是沒辦法加到qflist
      })
      return
    end
    local bufnr = vim.api.nvim_get_current_buf()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local text = vim.api.nvim_get_current_line()

    -- 先清沒有用，因為用 :'<,'>g/key/Qfa 實際上會一個匹配項都執行一次此函數, 因此每次都會清除, 如此只會剩下最下一筆而已
    -- if args.fargs[1] == "-c" then
    --   -- vim.cmd("cexpr []")
    --   vim.fn.setqflist({}, 'f') -- 用這個也是不行
    -- end

    vim.fn.setqflist({ {
      bufnr = bufnr,
      lnum = lnum,
      text = text,
    } }, 'a')

    -- vim.cmd("copen") -- Warn: 這種情況下使用這個會中斷，導致最後只有一筆
  end, {
    desc = "Can be used for :g//Qfa to add the result to qflist",
    nargs = "?",
    range = true,
    complete = function()
      return {
        "-h",
      }
    end
  })

-- print(vim.inspect(get_font_map()))

return commands
