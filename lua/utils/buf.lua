local M = {}

--- NOTE: <C-W>v 分割視窗或者編輯，效果都還是有
--- 缺點是如此的設計，每一列的顏色只能有一個
---
--- @param buf integer vim.api.nvim_get_current_buf()
--- @param lnum integer vim.api.nvim_buf_line_count(buf)
--- @param msgs table  {{'line1', '@label'}, {'line2', 'ERROR'}}
function M.appendbufline(buf, lnum, msgs)
  local ns_id_hl = vim.api.nvim_create_namespace('carson.buffer.help') -- Creates a new namespace or gets an existing one.
  for i, msg in ipairs(msgs) do
    local text, hl_group = msg[1], msg[2]

    vim.fn.appendbufline(buf, lnum, text)
    vim.api.nvim_buf_set_extmark(buf, ns_id_hl, lnum, 0, { end_col = #text, hl_group = hl_group }) -- 💡
    lnum = lnum + 1
  end
end

return M
