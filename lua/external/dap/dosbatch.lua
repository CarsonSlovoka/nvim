local dap = require("dap")
local utils = require("utils.utils")

-- 若使用windows的wsl, 在該電腦能直接使用 cmd.exe 去執行匹次檔
dap.configurations.dosbatch = {
  {
    type = "terminal",
    exe = "cmd.exe /c",
    -- Note: 路徑要是windows的路徑才可以，所以可以用wslpath -w得到windows的路徑
    name = "[term] cmd.exe /c $(wslpath -w <file>)",
    wslpath = true,
  },
  {
    type = "terminal",
    exe = "cmd.exe /c",
    name = "[term] cmd.exe /c $(wslpath -w <file>) [args]",
    args = utils.dap.ask_args,
    wslpath = true,
  },
}
