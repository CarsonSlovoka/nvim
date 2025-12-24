local dap = require("dap")

local codelldb_args = {
  "--port", "${port}",
}
if vim.uv.os_uname().sysname == "Linux" then
  -- "--liblldb", vim.fn.expand("~/codelldb/extension/lldb/lib/liblldb.so"), ❌ 放這個會有問題
  --   file ~/codelldb/extension/lldb/lib/liblldb.so
  --     ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, stripped 👈 這是一個stripped的版本，所以一些調式的資訊都已經移除，所以會不能用
  --
  --  https://www.swift.org/install/linux/ 安裝完Swiftly, 如果都用預設的路徑就會有檔案: ~/.local/share/swiftly/toolchains/6.1.2/usr/lib/liblldb.so.17.0.0
  -- "--liblldb", vim.fn.expand("~/.local/share/swiftly/toolchains/6.1.2/usr/lib/liblldb.so.17.0.0"), -- 可以用這個指令去找so的位置 `fd -t f -HI liblldb.so ~`
  --
  -- "--liblldb", vim.fn.expand("~/.local/share/swiftly/toolchains/6.1.2/usr/lib/liblldb.so"),     -- 放連結也可以
  --   file ~/.local/share/swiftly/toolchains/6.1.2/usr/lib/liblldb.so.17.0.0
  --     ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, not stripped 👈 是 not stripped的版本，所有debug可以用
  -- WARN: --liblldb 一定要給，不然會遇到錯誤: Exception: Could not find type system for language swift: TypeSystem for language swift doesn't exist

  table.insert(codelldb_args, "--liblldb")
  table.insert(codelldb_args, vim.fn.expand("~/.local/share/swiftly/toolchains/6.1.2/usr/lib/liblldb.so.17.0.0"))
  -- 可以用這個指令去找so的位置 `fd -t f -HI liblldb.so ~`
elseif vim.uv.os_uname().sysname == "Darwin" then
  -- 以下內容都沒用，如果是用mac，不需要裝codelldb, 與swiftly, 都使用xcode所提供的工具，即可對swift來debug
  -- table.insert(codelldb_args, "--liblldb")
  -- table.insert(codelldb_args, vim.fn.expand("~/codelldb/extension/lldb/lib/liblldb.dylib"))
end


if vim.uv.os_uname().sysname == "Linux" then
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
      args = codelldb_args,
    },
    name = "codelldb",
  }

  -- 以下沒用, 不論env是否有設定都不能成功
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
end

if vim.uv.os_uname().sysname == "Darwin" then
  -- Tip: xcrun 是安裝XCode之後會有的工具
  -- xcrun --version
  --  xcrun version 72.

  -- Tip: 查找工具路徑: `xcrun --find swiftc`
  -- /Applications/Xcode_26.0.1.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc
  -- Tip: `xcrun --find lldb`
  -- /Applications/Xcode_26.0.1.app/Contents/Developer/usr/bin/lldb
  -- Tip: `xcrun --find lldb-dap` 👈 這個就是我們用來偵錯的工具
  -- /Applications/Xcode_26.0.1.app/Contents/Developer/usr/bin/lldb-dap

  -- Tip: 可以使用此指令找出SDK的路徑: `xcrun --show-sdk-path`

  -- Tip: 顯示當前的xcode版本: `xcrun --show-sdk-version`

  -- Tip:
  -- 使用指令 `xcrun lldb` 進入後輸入:
  -- settings set target.language swift
  -- quit
  -- 若無錯誤，即支援Swift, 否則就需要比較新版的Xcode

  -- local lldb_dap_path = vim.fn.trim(vim.fn.system("xcrun -f lldb-dap")) -- 可行，但是也可以寫絕對路徑
  -- /Applications/Xcode_26.0.1.app/Contents/Developer/usr/bin/lldb-dap
  dap.adapters["lldb-dap"] = { -- 在 xcodebuild.nvim 用的名稱是 lldb-dap
    name = 'lldb-dap',
    type = 'executable',
    -- command = lldb_dap_path,
    command = '/usr/bin/xcrun',
    args = {
      -- '-f',
      'lldb-dap'
    },
  }
end

-- https://github.com/vadimcn/codelldb/blob/dd0687c/MANUAL.md#starting-a-new-debug-session
if vim.uv.os_uname().sysname == "Darwin" then
  dap.configurations.swift = {
    {
      -- Note: 這一類的類型可以用在簡單的專案，例如: `swift build --configuration debug` 出來的產物，可選擇該執行檔後，即可開始debug
      type = 'lldb-dap',
      name = 'Launch Swift',
      request = 'launch',
      program = function()
        return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
      end,
      cwd = '${workspaceFolder}',
      stopOnEntry = false, -- 進入時是否停在 main
      args = {},           -- function() return vim.fn.input('Args: ')
    },
    {
      type = 'lldb-dap',
      name = 'Launch Swift (Arguments)',
      request = 'launch',
      program = function()
        return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
      end,
      cwd = '${workspaceFolder}',
      stopOnEntry = false,
      args = require("dap-go").get_arguments,
    },
    {
      type = 'lldb-dap',
      name = "iOS Simulator: Attach to App",
      request = 'attach',
      -- lldb -n xxx  也是可以debug, 但是太過陽春
      program = function()
        return vim.fn.input('Path to executable: ',
          vim.fn.expand("~/Library/Developer/Xcode/DerivedData"), 'file')
      end,
      cwd = '${workspaceFolder}',
      -- Tip: 此項目可以先做script之中設定好斷點，再從 Simulator 去開啟App (但不能再已經開始的App中使用)
      waitFor = true, -- 當你手動從模擬器點開 App 時，它會自動捕捉
      stopOnEntry = false,
      args = {},
      initCommands = {
        -- 'platform select ios-simulator',  可以select的項目應該是: `xcrun simctl list devices` 裡面的內容
        -- 'settings set target.process.thread-step-avoid-regexp ""',
      },
    },
    {
      -- Tip: 可以在已經開啟的App中使用 (缺點是如果想要再一開始的入口處就下斷點就沒辦法用這個，要用有waitFor的方式)
      type = 'lldb-dap',
      name = "iOS Simulator: Attach to App (pid)",
      request = 'attach',
      program = function()
        return vim.fn.input('Path to executable: ',
          vim.fn.expand("~/Library/Developer/Xcode/DerivedData"), 'file')
      end,
      -- pid = '${command:pickProcess}', --  👈 這個確定有效，可以找到要的pid, 只不過pid的列表可能會太多，要找也是麻煩
      pid = function() return vim.fn.input('pid:') end, -- 例如透過: `xcrun simctl launch "iPhone 17 pro" com.demo.FocusMood` 得到的pid
      cwd = '${workspaceFolder}',
      stopOnEntry = false,
      args = {},
    },
  }
else
  -- 在mac上也能用 codelldb 但是啟動之後，查看變數，可能都會有問題，會報怨:  TypeSystem for language swift doesn't exist
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
  }
end
