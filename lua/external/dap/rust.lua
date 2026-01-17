local dap = require('dap')
local dapui = require('dapui')

dap.adapters.codelldb = {
  type = 'server',
  port = "${port}",
  executable = {
    -- https://github.com/vadimcn/codelldb/releases
    -- 在releases的頁面下載對應平台的vsix, 然後可以重新命名為zip,然後解壓
    -- mkdir -pv ~/codelldb
    -- wget https://github.com/vadimcn/codelldb/releases/download/v1.12.1/codelldb-darwin-arm64.vsix -O ~/codelldb/codelldb.zip
    -- cd ~/codelldb
    -- unzip ~/codelldb
    command = vim.fn.expand('~/codelldb/extension/adapter/codelldb'),
    args = { "--port", "${port}" },
  }
}

dap.configurations.rust = {
  {
    name = "Launch",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/target/debug/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  },
}
