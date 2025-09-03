local M = {}

-- 獲取當前 Lua 檔案的目錄
local cur_file = debug.getinfo(1, "S").source:sub(2)
local CUR_DIR = vim.fn.fnamemodify(cur_file, ":h")
print(CUR_DIR)


---
--- usage: print(require("py").read_script("hello.py"))
---
---@param script_name string
---@return string content
---@return string? errmsg
function M.read_script(script_name)
  local script_abspath = vim.fn.fnamemodify(CUR_DIR .. "/" .. "py" .. "/" .. script_name, ":p")

  local file = io.open(script_abspath, "r")
  if not file then
    return "", "Failed to open file: " .. script_abspath
  end
  local content = file:read("*a")
  file:close()
  return content
end

return M
