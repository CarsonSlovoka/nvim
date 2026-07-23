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
    type = "none",
    name = "📁 Copy the absolute path of the directory to the clipboard",
    function()
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
