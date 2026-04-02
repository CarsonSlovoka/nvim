-- Important: 如果發現: `:checkhealth nvim-treesitter` 的H一直沒有打勾，可以嘗試: `TSUninstall all`之後重新，再讓它重新安裝所有項目即可

-- local function ts_disable(_, bufnr)
--   return vim.api.nvim_buf_line_count(bufnr) > 10000
-- end

-- ~/.local/share/nvim/site/pack/core/opt/nvim-treesitter/
require("nvim-treesitter").setup({
  -- `:lua print(vim.fn.stdpath('data') .. '/site')`
  -- ~/.local/share/nvim/site
  install_dir = vim.fn.stdpath("data") .. "/site",

  -- 👇 以下配置從 Neovim 0.12 + nvim-treesitter main 開始不再有效
  -- highlight = {
  --   enable = true,
  --   additional_vim_regex_highlighting = false,
  --   -- disable = function(_, bufnr)
  --   --   return ts_disable(_, bufnr)
  --   -- end,
  -- },
  -- indent = { enable = true },
  -- fold = {
  --   -- vim.opt.foldmethod = "expr"
  --   -- vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
  --   enable = true,
  -- }
})

local parsers = {
  "bash",
  "lua",
  "go", "gotmpl",
  "python",

  "xml",
  "css",

  "json",
  -- "jsonc",

  "markdown",
  "markdown_inline",
  "dart",
  "elixir",
  "sql",
  "diff",
  "html",
  "latex",
  "yaml",
  "javascript",

  "jsdoc",
  "regex",

  "ssh_config",
  "typescript",
}

require("nvim-treesitter").install(parsers):wait(300000)

vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    if pcall(vim.treesitter.start, args.buf) then
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end
})


-- vim.api.nvim_create_autocmd('FileType', {
--   pattern = { '<filetype>' },
--   callback = function() vim.treesitter.start() end,
-- })
