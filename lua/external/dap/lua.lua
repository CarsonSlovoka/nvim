require("dap").adapters.nlua = function(callback, config)
  -- 可以直接用
  -- lua require"osv".launch({port = 8086}) <-- 不建議用，就執行用launch()之後接run_this即可
  -- lua require'osv'.launch() -- 如果沒有port預設會隨便生成一個
  -- lua require'osv'.stop() -- 結束launch
  -- lua require'osv'.run_this()
  -- lua print(require "osv".is_running()) -- launch()之後就是true了
  callback({ type = 'server', host = config.host or "127.0.0.1", port = config.port or 8086 })
end

require("dap").adapters.local_lua = {
  type = "executable",
  command = "node",
  -- local-lua-debugger-vscode取得
  --  git clone https://github.com/tomblind/local-lua-debugger-vscode.git ~/.local/share/nvim/lsp_servers/local-lua-debugger-vscode
  --  之後請參考: ../../../README.md 中的說明, 來將ts轉成js
  args = { vim.fn.expand("~/.local/share/nvim/lsp_servers/local-lua-debugger-vscode/extension/debugAdapter.js") },
  enrich_config = function(config, on_config)
    local c = vim.deepcopy(config)
    if not config.extensionPath then
      c.extensionPath = vim.fn.expand("~/.local/share/nvim/lsp_servers/local-lua-debugger-vscode")
    end
    on_config(c)
  end,
}

require("dap").configurations.lua = {
  {
    type = 'nlua',
    request = 'attach',
    name = "Attach to running Neovim instance", -- 是nvim的環境，如果是其它的lua, 例如lua5.3, 這種它的require路徑不同
  },
  {
    name = 'Current file (lua 5.4)',
    type = 'local_lua',
    request = 'launch',
    cwd = '${workspaceFolder}',
    program = {
      lua = 'lua5.4',
      file = '${file}',
    },
    stopOnEntry = false,
    scriptRoots = { "${workspaceFolder}" }, -- 可選：指定模組搜尋路徑，避免 require 路徑問題
    -- args = {},
  },
}
