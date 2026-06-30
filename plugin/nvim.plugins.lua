-- 這些內建plugin比較後面在載入, 讓一開始啟動比較快

-- :help plugins.txt
vim.defer_fn(function()
  vim.cmd("packadd nvim.difftool") -- :DiffTool {left_file} {right_file}  就不需要用兩次 :diffthis
  vim.cmd("packadd cfilter")       -- :Cfilter, :Lfilter
  -- vim.cmd("packadd justify")       -- v_j  -- 不好用, 使用 :!column 比較好
  vim.cmd("packadd nvim.undotree") -- 可以得到指令 :Undotree 可以開啟或關閉
  vim.cmd("packadd nvim.tohtml")   -- :TOhtml -- 預設會生成一個暫存的html檔案 也可以用參數指定生成的html位置


  -- == matchparen == 此插件預設啟用, 如果要
  -- help matchparen
  -- vim.g.loaded_matchparen = 0  -- 這個可能要找到很好的時機，不然有可能是先執行再被覆蓋，所以還是無效, 最好的辦法是用cmd去關
  -- :echo exists("g:loaded_matchparen")
  -- :NoMatchParen  -- 關閉
  -- :DoMatchParen  -- 再次啟用
end, 1000)
