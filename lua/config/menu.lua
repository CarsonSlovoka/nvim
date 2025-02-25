-- 有關於此腳本，可以參考
-- 最初版本: https://github.com/CarsonSlovoka/nvim/commit/9bdaf874f83edcf08ea3ba379275dfdf0f5ac09e
-- 次版: https://github.com/CarsonSlovoka/nvim/blob/0a262fd1da23497e0ab65bd43dda1ecff2aada7c/lua/config/menu.lua

local M = {}

-- 新增函數：讀取圖片文本文件
local function read_lines(file_path)
  local file = io.open(file_path, "r")
  if not file then
    vim.notify("無法讀取圖片文件: " .. file_path, vim.log.levels.WARN)
    return nil
  end
  local lines = {}
  for line in file:lines() do
    table.insert(lines, line)
  end
  file:close()
  return lines
end


local ASCII_ART_TXT = [[
                      _   ____________ _    ________  ___
                     / | / / ____/ __ \ |  / /  _/  |/  /
                    /  |/ / __/ / / / / | / // // /|_/ /
                   / /|  / /___/ /_/ /| |/ // // /  / /
                  /_/ |_/_____/\____/ |___/___/_/  /_/
   _________    ____  _____ ____  _   __   ___________ _______   ________
  / ____/   |  / __ \/ ___// __ \/ | / /  /_  __/ ___// ____/ | / / ____/
 / /   / /| | / /_/ /\__ \/ / / /  |/ /    / /  \__ \/ __/ /  |/ / / __
/ /___/ ___ |/ _, _/___/ / /_/ / /|  /    / /  ___/ / /___/ /|  / /_/ /
\____/_/  |_/_/ |_|/____/\____/_/ |_/    /_/  /____/_____/_/ |_/\____/
]]

local function startup_time(start_time)
  if start_time == 0 then
    return "<na>"
  end
  local end_time = vim.loop.hrtime()
  local time_ms = (end_time - start_time) / 1e6 -- 轉為毫秒
  return tostring(time_ms)
end

function M.setup(opts)
  opts = opts or {
    start_time = 0,
  }

  -- 檢查是否為啟動時的空 buffer (即沒有文件或參數)
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


  -- 讀取圖片文本文件
  -- Text to ASCII Art Generator: https://patorjk.com/
  -- https://patorjk.com/software/taag/#p=display&h=2&v=1&f=Slant&t=%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20NEOVIM%0ACARSON%20TSENG
  -- -- 不想在準備文件，直接將txt的內容當成字串處理即可
  -- local image_lines = read_lines(vim.fn.expand("~/.config/nvim/menu_icon.txt")) or { -- 讀不到可以用預設文字
  --   "NEOVIM",
  --   "CARSON"
  -- }
  -- local ascii_art_title = {}
  -- for _, line in ipairs(image_lines) do
  --   table.insert(ascii_art_title, { { text = line, highlight = "StartupTitle" } })
  -- end

  local ascii_art_title = {}
  local ascii_art_title_max_col_length = 0
  for line in ASCII_ART_TXT:gmatch("[^\n]+") do
    table.insert(ascii_art_title, { { text = line, highlight = "StartupTitle" } })
    if #line > ascii_art_title_max_col_length then
      ascii_art_title_max_col_length = #line
    end
  end

  -- 定義要顯示的內容（模擬你的畫面）
  local content = {
    { { text = "", highlight = nil } },

    {
      { text = ":q",      highlight = "StartupMenu" },
      { text = "<Enter>", highlight = "Comment" },
      { text = " [Quit]", highlight = "StartupInfo" }
    },
    {
      { text = ",bk",                highlight = "StartupMenu" },
      { text = "   [open bookmark]", highlight = "StartupInfo" }
    },
    {
      { text = ",t",                  highlight = "StartupMenu" },
      { text = "    [nvimTree open]", highlight = "StartupInfo" }
    },
    {
      { text = ",cd",             highlight = "StartupMenu" },
      { text = "   [change dir]", highlight = "StartupInfo" } },

    { { text = "", highlight = nil } },

    {
      { text = "Neovim startup time: ",       highlight = nil },
      { text = startup_time(opts.start_time), highlight = "StartupInfo" },
      { text = " ms",                         highlight = nil },
    },

    { { text = "", highlight = nil } },

    {
      { text = ":h",      highlight = "StartupMenu" },
      { text = "<Enter>", highlight = "Comment" },
      { text = " [Help]", highlight = "StartupInfo" }
    },
    {
      { text = ":help news",     highlight = "StartupMenu" },
      { text = "<Enter>",        highlight = "Comment" },
      { text = " [see changes]", highlight = "StartupInfo" }
    },
    {
      { text = ":checkhealth",        highlight = "StartupMenu" },
      { text = "<Enter>",             highlight = "Comment" },
      { text = " [to optimize Nvim]", highlight = "StartupInfo" }
    },

    { { text = "", highlight = nil } },

    {
      { text = "  Nvim is open source and freely distributable", highlight = nil }
    },
    {
      { text = "gx",                        highlight = "StartupCmd" },
      { text = "  https://neovim.io/#chat", highlight = "StartupInfo" }
    },

    { { text = "", highlight = nil } },

    {
      { text = "請幫助烏干達孩童", highlight = nil },
      { text = ":help iccf", highlight = "StartupMenu" },
      { text = "<Enter>", highlight = "Comment" },
    },
    {
      { text = "gx",                          highlight = "StartupCmd" },
      { text = "  https://iccf-holland.org/", highlight = "StartupInfo" }
    }
  }

  for i = #ascii_art_title, 1, -1 do
    table.insert(content, 1, ascii_art_title[i]) -- 從頭開始插入
  end

  -- 計算需要添加的空行數以實現垂直居中
  local content_height = #content
  local padding_top = math.floor((win_height - content_height) / 2)

  -- 創建帶有上 padding 的新行列表，並實現水平居中
  local centered_lines = {}
  local highlight_positions = {}     -- Store {line_num, start_col, end_col, highlight} for each segment
  local padding_lefts = {}           -- 儲存每行的 padding_left 以供高亮使用
  for i = 1, padding_top do
    table.insert(centered_lines, "") -- 添加空行到頂部
  end

  for n_row, row in ipairs(content) do
    local full_line = ""
    local row_highlights = {}
    local cur_col = 0

    -- 處理每一列，將每一個segments合併
    for _, segment in ipairs(row) do
      full_line = full_line .. segment.text
      if segment.highlight then
        table.insert(row_highlights, {
          start_col = cur_col,
          end_col = cur_col + #segment.text,
          highlight = segment.highlight,
        })
      end
      cur_col = cur_col + #segment.text
    end

    -- 計算每行需要添加的左邊空格數以實現水平居中
    local line_length = #full_line -- 假設所有字符寬度相同（簡單計算）

    local padding_left = 0
    if n_row > #ascii_art_title then
      padding_left = math.floor((win_width - line_length) / 2)
    else
      padding_left = math.floor((win_width - ascii_art_title_max_col_length) / 2) -- 標題因為是用Text to ASCII Art的方式，所以每一個字母的位置都很重要，要整體來統一標準，而非每列各至置中
    end

    table.insert(padding_lefts, padding_left) -- 儲存每個 padding_left
    local padded_line = string.rep(" ", padding_left) .. full_line
    table.insert(centered_lines, padded_line)

    -- Adjust highlight positions with padding_left
    for _, hl in ipairs(row_highlights) do
      table.insert(highlight_positions, {
        line_num = padding_top + n_row - 1,
        start_col = padding_left + hl.start_col,
        end_col = padding_left + hl.end_col,
        highlight = hl.highlight,
      })
    end
  end

  -- 將文字寫入 buffer
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, centered_lines)


  -- 添加高亮（模擬顏色）
  -- 定義高亮組
  vim.api.nvim_set_hl(0, "StartupTitle", { fg = "#00FFFF", bold = true }) -- 藍色標題
  vim.api.nvim_set_hl(0, "StartupMenu", { fg = "#00FF00" })               -- 綠色菜單
  vim.api.nvim_set_hl(0, "StartupCmd", { fg = "#00FF00" })
  vim.api.nvim_set_hl(0, "StartupInfo", { fg = "#FFA500" })               -- 橙色資訊

  -- 應用高亮到特定行（調整為新的行號，使用對應的 padding_left）
  local base_line = padding_top -- 基於 padding 計算行號

  --[[ 這太麻煩，改用結構化數據驅動來呈現
vim.api.nvim_buf_add_highlight(buf, 0, "StartupTitle", base_line + 0, padding_lefts[1] + 4, -1)  -- "NEOVIM"
vim.api.nvim_buf_add_highlight(buf, 0, "StartupTitle", base_line + 1, padding_lefts[2] + 4, -1)  -- "Carson"
-- ...
vim.api.nvim_buf_add_highlight(buf, 0, "StartupInfo", base_line + 13, padding_lefts[14] + 2, -1) -- "Neovim loaded..."
vim.api.nvim_buf_add_highlight(buf, 0, "StartupInfo", base_line + 14, padding_lefts[15] + 2, -1) -- "Nvim is open source..."
--]]


  -- 應用高亮
  for _, hl in ipairs(highlight_positions) do
    vim.api.nvim_buf_add_highlight(buf, 0, hl.highlight, hl.line_num, hl.start_col, hl.end_col)
  end

  -- 設置 buffer 為不可編輯（只讀）
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

return M
