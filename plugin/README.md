在此目錄的lua都會被自動執行

# Plugin

## 載入時機

當使用 `nvim -u my_init.lua -l myscript.lua` 時

其實都會載入`~/.config/nvim/plugin/`目錄中的內容，不過會先載入-u的init才會開始陸續plugin的內容

因此如果是一些平常-l使都不會用到的插件，建議不要寫在此目錄中，或者用`vim.g`的方式，判別有設定才會載入之類的

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

## Update

> nvim -u NORC -l update.lua

```lua
-- update.lua
vim.pack.update({
    "nvim-treesitter",
    "nvim-treesitter-context",
    "nvim-treesitter-textobjects",
  },
  {
    -- force = true,     -- ❗ 這很重要，如果要用nvim -l的方式跑，少了confirm會只有fetch不會主動checkout過去❗
    -- offline = true,   -- 如果已經clone下來了, 就可以不需要網路. 預設是false
    target = "lockfile", -- 或者指定的版本. 所以先在 ../nvim-pack-lock.json 中寫好要的rev版本即可
  }
)
```

> [!WARNING] 當不用-l的方式跑，也就是在nvim使用中，貼上命令. 有用ssh時會遇到: `Permission denied (publickey)`的錯誤
>
> 而加了`force = true` 時，會沒有看到錯誤，但實際上也是沒有成功的
