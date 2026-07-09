local dap = require("dap")
local utils = require("utils.utils")


---@class PerlRunConfig
---@field type "perl"
---@field name string
---@field args? string[]|fun():string[]


dap.adapters.perl = function(_, config)
  local script_name = vim.fn.expand("%:t")
  local script_dir = vim.fn.expand("%:p:h")

  vim.cmd.lcd(vim.fn.fnameescape(script_dir))

  vim.cmd("topleft new")

  local cmd = { "perl", script_name }
  vim.list_extend(cmd, utils.dap.get_args(config))

  -- 這可行，但是執行完就會離開
  -- vim.fn.jobstart(cmd, {
  --   cwd = script_dir,
  --   term = true,
  -- })
  -- vim.cmd("startinsert")

  vim.cmd("term")
  vim.cmd("startinsert")
  vim.api.nvim_input(string.format([[%s <CR>]], table.concat(cmd, " ")))
end

dap.configurations.perl = {} -- filetype
for _, config in ipairs({
  {
    type = "perl",
    name = "run current file",
    args = {},
  },
  {
    type = "perl",
    name = "run current file with args",
    args = function()
      local input = vim.fn.input("perl args: ")

      return vim.split(input, "%s+", {
        trimempty = true,
      })
    end,
  },
}) do
  table.insert(dap.configurations.perl, config)
end
