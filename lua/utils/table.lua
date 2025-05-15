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

return M
