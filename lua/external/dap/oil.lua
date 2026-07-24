local dap = require("dap")

local function copy_path(path)
  vim.fn.setreg("+", path)
  vim.fn.setreg('"', path)
  vim.api.nvim_echo({
    { "Coped: ", "Normal" },
    { path,      "@label" },
  }, false, {})
end

dap.configurations.oil = {
  {
    type = "none", -- 如果少了，或者type找不到定義會得到錯誤: `Config references missing adapter `nil` ...`
    name = "📁 Copy the absolute path of the directory to the clipboard",
    -- my_attr = function () return {} end, -- 反回一個array, 也可以config曉得此屬性
    -- cb = function () return function () end end, -- 如果真得想要回傳函數可以讓回傳值是函數.
    function() -- dap.configurations 如果發現是函數會直接執行
      local path = require("oil").get_current_dir()
      copy_path(path)
    end
  },
  {
    type = "none",
    name = "📄 Copy the absolute path of the file to the clipboard",
    function()
      vim.cmd("normal! viWy")
      local basename = vim.fn.getreg('"')
      local dir_path = require("oil").get_current_dir()
      copy_path(dir_path .. basename)
    end
  },
}
