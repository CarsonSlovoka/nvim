-- 檢查是否為啟動時的空 buffer（即沒有文件或參數）
if vim.fn.argc() ~= 0 then
  return
end

-- 創建一個新的 buffer
vim.api.nvim_command("enew") -- 開啟一個新 buffer
local buf = vim.api.nvim_get_current_buf()

vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

-- 獲取終端窗口的高度和寬度
local win_height = vim.api.nvim_win_get_height(0)
local win_width = vim.api.nvim_win_get_width(0)

-- 定義要顯示的內容（模擬你的畫面）
local lines = {
  "    NEOVIM",
  "    CARSON",
  "",
  "  q [New File]",
  "  n [New File]",
  "  r [Recent Files]",
  "  f [Find Text]",
  "  c [config]",
  "  s [Restore Session]",
  "  l [Lazy Extras]",
  "  x [Lazy]",
  "  q [Quit]",
  "",
  "  Neovim loaded 24/79 plugins in 60.12ms",
  "  Nvim is open source and freely distributable: https://neovim.io/#chat",
}

-- 計算需要添加的空行數以實現垂直居中
local content_height = #lines
local padding_top = math.floor((win_height - content_height) / 2)

-- 創建帶有上 padding 的新行列表，並實現水平居中
local centered_lines = {}
local padding_lefts = {}           -- 儲存每行的 padding_left 以供高亮使用
for i = 1, padding_top do
  table.insert(centered_lines, "") -- 添加空行到頂部
end
for _, line in ipairs(lines) do
  -- 計算每行需要添加的左邊空格數以實現水平居中
  local line_length = #line                 -- 假設所有字符寬度相同（簡單計算）
  local padding_left = math.floor((win_width - line_length) / 2)
  table.insert(padding_lefts, padding_left) -- 儲存每個 padding_left
  local padded_line = string.rep(" ", padding_left) .. line
  table.insert(centered_lines, padded_line)
end

-- 將文字寫入 buffer
vim.api.nvim_buf_set_lines(buf, 0, -1, false, centered_lines)


-- 添加高亮（模擬顏色）
-- 定義高亮組
vim.api.nvim_set_hl(0, "StartupTitle", { fg = "#00FFFF", bold = true }) -- 藍色標題
vim.api.nvim_set_hl(0, "StartupMenu", { fg = "#00FF00" })               -- 綠色菜單
vim.api.nvim_set_hl(0, "StartupInfo", { fg = "#FFA500" })               -- 橙色資訊

-- 應用高亮到特定行（調整為新的行號，使用對應的 padding_left）
local base_line = padding_top -- 基於 padding 計算行號

-- 確保 padding_lefts 的索引與 lines 對應
vim.api.nvim_buf_add_highlight(buf, 0, "StartupTitle", base_line + 0, padding_lefts[1] + 4, -1)                     -- "NEOVIM"
vim.api.nvim_buf_add_highlight(buf, 0, "StartupTitle", base_line + 1, padding_lefts[2] + 4, -1)                     -- "Carson"
vim.api.nvim_buf_add_highlight(buf, 0, "StartupMenu", base_line + 3, padding_lefts[4] + 2, padding_lefts[4] + 3)    -- "q"
vim.api.nvim_buf_add_highlight(buf, 0, "StartupMenu", base_line + 4, padding_lefts[5] + 2, padding_lefts[5] + 3)    -- "n"
vim.api.nvim_buf_add_highlight(buf, 0, "StartupMenu", base_line + 5, padding_lefts[6] + 2, padding_lefts[6] + 3)    -- "r"
vim.api.nvim_buf_add_highlight(buf, 0, "StartupMenu", base_line + 6, padding_lefts[7] + 2, padding_lefts[7] + 3)    -- "f"
vim.api.nvim_buf_add_highlight(buf, 0, "StartupMenu", base_line + 7, padding_lefts[8] + 2, padding_lefts[8] + 3)    -- "c"
vim.api.nvim_buf_add_highlight(buf, 0, "StartupMenu", base_line + 8, padding_lefts[9] + 2, padding_lefts[9] + 3)    -- "s"
vim.api.nvim_buf_add_highlight(buf, 0, "StartupMenu", base_line + 9, padding_lefts[10] + 2, padding_lefts[10] + 3)  -- "l"
vim.api.nvim_buf_add_highlight(buf, 0, "StartupMenu", base_line + 10, padding_lefts[11] + 2, padding_lefts[11] + 3) -- "x"
vim.api.nvim_buf_add_highlight(buf, 0, "StartupMenu", base_line + 11, padding_lefts[12] + 2, padding_lefts[12] + 3) -- "q"
vim.api.nvim_buf_add_highlight(buf, 0, "StartupInfo", base_line + 13, padding_lefts[14] + 2, -1)                    -- "Neovim loaded..."
vim.api.nvim_buf_add_highlight(buf, 0, "StartupInfo", base_line + 14, padding_lefts[15] + 2, -1)                    -- "Nvim is open source..."

-- 設置 buffer 為不可編輯（只讀）
vim.api.nvim_buf_set_option(buf, "modifiable", false)
