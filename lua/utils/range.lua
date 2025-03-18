local M = {}

function M.get_selected_text()
  local mode = vim.fn.mode()

  local start_pos
  local end_pos
  if mode == 'v' or mode == 'V' then
    -- vim.api.nvim_input("<ESC>") -- 這種清況下，就算先嘗試離開，此時的getpos("'<")也還是之前的結果
    start_pos = vim.fn.getpos("v")  -- 視覺模式的起點
    end_pos = vim.fn.getpos(".")    -- 當前光標的位置當作終點
  else
    start_pos = vim.fn.getpos("'<") -- 抓取之前選取的起點
    end_pos = vim.fn.getpos("'>")
  end

  local line1, col1 = start_pos[2], start_pos[3]
  local line2, col2 = end_pos[2], end_pos[3]
  local lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
  if #lines == 0 then
    return
  end
  local selected_text = table.concat(lines, '')
  if line1 == line2 then
    selected_text = string.sub(lines[1], col1, col2)
  end
  return selected_text
end

return M
