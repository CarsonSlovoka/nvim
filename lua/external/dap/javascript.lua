-- https://codeberg.org/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation#javascript

local dapDebugServerPath = vim.fn.expand("~/js-debug/src/dapDebugServer.js")
if vim.fn.filereadable(dapDebugServerPath) == 0 then
  vim.api.nvim_echo(
    {
      { '❌ dapDebugServer.js file does not exist. Please download and unzip:\n', "Normal" },
      { 'https://github.com/microsoft/vscode-js-debug/releases', '@label' },
      { '\n', "Normal" },
      { 'tar zxf ~/Downloads/js-debug-dap-v1.105.0.tar.gz -d ~/Downloads/temp/', "@label" },
      { '\n', "Normal" },
      { 'ls -lh ~/js-debug/src/dapDebugServer.js', "@label" },
    }, true, {})
  return
end

require("dap").adapters["pwa-node"] = {
  type = "server",
  host = "localhost",
  port = "${port}",
  executable = {
    command = "node",
    -- dapDebugServer.js下載: https://github.com/microsoft/vscode-js-debug/releases
    args = { dapDebugServerPath, "${port}" },
  }
}

require("dap").configurations.javascript = {
  {
    type = "pwa-node",
    request = "launch",
    name = "Launch file",
    program = "${file}",
    cwd = "${workspaceFolder}",
  },
}
