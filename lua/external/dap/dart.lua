require("dap").adapters.flutter = function() -- callback, config
  if vim.o.filetype == "dart" then
    vim.cmd("FlutterRun")
    vim.api.nvim_echo({
      { 'FlutterRun', '@label' },
    }, true, {})
  end
  require("dap").continue() -- :DapContinue
end


require("dap").configurations.dart = {
  {
    type = "flutter",
    name = "start debug flutter",
    request = "launch",
    cwd = "${workspaceFolder}",
  },
}
