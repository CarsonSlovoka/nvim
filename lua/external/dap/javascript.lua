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

for _, filetype in ipairs({
  "javascript",
  "typescript",
}) do
  require("dap").configurations[filetype] = {
    {
      name = "Launch file",
      type = "pwa-node",
      request = "launch",
      program = "${file}",
      cwd = "${workspaceFolder}",
    },
    -- bun 都沒有試成功
    -- {
    --   name = "Launch Bun",
    --   type = "pwa-node",
    --   request = "launch",
    --   runtimeExecutable = "bun",
    --   runtimeArgs = { "run", "--inspect-brk", "${file}" },
    --   port = function()
    --     return vim.fn.input("port: ")
    --   end,
    --   rootPath = vim.fn.getcwd(),
    --   cwd = vim.fn.getcwd(),
    --   console = "integratedTerminal",
    --   -- internalConsoleOptions = "neverOpen",
    --   -- protocol = "ws",
    -- },
    -- {
    --   name = "Attach to Bun",
    --   type = "pwa-node",
    --   request = "attach",
    --   port = 6499, -- Bun 預設偵錯埠是 6499
    --   -- port = function()
    --   --   return vim.fn.input("port: ")
    --   -- end,
    --   rootPath = vim.fn.getcwd(),
    --   cwd = vim.fn.getcwd(),
    --   restart = true, -- 自動重新連接
    --   -- protocol = "inspector",
    --   protocol = "ws", -- 換這個也是失敗
    --   sourceMaps = true,
    -- },
    {
      name = "Launch Deno File",
      type = "pwa-node",
      request = "launch",
      -- Use "deno" as the runtime executable
      runtimeExecutable = "deno",
      -- Use --inspect-brk to pause execution until the debugger attaches
      runtimeArgs = { "run", "--inspect-brk", "--allow-all" }, -- Add necessary permissions like --allow-all
      program = "${file}",
      cwd = "${workspaceFolder}",
      sourceMaps = true,
      protocol = "ws",         -- Deno uses the V8 inspector protocol via WebSockets
      attachSimplePort = 9229, -- Default Deno inspect port
    },
    {
      name = "Launch Deno File (input cwd:)",
      type = "pwa-node",
      request = "launch",
      -- Use "deno" as the runtime executable
      runtimeExecutable = "deno",
      -- Use --inspect-brk to pause execution until the debugger attaches
      runtimeArgs = { "run",
        "--inspect-brk", -- 一定要有
        "--allow-all"    -- Add necessary permissions like --allow-all
      },
      program = "${file}",
      cwd = function() return vim.fn.input("workspaceFolder: ", vim.fn.getcwd() .. "/", "file") end,
      sourceMaps = true,
      protocol = "ws",         -- Deno uses the V8 inspector protocol via WebSockets
      attachSimplePort = 9229, -- Default Deno inspect port
    },
    {
      name = "Launch Deno Test File",
      type = 'pwa-node',
      request = 'launch',
      runtimeExecutable = "deno",
      runtimeArgs = { "test", "--inspect-brk", "--allow-all" }, -- 只用--inspect會無效
      program = "${file}",
      cwd = "${workspaceFolder}",
      attachSimplePort = 9229,
    },
  }
end
