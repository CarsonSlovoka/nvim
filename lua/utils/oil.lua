local M = {}
function M.get_cursor_path()
  -- print(vim.inspect(require("oil").get_cursor_entry()))
  local entry = require("oil").get_cursor_entry()
  if not entry then
    return nil, "no entry under cursor"
  end
  if entry.type ~= "file" and entry.type ~= "directory" then
    return nil, ("not a regular file or directory (type = %s)"):format(entry.type)
  end
  local dir = require("oil").get_current_dir()
  if not dir then
    return nil, "cannot get current oil directory"
  end
  -- oil.get_current_dir() 回傳的路徑已帶尾端 /
  return dir .. entry.name
end

return M
