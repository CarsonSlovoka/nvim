return {
  {
    label = "Run with Lua",
    callback = function(path)
      local cmd = ("nvim -l %s"):format(vim.fn.shellescape(path))
      vim.cmd("topleft split | terminal " .. cmd)
    end,
  },
  {
    label = "Run with Lua + args",
    callback = function(path)
      vim.ui.input({ prompt = "Lua args: " }, function(args)
        if not args then return end
        local cmd = ("nvim -l %s %s"):format(
          vim.fn.shellescape(path),
          args
        )
        vim.cmd("topleft split | terminal " .. cmd)
      end)
    end,
  },
  {
    label = "[term] Run with Lua + args",
    callback = function(path)
      local dir = vim.fn.fnamemodify(path, ":h")
      vim.cmd("lcd " .. dir)
      local basenmae = vim.fn.fnamemodify(path, ":t")
      local input = vim.fn.input("args: ")
      local args = vim.split(input, "%s+", { trimempty = true, })
      local cmd = { "nvim", "-l", basenmae }
      vim.list_extend(cmd, args)
      vim.cmd("topleft new | setlocal buftype=nofile noswapfile bufhidden=wipe nobuflisted | term")
      -- vim.cmd("topleft new | term")
      -- Note: 已知這樣做，最後exit時，還會需要自己在手動關閉一個視窗
      vim.cmd("startinsert")
      vim.api.nvim_input(string.format([[%s <CR>]], table.concat(cmd, " ")))
    end,
  },
}
