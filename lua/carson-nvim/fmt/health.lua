local M = {}
-- 如果是用這樣的方式: `:checkhealth carson-nvim.fmt` 可以不必要寫check
-- 但如果是: `:checkhealth` 這個的檢核就會需要寫模組的check函數, 不然就會報錯
-- > All such health modules must return a Lua table containing a check() function.

M.check = function()
  require("carson-nvim.fmt.sh").check()
end

return M
