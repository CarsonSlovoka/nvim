local keymaps = {}

local exec = require("utils.exec")

local function setup_normal()
  -- 複製文件的絕對路徑
  vim.keymap.set('n', -- normal mode
    '<leader>cwd',
    ':let @+=expand("%:p")<CR>', -- % 表示當前的文件名, :p (轉成絕對路徑)
    { noremap = true, silent = true }
  )
end

local function setup_visual()
  -- 將所有內容複製到剪貼簿
  vim.keymap.set('v', -- Visual 模式
    '<leader>c', -- 快捷鍵為 <leader>c
    '"+y', -- 將選中的內容複製到系統剪貼板
    { noremap = true, silent = true }
  )

  vim.keymap.set('x',
    '<leader><F5>',
  -- [[:lua ExecuteSelection()<CR>]],
    function()
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true) -- 先離開visual模式，否則它會認為是在visual中運作，這會等到esc之後才會動作，導致你可能認為要按第二次才會觸發
      vim.schedule(exec.ExecuteSelection) -- 並且使用 schedule 確保在模式更新後執行
    end,
    { noremap = true, silent = true, desc="執行選中項目"}
  )

  -- 將工作目錄更改為當前檔案的目錄
  vim.keymap.set("n", "<leader>cd", function()
    local current_file = vim.fn.expand("%:p:h") -- 獲取當前檔案的目錄
    if current_file == "" then
      print("未打開任何檔案")
      return
    end
    vim.cmd("cd " .. current_file) -- 使用 ':cd' 命令切換目錄
    print("工作目錄已切換到: " .. current_file)

    -- 如果 nvim-tree 已加載，更新其根目錄
    local ok, nvim_treeAPI = pcall(require, "nvim-tree.api")
    if ok then
      nvim_treeAPI.tree.change_root(current_file) -- 更新 nvim-tree 的根目錄
      print("nvim-tree 根目錄已更新到: " .. current_file)
    else
      print("nvim-tree 未加載")
    end
  end, { desc = "切換到檔案目錄" })
end

function keymaps.setup()
  setup_normal()
  setup_visual()
end

return keymaps
