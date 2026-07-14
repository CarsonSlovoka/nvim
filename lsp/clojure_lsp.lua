-- Note: 目前沒有使用到，如果要用要在vim.lsp.enable新增此項目才會有用: `git show -p 6813150b66c60583213f363634cb77c28fe30e8a:plugin/lspconfig.lua | bat -l lua -P -r 134:152`

-- https://github.com/neovim/nvim-lspconfig/blob/d5b6e3db4c17b0146f63a2fc47e2027a754b2cb1/lsp/clojure_lsp.lua#L1-L12
-- https://github.com/clojure-lsp/clojure-lsp
-- https://clojure-lsp.io/installation/

---@brief
---
--- https://github.com/clojure-lsp/clojure-lsp
---
--- Clojure Language Server

---@type vim.lsp.Config
return {
  cmd = { 'clojure-lsp' },
  filetypes = { 'clojure', 'edn' },
  root_markers = { 'project.clj', 'deps.edn', 'build.boot', 'shadow-cljs.edn', '.git', 'bb.edn' },
}
