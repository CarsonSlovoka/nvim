local osUtils = require("utils.os")

-- print("my lsp pyright")
local pyright_path
if osUtils.IsWindows then
  -- 透過powershell的gcm來找pyright.exe的路徑
  pyright_path = vim.fn.system('powershell -Command "(gcm pyright).Source"')
else
  pyright_path = vim.fn.expand('~/.pyenv/shims/pyright')
end
vim.g.lsp_pyright_path = pyright_path



-- require("lspconfig").pyright.setup {} -- legacy https://github.com/neovim/nvim-lspconfig/blob/81920264a264144bd075f7f48f0c4356fc2c6236/README.md?plain=1#L34-L41
-- vim.lsp.config('pyright',
--   require("lspconfig.configs.pyright")
-- ) -- 👆也不需要再用nvim-lspconfig這個套件

-- https://github.com/neovim/nvim-lspconfig/blob/3d97ec4174bcc750d70718ddedabf150536a5891/lua/lspconfig/configs/pyright.lua#L1-L80
-- https://github.com/neovim/nvim-lspconfig/blob/3d97ec4174bcc750d70718ddedabf150536a5891/lsp/pyright.lua#L1-L59


---@brief
---
--- https://github.com/microsoft/pyright
---
--- `pyright`, a static type checker and language server for python


local function set_python_path(path)
  local clients = vim.lsp.get_clients {
    bufnr = vim.api.nvim_get_current_buf(),
    name = 'pyright',
  }
  for _, client in ipairs(clients) do
    if client.settings then
      client.settings.python = vim.tbl_deep_extend('force', client.settings.python, { pythonPath = path })
    else
      client.config.settings = vim.tbl_deep_extend('force', client.config.settings, { python = { pythonPath = path } })
    end
    client:notify('workspace/didChangeConfiguration', { settings = nil })
  end
end


---@type vim.lsp.Config
return {
  cmd = { 'pyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = {
    'pyproject.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt',
    'Pipfile',
    'pyrightconfig.json',
    '.git',
  },
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = 'openFilesOnly',
      },
    },
  },
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, 'LspPyrightOrganizeImports', function()
      client:exec_cmd({
        command = 'pyright.organizeimports',
        arguments = { vim.uri_from_bufnr(bufnr) },
      })
    end, {
      desc = 'Organize Imports',
    })
    vim.api.nvim_buf_create_user_command(bufnr, 'LspPyrightSetPythonPath', set_python_path, {
      desc = 'Reconfigure pyright with the provided python path',
      nargs = 1,
      complete = 'file',
    })
  end,
  desc = { description = "🔗 https://github.com/microsoft/pyright" }
}
