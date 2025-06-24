local M = {}

--- 依據名稱來查找該buffer是否存在，如果存在則返回該buffer id
---@param bufname string 包含目錄名稱 vim.fn.getcwd() .. "/" .. vim.fn.expand("%:t")
---@return boolean
---@return number|nil buffer
function M.get_buf(bufname)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(buf) == bufname then
      return true, buf
    end
  end
  return false, nil
end

return M
