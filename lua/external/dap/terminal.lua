local M = {}

local dap = require("dap")
local utils = require("utils.utils")

---@class TermianlConfig
---@field type "terminal"
---@field exe string bash, go, perl, python, ...
---@field name string prompt
---@field autocd boolean? (default: true)
---@field args? string[]|fun():string[]


dap.adapters.terminal = function(_, config)
  ---@cast config TermianlConfig

  if not config.exe then
    vim.notify(
      string.format([[
The necessary parameter `exe` is missing.
dap.configurations.%s = {
  {
    type= "terminal",
    exe = "", -- 👈  add this
  },
   -- ...
}"
    ]], vim.bo.filetype),
      vim.log.levels.ERROR)
    return
  end

  local script_name = vim.fn.expand("%:t")
  local script_dir = vim.fn.expand("%:p:h")

  local autocd = config.autocd ~= false -- default true

  if autocd then
    -- vim.cmd("lcd %:h")
    vim.cmd.lcd(vim.fn.fnameescape(script_dir))
  end

  local cmd = { config.exe, script_name }
  vim.list_extend(cmd, utils.dap.get_args(config))

  -- 暫時先不加
  -- if config.range then
  --   -- local selected = vim.fn.getreg('"')
  --   vim.api.nvim_input(string.format([[<C-r>"<CR>]])) -- 目上所選的內容，然後執行
  --   return
  -- end

  vim.cmd("topleft new | term")
  vim.cmd("startinsert")
  vim.api.nvim_input(string.format([[%s <CR>]], table.concat(cmd, " ")))
end


return M
