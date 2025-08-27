-- :lua require("lspconfig").gopls.setup { settings = { gopls = { buildFlags = { "-tags=xxx" } } } } -- 👈 這招可行. (可再搭配 :e 來刷新)
vim.api.nvim_create_user_command("GoplsSetBuildFlags",
  function(args)
    -- local buildFlags = args.fargs
    local buildFlags = table.concat(args.fargs, ",") -- https://stackoverflow.com/a/64318502/9935654
    -- print(vim.inspect(buildFlags))
    require("lspconfig").gopls.setup { settings = { gopls = { buildFlags = { "-tags=" .. buildFlags } } } }
  end,
  {
    desc = "set build tags. 使查看變數定義能依據tags來跳轉",
    nargs = "?",
    complete = function(_, cmd_line)
      local argc = #(vim.split(cmd_line, "%s+")) - 1
      if argc == 1 then
        -- return { "-tags=default" }
        return { "default" }
      end
      return { "other" .. argc - 1 }
    end,
  }
)

-- 以下這些就不用寫了，直接return setup的對像即可
-- require("lspconfig").gopls.setup {
--   settings = {
--     gopls = {
--       buildFlags = { }
--     }
--   },
-- }


-- ../pack/lsp/start/nvim-lspconfig/lua/lspconfig/configs/gopls.lua
return {
  settings = {
    gopls = {
      -- :lua print(vim.inspect(vim.lsp.get_active_clients()))
      -- 已知在go專案新增.gopls.{lua, json, yml}這些都無效
      buildFlags = {
        -- "-tags=xxx"
      } -- 這影響編輯時候對變數有定義是抓取哪一個檔案為主
    }
  },
  -- on_attach = function(client, bunfr)
  --   print("hello", vim.inspect(client))
  -- end

  -- desc也可以寫，如此在 :checkhealth 中也可以看到該敘述
  --   docs = {
  --     description = [[
  -- ]],
  --   },
}
