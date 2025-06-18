> 根據: [treesitter.txt](https://github.com/neovim/neovim/blob/3b85046ed5f257cdd16aba32a95ac7d4849293b0/runtime/doc/treesitter.txt#L76-L78)

此目錄結構要是如此

```
queries/xxx/highlights.scm
```

其中xxx之應的是定義的語法名稱

例如[strings/highlights.scm](strings/highlights.scm)

# checkhealth

```
Parser/Features         H L F I J
  - bash                ✓ ✓ ✓ . ✓
  - c                   ✓ ✓ ✓ ✓ ✓
  - go                  ✓ ✓ ✓ ✓ ✓
  - gotmpl              ✓ ✓ ✓ . ✓
  - javascript          ✓ ✓ ✓ ✓ ✓
  - lua                 ✓ ✓ ✓ ✓ ✓
  - markdown            ✓ . ✓ ✓ ✓
  - markdown_inline     ✓ . . . ✓
  - query               ✓ ✓ ✓ ✓ ✓
  - strings             ✓ ✓ ✓ ✓ ✓
  - vim                 ✓ ✓ ✓ . ✓
  - vimdoc              ✓ . . . ✓

  Legend: H[ighlight], L[ocals], F[olds], I[ndents], In[j]ections
         +) multiple parsers found, only one will be used
         x) errors found in the query, try to run :TSUpdate {lang} ~
```

- H: [highlights.scm](strings/highlights.scm)
- L: [locals.scm](strings/locals.scm)
- F: [folds.scm](strings/folds.scm)
- I: [indents.scm](strings/indents.scm)
- In: [injections.scm](strings/injections.scm)

只要有相對應的scm檔案，該項目就會被打勾`✓`
