在此目錄的lua都會被自動執行


## Debug

可以用這樣的方式來觀察觸發的事件，來決定是否想要用該plugin

```vim
set verbosefile=~/temp.nvim.log | set verbose=9
set verbose=0  " 關閉
```

## 大量使用到 CursorMoved 的插件

### 內建插件

`:help plugins.txt`

- matchparen: 考慮用`:NoMatchParen`, `:DoMatchParen`來禁用或啟用

### 第三方Plugin

- [csvview](csvview.lua): 非csv的filetype也會觸發
- [nvim-treesitter-context](nvim-treesitter-context.lua)
- [nvim-treesitter-textobjects](nvim-treesitter-textobjects.lua)
- [lualine](lualine.lua)

若速度考量，可考慮不用這些插件

