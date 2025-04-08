local M = {}

--- @return number ms 毫秒
function M.it(fn)
  local s_t = vim.loop.hrtime()
  fn()
  local e_t = vim.loop.hrtime()
  return (e_t - s_t) / 1e6
end

return M
