local M = {}

--- @param arg_lead string 要expand才會支持 ~ 的格式，建議在外層的arg_lead直接就設定
--- @return table
function M.getDirOnly(arg_lead)
  -- local all_file = vim.fn.getcompletion(vim.fn.expand(arg_lead), "file") -- 可以這樣，但是外層通常也要再設定一次，所以會做到兩次的vim.fn.expand
  local all_file = vim.fn.getcompletion(arg_lead, "file") -- 包含檔案和目錄
  local directories = {}
  for _, result in ipairs(all_file) do
    if vim.loop.fs_stat(result) and vim.loop.fs_stat(result).type == "directory" then
      table.insert(directories, result)
    end
  end
  return directories
end

--- @param arg_lead string 要expand才會支持 ~ 的格式，建議在外層的arg_lead直接就設定
--- @return table
function M.get_file_only(arg_lead)
  local all_file = vim.fn.getcompletion(arg_lead, "file")
  local files = {}
  for _, result in ipairs(all_file) do
    if vim.loop.fs_stat(result) and vim.loop.fs_stat(result).type == "file" then
      table.insert(files, result)
    end
  end
  return files
end

return M
