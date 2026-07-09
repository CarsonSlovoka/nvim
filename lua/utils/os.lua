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

--- 檢查或提示建立輸出目錄
---@return boolean? suc
function M.check_output_dir(dir_path)
  if vim.fn.isdirectory(dir_path) == 1 then
    return true
  end

  local input = vim.fn.input(string.format("Directory %s does not exist, do you want to create it? (y/n):", dir_path))
  if input:lower() == "y" or input:lower() == "yes" then
    vim.fn.mkdir(dir_path, "p")
    print(string.format("✅ Directory %s has been successfully established!", dir_path))
    return true
  else
    print("Cancel directory")
    return false
  end
end

---@param path string
---@return boolean
function M.copy_file_to_clipboard(path)
  path = vim.fn.fnamemodify(path, ":p")

  if vim.fn.filereadable(path) ~= 1 and vim.fn.isdirectory(path) ~= 1 then
    vim.notify("File not found: " .. path, vim.log.levels.ERROR)
    return false
  end

  -- macOS: copy as Finder file object
  if vim.fn.has("macunix") == 1 then
    local statement = string.format([[tell application "Finder" to set the clipboard to (POSIX file "%s")]], path)
    local result = vim.system({
      "osascript", "-e", statement,
    }, { text = true }):wait()
    if result.code ~= 0 then
      vim.notify(result.stderr or "Failed to copy file", vim.log.levels.ERROR)
      return false
    end

    return true
  end

  -- Linux: GNOME/Nautilus-compatible file clipboard format (Note: 尚未驗證)
  local sysname = (vim.uv or vim.loop).os_uname().sysname
  if sysname == "Linux" then
    -- Note: 目前只做wayland, 不管x11
    local uri = vim.uri_from_fname(path)
    local data = uri .. "\r\n"

    if vim.fn.executable("wl-copy") ~= 1 then
      vim.notify(
        "Need wl-copy or xclip. On Ubuntu: sudo apt install wl-clipboard xclip",
        vim.log.levels.ERROR
      )
      return false
    end

    -- bash 測試
    -- FILE="./os.lua"
    -- URI="$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve().as_uri())' "$FILE")"
    -- echo "$URI" -- # file:///path/to/os.lua
    -- echo "$XDG_SESSION_TYPE"  -- wayland
    -- printf '%s\r\n' "$URI" | wl-copy --type text/uri-list

    -- Warn: 這種情況用wait會卡住不動. 要用callback的方式
    -- local result = vim.system(
    --   { "wl-copy", "--type", "text/uri-list", },
    --   { stdin = data, text = true, }
    -- ):wait()

    vim.system({
      "wl-copy",
      "--type",
      "text/uri-list",
    }, {
      stdin = data,
      text = true,
    }, function(result)
      if result.code ~= 0 then
        vim.schedule(function()
          vim.notify(result.stderr or "Failed to copy file URI", vim.log.levels.ERROR)
        end)
      end
    end)

    return true
  end

  vim.notify("Copy file object is only implemented for macOS/Linux", vim.log.levels.ERROR)
  return false
end

M.IsWindows = isWindows()

return M
