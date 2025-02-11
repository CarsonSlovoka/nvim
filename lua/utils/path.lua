local M = {}

function M.join(...)
  local parts = { ... } -- 將參數放到table中
  local path = table.concat(parts, "/")

  -- 移除多餘的斜線 (連續兩個或以上的斜線替換為一個)
  path = path:gsub("/+", "/")
  return path
end

return M
