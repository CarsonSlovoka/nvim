-- 🧙 如果有用nvim-treesitter裝相關的語法，預設它的突顯會在此ftplugin之上

-- --- @type table
-- local treesitter_list = require("nvim-treesitter.parsers").get_parser_configs()
-- :lua print(require("nvim-treesitter.parsers").get_parser_configs().strings)

-- 避免重複定義
-- 如果已經有用treesitter裝相關的語法也不再執行此腳本
if vim.b.current_syntax
-- or treesitter_list.strings ~= nil -- 就個不準，如果有設定，只是用 :TSUninstall strings 去解除，那麼雖然沒裝了，但是設定檔還是在
then
  return
end

-- We need nocompatible mode in order to continue lines with backslashes.
-- Original setting will be restored.
-- 先增加vim, 之後再調整回來
local cpo_save = vim.o.cpo
vim.o.cpo = vim.o.cpo .. 'vim'

-- 👇 以下的方法可行，但是如果split視窗，高亮會不見，要用 :e 來刷新才可以
-- vim.fn.matchadd("stringsKey", [[^"\zs.*\ze"]])
-- vim.fn.matchadd("stringsValue", [[^".*"\s*=\s*"\zs.*\ze";]])


-- number
vim.cmd([[
  " integer number
  " \< 與 \> 為單同邊界，不會匹配到 ab123 或 123ab
  syn match stringsNumber "\<\d\+\>"
  " floating point number, with dot, optional exponent
  syn match stringsNumber  "\<\d\+\.\d*\%([eE][-+]\=\d\+\)\="
  " floating point number, starting with a dot, optional exponent
  syn match stringsNumber  "\.\d\+\%([eE][-+]\=\d\+\)\=\>"
  " floating point number, without dot, with exponent
  syn match stringsNumber  "\<\d\+[eE][-+]\=\d\+\>"
]])

-- 若字串可能跨行，就不要加 oneline
-- 在單行又想要用region的情況下(用它的start, end)此時可用online增加效能
vim.cmd([[
  syntax region stringsHex display oneline start=/0x/ end=/[^0-9A-Fa-f]/ contains=NONE
]])
vim.api.nvim_set_hl(0, 'stringsHex', { link = "stringsNumber" })

vim.cmd([[
  syn match stringsPlaceholder "%@"
  syn match stringsPlaceholder /\\n/
]])

vim.cmd([[
  syntax match stringsKey   /^\s*"\zs[^"]\+\ze"\s*=/
  syntax match stringsEqual /=/
  syntax match stringsAlpha /[a-zA-Z]/
  syntax match stringsValue /"\zs[^"]\+\ze"\s*;/ contains=stringsPlaceholder,stringsNumber,stringsAlpha,stringsHex
]])

-- @Spell 會做拼字檢查
-- contains允許match之中包含其它的高亮
-- contains可接keyword的內group或者其它的match的group都行
vim.cmd([[
  syn keyword stringsTodo            contained FIXME todo
  syn match   stringsComment "^\s*//.*$" contains=stringsTodo,@Spell
]])

-- region可以做多列的判斷
vim.cmd([[
  syn region stringsComment start=/^\s*\/\*/ end=/\*\// contains=stringsTodo,@Spell
]])

-- 如果沒有用oneline，那麼end的;可能會批配到其它的列的; 就會導致這些列的範圍都會被當成stringsLine
vim.cmd([[
  syn region stringsLine display oneline start=/"[^0-9 \t]\+.*"\s*=\s*".*"/ end=/;/ contains=stringsKey,stringsEqual,stringsValue
]])
-- vim.cmd([[
--   syn match stringsComment contained display '[="]\+'
-- ]])


vim.cmd([[
  " 開頭不是"或\
  syn match stringsErrorLine /^\s*[^"\/].*/ contains=stringsComment

  " 結尾不是;
  syn match stringsErrorLine /[^;]$/ contains=stringsComment

  " 沒有=號
  " syn match stringsErrorLine /[^=]+/ contains=stringsComment,stringsLine 切記！+也要用跳脫字元才有效！
  syn match stringsErrorLine /[^=]\+/ contains=stringsComment,stringsLine
]])

-- 設定 highlight 顏色
vim.api.nvim_set_hl(0, 'stringsKey', {
  fg = "#00aaff",
  -- bg = "#0022aa"
})
vim.api.nvim_set_hl(0, 'stringsEqual', { fg = "#aaaaaa" })
vim.api.nvim_set_hl(0, 'stringsNumber', { fg = "#ffff00" })
vim.api.nvim_set_hl(0, 'stringsPlaceholder', { fg = "#ffa657" })
vim.api.nvim_set_hl(0, 'stringsAlpha', { fg = "#79c7f3" })
vim.api.nvim_set_hl(0, 'stringsValue', { fg = "#ffffff" })
vim.api.nvim_set_hl(0, 'stringsLine', {
  fg = "#aaaaaa",
  -- bg = "#112233"
})
vim.api.nvim_set_hl(0, 'stringsErrorLine', { bg = "#ff0000", strikethrough = true })


vim.api.nvim_set_hl(0, 'stringsTodo', { fg = "#33ff00" })
vim.api.nvim_set_hl(0, 'stringsComment', { fg = "#888888", italic = true })



-- Set the current syntax for the buffer 呼應一開始的b.current_syntax 如此避免重覆定義
vim.b.current_syntax = 'strings'

-- Restore 'cpo' option
vim.o.cpo = cpo_save
