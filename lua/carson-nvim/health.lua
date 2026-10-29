local M = {}

-- 多寫這個模組是為了 `:checkhealth carson-nvim` 也可以使用
function M.check()
  require("carson-nvim.fmt.health").check()
end

return M
