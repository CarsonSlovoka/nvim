---@param opt table
---@param path string
local function run_7z(opt, path)
  -- Check if 7zz is installed
  if vim.fn.executable("7zz") == 0 then
    vim.notify("7zz is not installed. Please install 7-zip first (`brew install sevenzip`)", vim.log.levels.ERROR)
    return
  end

  local cmd = vim.list_extend({ "7zz" }, opt)
  table.insert(cmd, path)

  local dir = vim.fn.fnamemodify(path, ":h")
  vim.system(
    cmd,
    { text = true, cwd = dir },
    function(obj)
      vim.schedule(function()
        if obj.code == 0 then
          vim.notify(table.concat(cmd, " ") .. "\n ✅ Extract successfully", vim.log.levels.INFO)
          require("oil.actions").refresh.callback()
        else
          vim.notify(
            ("Extract failed:\n%s"):format(obj.stderr or obj.stdout or "unknown"),
            vim.log.levels.ERROR
          )
        end
      end)
    end
  )
end

return {
  {
    label = "7zz x",
    callback = function(path)
      run_7z({ "x" }, path)
    end,
  },
  {
    label = "7zz e (flat decompression)",
    callback = function(path)
      run_7z({ "e" }, path)
    end,
  },
}

