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
    -- require 'osv'.run_this() -- 新版的dap已經棄用. 因為它容易混淆且功能重複。官方建議的架構仍是：Debuggee Neovim 啟動 OSV server，另一個 Neovim 使用 nvim-dap 連線
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
    "", "", -- -l", script_name,
  }
  local lua_found = false
  local u_found = false
  local args = utils.dap.get_args(config)
  for index, name in ipairs(args) do
    if name == "-u" or name == "-l" then
      if name == "-u" then
        cmd[2] = "-u"
        cmd[3] = args[index + 1]
        u_found = true
      else
        cmd[4] = "-l"
        cmd[5] = args[index + 1]
        lua_found = true
      end
      args[index] = "" -- 清空
      args[index + 1] = ""
      if u_found and lua_found then
        break
      end
    end
  end
  if not lua_found then
    cmd[4] = "-l"
    cmd[5] = script_name
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
    name = "Attach to running Neovim instance. (Note: call launch server first)", -- 是nvim的環境，如果是其它的lua, 例如lua5.3, 這種它的require路徑不同
  },
  {
    type = 'none',
    name = "launch server",
    -- -- Note: 👇 可以這樣做，但是這樣就要再開一個nvim, 多此一舉，可以開一個終端，然後用--headless即可
    -- function()
    --   vim.pack.add({ "https://github.com/jbyuki/one-small-step-for-vimkind" }) -- 如果載入過了，其實就不需要了
    --   local input = vim.fn.input("args: ")
    --   arg = vim.split(input, "%s+", { trimempty = true, }) -- 相當於: _G.arg
    --
    --   require 'osv'.launch({ port = 8086, blocking = true, output = false, break_on_exception = true })
    --   local script_path = vim.fn.expand("%:p")
    --   vim.cmd("luafile " .. script_path)
    -- end,

    function()
      -- 其它的參考: https://gist.github.com/CarsonSlovoka/2df33947b47eae7376e2a29df43d81f3#file-debugger-runner-lua-L1-L31 👈 這是失敗的嘗試，留做參考

      -- nvim --headless \
      --   -u "$HOME/myinit.lua" \
      --   -c 'packadd one-small-step-for-vimkind' \
      --   -c "lua require('osv').launch({
      --     port = 8086,
      --     blocking = true,
      --     output = true,  -- output 如果為false. DapUIrepl 視窗將不會有內容
      --     break_on_exception = true,
      --   })" \
      --   --cmd "lua _G.arg = {'test.csv'}" \
      --   -c "lua dofile('my_script.lua')" \
      --   -c 'qa!' # 可不接，但是最後就卡著
      --   :lua require("osv").stop() -- 如果不是用 --headless 也可以這樣手動結束
      --  Note: 記得用--cmd 來日入 _G.arg 的參數，用-c沒用. 要用--cmd提前就告知

      local script_name = vim.fn.expand("%:t")
      vim.cmd("lcd %:h")

      vim.cmd("topleft new | term")
      vim.cmd("startinsert")

      local cmd = { "nvim",
        "--headless", -- 不用ui介面
        "-u", "NONE", -- 此為-u的保留
        "-c", "'packadd one-small-step-for-vimkind'",
        "-c", [[
      'lua require("osv").launch({
        port = 8086,
        blocking = true,
        output = true,
        break_on_exception = true,
      })']],
        "-c", string.format("'lua dofile(%q)'", script_name),
      }
      local args = utils.dap.ask_args()
      print(vim.inspect(args))
      for index, name in ipairs(args) do
        if name == "-u" then
          -- cmd[3] = "-u"
          cmd[4] = vim.fn.fnamemodify(args[index + 1], ":p")
          args[index] = "" -- 清空. Warn: 不要設定成nil, 會影響到其它的元素
          args[index + 1] = ""
          break
        end
      end

      args = vim.iter(args):filter(function(v) return v ~= "" end):totable() -- 去除空字串的元素

      table.insert(cmd,
        string.format([[--cmd 'lua _G.arg={%s}']], -- Caution: 一定要用--cmd來加入_G.arg的元素, 如果是用-c就已經太遲了
          table.concat(vim.tbl_map(function(v)
            -- if v == "" then return nil end -- array中設定nil會有影響, 結果不正確
            return string.format("%q", v)
          end, args), ", "))
      )
      table.insert(cmd, "-c 'qa!'")
      vim.api.nvim_input(string.format([[%s <CR>]], table.concat(cmd, " ")))
    end
  },
  get_local_cmd_item("lua5.1"),
  get_local_cmd_item("lua5.1", true),
  get_local_cmd_item("lua5.4"),
  get_local_cmd_item("lua5.4", true),
}
