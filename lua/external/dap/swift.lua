local dap = require("dap")

dap.adapters.codelldb = {
  type = "server",  -- "server" 表示連接 TCP 伺服器
  host = "127.0.0.1",
  port = "${port}", -- 會自動使用隨機端口
  executable = {
    -- https://github.com/vadimcn/codelldb/releases
    -- 在releases的頁面下載對應平台的vsix, 然後可以重新命名為zip,然後解壓
    -- wget https://github.com/vadimcn/codelldb/releases/download/v1.11.5/codelldb-linux-x64.vsix -O ~/codelldb/codelldb.zip
    -- cd ~/codelldb
    -- unzip ~/codelldb
    command = vim.fn.expand("~/codelldb/extension/adapter/codelldb"),
    port = "${port}",
    args = {
      "--port", "${port}",

      -- "--liblldb", vim.fn.expand("~/codelldb/extension/lldb/lib/liblldb.so"), ❌ 放這個會有問題
      --   file ~/codelldb/extension/lldb/lib/liblldb.so
      --     ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, stripped 👈 這是一個stripped的版本，所以一些調式的資訊都已經移除，所以會不能用
      --
      --  https://www.swift.org/install/linux/ 安裝完Swiftly, 如果都用預設的路徑就會有檔案: ~/.local/share/swiftly/toolchains/6.1.2/usr/lib/liblldb.so.17.0.0
      "--liblldb", vim.fn.expand("~/.local/share/swiftly/toolchains/6.1.2/usr/lib/liblldb.so.17.0.0"), -- 可以用這個指令去找so的位置 `fd -t f -HI liblldb.so ~`
      -- "--liblldb", vim.fn.expand("~/.local/share/swiftly/toolchains/6.1.2/usr/lib/liblldb.so"),     -- 放連結也可以
      --   file ~/.local/share/swiftly/toolchains/6.1.2/usr/lib/liblldb.so.17.0.0
      --     ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, not stripped 👈 是 not stripped的版本，所有debug可以用
      -- WARN: --liblldb 一定要給，不然會遇到錯誤: Exception: Could not find type system for language swift: TypeSystem for language swift doesn't exist
    },
  },
  name = "codelldb",
}

-- -- 以下沒用, 不論env是否有設定都不能成功
-- dap.adapters.lldb = {
--   type = 'executable',
--   -- https://www.swift.org/install/linux/ 安裝完Swiftly就會有lldb這個工具了
--   command = vim.fn.expand("~/.local/share/swiftly/bin/lldb"),
--   name = 'lldb',
--   args = {},
--   env = {
--     PATH = vim.fn.getenv('PATH') .. ':' .. vim.fn.expand('~/.local/share/swiftly/bin'),
--     LLDB_CUSTOM_Lldb = vim.fn.expand('~/.local/share/swiftly/toolchains/6.1.2/usr/lib/liblldb.so.17.0.0'),
--   },
-- }


-- https://github.com/vadimcn/codelldb/blob/dd0687c/MANUAL.md#starting-a-new-debug-session
dap.configurations.swift = {
  {
    type = "codelldb",
    name = "Debug Swift (codelldb)",
    request = "launch",
    program = function()
      return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = false, -- 進入時不自動暫停
    args = {},           -- 運行參數
  },
  {
    type = "codelldb",
    name = "Debug Swift (Arguments) (codelldb)",
    request = "launch",
    program = function()
      -- swift build --configuration debug
      -- /path/to/project/.build/debug/executableTarget.name
      return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
    args = require("dap-go").get_arguments,
  },
  -- 附加到運行中程序（用於模擬器或裝置）👈 沒試過
  {
    type = "codelldb",
    name = "Attach to process (codelldb)",
    request = "attach",
    pid = require("dap.utils").pick_process, -- 選擇 PID
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
  },

  -- 以下 lldb 不建議用, 會失敗 (而用 codelldb 確定可行)
  -- {
  --   type = 'lldb',
  --   name = 'Launch Swift',
  --   request = 'launch',
  --   program = function()
  --     return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
  --   end,
  --   cwd = '${workspaceFolder}',
  --   stopOnEntry = false, -- 進入時是否停在 main
  --   args = {},           -- function() return vim.fn.input('Args: ')
  -- },
  -- {
  --   type = 'lldb',
  --   name = 'Launch Swift (Arguments)',
  --   request = 'launch',
  --   program = function()
  --     return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
  --   end,
  --   cwd = '${workspaceFolder}',
  --   stopOnEntry = false,
  --   args = require("dap-go").get_arguments,
  -- },
  -- {
  --   type = 'lldb',
  --   name = 'Attach to process',
  --   request = 'attach',
  --   pid = require('dap.utils').pick_process,
  -- },
}
