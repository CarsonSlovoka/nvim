-- https://github.com/neovim/nvim-lspconfig/blob/3d97ec4174bcc750d70718ddedabf150536a5891/lua/lspconfig/configs/jsonls.lua
-- https://github.com/neovim/nvim-lspconfig/blob/3d97ec4174bcc750d70718ddedabf150536a5891/lsp/jsonls.lua

---@brief
---
--- https://github.com/hrsh7th/vscode-langservers-extracted
---
--- vscode-json-language-server, a language server for JSON and JSON schema
---
--- `vscode-json-language-server` can be installed via `npm`:
--- ```sh
--- npm i -g vscode-langservers-extracted
--- ```
---
--- `vscode-json-language-server` only provides completions when snippet support is enabled. If you use Neovim older than v0.10 you need to enable completion, install a snippet plugin and add the following override to your language client capabilities during setup.
---
--- ```lua
--- --Enable (broadcasting) snippet capability for completion
--- local capabilities = vim.lsp.protocol.make_client_capabilities()
--- capabilities.textDocument.completion.completionItem.snippetSupport = true
---
--- vim.lsp.config('jsonls', {
---   capabilities = capabilities,
--- })
--- ```

---@type vim.lsp.Config
return {
  -- 能依據 $schema 去驗證欄位正確性
  cmd = { 'vscode-json-language-server', '--stdio' },
  filetypes = { 'json', 'jsonc' },
  init_options = {
    provideFormatter = true,
  },
  root_markers = { '.git' },

  on_new_config = function(new_config)
    -- Node.js 的憑證庫變更： 如果您最近透過 brew upgrade 更新了 Node.js，新版本的安全機制可能收緊了，或者它不再預設去讀取 macOS 系統鑰匙圈（Keychain）裡的憑證，導致它在發起 HTTPS 請求時找不到信任的根憑證（CA）
    new_config.env = new_config.env or {}
    new_config.env.NODE_TLS_REJECT_UNAUTHORIZED = os.getenv("NODE_TLS_REJECT_UNAUTHORIZED") -- 解決 jsonc 中的警告: Unable to load schema from 'https://opencode.ai/config.json': unable to get local issuer certificate.
    -- export NODE_EXTRA_CA_CERTS="/opt/homebrew/etc/ca-certificates/cert.pem"  👈 可以在 .zshrc 或者 .bashrc 等等之類的檔案寫上相關的環境變數即可
  end,
}
