; https://github.com/nvim-treesitter/nvim-treesitter/blob/42fc28ba918343ebfd5565147a42a26580579482/queries/bash/folds.scm#L1-L9

; 要是以下設定，此folds才會有作用
; vim.opt.foldmethod = "expr" 👈 可能要開始的時候再用一次 :set foldmethod=expr才行
; vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

; 對這些內容都能應用摺行
; [
;  (pair)
;  (comment)
; ] @fold

(
 (comment) @fold
 (#match? @fold "^/\\*") ; 只折 /** ... */ 多行註解
)

