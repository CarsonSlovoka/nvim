-- 這些內建plugin比較後面在載入, 讓一開始啟動比較快

-- :help plugins.txt
vim.defer_fn(function()
  vim.cmd("packadd nvim.difftool") -- :DiffTool {left_file} {right_file}  就不需要用兩次 :diffthis
  vim.cmd("packadd cfilter")       -- :Cfilter, :Lfilter
  -- vim.cmd("packadd justify")       -- v_j  -- 不好用, 使用 :!column 比較好
  vim.cmd("packadd nvim.undotree") -- 可以得到指令 :Undotree 可以開啟或關閉
  vim.cmd("packadd nvim.tohtml")   -- :TOhtml -- 預設會生成一個暫存的html檔案 也可以用參數指定生成的html位置
end, 1000)
