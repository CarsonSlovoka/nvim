local M = {}

local function print_stat_time(path, field)
  local stat = vim.uv.fs_stat(path)
  if stat then
    print(os.date("%Y-%m-%d %H:%M:%S", stat[field].sec))
  end
end

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
  {
    label = "menu: fs_stat",
    children = {
      {
        label = "mtime",
        callback = function(path)
          print_stat_time(path, "mtime")
        end
      },
      {
        label = "atime",
        callback = function(path)
          print_stat_time(path, "atime")
        end
      },
      {
        label = "ctime",
        callback = function(path)
          print_stat_time(path, "ctime")
        end
      },
      {
        label = "fs_stat",
        callback = function(path)
          print(vim.inspect(vim.uv.fs_stat(path)))
        end,
      }
    },
  }
}

M.fs_stat = {
  label = "fs_stat",
  children = fs_stat_children,
}

return M
