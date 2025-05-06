-- 🧙 每次開啟filetype為qf的時候，都會觸發. 即每次 :copen 都會觸發整個腳本的內容
-- print("qf test")
--
-- https://neovim.io/doc/user/quickfix.html
-- When the quickfix window has been filled, two autocommand events are
-- triggered.  First the 'filetype' option is set to "qf"

-- vim.cmd([[ syntax match YellowBold /init/ ]]) -- 在一般的文件下可行，即: syntax match YellowBold /init/
-- :lua print(vim.fn.matchadd("YellowBold", [[init]])) -- ok -- 返回id，此id可以用matchdelete來移除
-- vim.fn.matchdelete(1510) -- 一次只能刪一筆，可以用 clearmatches(win_id) 來刪全部

local win_id = vim.api.nvim_get_current_win()
local ns_id = vim.api.nvim_create_namespace("qf_highlight_" .. win_id)
-- local buf_id = vim.api.nvim_win_get_buf(win_id)

-- 避免使用全域的定義，可能影響到一些自定義項
-- vim.api.nvim_set_hl(0, "YellowBold", { fg = "#b38bfd" })
-- vim.api.nvim_set_hl(0, "YellowBold", { fg = "#b38bfd" })
-- vim.api.nvim_set_hl(0, "HLLine", { fg = "#3fb440" })

vim.api.nvim_set_hl(ns_id, "HLFilepath", { fg = "#b38bfd" })
vim.api.nvim_set_hl(ns_id, "HLLine", { fg = "#3fb440" })
vim.api.nvim_win_set_hl_ns(win_id, ns_id)

-- vim.fn.matchadd("@constant.html", [[^\s*.*\ze:\d\+:\d\+]]) -- @constant.html, @attribute是第三方所定義，我想設定成和vimgrep相同的突顯
-- vim.fn.matchadd("@attribute", [[^\s*.*:\zs\d\+\ze:\d\+]])

vim.fn.matchadd("Normal", [[.*]], 0, -1, { window = win_id })                      -- 先統一不做特別的突顯
vim.fn.matchadd("HLFilepath", [[^\s*.*\ze:\d\+:\d\+]],                             -- filepath
  10,                                                                              -- priority 預設就為10, 數值越高，越不容易被覆蓋
  -1,                                                                              -- id是正整數，其中1, 2, 3是保留的，指的是 :match, :2match, :3match; id如果沒給或設定為-1，將自動生成一個ID(至少從1000起跳)
  { window = win_id }                                                              -- window也可以不用指派，如果沒有定義的group不存在就不突顯而已
)
vim.fn.matchadd("HLLine", [[^\s*.*:\zs\d\+\ze:\d\+]], 10, -1, { window = win_id }) -- line
