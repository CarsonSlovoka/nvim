local dap = require("dap")
local utils = require("utils.utils")

---@class ShRunConfig
---@field type "bash"
---@field name string
---@field range boolean
---@field args? string[]|fun():string[]

dap.adapters.bash = function(_, config)
  ---@cast config ShRunConfig

  local script_name = vim.fn.expand("%:t")
  vim.cmd("lcd %:h")
  if config.range then
    -- vim.cmd("normal! gvy") -- 這是得到前一次選取的範圍，在解除visual下使用會有用
    -- vim.fn.setreg('"', vim.fn.join(vim.fn.getregion(vim.fn.getpos("'<"), vim.fn.getpos("'>")), '')) -- 這個也沒用
    vim.cmd("normal! ygvy") -- 可以先y一次來解除visual, 之後gvy就會有用
  end

  vim.cmd("topleft new | term")
  vim.cmd("startinsert")

  if config.range then
    -- local selected = vim.fn.getreg('"')
    vim.api.nvim_input(string.format([[<C-r>"<CR>]])) -- 目上所選的內容，然後執行
    return
  end

  local cmd = { "bash", script_name }
  vim.list_extend(cmd, utils.dap.get_args(config))
  vim.api.nvim_input(string.format([[%s <CR>]], table.concat(cmd, " ")))
end

dap.configurations.sh = {} -- filetype: sh 時會套用此設定
for _, config in ipairs({
  {
    type = "bash",
    name = "▶️    run current file",
  },
  {
    type = "bash",
    name = "▶️... run current file with args",
    args = function()
      local input = vim.fn.input("args: ")
      return vim.split(input, "%s+", { trimempty = true, })
    end,
  },
  {
    type = "bash",
    name = "▶️< > run selection",
    range = true,
  },
  {
    type = "terminal",
    exe = "bats -p", -- https://github.com/bats-core/bats-core 安裝: https://bats-core.readthedocs.io/en/stable/installation.html
    name = "bats -p <file>",
  },
  {
    type = "terminal",
    exe = "bats -p",
    name = "bats -p --filter xxx <file>",
    args = function()
      local filter = utils.dap.ask_args("filter:")
      if #filter > 0 then
        return { "--filter", filter[1] }
      end
    end
  },
  {
    type = "terminal",
    exe = "bats",
    name = "bats [args] <file>",
    args = utils.dap.ask_args,
  }
}) do
  ---@cast config ShRunConfig
  table.insert(dap.configurations.sh, config)
end
