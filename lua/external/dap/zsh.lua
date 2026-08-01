local dap = require("dap")
local utils = require("utils.utils")

dap.configurations.zsh = {
  {
    type = "terminal",
    exe = "zsh",
    name = "[term] zsh <file>",
  },
  {
    type = "terminal",
    exe = "zsh",
    name = "[term] zsh <file> [args]",
    args = utils.dap.ask_args,
  },
}
