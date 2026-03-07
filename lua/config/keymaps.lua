local keymaps = {}

local utils = require("utils.utils")
local exec = require("utils.exec")
local map = require("utils.keymap").keymap
-- 如果有key已經被設定，有模糊的情況，會需要等待，如果不想要等待，可以按完之後隨便再按下一個不相關的鍵(ESC, space,...)使其快速反應

---@param label string char
local function set_mark(label)
  local group = require("config.sign_define").group
  local sign_id = vim.api.nvim_create_namespace(group .. "_" .. label)
  local line = vim.api.nvim_win_get_cursor(0)[1]
  -- 清除該 mark 的舊 sign
  vim.fn.sign_unplace(group, { buffer = vim.fn.bufnr(), id = sign_id })

  -- 放置新 sign
  vim.fn.sign_place(sign_id, group, "MarkPin" .. label, vim.fn.bufnr(), { lnum = line })
end

map({ "n", "v" }, "<leader>/", ':noh<CR>', { desc = ":nohlsearch" })

-- 系統剪貼簿相關
map({ "n", "v" }, "<leader>y", '"+y', { desc = "Copy to system clipboard" })
map({ "v" }, "<leader>+y", function()
    -- https://stackoverflow.com/a/6303919/9935654
    -- :help :let.=
    vim.cmd([[normal! ""y]]) -- 先複製選取的內容
    vim.cmd([[let @+ .= @"]])
  end,
  { desc = "Append selected content to the system clipboard" }
)
map({ "v" }, "<leader>+Y", function()
    vim.cmd([[normal! ""y]])
    -- vim.cmd([[let @+ .= @" .. '\n']]) -- 這不行
    vim.cmd([[let @+ .= @" . "\n"]])
  end,
  { desc = "Append selected content + \n to the system clipboard" }
)
map({ "n", "v" }, "<leader>d", '"+d', { desc = "The cut content will also be retained in the system clipboard" })

-- map("i", "<C-h>", '<C-o>b', { desc = "<C-Left>" }) -- 用C-o的效果不好
map({ "i", "v" }, "<C-h>", '<C-Left>', { desc = "<C-Left>" })
map({ "i", "v" }, "<C-l>", '<C-Right>', { desc = "<C-Right>" })

-- map("i", "<C-S-h>", '<Left>', { desc = "move left" })
map("i", "<A-h>", '<Left>', { desc = "move left" })
map("i", "<A-j>", '<Down>', { desc = "move down" })
map("i", "<A-k>", '<Up>', { desc = "move up" }) -- 避免和C-K digraphs 重複到
map("i", "<A-l>", '<Right>', { desc = "move right" })

map("t", "<leader><leader>c",
  function() vim.cmd("Clear") end, -- git log -1 65a8fba -L3491,+11:commands.lua
  { desc = "Clears the terminal's screen and can no longer use scrollback to find the previous input", }
)

-- map("n", "/", 'ms/')
map("n", "/",
  function()
    set_mark("s")
    return "ms/"
  end,
  {
    desc = "在搜尋前，先在目前的位置mark s再進行搜尋",
    expr = true
  }
)

-- map("n", "?", 'ms?')
map("n", "?",
  function()
    set_mark("s")
    return "ms?"
  end,
  {
    desc = "在搜尋前，先在目前的位置mark s再進行搜尋",
    expr = true
  }
)

-- map("n", "<leader>.", ':<Up><CR>', { desc = "重複上一個命令" }) -- 這樣可行
map("n", "<leader>,", '@:', { desc = "Repeat last command-line" }) -- 其實原本就有這個命令了 `:help @:` 先執行一次執令之後，再用@@也可以再次執行上一個指令

map("n", "<leader><leader>t",
  function() vim.cmd("cd %:h | sp | term") end,
  { desc = "cd %:h | sp | term" } -- 類似於:Term
)
map("n", "<leader>git",
  function()
    if vim.fn.executable("lazygit") == 0 then
      vim.notify("lazygit not found. go install github.com/jesseduffield/lazygit@latest", vim.log.levels.WARN)
      return
    end
    -- vim.cmd("cd %:h | tabnew | setlocal buftype=nofile | term lazygit") -- 可行，但是lazygit退出後也不能繼續使用terminal, 並且這樣的方式不是insert是在normal

    vim.cmd("cd %:h") -- 先切換到當前該檔案的目錄

    -- 找出它的git根目錄
    local git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
    if vim.v.shell_error ~= 0 then
      vim.notify("Not in a Git repository", vim.log.levels.ERROR)
      return
    end

    local git_dirname = vim.fs.basename(vim.fn.fnamemodify(git_root, ":r")) -- :r對vim.fn.expand能有效，而對vim.fn.fnamemodify就還需要basename的幫忙

    vim.cmd(string.format("cd %s | tabnew | setlocal buftype=nofile | term", git_root))
    vim.cmd("file git:" .. git_dirname)
    vim.cmd("startinsert")
    vim.api.nvim_input("echo 'git branch --unset-upstream'<CR>") -- 新增一些可能會用到的提示
    vim.api.nvim_input("lazygit --screen-mode half<CR>")
  end,
  { desc = "cd %:h | tabnew | setlocal buftype=nofile | term lazygit -sm half" }
)

map("n", "<leader>ql", function()
  -- local current_qf_idx = vim.fn.getqflist({ id = 0, idx = 1 }).idx -- 這個得到的都是1
  -- local cur_title = vim.fn.getqflist({ id = 0, title = 1 }).title

  -- 這要遍歷才可以
  -- local cur_idx -- 用來儲存當前 qflist 的絕對索引
  -- -- 先找到當前 qflist 的絕對索引
  -- local total_nr = vim.fn.getqflist({ nr = '$' }).nr
  -- for i = 1, total_nr do
  --   local qf_list = vim.fn.getqflist({ id = i, title = 1 })
  --   if qf_list.title == cur_title then
  --     cur_idx = i
  --     break
  --   end
  --   if not qf_list.title or qf_list.title == "" then
  --     break
  --   end
  -- end


  print("=== Quickfix Lists ===")
  ---- i = 1 -- vim.fn.getqflist id如果是0, 或者idx為0都表示當前所在的qflist
  ---- while true do
  -- for i = 1, total_nr do -- 由於idx沒辦法推算，所以改寫法，但還是保留舊的參考
  --   -- local qf_list = vim.fn.getqflist({ id = i, items = 1, title = 1 }) -- ❗🧙 id會自動給的，如果用-f清空之後，再去新增，id是接續之前的去給，所以要用idx
  --   local qf_list = vim.fn.getqflist({ idx = i, items = 1, title = 1 }) -- 如果後面的title沒有用1，那麼取的項目就不會抓title，後面的此數值就是空的
  --   -- print("debug", vim.inspect(qf_list))
  --   local qf_title = qf_list.title
  --   local item_count = #qf_list.items
  --   local relative_pos = cur_idx and (i - cur_idx) or i -- 可以方便曉得要用:3colder, :2newer 之類的
  --   local is_current = (qf_title == cur_title) and " 👈 current" or ""
  --   if item_count > 0 then
  --     print(string.format("qflist %2d: %s | %d items%s",
  --       relative_pos, qf_list.title, item_count, is_current
  --     ))
  --   elseif qf_title and qf_title ~= "" then
  --     print(string.format("qflist %2d: %s | %d empty%s",
  --       relative_pos, qf_list.title, item_count, is_current
  --     ))
  --   end
  -- end

  local cur_nr = vim.fn.getqflist({ id = 0, all = 1 }).nr -- 最後還要再換回去原本的qflist
  local total_nr = vim.fn.getqflist({ nr = '$' }).nr

  -- 先切換到最舊的版本
  local count_corder = 0 -- 表示調用了幾次到頂端
  while pcall(vim.cmd, "colder") do
    count_corder = count_corder + 1
    -- 持續執行直到失敗（到達最舊版本）
  end

  local msg_list = {}               -- 由於是透過:cnewer來切換，中間都會有提示訊息，為了避免影響，統一在最後寫入
  local relative_pos = count_corder -- 可以方便曉得要用:3colder, :2newer 之類的
  local cur_found = false
  while true do
    -- local qf = vim.fn.getqflist({ id = 0, idx = 1, items = 1, title = 1 }) -- 這個是錯誤，這樣idx就是1，沒用
    local qf = vim.fn.getqflist({ id = 0, items = 1, title = 1 })
    local qf_title = qf.title
    local item_count = #qf.items

    local is_current = (relative_pos == 0) and " 👈 current" or ""
    if #is_current > 0 then
      cur_found = true
    end

    if item_count > 0 then
      table.insert(msg_list, { string.format("%2d: %s | %d items%s\n",
        relative_pos, qf_title, item_count, is_current
      ), "Normal" })
    elseif qf_title and qf_title ~= "" then
      table.insert(msg_list, { string.format("%2d: %s | %d empty%s\n",
        relative_pos, qf_title, item_count, is_current
      ), "Normal" })
    end

    -- 嘗試切換到更新的版本
    local status, _ = pcall(vim.cmd, "cnewer")
    -- 如果無法再切換，退出
    if not status then
      break
    end

    if not cur_found then
      relative_pos = relative_pos - 1
    else
      relative_pos = relative_pos + 1
    end
  end

  -- for _, line in ipairs(lines) do
  --   vim.api.nvim_echo({{line, "Normal"}}, true, {})
  -- end
  vim.api.nvim_echo(msg_list, false, {})

  if total_nr - cur_nr > 0 then
    pcall(vim.cmd, "colder " .. total_nr - cur_nr)
  end
end, { desc = "List all quickfix lists. 類似於內建的 :chistory" })

for i = 0, 9 do
  map("n", "<leader>fl" .. i, function()
    vim.o.foldlevel = i
  end, {
    desc = ":set foldlevel=" .. i,
  }
  )
  map("n", "<leader>fc" .. i, function()
      vim.o.foldcolumn = tostring(i)
    end,
    {
      desc = ":set foldcolumn=" .. i,
    }
  )
end

-- local strRegs = '0123456789+"*' -- 沒有辦法透過這樣的方式來更改+的內容
local strRegs = '0123456789'
for i = 1, #strRegs do
  local c = strRegs:sub(i, i)
  -- 書籤相關
  map('n', "<leader>by" .. c,
    function()
      local filepath = vim.fn.expand('%:p') -- 完整路徑
      local line = vim.fn.line('.')         -- 當前行號
      local col = vim.fn.col('.')           -- 當前列號
      -- local location = string.format("%s:%d:%d", filepath, line, col) -- 如果用: 在windows會被磁碟名稱影響
      local location = string.format("%s|%d|%d", filepath, line, col)
      vim.fn.setreg(tostring(c), location)
      vim.fn.setreg('"', location) -- 也複製到暫存器"
    end,
    {
      desc = "複製當前的位置到剪貼簿"
    }
  )
  map('v', "<leader>by" .. c,
    function()
      local selected_text = table.concat(utils.range.get_selected_text(), " ")
      local text = selected_text
      local filepath = vim.fn.expand('%:p')
      local line = vim.fn.line('.')
      local col = vim.fn.col('.')
      local location = string.format("%s|%d|%d", filepath, line, col)
      local full_text = location .. " | " .. text
      vim.fn.setreg(tostring(c), full_text)
      vim.fn.setreg('"', full_text)
      vim.api.nvim_input("<ESC>") -- 協助離開visaul模式
    end,
    {
      desc = "複製當前的位置到剪貼簿, 並且用目前選取的內容來當成描述"
    }
  )
end

map({ 'n', 'v' }, '<leader>gf',
  function()
    local mode = vim.fn.mode()

    local selected_text = ""
    if mode == "n" then
      -- 記住當前光標位置
      local original_pos = vim.api.nvim_win_get_cursor(0)

      -- 移動到單詞開頭 (B) 和單詞結尾 (E)，提取範圍內的文字
      local start_col = vim.fn.col('.')
      if tonumber(start_col) ~= 1 then -- 如果是1，就不需要再使用B，這樣反而會跑到上一列去
        vim.cmd("normal! B")           -- 移動到單詞開頭
        start_col = vim.fn.col('.')
      end
      vim.cmd("normal! E") -- 移動到單詞結尾
      local end_col = vim.fn.col('.')

      -- 取得完單詞頭尾後就可以恢復原始光標位置
      vim.api.nvim_win_set_cursor(0, original_pos)

      local line = vim.api.nvim_get_current_line()
      selected_text = line:sub(start_col, end_col)
      -- selected_text = selected_text:gsub("[:|]+$", "") -- ../home/app.h:137: -- 避免有:或者|在最後面而產生干擾,  不過 home/app.h:137中文, 這種情況還是會有問題
    else
      -- 如果是用lazygit自定義輸出格式，也可以用選取的方式來跳轉到指定的地方
      -- print("mode is v or V")
      selected_text = utils.range.get_selected_text()[1]
    end

    -- local path, lnum, col = line:match("([^:]+):(%d+):(%d+)")
    -- local path, lnum, col = selected_text:match("([^|]+)[|:](%d+)[|:](%d+)") -- 讓|, :都可以當成分隔符，但是我想讓col可以不是必需的，所以用更複雜的方式寫

    local path, lnum, col = nil, nil, nil
    local patterns = {
      -- { "^(.-):(%d+):(%d+)$", 3 }, -- "../../home/app.h:20:5" -- 數字不一定要在最後面，因此不需要$，不然 `home/app.h:137中文` 這樣會抓不到
      -- { "^(.-):(%d+)$",       2 }, -- "../../home/app.h:20"
      -- { "^(.-)|(%d+)|(%d+)$", 3 }, -- "../../home/app.h|20|5"
      -- { "^(.-)|(%d+)$",       2 }, -- "../../home/app.h|20"
      { "^(.-):(%d+):(%d+)", 3 }, -- "../../home/app.h:20:5"
      { "^(.-):(%d+)", 2 },       -- "../../home/app.h:20"
      { "^(.-)|(%d+)|(%d+)", 3 }, -- "../../home/app.h|20|5"
      { "^(.-)|(%d+)", 2 },       -- "../../home/app.h|20"
      { "^(.-)$", 1 }             -- "../../home/app.h" -- 處理只有路徑而沒有列行號, 只實這種情況可以用內鍵的gf也行
    }
    for _, pattern_info in ipairs(patterns) do
      local pattern, num_captures = pattern_info[1], pattern_info[2]
      local captures = { string.match(selected_text, pattern) }

      if #captures > 0 then
        if num_captures == 1 then
          path = captures[1]
        elseif num_captures == 2 then
          path = captures[1]
          lnum = tonumber(captures[2])
        elseif num_captures == 3 then
          path = captures[1]
          lnum = tonumber(captures[2])
          col = tonumber(captures[3])
        end
        break
      end
    end

    if path and vim.fn.filereadable(path) == 1 then
      -- vim.cmd("edit +" .. lnum .. " " .. path)
      vim.cmd("edit " .. path)
      if lnum then -- 如果沒有lnum，就不使用nvim_win_set_cursor，這是因為edit會自己記得上一次到此檔案的位置，因此應該會比安排到1, 1好
        vim.api.nvim_win_set_cursor(0, { tonumber(lnum), tonumber(col or 1) - 1 })
      end
    else
      vim.notify(string.format("無效的書籤格式或路徑不存在: %s\npath: %s\nlnum: %s\ncol: %s",
          selected_text, path, lnum, col),
        vim.log.levels.ERROR
      )
    end
  end,
  {
    desc = "rg --vimgrep時可以做跳轉 或 適用於<leader>byN的產物",
  }
)

map({ 'n', 'v' }, '<leader>gF', function()
    -- Note: gF 預設已經有定義, 和gf不同的是，它可以跳到指定的列(欄沒有)，例如: ./README.md:5:2   gf只會跳到該文字(會考慮最後一次的位置), 而gF會跳到第5行
    local git_path = vim.fs.root(0, '.git')
    if git_path then
      vim.cmd("cd " .. git_path)
    end
    return "gf"
  end,
  {
    desc = "Jump using the git directory as the working directory",
    expr = true,
  }
)

map({ 'n', 'v' }, 'gi',
  function()
    local exe = ""
    if vim.uv.os_uname().sysname == "Linux" then
      for _, cmd in ipairs({ "swayimg", "chafa" }) do
        if vim.fn.executable(cmd) == 1 then
          exe = cmd
          break
        end
      end

      if exe == "" then
        vim.notify("preview tool not found.\nsudo apt install swayimg\nor\nsudo apt install chafa", vim.log.levels.WARN)
        return
      end
    elseif vim.uv.os_uname().sysname == "Darwin" then
      exe = "open -a Preview"
    else
      vim.api.nvim_echo({
        { "❌ unsupport platform ", "Normal" },
        { vim.uv.os_uname().sysname, "@label" },
      }, false, {})
      return
    end

    vim.cmd("cd %:h")
    local mode = vim.fn.mode()
    local img_path = ""
    if mode == "n" then
      vim.cmd("normal! viby") -- 複製( )中的內容
      img_path = vim.fn.getreg('"')
    else
      img_path = utils.range.get_selected_text()[1]
      vim.api.nvim_input("<esc>")
    end
    if exe ~= "chafa" then
      -- ~/.config/swayimg/config 中可以設定預設的配置，例如: info.show=no, general.overlay=yes
      -- vim.cmd("!swayimg " .. img_path .. " & ")   -- 記得補上 & 使之後還可以繼續操作
      vim.fn.system(exe .. " " .. img_path .. " & ") -- 使用vim.fn.system不會有訊息 `Press Enter ot type command to continue` (因為它不互動) 因此回來之後可以少按下Enter
    else
      vim.cmd("Chafa " .. img_path)                  -- 這是自定義的 :Chafa 指令
    end
  end,
  {
    desc = "使用swayimg 或 chafa來檢視圖片(適用於foot所開啟的nvim中的終端機)",
  }
)

local function setup_normal()
  map('n', -- normal mode
    '<leader>Y',
    function()
      local abs_path = vim.fn.expand(("%:p"))
      local filename = vim.fn.expand(("%:t"))

      -- 定義選項
      local options = {
        abs_path,
        filename
      }
      local git_rel_path = vim.fn.systemlist("git ls-files --full-name " .. vim.fn.shellescape(abs_path))[1]
      if vim.v.shell_error == 0 then
        table.insert(options, git_rel_path)
      end

      vim.ui.select(options,
        {
          prompt = "Choose path format to copy:",
          format_item = function(item)
            local m = {
              [abs_path] = "Absolute Path: ",
              [filename] = "Filename: ",
            }
            if git_rel_path then
              m[git_rel_path] = "Git Relative Path: "
            end
            return m[item] and m[item] .. item or item
          end
        },
        function(choice)
          if not choice then
            return
          end

          vim.fn.setreg("+", choice)
          vim.api.nvim_echo({
            { "✅ Copied: ", "Normal" },
            { choice, "@label" },
          }, false, {})
        end
      )
      -- return ':let @+=expand("%:p")<CR>' -- % 表示當前的文件名, :p (轉成絕對路徑)
    end,
    {
      desc = "copy the filepath",
      -- expr = true,
    }
  )

  map({
      'n', -- 格式化整個內容
      'x', -- 整列的選取模式, 格式化選取行
    }, '<leader>fmt',
    function()
      vim.lsp.buf.format({
        -- async = false, -- 可以用異步，這樣還可以去處理別的事，但是所想要明確的等待完成
        timeout_ms = 3000,
        -- range -- 整列的選取模式，只會格式化選取的行
      })
      vim.notify(
        string.format("%s lsp.buf.format done ", os.date("%Y-%m-%d %H:%M:%S")),
        vim.log.levels.INFO
      )
      -- return "<Esc>" -- 結束visual -- 我用expr=true配合這個會錯，估計和裡面的函數實作也有關
      vim.api.nvim_input('<C-\\><C-n>') -- 強制回到 normal 模式
    end,
    -- 有可能該lsp服務器還沒有載入，就會導致抓不到而錯誤，如果沒有用:e只是單純的切換視窗會因為緩存的關係，還是會失敗，所以一定要用:e來重載即可
    {
      desc = "格式化代碼, 如果遇到 Format request failed, nomatching language servers. 請用:e來重新載入",
      -- expr = true,
    }
  )

  -- 以下可行，但用預設的會比較好
  -- map('n', "<C-w>>", ":vertical resize +20<CR>", {})
  -- map('n', "<C-w><", ":vertical resize -20<CR>", {})
  -- map('n', "", ":resize +20<CR>", {})
  -- map('n', "", ":resize -20<CR>", {})

  -- map('n', "<leader>xts", ":cd ~/xxx | sp | terminal<CR>i", { -- sp可以切成上下的分割
  map('n', "<leader>xts", ":sp | terminal<CR>i", { -- sp可以切成上下的分割
    desc = '進入之後i下可以開啟打命令; <C-\\><C-n>可以再變回normal模式，可以複製內容，也能再用v變成visual'
  })
  map('n', "<leader>xtv", ":vsp | terminal<CR>i", { desc = '垂直分割，並於開啟終端機. 可以透過nvim-tree換到指定的工作路徑後再使用此熱鍵' })
  -- map('t', "<Esc>", "<C-\\><C-n>", { desc = "在terminal下可以離開該模式. 方便接下來選取內容或離開..." })
  -- map('t', "<leader><Esc>", "<Esc>", { desc = "Same as normal Esc key" }) -- 真的Esc按鍵，有時候還是會需要. 請參考: https://vi.stackexchange.com/a/46981/31859
  map('t', "<C-R>", function()
      -- vim.fn.getchar() -- 等待用戶輸入
      -- vim.fn.nr2char -- 轉換為字符

      local key = vim.fn.nr2char(tonumber(vim.fn.getchar()) or 0)
      if key == '=' then
        local expression = vim.fn.input("=")
        return (
          "<C-\\><C-N>" ..
          -- "<C-R>=" .. expression .. "<CR>" .. -- 沒用
          ":pu=" .. expression .. "<CR>" ..
          "i" -- insert
        )
      end

      return (           -- 要將 expr 設定為true才會有用
        "<C-\\><C-N>" .. -- 退回到一般模式
        "\"" .. key ..   -- 使用暫存器, 例如: "a
        "pi"             -- 貼上 並且 再切換成insert的模式
      )
    end,
    {
      expr = true, -- 用按鍵方式的回傳，一定要將expr設定為true才會有效
      desc = "可以使用<C-R>來使用暫儲器的內容",
    }
  )
  map('t', "<C-K>", function()
      -- https://stackoverflow.com/a/79691125/9935654
      local ch1 = vim.fn.nr2char(tonumber(vim.fn.getchar()) or 0)
      local ch2 = vim.fn.nr2char(tonumber(vim.fn.getchar()) or 0)
      return "<C-\\><C-N>" ..
          string.format(":pu=digraph_get('%s%s')<CR>", ch1, ch2) ..
          "i"
    end,
    {
      expr = true,
      desc = "insert digraphs",
    }
  )
  map('n', "Q", ":q<CR>", {})

  -- <C-w>c -- 關閉當前窗口
  -- <C-w>o -- 關閉當前以外的窗口(頁籤窗口不算)
  map('n', "<A-w>", "<C-w>w", { desc = "輪循切換視窗" })
  map('n', "<A-h>", "<C-w>h", { desc = "往左切換視窗" })
  map('n', "<A-j>", "<C-w>j", { desc = "往下切換視窗" })
  map('n', "<A-k>", "<C-w>k", { desc = "往上切換視窗" })
  map('n', "<A-l>", "<C-w>l", { desc = "往右切換視窗" })


  -- :help wincmd
  -- map('n', "<M-H>", function() vim.cmd("wincmd H") end, { desc = "move window to left" })
  map('n', "<M-H>", "<C-W>H", { desc = "[←] Move the current window to be at the very left" }) -- 同步 :wincmd H
  map('n', "<M-J>", "<C-W>J", { desc = "[↓] Move the current window to be at the very bottom" })
  map('n', "<M-K>", "<C-W>K", { desc = "[↑] Move the current window to be at the very top" })
  map('n', "<M-L>", "<C-W>L", { desc = "[→] Move the current window to be at the very right" })


  local autoPair = true
  vim.api.nvim_create_user_command("SetAutoPair",
    function(args)
      autoPair = args.fargs[1] == "1"
      vim.notify("auto pair: " .. tostring(autoPair), vim.log.levels.INFO)
    end,
    {
      desc = [[auto pair ( ), [ ], { }, " ", ``]],
      nargs = 1,
      complete = function()
        return { "1", "0" }
      end
    }
  )
  for open, close in pairs({
    ["("] = ")",
    ["["] = "]",
    ["{"] = "}",
    ['"'] = '"',
    ["`"] = "`",
  }) do
    map('i', open,
      function()
        if not autoPair then
          return open
        end
        return open .. close .. "<Left>" -- 輸入配對的括號並往左移動到中間，方便輸入括號內的內容
      end,
      {
        desc = "自動補全" .. open,
        expr = true,
      }
    )
  end

  -- 🧙 `< 和 `> 是跳到選取範圍的開頭和結尾
  -- map('v', '<leader>"', '<Esc>`<i"<Esc>`>a"<Esc>') 這個會不對，因為先加上開頭的"之後，其實結尾的位置就變了，所以要先加結尾
  map('v', '<leader>"', '<Esc>`>a"<Esc>`<i"<Esc>', { desc = 'Wrap selection with double quotes " "' })
  map('n', '<leader>"', 'i"<Esc>ea"<Esc>', { desc = 'Wrap with double quotes " "' })

  map('v', "<leader>'", "<Esc>`>a'<Esc>`<i'<Esc>", { desc = "Wrap selection with single quotes ' '" })
  map('n', "<leader>'", "i'<Esc>ea'<Esc>", { desc = "Wrap with single quotes ' '" })

  map('v', '<leader>`', '<Esc>`>a`<Esc>`<i`<Esc>', { desc = "Wrap selection with backticks ` `" })
  map('n', '<leader>`', 'i`<Esc>ea`<Esc>', { desc = "Wrap with backticks ` `" })

  map('v', '<leader>(', '<Esc>`>a)<Esc>`<i(<Esc>', { desc = "Wrap selection with parentheses ( )" })
  map('n', '<leader>(', 'i(<Esc>ea)<Esc>', { desc = "Wrap with parentheses ( )" })

  map('v', '<leader>[', '<Esc>`>a]<Esc>`<i[<Esc>', { desc = "Wrap selection with square brackets [ ]" })
  map('n', '<leader>[', 'i[<Esc>ea]<Esc>', { desc = "Wrap with square brackets [ ]" })

  map('v', '<leader>{', '<Esc>`>a}<Esc>`<i{<Esc>', { desc = "Wrap selection with curly braces { }" })
  map('v', '<leader>{', '<Esc>`>a}<Esc>`<i{<Esc>', { desc = "Wrap with curly braces { }" })
end

local function setup_visual()
  -- :m '>+1 將當前選中的文本下移一行
  -- gv 重新高亮選中的區域(在 > 和 < 定義的範圍內)
  -- = 格式化文本
  map("v", "J", ":m '>+1<CR>gv=gv", { desc = "將當前選中的文本下移一行" }) -- 如果用了 [TextChanged](https://github.com/CarsonSlovoka/nvim/blob/14828d70377b26c72e4a4239a510200441b18720/lua/config/autocmd.lua#L21)會儲檔，這個可能會變得怪怪的
  map("v", "K", ":m '<-2<CR>gv=gv", { desc = "將當前選中的文本上移一行" })

  -- map('v', 'find', '""y/<C-R>"<CR>', -- 先將選中的內容保存到""內，之後在用搜尋去找該項目
  --   { desc = "搜尋當前選中的項目" }) -- 不需要此熱鍵，用*, # 都可以達到此效果, 只是沒有複製到剪貼簿而已


  map('x',
    '<leader><F17>', -- <leader><S-F5>
    -- [[:lua ExecuteSelection()<CR>]],
    function()
      local cmd = nil
      if utils.table.contains({ "dosini", "sh", "lua", "zsh" }, vim.bo.filetype) then
        -- 對於只要選取一列的情況下，忽略最前面的 `#` 方便執行註解的指令
        local selected_lines = utils.range.get_selected_text()
        if #selected_lines == 1 then
          cmd = table.concat(selected_lines, " ")
          cmd = string.gsub(cmd, "^%s*(.-)%s*$", "%1") -- 去除前後空白
          local first_char = string.sub(cmd, 1, 1)
          if first_char == "#" then
            cmd = string.sub(cmd, 2)
          end
        end
      end

      local org_wd = vim.fn.getcwd()
      vim.cmd("cd %:h")
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true) -- 先離開visual模式，否則它會認為是在visual中運作，這會等到esc之後才會動作，導致你可能認為要按第二次才會觸發
      -- vim.schedule(exec.ExecuteSelection)                                                          -- 並且使用 schedule 確保在模式更新後執行
      vim.schedule(function()
        exec.ExecuteSelection(cmd)
      end)
      vim.cmd("cd " .. org_wd)
    end,
    { desc = "執行選中項目" }
  )

  map('x', '<leader><F5>',
    function()
      local lines = utils.range.get_selected_text()

      local org_wd = vim.fn.getcwd()
      vim.cmd("cd %:h")

      vim.cmd('topleft new')
      vim.cmd("term")
      vim.cmd("startinsert")
      for i in ipairs(lines) do
        vim.api.nvim_input(lines[i] .. "<CR>")
      end

      vim.cmd("cd " .. org_wd)
    end,
    { desc = "Execute the selected item" }
  )

  -- 將工作目錄更改為當前檔案的目錄
  map("n", "<leader>cd", function()
    local cur_dir = vim.fn.expand("%:p:h")
    if cur_dir == "" then
      print("未打開任何檔案")
      return
    end
    vim.cmd("cd " .. cur_dir) -- 使用 ':cd' 命令切換目錄
    print("工作目錄已切換到: " .. cur_dir)

    -- 如果 nvim-tree 已加載，更新其根目錄
    local ok, nvim_treeAPI = pcall(require, "nvim-tree.api")
    if ok then
      nvim_treeAPI.tree.change_root(cur_dir) -- 更新 nvim-tree 的根目錄
      print("nvim-tree 根目錄已更新到: " .. cur_dir)
    else
      print("nvim-tree 未加載")
    end
  end, { desc = "切換到檔案目錄" })

  map("v", "<leader>cd",
    function()
      local cur_dir = table.concat(utils.range.get_selected_text(), "")
      local mode = vim.api.nvim_get_mode().mode
      if mode == "V" and vim.bo.buftype == 'terminal' then
        local pattern = ""
        if utils.os.IsWindows then
          pattern = '^(.-)>'         -- path>cmd
        else
          pattern = '^.-:([~/].-)%$' -- user:path$cmd
        end
        local match = string.match(cur_dir, pattern)
        if match then
          cur_dir = match
        end
      end
      vim.cmd("cd " .. cur_dir)
      print("工作目錄已切換到: " .. cur_dir)
      local ok, nvim_treeAPI = pcall(require, "nvim-tree.api")
      if ok then
        nvim_treeAPI.tree.change_root(cur_dir)
        print("nvim-tree 根目錄已更新到: " .. cur_dir)
      end
      return "<Esc>" -- 結束visual模式
    end,
    {
      desc = "cd '<,'>",
      expr = true,
    })

  -- 用處不大，移除，避免鍵位衝突
  -- map('v', '<leader>r', 'y:%s/<C-R>"//gc<Left><Left><Left>',
  --   { desc = "取代 如果是特定範圍可以改成 :66,100s/old/new/gc (觸發後請直接打上要取代的文字就會看到有command出來了" }
  -- )
end

local function setup_insert()
  map('v', 'p', '"_dP', {
    desc = '正常在visual下，於指定的反白處貼上內容後，下一次再貼的內容會是之前反白處的內容，為了避免如此讓其貼上的時候不要複製' }
  )
end

function keymaps.setup()
  setup_normal()
  setup_visual()
  setup_insert()
end

return keymaps
