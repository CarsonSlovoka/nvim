local M = {}

--- @return table
function M.getDirOnly(argLead)
  local all_file = vim.fn.getcompletion(argLead, "file") -- 包含檔案和目錄
  local directories = {}
  for _, result in ipairs(all_file) do
    if vim.loop.fs_stat(result) and vim.loop.fs_stat(result).type == "directory" then
      table.insert(directories, result)
    end
  end
  return directories
end

---@param arg_lead string
function M.get_file_only(arg_lead)
  local all_file = vim.fn.getcompletion(arg_lead, "file") -- 包含檔案和目錄
  local files = {}
  for _, result in ipairs(all_file) do
    if vim.loop.fs_stat(result) and vim.loop.fs_stat(result).type == "file" then
      table.insert(files, result)
    end
  end
  return files
end

return M
