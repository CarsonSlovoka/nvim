; 前面是grammar.js所定義的rules的關鍵字; 後方則是nvim上所定義的高亮, 值得一提的是高亮的名稱一定要用@來開頭
(string) @string
; vim.api.nvim_set_hl(0, "@YellowBold", { fg = "#000000", bg = "#ffff00", bold = true, italic = true })
; (string) @YellowBold

; 記得 :Inspect 可以用來查看突顯的資訊

; :help treesitter.txt

(comment) @comment
(pair) @pair
"=" @label
";" @punctuation.delimiter
