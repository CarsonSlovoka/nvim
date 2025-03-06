local keymaps = {}

local exec = require("utils.exec")
local map = require("utils.keymap").keymap
-- 如果有key已經被設定，有模糊的情況，會需要等待，如果不想要等待，可以按完之後隨便再按下一個不相關的鍵(ESC, space,...)使其快速反應


-- 系統剪貼簿相關
map("n", "<leader>y", '"+y', { desc = "複製到系統剪貼簿" })
map("v", "<leader>y", '"+y', { desc = "複製到系統剪貼簿" })
map("n", "<leader>Y", '"+Y', { desc = "複製到系統剪貼簿" })

map("n", "<leader>d", '"+d', { desc = "剪下的內容也會保留在系統剪貼簿" })
map("v", "<leader>d", '"+d', { desc = "剪下的內容也會保留在系統剪貼簿" })
map("n", "<leader>D", '"+D', { desc = "剪下的內容也會保留在系統剪貼簿" })

map("n", "<leader>ql", function()
  -- local current_qf_idx = vim.fn.getqflist({ id = 0, idx = 1 }).idx -- 這個得到的都是1
  local cur_title = vim.fn.getqflist({ id = 0, title = 1 }).title

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
end, { desc = "List all quickfix lists" })

local function setup_normal()
  map('n',                       -- normal mode
    '<leader>cwd',
    ':let @+=expand("%:p")<CR>', -- % 表示當前的文件名, :p (轉成絕對路徑)
    { desc = "複製文件的絕對路徑" }
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
      vim.notify("格式化結束", vim.log.levels.INFO)
    end,
    { desc = "格式化代碼" }
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
  map('t', "<Esc>", "<C-\\><C-n>", { desc = "在terminal下可以離開該模式. 方便接下來選取內容或離開..." })
  map('t', "<C-R>", function()
      -- vim.fn.getchar() -- 等待用戶輸入
      -- vim.fn.nr2char -- 轉換為字符
      return (                                      -- 要將 expr 設定為true才會有用
        "<C-\\><C-N>" ..                            -- 退回到一般模式
        "\"" .. vim.fn.nr2char(vim.fn.getchar()) .. -- 使用暫存器
        "pi"                                        -- 貼上 並且 再切換成insert的模式
      )
    end,
    {
      expr = true, -- 用按鍵方式的回傳，一定要將expr設定為true才會有效
      desc = "可以使用<C-R>來使用暫儲器的內容",
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

  for open, close in pairs({
    ["("] = ")",
    ["["] = "]",
    ["{"] = "}",
    ['"'] = '"',
    ["`"] = "`",
  }) do
    map('i', open,
      open .. close .. "<Left>", -- 輸入配對的括號並往左移動到中間，方便輸入括號內的內容
      { desc = "自動補全" .. open }
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
  map('v', -- Visual 模式
    '<leader>c', -- 快捷鍵為 <leader>c
    '"+y',
    { desc = "將選中的內容複製到系統剪貼板" }
  )

  map('v', 'find', '""y/<C-R>"<CR>', -- 先將選中的內容保存到""內，之後在用搜尋去找該項目
    { desc = "搜尋當前選中的項目" })

  map('x',
    '<leader><F5>',
    -- [[:lua ExecuteSelection()<CR>]],
    function()
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true) -- 先離開visual模式，否則它會認為是在visual中運作，這會等到esc之後才會動作，導致你可能認為要按第二次才會觸發
      vim.schedule(exec.ExecuteSelection)                                                          -- 並且使用 schedule 確保在模式更新後執行
    end,
    { desc = "執行選中項目" }
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

  map('v', '<leader>r', 'y:%s/<C-R>"//gc<Left><Left><Left>',
    { desc = "取代 如果是特定範圍可以改成 :66,100s/old/new/gc (觸發後請直接打上要取代的文字就會看到有command出來了" }
  )
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
