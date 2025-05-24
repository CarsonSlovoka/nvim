local M = {
  win = nil,
  buf = nil,
  width = 30,       -- 側邊視窗寬度
  _focus_width = 30 -- 切換到該win時的畫面寬度
}

local HL_REG_NUMBER = "RegisterNumber"
local HL_REG_LETTER = "RegisterLetter"
local HL_REG_SPECIAL = "RegisterSpecial"

vim.api.nvim_set_hl(0, HL_REG_NUMBER, { bg = "#00FFFF", fg = "#000000" })
vim.api.nvim_set_hl(0, HL_REG_LETTER, { bg = "#55FF55", fg = "#000000" })
vim.api.nvim_set_hl(0, HL_REG_SPECIAL, { bg = "#FFFF55", fg = "#000000" })

local ns_id_hl = vim.api.nvim_create_namespace('register_spy_highlight') -- Creates a new namespace or gets an existing one.


local group = vim.api.nvim_create_augroup("registers_spy", { clear = false }) -- 不需要clear, 如果真得有重覆，就和該group一樣即可
vim.api.nvim_create_autocmd('WinEnter', {
  desc = "讓registers_spy的視窗寬度變大",
  callback = function(_)
    if M.win and vim.api.nvim_buf_is_valid(M.buf) and vim.api.nvim_get_current_win() == M.win then
      vim.api.nvim_win_set_width(M.win, M._focus_width)
    end
  end,
  group = group,
  -- once = true,
})


vim.api.nvim_create_autocmd('WinLeave', {
  desc = "讓registers_spy的視窗恢復正常大小",
  callback = function(_)
    if M.win and vim.api.nvim_buf_is_valid(M.buf) then
      print(M.width)
      vim.api.nvim_win_set_width(M.win, M.width)
    end
  end,
  group = group,
})

-- 創建側邊視窗
function M.setup_register_window()
  -- 創建緩衝區
  local buf = vim.api.nvim_create_buf(false, true)                      -- 非檔案緩衝區，可寫
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })     -- 關閉視窗時自動清除
  -- vim.api.nvim_set_option_value('filetype', 'yaml', { buf = buf })  -- 用yaml可以突顯 x: 不過還是自己定義會比較好
  vim.api.nvim_set_option_value('filetype', 'registers', { buf = buf }) -- 自定義 filetype

  -- 設置視窗選項
  local height = vim.api.nvim_get_option_value('lines', { scope = "global" }) - 2
  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'editor',
    width = M.width,
    height = height,
    col = vim.api.nvim_get_option_value('columns', { scope = "global" }) - M.width - 1, -- 靠右側
    row = 1,
    style = 'minimal',
    border = 'single',
    title = "registers_spy",
    title_pos = "center",
  })

  -- 設置視窗為不可聚焦
  -- vim.api.nvim_win_set_option(win, 'winhl', 'Normal:NormalFloat')  Use nvim_set_option_value() instead
  -- :h winhl
  -- :h NormalFloat
  vim.api.nvim_set_option_value('winhl', 'Normal:NormalFloat', { win = win })
  vim.api.nvim_set_option_value('wrap', false, { win = win }) -- 禁用自動換行
  -- vim.api.nvim_win_set_config(win, { focusable = false })  -- 不可聚焦. 因為很太多暫儲器，所以需要移動才能檢視

  return buf, win
end

-- 更新寄存器內容
function M.update_registers(buf)
  local registers = [["0123456789]] ..
      [[abcdefghijklmnopqrstuvwxyz]] ..
      [["*+-.:/=%#]] -- help :registers
  -- "_ 是黑泂暫存器，例如: "_d 預設而言d的操作會保存在""和"_中，此時用"_來操作不會影響到其它暫存器的內容
  -- 因此"_是一個不可讀到任何東西的暫存器，顯示它沒有意義

  local lines = {}
  for i = 1, #registers do
    local reg = registers:sub(i, i)
    local content = vim.fn.getreg(reg) or ''
    -- 限制每行長度，避免太長 (太長也無所謂)
    -- if #content > 50 then
    --   content = string.sub(content, 1, 47) .. '...'
    -- end
    -- 替換換行符，確保單行顯示
    content = content:gsub('\n', '\\n')
    table.insert(lines, reg .. ': ' .. content)
  end

  -- 更新緩衝區內容
  vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })

  -- set highlight (需要等待文本設定完成，如此set_extmark才不會超出range)
  -- 清除舊的語法高亮
  -- vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)       -- 全清其實也不會怎樣，但還是只清自定義的就好
  vim.api.nvim_buf_clear_namespace(buf, ns_id_hl, 0, -1)
  for i = 1, #registers do
    local reg = registers:sub(i, i)
    -- set highlight
    local highlight_group
    if reg:match('%d') or reg == '"' then
      highlight_group = HL_REG_NUMBER
    elseif reg:match('%a') then
      highlight_group = HL_REG_LETTER
    else
      highlight_group = HL_REG_SPECIAL
    end
    -- vim.api.nvim_buf_add_highlight(buf, -1, highlight_group, i - 1, 0, 1) -- deprecated
    -- local ns_id = vim.api.nvim_create_namespace('register_spy_highlight') -- Creates a new namespace or gets an existing one.
    vim.api.nvim_buf_set_extmark(buf, ns_id_hl, i - 1, 0, { end_col = 1, hl_group = highlight_group })
  end
end

-- 初始化並定時更新
function M.init()
  local create_time = os.date("%Y%m%d_%H%M%S")
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

  -- 不太需要在退出nvim時再動作(反正都要關了)，而且有呼叫vim.api.nvim_win_close時，就有處理了，它就會讓nvim_buf_is_valid變為false
  -- 且如果寫在這邊，每次init則都會增加一個VimLeave的事件
  -- vim.api.nvim_create_autocmd('VimLeave', { -- 整個退出neovim
  --   callback = function()
  --     -- print(create_time)
  --     -- vim.fn.confirm("debug", "&Yes\n&No", 2)
  --     if vim.api.nvim_buf_is_valid(buf) then
  --       vim.api.nvim_buf_delete(buf, { force = true })
  --     end
  --   end,
  -- })

  return buf, win
end

-- 切換視窗顯示(若窗口不存在會重新建立)
function M.toggle()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
    M.win = nil
    M.buf = nil
    M._focus_width = M.width
  else
    M._focus_width = vim.api.nvim_win_get_width(0) -- 以建立此視窗前的該win寬度為主
    M.buf, M.win = M.init()
  end
end

return M
