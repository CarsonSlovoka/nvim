當在 [init.lua](../init.lua) 中使用

```lua
vim.lsp.enable('mylsp')
```

當換到相關的檔案，就會先抓 `$RUNTIMEPATH/lsp/mylsp` 如果這個項目有就會優先執行

> [!NOTE]
> 也可以直接用 `:checkhealth` 不需要換到該檔案，也可以確認lsp到底有沒有加成功

如果沒有，則會用 `lspconfig.configs.mylsp` 來當作參考,


如果不曉得內容可以寫什麼可以參考nvim-lspconfig裡面的設定, 例如:

- [lua/lspconfig/configs/pyright.lua](https://github.com/neovim/nvim-lspconfig/blob/3d97ec4174bcc750d70718ddedabf150536a5891/lua/lspconfig/configs/pyright.lua#L1-L80): 裡面會用到require, 所以如果你想要直接複製裡頭的內容，還會需要將require相關的東西也包含在那，所幸在[lsp](https://github.com/neovim/nvim-lspconfig/tree/44201a9/lsp)的目錄有解開後的版本
- [lsp/pyright.lua](https://github.com/neovim/nvim-lspconfig/blob/3d97ec4174bcc750d70718ddedabf150536a5891/lsp/pyright.lua#L1-L59): 這個是如果使用nvim-lspconfig時，真正會用的設定, 因該是把相require的內容解開之後，輸出的結果，使人可以直接複製這裡面的設定

> [!CAUTION]
> 從nvim 0.11之後，已經有內建lsp, 可以不需要再使用[nvim-lspconfig](https://github.com/neovim/nvim-lspconfig/)這個插件
>
> 如果使用了，那麼它的設定會強至取代掉[return](gopls.lua)的結果, 導致設定不如預期

