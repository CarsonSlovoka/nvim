return {
  {
    label = "Unzip here",
    callback = function(path)
      local dir = vim.fn.fnamemodify(path, ":h")
      local cmd = { "unzip", "-o", path, "-d", dir }
      vim.system(
        cmd,
        { text = true, cwd = dir },
        function(obj)
          vim.schedule(function()
            if obj.code == 0 then
              vim.notify(table.concat(cmd, " ") .. "\n ✅ Unzipped successfully", vim.log.levels.INFO)
              -- 重新整理 oil 視窗
              require("oil.actions").refresh.callback()
            else
              vim.notify(
                ("Unzip failed:\n%s"):format(obj.stderr or obj.stdout or "unknown"),
                vim.log.levels.ERROR
              )
            end
          end)
        end
      )
    end,
  }
}
