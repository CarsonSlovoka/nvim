當在 [init.lua](../init.lua) 中使用

```lua
vim.lsp.enable('mylsp')
```

當換到相關的檔案，就會先抓 `$RUNTIMEPATH/lsp/mylsp` 如果這個項目有就會優先執行

如果沒有，則會用 `lspconfig.configs.mylsp` 來當作參考,

例如: [lspconfig.configs.pyright](../pack/lsp/start/nvim-lspconfig/lua/lspconfig/configs/pyright.lua)

