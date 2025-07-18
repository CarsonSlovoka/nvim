local M = {}

--- 下載檔案的函數
--- @param url string
--- @param filepath string
--- @return boolean? ok
--- @example download_file("https://discord.com/test.png", "output.png")
function M.download_file(url, filepath)
  local res = require("plenary.curl").get(url, {
    accept = "application/octet-stream",
    output = filepath, -- 這是可選項，如果是下載檔案，可以直接利用這個選項，就不需要自己再去用file.write
  })

  if res.status ~= 200 then
    vim.notify(string.format("Download failed, status code: %d", res.status), vim.log.levels.WARN)
    return
  end

  -- 以下可行，但直接靠output可選項即可
  -- local file = io.open(filepath, "wb")
  -- if not file then
  --   print(string.format("cannot create file %s", filepath))
  --   return false
  -- end
  -- file:write(res.body)
  -- file:close()

  print(string.format("✅ %s downloaded successfully", filepath))

  return true
end

return M
