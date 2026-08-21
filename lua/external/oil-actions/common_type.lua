local M = {}

local fs_stat_children = {
  {
    label = "du -hs", -- display disk usage statistics
    callback = function(path)
      local r = vim.system({ "sh", "-c", string.format("du -hs %q", path) }):wait()
      if r.code ~= 0 then
        vim.schedule(function()
          vim.notify("du -hs failed:\n" .. (r.stderr or ""), vim.log.levels.ERROR)
        end)
      end
      print(r.stdout)
    end,
  },
}

M.fs_stat = {
  label = "fs_stat",
  children = fs_stat_children,
}

return M
