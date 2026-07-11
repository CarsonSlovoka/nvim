vim.pack.add({ "https://github.com/nvim-tree/nvim-tree.lua" })
local m = require("nvim-tree")

--[[
  USAGE:

  :NvimTreeOpen

  g?
  ]] --
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

m.setup({
  sort = {
    sorter = "case_sensitive",
  },
  view = {
    width = 30,
  },
  renderer = {
    -- highlight_opened_files = "name", -- :help highlight_opened_files
    group_empty = true,
    -- :lua print("➜➜"") # 可以print這些試試，如果是亂碼，就是字型沒有提供，要安裝，並且改終端機的字型即可
    icons = { -- (可選)
      glyphs = {
        default = "", -- 預設找不到項目的圖標
        symlink = "",
        git = {
          unstaged = "",
          staged = "S",
          unmerged = "",
          renamed = "➜",
          deleted = "",
          untracked = "U", -- 自定前綴，定成U表示這個項目還沒有被git添加
        },
        folder = { -- 這些是預設，如果不喜歡，也可以自己改成喜歡的emoji
          default = "", -- 📁
          open = "📂", -- 
          empty = "",
          empty_open = "",
          symlink = "",
        },
      },
    },
  },
  filters = {
    dotfiles = true, -- 如果想要看到.開頭的檔案或目錄{.git/, .gitignore, .gitmodules, ...}，要設定成false
  },
})
-- vim.keymap.set("n", "<leader>t", ":NvimTreeOpen<CR>", { desc = "Open NvimTree" }) -- 可以先將TreeOpen到指定的位置，再用telescope去搜
vim.keymap.set("n", "<leader>t", ":NvimTreeToggle<CR>", { desc = "toggle NvimTree" })

vim.keymap.set("n", "<A-t>", function()
    local cur_file_path = vim.fn.expand("%:p")
    -- 也可以考慮用 <C-W>T  把目前視窗「搬」到新 tab (原本視窗會消失)
    vim.cmd("tabnew " .. cur_file_path) -- 會保留原本視窗，新 tab 顯示相同 buffer
  end,
  { desc = "在新的頁籤開啟當前的文件" }
)
