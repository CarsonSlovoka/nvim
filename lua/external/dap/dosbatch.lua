local dap = require("dap")
local utils = require("utils.utils")

-- 若使用windows的wsl, 在該電腦能直接使用 cmd.exe 去執行匹次檔
dap.configurations.dosbatch = {
  {
    type = "terminal",
    exe = "cmd.exe /c",
    name = "[term] cmd.exe /c <file>",
  },
  {
    type = "terminal",
    exe = "cmd.exe /c",
    name = "[term] cmd.exe /c <file> [args]",
    args = utils.dap.ask_args,
  },
}
