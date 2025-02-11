local M = {}

--- 將多個array整合成一個新的array
--- @param ... table[]|number[] 待合併的陣列集合
--- @return table 合併後的新陣列
function M.Merge(...)
  local result = {}
  for _, array in ipairs({ ... }) do
    for _, value in ipairs(array) do
      table.insert(result, value)
    end
  end
  return result
end

return M
