local M = {
  win = nil,
  buf = nil,
  height = 5,
  border = "rounded" -- :help winborder
}

M.DEFAULT_REGISTER = [["0123456789]] ..
    [[abcdefghijklmnopqrstuvwxyz]] ..
    [["*+-.:/=%#]] -- help :registers

M.registers = M.DEFAULT_REGISTER

local ns_id_hl = vim.api.nvim_create_namespace('register_spy_highlight') -- Creates a new namespace or gets an existing one.

function M.setup_register_window()
  local buf = vim.api.nvim_create_buf(false, true)                      -- 非檔案緩衝區，可寫
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })     -- 關閉視窗時自動清除
  vim.api.nvim_set_option_value('filetype', 'registers', { buf = buf }) -- 自定義 filetype

  -- 設置視窗選項
  local height = vim.api.nvim_win_get_height(0)
  local width = vim.api.nvim_win_get_width(0)
  -- local col = vim.api.nvim_get_option_value('columns', { scope = "local", win = vim.api.nvim_get_current_win() }) -- ❌
  -- local col = vim.api.nvim_get_option_value('columns', { scope = "local" }) -- 這不準, 它不是抓win，是抓buf

  -- 獲取當前窗口在編輯器中的位置
  local win_pos = vim.api.nvim_win_get_position(vim.api.nvim_get_current_win())
  local row = win_pos[1] -- 當前窗口的起始行
  local col = win_pos[2] -- 當前窗口的起始列
  row = row + height - M.height
  if M.border and M.border ~= "none" and M.border ~= "" then
    row = row - 2 -- 最下方的2列一個是lua line的狀態，另一個是-- INSERT -- 模式的觀看
  end
  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'editor',
    width = width,
    height = M.height,
    -- col, row 是指從什麼地方開始畫
    col = col,
    row = row,               -- 如果border不為none時應該要考量最下方的2列: lua line status; MODE: -- INSERT --
    style = 'minimal',
    border = M.border,       -- :help winborder
    title = "registers_spy", -- 僅在有border時才會出來
    title_pos = "center",
  })

  vim.api.nvim_set_option_value('winhl', 'Normal:NormalFloat', { win = win })
  vim.api.nvim_set_option_value('wrap', false, { win = win }) -- 禁用自動換行
  -- vim.api.nvim_win_set_config(win, { focusable = false })  -- 不可聚焦. 因為很太多暫儲器，所以需要移動才能檢視

  vim.fn.clearmatches(win)
  vim.api.nvim_set_hl(ns_id_hl, "HL_NUMBER", { bg = "#00FFFF", fg = "#000000" })
  vim.api.nvim_set_hl(ns_id_hl, "HL_LETTER", { bg = "#55FF55", fg = "#000000" })
  vim.api.nvim_set_hl(ns_id_hl, "HL_SPECIAL", { bg = "#FFFF55", fg = "#000000" })
  vim.api.nvim_set_hl(ns_id_hl, "FloatBorder", { fg = "#ff00ff" }) -- :help FloatBorder
  vim.fn.matchadd("HL_NUMBER", [[^\d]], 10, -1, { window = win })
  vim.fn.matchadd("HL_LETTER", '^[a-z]', 10, -1, { window = win })
  vim.fn.matchadd("HL_SPECIAL", '^["*+-.:/=%#]', 10, -1, { window = win })
  vim.api.nvim_win_set_hl_ns(win, ns_id_hl)

  return buf, win
end

-- 更新寄存器內容
function M.update_registers(buf)
  local lines = {}
  for i = 1, #M.registers do
    local reg = M.registers:sub(i, i)
    local content = vim.fn.getreg(reg) or ''
    content = content:gsub('\n', '\\n')
    table.insert(lines, reg .. ': ' .. content)
  end

  -- 更新緩衝區內容
  vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
end

-- 初始化並定時更新
function M.init()
  local buf, win = M.setup_register_window()

  M.update_registers(buf)

  local timer = vim.loop.new_timer()
  local start_after_ms = 1000
  local repeat_per_ms = 1000
  timer:start(start_after_ms, repeat_per_ms, vim.schedule_wrap(
    function()
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_win_is_valid(win) then
        M.update_registers(buf)
      else
        timer:stop()
      end
    end
  ))

  return buf, win
end

function M.toggle()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    M.height = vim.api.nvim_win_get_height(M.win) -- 保存使用者最後的設定
    vim.api.nvim_win_close(M.win, true)
    M.win = nil
    M.buf = nil
  else
    M.buf, M.win = M.init()
  end
end

return M
