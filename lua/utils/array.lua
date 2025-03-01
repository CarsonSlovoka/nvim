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

--- 在原table移除掉空的元素
--- @param t table
--- @example M.remove_empty_items({"a", nil, 1, nil, 2}) => { "a", 1, 2 }
function M.remove_empty_items(t)
  -- 從頭開始寫入非nil的元素(也就是前面的元素都非nil)
  local write_index = 1
  for read_index = 1, #t do
    if t[read_index] ~= nil and t[read_index] ~= "" then
      t[write_index] = t[read_index]
      write_index = write_index + 1
    end
  end
  -- 接著讓後面的元素都變成nil, 如此就移除多餘的項目了
  for i = write_index, #t do
    t[i] = nil
  end
end

return M
