local M = {}

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

return M
