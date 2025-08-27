-- https://github.com/neovim/nvim-lspconfig/blob/3d97ec4174bcc750d70718ddedabf150536a5891/lua/lspconfig/configs/sqls.lua
-- https://github.com/neovim/nvim-lspconfig/blob/3d97ec4174bcc750d70718ddedabf150536a5891/lsp/sqls.lua

local utils = require("utils.utils")

local default_config = {
  cmd = {
    -- go install github.com/sqls-server/sqls@latest
    'sqls'
  },
  filetypes = { 'sql', 'mysql' },
  root_markers = { 'config.yml' },
  on_attach = function(client, bufnr)
    -- https://github.com/nanotee/sqls.nvim/blob/d1bc5421ef3e8edc5101e37edbb7de6639207a09/README.md?plain=1#L35-L40
    require('sqls').on_attach(client, bufnr)
  end,
  settings = { -- :lua print(vim.inspect(require("lspconfig").sqls.manager.config.settings))
    sqls = {
      -- https://github.com/sqls-server/sqls/blob/efe7f66d16e9479e242d3876c2a4a878ee190568/README.md?plain=1#L184-L202
      connections = {
        -- { -- 可以透過 :SqlsInsertConnecions 來新增
        --   driver = 'sqlite3',
        --   -- sqlite3 ~/database.db
        --   dataSourceName = vim.fn.expand('~/database.sqlite3'),
        -- },
      },
    },
  },
}

local accept_data_source_names = {
  sqlite = true,
  sqlite3 = true,
  db = true,
}
vim.api.nvim_create_user_command('SqlsInsertConn',
  function(args)
    if #args.fargs ~= 2 then
      vim.notify("#para ~= 2. :SqlsInsertConnecions sqlite3 my.db", vim.log.levels.ERROR)
      return
    end
    local dataSourceName = vim.fn.fnamemodify(vim.fn.expand(args.fargs[2]), ":p") -- 轉為絕對路徑

    -- local connections = require("lspconfig").sqls.manager.config.settings.sqls.connections -- 沒有辦法只改變這個就有用
    local connections = {
      { -- 將新增加的項目放在第一筆，如此 :SqlsSwitchConnection 直接選1即可
        driver = args.fargs[1],
        dataSourceName = dataSourceName,
      }
    } -- 所以重新加入

    -- for _, conn in ipairs(require("lspconfig").sqls.manager.config.settings.sqls.connections) do
    --   table.insert(connections, conn)
    -- end

    default_config.settings.sqls.connections = connections

    vim.lsp.config('sqls', default_config)
  end,
  {
    desc = "sqls.connections.insert(driver, dataSourceName))",
    nargs = "+",
    complete = function(arg_lead, cmd_line)
      local argc = #(vim.split(cmd_line, "%s+")) - 1
      if argc == 1 then
        return { "sqlite3" }
      end

      local all_files = vim.fn.getcompletion(vim.fn.expand(arg_lead), "file")
      return vim.tbl_filter(
        function(path)
          return accept_data_source_names[string.lower(vim.fn.fnamemodify(path, ":e"))] or
              vim.fn.isdirectory(path) == 1 -- 目錄
        end,
        utils.table.sort_files_first(all_files)
      )
    end
  }
)


---@brief
---
--- https://github.com/sqls-server/sqls
---
--- ```lua
--- vim.lsp.config('sqls', {
---   cmd = {"path/to/command", "-config", "path/to/config.yml"};
---   ...
--- })
--- ```
--- Sqls can be installed via `go install github.com/sqls-server/sqls@latest`. Instructions for compiling Sqls from the source can be found at [sqls-server/sqls](https://github.com/sqls-server/sqls).

---@type vim.lsp.Config
return default_config
