local dap = require("dap")
local utils = require("utils.utils")

dap.configurations.make = {
  {
    type = "terminal",
    exe = "make",
    name = "[term] make <file>",
  },
  {
    type = "terminal",
    exe = "make",
    name = "[term] make <file> [args]",
    args = utils.dap.ask_args,
  },
}
