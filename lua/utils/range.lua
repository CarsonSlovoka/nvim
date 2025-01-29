local M = {}

function M.get_selected_text()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
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
