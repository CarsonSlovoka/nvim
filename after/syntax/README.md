# syntax參考寫法

> [!TIP]
> 善用`:Inspect`來觀察使用的顏色！

> https://github.com/neovim/neovim/tree/304a9ba/runtime/syntax


```vim
" syn keyword: 完全匹配，不需要正則表達式
" nextgroup 表示在其之後會預期出現一個項目
syn keyword a2psPreProc Include nextgroup=a2psKeywordColon " Include 之後要接 a2psKeywordColon 所定義的內容，這裡為 ':'
syn keyword a2psMacro UserOption nextgroup=a2psKeywordColon

" sync keyword KEV value1, value2, ... " 如果有很多關鍵字時，可以連著打
syn keyword a2psKeyword LibraryPath AppendLibraryPath PrependLibraryPath Options Medium Printer UnknownPrinter DefaultPrinter OutputFirstLine PageLabelFormat Delegation FileCommand nextgroup=a2psKeywordColon

" syn match GROUP_NAME contained display TEXT
" display 可能與是否摺疊有關
syn match a2psKeywordColon contained display ':' " 對上之前的nextgroup

syn keyword a2psKeyword Variable nextgroup=a2psVariableColon
syn match a2psVariableColon contained display ':' nextgroup=a2psVariable skipwhite " skipwhite允許之間有空格或製表符

syn match a2psVariable contained display '[^ \t:(){}]\+' contains=a2psVarPrefix
syn region a2psString display oneline start=+'+ end=+'+ contains=a2psSubst
syn region a2psString display oneline start=+"+ end=+"+ contains=a2psSubst
syn keyword a2psTodo contained TODO FIXME XXX NOTE
syn region a2psComment display oneline start='^\s*#' end='$' contains=a2psTodo,@Spell
```

# 目錄結構

- 單檔案: 可以將單一檔案依照 其filetype 直接放到本目錄，而不需要再建立 該filetype 的子目錄，例如: [qf.lua](qf.lua)
- 目錄: 如果該filetype比較複雜，是可以建立其filetype的目錄，在filetype與其對應時，會自動將該目錄所有的lua都載入

    例如: [strings](./strings)

