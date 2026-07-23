local M = {}

local dap = require("dap")
local utils = require("utils.utils")


dap.adapters.none = function(_, config)
  if not config.cb then
    vim.notify(
      string.format([[
The necessary parameter `` is missing.
dap.configurations.%s = {
  {
    type= "none",
    exe = "cb", -- 👈  add this
  },
   -- ...
}"
    ]], vim.bo.filetype),
      vim.log.levels.ERROR)
    return
  end

  if type(config.cb) ~= "function" then
    vim.notify("Not a function", vim.log.levels.ERROR)
  end

  config.cb(config)
end


return M
