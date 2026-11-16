local function print_errcode(obj)
  -- 需排程, 因為在選單放卡住 (Fast Event Context限制)
  vim.schedule(function()
    if obj.code ~= 0 then
      vim.notify(
        ("❌ failed:\n%s"):format(obj.stderr or obj.stdout or "unknown"),
        vim.log.levels.ERROR
      )
    end
  end)
end
return {
  {
    -- open -a Safari "file:///$(realpath ~/Downloads/my.mp3)"
    label = "open -a Safari",
    callback = function(path)
      local dir = vim.fn.fnamemodify(path, ":h")
      local file = vim.fn.fnamemodify(path, ":p")
      local cmd = { "open", "-a", "Safari", "file://" .. file }
      -- print(vim.inspect(cmd))
      vim.system(
        cmd,
        { text = true, cwd = dir },
        print_errcode
      )
    end,
  }
}
