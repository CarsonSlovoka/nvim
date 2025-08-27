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
vim.lsp.config('pyright',
  require("lspconfig.configs.pyright") -- 預設用的cmd為pyright-langserver --stdio
)                                      -- https://github.com/neovim/nvim-lspconfig/blob/ecb74c22b4a6c41162153f77e73d4ef645fedfa0/lsp/pyright.lua#L36-L67
-- https://github.com/neovim/nvim-lspconfig/blob/81920264a264144bd075f7f48f0c4356fc2c6236/README.md?plain=1#L108-L120
