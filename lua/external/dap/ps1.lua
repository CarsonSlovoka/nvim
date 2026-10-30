local dap = require("dap")
local utils = require("utils.utils")

dap.configurations.ps1 = {
  {
    -- powershell.exe -ExecutionPolicy Bypass -File "my.ps1"
    type = "terminal",
    exe = "powershell.exe -ExecutionPolicy Bypass -File",
    name = "[term] powershell.exe -ExecutionPolicy Bypass -File $(wslpath -w <file>)",
    wslpath = true,
  },
}
