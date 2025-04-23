-- :help sign_define

vim.fn.sign_define("DapBreakpoint",
  {
    text = "🔴", -- 
    -- texthl = "Green", -- 非文本，而是指sign的text也就是🔴的顏色(背景色)
    linehl = "@breakpoint",
    -- curhl = "YellowBold", -- 🤔 尚不清楚有什麼用，都沒看到效果
    -- numhl = "" -- 左邊列號的顏色
  }
)

-- vim.keymap.set("n", "<leader>test", function()
--   -- 在第 5 行放置標記
--   vim.fn.sign_place(0, 'myTestGroup', 'DapBreakpoint', vim.api.nvim_get_current_buf(), { lnum = 5 })
-- end, { desc = "test only" })


vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "Function", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointRejected", { text = "🚫", texthl = "Comment", linehl = "Comment", numhl = "" }) -- 無法被debug到，例如在上面已經return了
vim.fn.sign_define("DapStopped", { text = "👉", texthl = "String", linehl = "@onbreakpoint", numhl = "Bold" })
