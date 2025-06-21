local M = {}

--- @return boolean
local function isWindows()
  if string.find(
        string.lower(vim.uv.os_uname().sysname), -- :help os_uname
        "windows"
      ) then
    return true
  end
  return false
end

--- 嘗試從HOME, userprofile等環境變數取得該文件路徑
--- windows下的nvim預設路徑為: %userprofile%\AppData\Local
--- :lua print(vim.fn.stdpath("config"))
--- 我不想要刻意調整它，不過像cargo這些預設的又會抓%userprofile%當底, 所以透過這種方法來自動抓能取道的項目
--- @return string
function M.GetPathFromHome(path)
  for _, homePath in ipairs({
    os.getenv("HOME"),
    os.getenv("userprofile"),
  }) do
    local fullPath = homePath .. path
    if vim.uv.fs_stat(fullPath) ~= nil then
      return fullPath
    end
  end
  return ""
end

--- @return string
function M.GetExePathFromHome(exePath)
  if M.IsWindows then
    exePath = exePath .. ".exe" -- 幫忙補上.exe
  end
  local p = M.GetPathFromHome(exePath)
  if p == "" then
    return ""
  end

  return p
end

--- @param cmd string
--- @param success_msg string
--- @param err_msg string
--- @return boolean
function M.execute_with_notify(cmd, success_msg, err_msg)
  local err_code = os.execute(cmd)
  if err_code == 0 then
    vim.notify("✅ " .. success_msg, vim.log.levels.INFO)
  else
    vim.notify(string.format("❌ %s [err_code: %d] ", err_msg, err_code), vim.log.levels.ERROR)
    return false
  end
  return true
end

--- @param cmd string
--- @param success_msg string
--- @param err_msg string
--- @return boolean
function M.remove_with_notify(cmd, success_msg, err_msg)
  local r1, err_desc = os.remove(cmd)
  if r1 ~= nil then
    vim.notify("✅ " .. success_msg, vim.log.levels.INFO)
  else
    vim.notify(string.format("❌ %s [%s] ", err_msg, err_desc), vim.log.levels.ERROR)
    return false
  end
  return true
end

M.IsWindows = isWindows()

return M
