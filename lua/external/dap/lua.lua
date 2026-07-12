local dap = require("dap")
local utils = require("utils.utils")

dap.adapters.nlua = function(callback, config)
  -- 可以直接用
  -- lua require"osv".launch({port = 8086}) <-- 不建議用，就執行用launch()之後接run_this即可
  -- lua require'osv'.launch() -- 如果沒有port預設會隨便生成一個
  -- lua require'osv'.stop() -- 結束launch
  -- lua require'osv'.run_this()
  -- lua print(require "osv".is_running()) -- launch()之後就是true了
  if vim.o.filetype == "lua" and not require "osv".is_running() then
    -- 如果還沒跑起，直接幫忙啟動
    require 'osv'.launch()
    require 'osv'.run_this()
  end
  callback({ type = 'server', host = config.host or "127.0.0.1", port = config.port or 8086 })
end

dap.adapters.local_lua = {
  type = "executable",
  command = "node",
  -- local-lua-debugger-vscode取得
  --  git clone https://github.com/tomblind/local-lua-debugger-vscode.git ~/.local/share/nvim/lsp_servers/local-lua-debugger-vscode
  --  之後請參考: ../../../README.md 中的說明, 來將ts轉成js
  args = { vim.fn.expand("~/.local/share/nvim/lsp_servers/local-lua-debugger-vscode/extension/debugAdapter.js") },
  enrich_config = function(config, on_config)
    local c = vim.deepcopy(config)
    if not config.extensionPath then
      c.extensionPath = vim.fn.expand("~/.local/share/nvim/lsp_servers/local-lua-debugger-vscode")
    end
    on_config(c)
  end,
}

--- @param lua_cmd string
--- @param args boolean?
local function get_local_cmd_item(lua_cmd, args)
  local item = {
    name = string.format('Current file %s (%s)',
      args and "with args" or "",
      lua_cmd
    ),
    type = 'local_lua',
    request = 'launch',
    cwd = '${workspaceFolder}',
    program = {
      lua = 'lua5.4',
      file = '${file}',
    },
    stopOnEntry = false,
    scriptRoots = { "${workspaceFolder}" }, -- 可選：指定模組搜尋路徑，避免 require 路徑問題
    -- args = {},
  }
  if args then
    item.args = require("dap-go").get_arguments
  end
  return item
end

require("dap").adapters.nvim = function(_, config)
  local script_name = vim.fn.expand("%:t")
  vim.cmd("lcd %:h")

  vim.cmd("topleft new | term")
  vim.cmd("startinsert")

  local cmd = { "nvim",
    "", "", -- 此為-u的保留
    "-l", script_name }
  local args = utils.dap.get_args(config)
  for index, name in ipairs(args) do
    if name == "-u" then
      -- -u init.lua 這個需要加在-l之前才可以
      cmd[2] = "-u"
      cmd[3] = args[index + 1]
      args[index] = "" -- 清空
      args[index + 1] = ""
      break
    end
  end
  vim.list_extend(cmd, args)
  vim.api.nvim_input(string.format([[%s <CR>]], table.concat(cmd, " ")))
end

require("dap").configurations.lua = {
  {
    type = "nvim",
    name = "▶️... nvim -l % with args",
    args = function()
      local input = vim.fn.input("args: ")
      return vim.split(input, "%s+", { trimempty = true, })
    end,
  },
  {
    type = 'nlua',
    request = 'attach',
    name = "Attach to running Neovim instance", -- 是nvim的環境，如果是其它的lua, 例如lua5.3, 這種它的require路徑不同
  },
  get_local_cmd_item("lua5.1"),
  get_local_cmd_item("lua5.1", true),
  get_local_cmd_item("lua5.4"),
  get_local_cmd_item("lua5.4", true),
}
