local utils = {}
utils.table = require("utils.table")
local t     = require("testing.testing")

local function Example_sort_files_first()
  local myList = {
    "/path/to/file1.txt",
    "/path/to/folder1",
    "/path/to/file2.txt",
    "/path/to/folder2",
    -- vim.fn.expand("~/.config/nvim/init.lua"),
  }


  -- 重新排序
  utils.table.sort_files_first(myList)

  local pass = true
  local errs = { errors = {} }
  for i, item in ipairs({
    { myList[1], "/path/to/file3.txt" },
    { myList[2], "/path/to/file2.txt" },
    { myList[3], "/path/to/folder1" },
    { myList[4], "/path/to/folder2" },
  }) do
    local actual, expected = item[1], item[2]
    if actual ~= expected then
      pass = false
      table.insert(errs["errors"], string.format('❌ [%d] got: %s want: %s', i, actual, expected))
    end
  end

  if not pass then
    table.insert(errs.errors, vim.inspect(myList))
  end

  return pass or errs
end

-- 會用到vim.fn會需要runtime才行，所以不能直接用lua5.1來跑
-- 可以用 require("utils.table_test") 的方式來測試
t.RunTest({
  { fn = Example_sort_files_first, name = "Example_sort_files_first" },
}, arg[1])
