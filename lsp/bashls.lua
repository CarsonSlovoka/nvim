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
        path = "shfmt",        -- 指定 shfmt 執行檔路徑 -- 如果沒有這個檔案不會報錯
        indent = 2,            -- 縮進使用 2 個空格 (好像沒有這個選項，預設看的是 tabstop )
        caseIndent = true,     -- 啟用 case 分支縮進
        binaryNextLine = true, -- 換行時運算子置於行首
      },
    },
  },
  filetypes = { 'bash', 'sh' },
  root_markers = { '.git' },
  -- offset_encoding = "utf-8", -- 加了在大檔案還是會遇到保存後出現亂碼的問題

  on_attach = function(client, bufnr)
    -- 如果是大的bash檔案(超過5000行)就手動格式化(可避免亂碼的問題)
    if vim.api.nvim_buf_line_count(bufnr) >= 5000 then
      client.server_capabilities.documentFormattingProvider = false
      vim.bo.equalprg = ""
      vim.keymap.set('n', '<leader>fmt', function()
        vim.cmd('normal! m"')
        vim.cmd('%!shfmt -i 2 -ci -bn')
        vim.cmd('normal! `"')
      end, {
        buffer = bufnr,
        desc = 'Format shell using shfmt',
      })
    else
      client.server_capabilities.documentFormattingProvider = true
    end
  end,
}
