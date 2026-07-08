local dap = require("dap")


---@class PerlRunConfig
---@field type "perl"
---@field name string
---@field args? string[]|fun():string[]

---@param config PerlRunConfig
local function get_args(config)
  local args = config.args or {}

  if type(args) == "function" then
    args = args()
  end

  if type(args) == "string" then
    args = vim.split(args, "%s+", { trimempty = true })
  end

  return args
end

dap.adapters.perl = function(_, config)
  local script_name = vim.fn.expand("%:t")
  local script_dir = vim.fn.expand("%:p:h")

  vim.cmd.lcd(vim.fn.fnameescape(script_dir))

  vim.cmd("topleft new")

  local cmd = { "perl", script_name }
  vim.list_extend(cmd, get_args(config))

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
