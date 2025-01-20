local keymaps = {}

local exec = require("utils.exec")
local map = require("utils.keymap").keymap
-- 如果有key已經被設定，有模糊的情況，會需要等待，如果不想要等待，可以按完之後隨便再按下一個不相關的鍵(ESC, space,...)使其快速反應


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
end

local function setup_visual()
  map('v',       -- Visual 模式
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
