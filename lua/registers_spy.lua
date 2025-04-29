local M = {}

-- 創建側邊視窗
function M.setup_register_window()
  -- 創建緩衝區
  local buf = vim.api.nvim_create_buf(false, true)                      -- 非檔案緩衝區，可寫
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })     -- 關閉視窗時自動清除
  -- vim.api.nvim_set_option_value('filetype', 'yaml', { buf = buf })  -- 用yaml可以突顯 x: 不過還是自己定義會比較好
  vim.api.nvim_set_option_value('filetype', 'registers', { buf = buf }) -- 自定義 filetype

  -- 設置視窗選項
  local width = 30 -- 側邊視窗寬度
  local height = vim.api.nvim_get_option_value('lines', { scope = "global" }) - 2
  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'editor',
    width = width,
    height = height,
    col = vim.api.nvim_get_option_value('columns', { scope = "global" }) - width - 1, -- 靠右側
    row = 1,
    style = 'minimal',
    border = 'single',
  })

  -- 設置視窗為不可聚焦
  -- vim.api.nvim_win_set_option(win, 'winhl', 'Normal:NormalFloat')  Use nvim_set_option_value() instead
  -- :h winhl
  vim.api.nvim_set_option_value('winhl', 'Normal:NormalFloat', { win = win })
  vim.api.nvim_set_option_value('wrap', false, { win = win }) -- 禁用自動換行
  -- vim.api.nvim_win_set_config(win, { focusable = false })     -- 不可聚焦

  return buf, win
end

-- 更新寄存器內容
function M.update_registers(buf)
  local registers = {
    '"', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', -- 數字寄存器
    'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',      -- 字母寄存器
    '*', '+', '-', '.', ':', '%', '/', '=', '#'            -- 特殊寄存器
  }
  local lines = {}
  for _, reg in ipairs(registers) do
    local content = vim.fn.getreg(reg) or ''
    -- 限制每行長度，避免太長
    if #content > 50 then
      content = string.sub(content, 1, 47) .. '...'
    end
    -- 替換換行符，確保單行顯示
    content = content:gsub('\n', '\\n')
    table.insert(lines, reg .. ': ' .. content)
  end

  -- 更新緩衝區內容
  vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })

  -- 清除舊的語法高亮
  vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)

  -- 動態應用高亮
  for i, reg in ipairs(registers) do
    local highlight_group
    if reg:match('%d') or reg == '"' then
      highlight_group = 'RegisterNumber'
    elseif reg:match('%a') then
      highlight_group = 'RegisterLetter'
    else
      highlight_group = 'RegisterSpecial'
    end
    -- vim.api.nvim_buf_add_highlight(buf, -1, highlight_group, i - 1, 0, 1) -- deprecated
    local ns_id = vim.api.nvim_create_namespace('register_spy_highlight') -- Creates a new namespace or gets an existing one.
    vim.api.nvim_buf_set_extmark(buf, ns_id, i - 1, 0, { end_col = 1, hl_group = highlight_group })
  end

  -- 設置語法高亮組
  vim.api.nvim_set_hl(0, "RegisterNumber", { bg = "#00FFFF", fg = "#000000" })
  vim.api.nvim_set_hl(0, "RegisterLetter", { bg = "#55FF55", fg = "#000000" })
  vim.api.nvim_set_hl(0, "RegisterSpecial", { bg = "#FFFF55", fg = "#000000" })
end

-- 初始化並定時更新
function M.init()
  local buf, win = M.setup_register_window()
  M.update_registers(buf)

  -- 定時器，每秒更新一次
  local timer = vim.loop.new_timer()
  timer:start(
    1000,              -- 啟動延遲 timeout
    1000,              -- 重複間隔 repeat
    vim.schedule_wrap( -- 不會有負擔，如果不需要時只需要用toggle將窗口關閉此計時器也會停止
      function()
        if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_win_is_valid(win) then
          M.update_registers(buf)
        else
          timer:stop()
        end
      end
    )
  )

  -- 當離開 Neovim 時關閉視窗
  vim.api.nvim_create_autocmd('VimLeave', {
    callback = function()
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end,
  })

  return buf, win
end

-- 切換視窗顯示(若窗口不存在會重新建立)
function M.toggle()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
    M.win = nil
    M.buf = nil
  else
    M.buf, M.win = M.init()
  end
end

return M
