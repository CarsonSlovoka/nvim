local M = {}

function M.sort_files_first(tbl)
  table.sort(tbl, function(a, b) -- true a在前面
    -- 使用 vim.fn.isdirectory 檢查是否為資料夾（1 表示資料夾，0 表示檔案）
    -- local a_is_dir = vim.fn.isdirectory(vim.fn.expand(a)) == 1 -- expand用這邊不好，如果需要請在tbl新增
    local a_is_dir = vim.fn.isdirectory(a) == 1
    local b_is_dir = vim.fn.isdirectory(b) == 1

    -- a file, b dir => a first
    if not a_is_dir and b_is_dir then
      return true

      -- a dir, b file => b first
    elseif a_is_dir and not b_is_dir then
      return false
    else
      -- a, b both {dir, file} => sort by alphabet
      return a < b
    end
  end)

  return tbl
end

--- contains({"ico", "png"}, "svg") -- false
---
--- 如果想元素很多且要頻繁的使用，可以用字典的方法會比較有效，參考: `get_mapping_table`
---
---@param t table
---@param elem any
function M.contains(t, elem)
  for _, e in ipairs(t) do
    if e == elem then
      return true
    end
  end
  return false
end

--- local m = get_mapping_table({"ico", "png"})
--- m["svg"] -- nil
--- m["png"] -- true
---
---@param t table
---@return {string:boolean}[]
function M.get_mapping_table(t)
  local map = {}
  for _, key in ipairs(t) do
    map[key] = true
  end
  return map
end

return M
