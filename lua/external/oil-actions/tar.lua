return {
  {
    label = "tar -xvf",
    callback = function(path)
      local dir = vim.fn.fnamemodify(path, ":h")
      local cmd = { "tar", "-xvf", path, "-C", dir }
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
    end,
  }
}
