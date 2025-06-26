-- 以下這兩個配置一定要有: 👈 實際上不管是哪一個，都一定要有以下這兩個，如果沒有看到就是該plugin幫忙設定好了而已
-- configurations.lua
-- adapters.nlua
require("dap").configurations.lua = {
  {
    type = 'nlua',
    request = 'attach',
    name = "Attach to running Neovim instance",
  }
}

require("dap").adapters.nlua = function(callback, config)
  -- 可以直接用
  -- lua require"osv".launch({port = 8086}) <-- 不建議用，就執行用launch()之後接run_this即可
  -- lua require'osv'.launch() -- 如果沒有port預設會隨便生成一個
  -- lua require'osv'.stop() -- 結束launch
  -- lua require'osv'.run_this()
  -- lua print(require "osv".is_running()) -- launch()之後就是true了
  callback({ type = 'server', host = config.host or "127.0.0.1", port = config.port or 8086 })
end
