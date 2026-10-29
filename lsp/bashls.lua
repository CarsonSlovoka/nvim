-- https://github.com/neovim/nvim-lspconfig/blob/3d97ec4174bcc750d70718ddedabf150536a5891/lua/lspconfig/configs/bashls.lua
-- https://github.com/neovim/nvim-lspconfig/blob/3d97ec4174bcc750d70718ddedabf150536a5891/lsp/bashls.lua

---@brief
---
--- https://github.com/bash-lsp/bash-language-server
---
--- `bash-language-server` can be installed via `npm`:
--- ```sh
--- npm i -g bash-language-server
--- ```
---
--- Language server for bash, written using tree sitter in typescript.

---@type vim.lsp.Config
return {
  cmd = { 'bash-language-server', 'start' },
  settings = {
    bashIde = {
      -- Glob pattern for finding and parsing shell script files in the workspace.
      -- Used by the background analysis features across files.

      -- Prevent recursive scanning which will cause issues when opening a file
      -- directly in the home directory (e.g. ~/foo.sh).
      --
      -- Default upstream pattern is "**/*@(.sh|.inc|.bash|.command)".
      globPattern = vim.env.GLOB_PATTERN or '*@(.sh|.inc|.bash|.command)',

      -- go install mvdan.cc/sh/v3/cmd/shfmt@latest
      shfmt = {
        path = "shfmt",         -- 指定 shfmt 執行檔路徑 -- 如果沒有這個檔案不會報錯
        indent = 2,             -- 縮進使用 2 個空格
        caseIndent = true,      -- 啟用 case 分支縮進
        binaryNextLine = true,  -- 換行時運算子置於行首
      },
    },
  },
  filetypes = { 'bash', 'sh' },
  root_markers = { '.git' },
}
