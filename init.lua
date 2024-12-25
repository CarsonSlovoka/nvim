local HOME = os.getenv("HOME")

-- runtimepath
local runtimepath = vim.api.nvim_get_option("runtimepath")
vim.opt.runtimepath = runtimepath .. ",~/.vim,~/.vim/after"
vim.opt.packpath = vim.opt.runtimepath:get()

-- python
vim.g.python3_host_prog = vim.fn.expand("~/.pyenv/versions/neovim3/bin/python")

-- vim
local vimrcPath = HOME .. "/.vimrc"
if vim.fn.filereadable(vimrcPath) == 1 then
    vim.cmd("source " .. vimrcPath)
end

-- config
require("config.options").setup()
require("config.keymaps").setup()
require("config.commands").setup()

-- pack/syntax/start/nvim-treesitter
require'nvim-treesitter.configs'.setup { -- pack/syntax/start/nvim-treesitter/lua/configs.lua
    ensure_installed = {
        "lua",
        "go",
        "markdown", "markdown_inline" },
    highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
    }
}

local lspconfig = require'lspconfig'
lspconfig.pyright.setup{}
vim.g.lsp_pyright_path = vim.fn.expand('~/.pyenv/shims/pyright')
lspconfig.gopls.setup{}
-- lspconfig.tsserver.setup{}
