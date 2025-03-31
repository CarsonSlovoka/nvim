> [!NOTE]
> 完整內容請查看: https://neovim.io/doc/user/news-0.11.html

# Mappings

- `grn`: 觸發: `vim.lsp.buf.rename()` 重新命名，例如當你有一個函數的名稱要改名，使用這個可以將相關的使用到的地方也重新命名
- `grr`: 觸發: `vim.lsp.buf.references()` 將所有的參考，寫入到quickfix列表中
- `gri`: `vim.lsp.buf.implementation()` 可以找到定義所在文件
- `gO`: `vim.lsp.buf.document_symbol()` 類似於`:Telescope lsp_docment_symbols`只是它是用quickfix list來呈現所有
- `gra`: `vim.lsp.buf.code_action()` 會有一個尋問的選擇可以選，例如在go語言下，如果有裝gopls. 它的選項是 `4: Browse documentation for func fmt.Print ` 可以在127.0.0.1的端口打開文檔幫助
- ⭐ `CTRL-S`: `vim.lsp.buf.signature_help()` 在**insert**下，使用此熱鍵可以幫助你曉得可以輸入哪些內容(例如function的參數是什麼，以及詳細的說明)
- `[q`: `:cp`
- `]q`: `:cn`
- `[<Space>` 在上方插入一列空行，類似於O，但是它可以不進入到insert模式
- `]<Space>` 在下方插入一列空行，類似於o，但是它可以不進入到insert模式

