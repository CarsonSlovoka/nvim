require("dap").adapters.nlua = function(callback, config)
  -- 可以直接用
  -- lua require"osv".launch({port = 8086}) <-- 不建議用，就執行用launch()之後接run_this即可
  -- lua require'osv'.launch() -- 如果沒有port預設會隨便生成一個
  -- lua require'osv'.stop() -- 結束launch
  -- lua require'osv'.run_this()
  -- lua print(require "osv".is_running()) -- launch()之後就是true了
  callback({ type = 'server', host = config.host or "127.0.0.1", port = config.port or 8086 })
end

require("dap").configurations.lua = {
  {
    type = 'nlua',
    request = 'attach',
    name = "Attach to running Neovim instance", -- 是nvim的環境，如果是其它的lua, 例如lua5.3, 這種它的require路徑不同
  },
}
