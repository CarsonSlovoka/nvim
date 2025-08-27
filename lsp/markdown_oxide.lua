-- https://github.com/neovim/nvim-lspconfig/blob/3d97ec4174bcc750d70718ddedabf150536a5891/lua/lspconfig/configs/markdown_oxide.lua
-- https://github.com/neovim/nvim-lspconfig/blob/3d97ec4174bcc750d70718ddedabf150536a5891/lsp/markdown_oxide.lua

local osUtils = require("utils.os")

---@brief
---
--- https://github.com/Feel-ix-343/markdown-oxide
---
--- Editor Agnostic PKM: you bring the text editor and we
--- bring the PKM.
---
--- Inspired by and compatible with Obsidian.
---
--- Check the readme to see how to properly setup.

---@param client vim.lsp.Client
---@param bufnr integer
---@param cmd string
local function command_factory(client, bufnr, cmd)
  return client:exec_cmd({
    title = ('Markdown-Oxide-%s'):format(cmd),
    command = 'jump',
    arguments = { cmd },
  }, { bufnr = bufnr })
end

---@type vim.lsp.Config
return {
  root_markers = { '.git', '.obsidian', '.moxide.toml' },
  filetypes = { 'markdown' },

  -- 請安裝rust後透過cargo來取得
  cmd = { osUtils.GetExePathFromHome("/.cargo/bin/markdown-oxide") }, -- 指定可執行檔的完整路徑

  on_attach = function(client, bufnr)
    for _, cmd in ipairs({ 'today', 'tomorrow', 'yesterday' }) do
      vim.api.nvim_buf_create_user_command(bufnr, 'Lsp' .. ('%s'):format(cmd:gsub('^%l', string.upper)), function()
        command_factory(client, bufnr, cmd)
      end, {
        desc = ('Open %s daily note'):format(cmd),
      })
    end
  end,
}
