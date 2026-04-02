-- local function ts_disable(_, bufnr)
--   return vim.api.nvim_buf_line_count(bufnr) > 10000
-- end

require("nvim-treesitter").setup({
  -- `:lua print(vim.fn.stdpath('data') .. '/site/pack/core/opt/')`
  -- ~/.local/share/nvim/site/pack/core/opt/
  install_dir = vim.fn.stdpath("data") .. "/site",
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
    -- disable = function(_, bufnr)
    --   return ts_disable(_, bufnr)
    -- end,
  },
  indent = { enable = true },
  fold = {
    -- vim.opt.foldmethod = "expr"
    -- vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
    enable = true,
  }
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
