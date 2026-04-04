local function load_dapui()
  local dapui = require "dapui" -- https://github.com/rcarriga/nvim-dap-ui
  dapui.setup({
    layouts = {
      -- scopes, breakpoints, stacks, watches, repl, console 共有這些可以設定: https://github.com/rcarriga/nvim-dap-ui/blob/73a26abf4941aa27da59820fd6b028ebcdbcf932/lua/dapui/init.lua#L90-L96
      -- 而每一個元素可以是這幾種的組合而成
      {
        elements = {
          -- { id = "scopes", size = 0.5 }, -- 調整 Scopes 的大小
          "scopes",
          -- "breakpoints",
          -- "stacks",
          "watches",
        },
        size = 5, -- 檢視的列(沒用到那麼多還是會佔那樣的空間)
        position = "bottom",
      },
      -- {
      --   elements = { "repl", "console" },
      --   size = 0.25,
      --   position = "bottom",
      -- },
    },
  })
  vim.api.nvim_create_user_command("DapUIOpen",
    function()
      dapui.open()
    end,
    { desc = "dapui.open()" }
  )
  vim.api.nvim_create_user_command("DapUIClose",
    function()
      dapui.close()
    end,
    { desc = "dapui.close()" }
  )

  for _, e in ipairs({
    -- :DapU*stac*s 再搭配Tab來選
    "scopes",
    "breakpoints",
    "stacks",
    "watches",
    "repl",
    "console"
  }) do
    vim.api.nvim_create_user_command("DapUI" .. e,
      function()
        dapui.float_element(e, {
          width = math.ceil(vim.api.nvim_win_get_width(0) * 3 / 4),
          height = math.ceil(vim.api.nvim_win_get_height(0) / 2),
          enter = true
        })
      end,
      {
        desc = "Open DAP " .. e .. "若要永久固定可以將其放到tab上"
      }
    )
  end

  vim.api.nvim_create_user_command("DapUI",
    function(args)
      local elem = args.fargs[1]
      vim.cmd("e DAP " ..
        elem:sub(1, 1):upper() .. -- 首字母大小
        elem:sub(2)
      )
    end,
    {
      desc = ":e DAP {Breakpoints, Scopes, Stacks, Watches, Repl}",
      nargs = 1,
      complete = function(arg_lead)
        return vim.tbl_filter(function(name)
          return name:match(arg_lead)
        end, {
          "scopes",
          "breakpoints",
          "stacks",
          "watches",
          "repl",
        })
      end
    }
  )
end

--- ../lua/external/dap/
local function load_external_dap()
  local ok, dap = pcall(require, "dap")
  if not ok then
    vim.notify("Failed to load dap", vim.log.levels.ERROR)
    return
  end

  require("external.dap.go")

  -- dap.configurations.<filetype>
  --
  require("dap").adapters.custom = {
    type = 'executable',
    command = "echo", -- 找一個不重要的指令, 為了通過require("dap")而已 -- 這個工具在 Linux / macOS / Windows shell 都有
  }

  require("external.dap._tutorial") -- 教學測試用
  require("external.dap.dart")
  require("external.dap.lua")
  require("external.dap.opentype")
  require("external.dap.python")
  require("external.dap.swift")
  require("external.dap.javascript")
  require("external.dap.rust")

  require("external.dap.ttx")

  require("external.dap.keymap")


  vim.api.nvim_create_user_command("DapSetBreakpoint",
    function()
      vim.ui.input(
        { prompt = "Condition (ex: i == 5 || i == 9 ): " },
        function(condition)
          dap.set_breakpoint(condition) -- 例如在for迴圈後使用 i == 5
        end
      )
    end,
    {
      desc = "Conditional Breakpoint"
    }
  )
  vim.keymap.set("n", "<leader>bc", function()
    vim.cmd("DapSetBreakpoint")
  end, { desc = "Conditional Breakpoint" })
end

vim.defer_fn(function()
  vim.pack.add({
    "https://github.com/mfussenegger/nvim-dap",
    "https://github.com/rcarriga/nvim-dap-ui",
    "https://github.com/nvim-neotest/nvim-nio",
    "https://github.com/mfussenegger/nvim-dap-python",
    "https://github.com/jbyuki/one-small-step-for-vimkind",
    "https://github.com/leoluz/nvim-dap-go",
  })
  load_dapui()
  load_external_dap()
end, 1000)
