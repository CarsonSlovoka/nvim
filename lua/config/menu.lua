local M = {}

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

  -- 定義要顯示的內容（模擬你的畫面）
  local content = {
    { { text = "NEOVIM", highlight = "StartupTitle" } },
    { { text = "CARSON", highlight = "StartupTitle" } },

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
    local line_length = #full_line            -- 假設所有字符寬度相同（簡單計算）
    local padding_left = math.floor((win_width - line_length) / 2)
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
