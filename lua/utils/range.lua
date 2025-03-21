local M = {}

function M.get_selected_text()
  local mode = vim.fn.mode()

  local start_pos
  local end_pos
  if mode == 'v' or mode == 'V' then
    -- 以下是在keymap的清況下，'<, '>會是前一次的結果
    -- vim.api.nvim_input("<ESC>") -- 這種清況下，就算先嘗試離開，此時的getpos("'<")也還是之前的結果
    start_pos = vim.fn.getpos("v") -- 視覺模式的起點
    end_pos = vim.fn.getpos(".")   -- 當前光標的位置當作終點
  else
    -- 如果是command所觸發，'<與'>都是目前的結果
    start_pos = vim.fn.getpos("'<") -- 抓取之前選取的起點
    end_pos = vim.fn.getpos("'>")
  end

  local line1, col1 = start_pos[2], start_pos[3]
  local line2, col2 = end_pos[2], end_pos[3]
  local lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
  if #lines == 0 then
    return
  end

  -- 同列
  if line1 == line2 then
    return string.sub(lines[1], col1, col2)
  end

  -- return table.concat(lines, '')

  local l1 = string.sub(lines[1], col1)    -- col1的位置是有包含的, col2省略會取到結束
  local l2 = string.sub(lines[1], 1, col2) -- sub可以0或1開始都行, 往後取col2個

  -- 二列
  if line2 - line1 == 1 then
    return l1 .. l2
  end

  -- 兩列以上
  local all = { l1, unpack(lines, 2, #lines - 1), l2 }
  -- return table.concat(all, "\n")
  return table.concat(all, "")
end

return M
