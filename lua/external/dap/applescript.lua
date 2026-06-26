local dap = require("dap")

dap.adapters.applescript = function(_, _)
  local script_name = vim.fn.expand("%:t")
  vim.cmd("lcd %:h")
  vim.cmd("topleft new | term")
  vim.cmd("startinsert")

  vim.api.nvim_input(string.format([[%s <CR>]], "osascript " .. script_name))
end

dap.configurations.applescript = {}
for _, config in ipairs({
  {
    type = "applescript",
    name = "run current file",
  },
}) do
  table.insert(dap.configurations.applescript, config)
end
