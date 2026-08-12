return {
  {
    label = "Run with Python",
    callback = function(path)
      local cmd = ("python3 %s"):format(vim.fn.shellescape(path))
      -- vim.cmd("botright split | terminal " .. cmd)
      vim.cmd("topleft split | terminal " .. cmd)
    end,
  },
  {
    label = "Run with Python + args",
    callback = function(path)
      vim.ui.input({ prompt = "Python args: " }, function(args)
        if not args then return end
        local cmd = ("python3 %s %s"):format(
          vim.fn.shellescape(path),
          args
        )
        vim.cmd("topleft split | terminal " .. cmd)
      end)
    end,
  }
}
