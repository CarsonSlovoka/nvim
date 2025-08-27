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



-- https://github.com/neovim/nvim-lspconfig/blob/3d97ec4174bcc750d70718ddedabf150536a5891/lua/lspconfig/configs/gopls.lua#L5-L36
-- https://github.com/neovim/nvim-lspconfig/blob/3d97ec4174bcc750d70718ddedabf150536a5891/lsp/gopls.lua#L88-L99

---@brief
---
--- https://github.com/golang/tools/tree/master/gopls
---
--- Google's lsp server for golang.

--- @class go_dir_custom_args
---
--- @field envvar_id string
---
--- @field custom_subdir string?

local mod_cache = nil
local std_lib = nil

---@param custom_args go_dir_custom_args
---@param on_complete fun(dir: string | nil)
local function identify_go_dir(custom_args, on_complete)
  local cmd = { 'go', 'env', custom_args.envvar_id }
  vim.system(cmd, { text = true }, function(output)
    local res = vim.trim(output.stdout or '')
    if output.code == 0 and res ~= '' then
      if custom_args.custom_subdir and custom_args.custom_subdir ~= '' then
        res = res .. custom_args.custom_subdir
      end
      on_complete(res)
    else
      vim.schedule(function()
        vim.notify(
          ('[gopls] identify ' .. custom_args.envvar_id .. ' dir cmd failed with code %d: %s\n%s'):format(
            output.code,
            vim.inspect(cmd),
            output.stderr
          )
        )
      end)
      on_complete(nil)
    end
  end)
end

---@return string?
local function get_std_lib_dir()
  if std_lib and std_lib ~= '' then
    return std_lib
  end

  identify_go_dir({ envvar_id = 'GOROOT', custom_subdir = '/src' }, function(dir)
    if dir then
      std_lib = dir
    end
  end)
  return std_lib
end

---@return string?
local function get_mod_cache_dir()
  if mod_cache and mod_cache ~= '' then
    return mod_cache
  end

  identify_go_dir({ envvar_id = 'GOMODCACHE' }, function(dir)
    if dir then
      mod_cache = dir
    end
  end)
  return mod_cache
end

---@param fname string
---@return string?
local function get_root_dir(fname)
  if mod_cache and fname:sub(1, #mod_cache) == mod_cache then
    local clients = vim.lsp.get_clients({ name = 'gopls' })
    if #clients > 0 then
      return clients[#clients].config.root_dir
    end
  end
  if std_lib and fname:sub(1, #std_lib) == std_lib then
    local clients = vim.lsp.get_clients({ name = 'gopls' })
    if #clients > 0 then
      return clients[#clients].config.root_dir
    end
  end
  return vim.fs.root(fname, 'go.work') or vim.fs.root(fname, 'go.mod') or vim.fs.root(fname, '.git')
end

---@type vim.lsp.Config
return {
  cmd = { 'gopls' },
  filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    get_mod_cache_dir()
    get_std_lib_dir()
    -- see: https://github.com/neovim/nvim-lspconfig/issues/804
    on_dir(get_root_dir(fname))
  end,
  -- on_attach = function(client, bunfr) print("my gopls") end,
  desc = { description = "🔗 https://github.com/golang/tools/tree/master/gopls" }
}
