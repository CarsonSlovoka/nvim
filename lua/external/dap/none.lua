local M = {}

local dap = require("dap")
local utils = require("utils.utils")


dap.adapters.none = function(_, config)
  -- print(vim.inspect(config)) -- Important: config只有數值類(array, string, ...)的可以被加入，如果屬性本身是function就會直接執行. 而當function沒有回傳值是這一個屬性就不會有, 但如果有回傳值，即便是function這裡的屬性也會有

  -- 就不寫任何東西了, 外層直接寫一個function實作完即可
  -- if not config.cb then
  --   vim.notify(
  --     string.format([[
  -- The necessary parameter `cb` is missing.
  -- dap.configurations.%s = {
  --   {
  --     type= "none",
  --     cb = function(config) end, -- 👈  add this
  --   },
  --    -- ...
  -- }"
  --     ]], vim.bo.filetype),
  --     vim.log.levels.ERROR)
  --   return
  -- end
  --
  -- if type(config.cb) ~= "function" then
  --   vim.notify("Not a function", vim.log.levels.ERROR)
  -- end
  --
  -- config.cb(config)
end


return M
