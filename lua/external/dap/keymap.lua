local dap = require("dap")

vim.keymap.set("n", "<F5>", function()
    dap.continue() -- 首次出現的選單要靠執行這個
  end,
  { desc = "Start/Continue Debugging" }
)


for _, key in ipairs({
  -- 在Num Lock啟用與否會影響到熱鍵的判讀
  "<S-F5>", -- Num Lock: on
  "<F17>"   -- Num Lock: off
}) do
  vim.keymap.set("n", key, function()
    if vim.o.filetype == "lua" then
      require 'osv'.stop()
    end
    dap.terminate()
    require("dapui").close()    -- lua的dap沒有自動關掉，所以補上，並且dapui.close()就算已經關閉再次執行也不會有事
  end, { desc = "Stop debug" }) -- insert模式下用C-V之後可以按下想要的熱鍵，就會出現正確的對應
end


vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Step Over" })
vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Step Into" })
for _, key in ipairs({
  "<S-F11>", -- Num Lock: on
  "<F23>"    -- Num Lock: off
}) do
  vim.keymap.set("n", key, dap.step_out, { desc = "Step Out" })
end


vim.keymap.set("n", "<F9>", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Open Debug REPL" })
vim.keymap.set("n", "<C-S-j>", dap.down, { desc = "[dap] moving down the call stack" }) -- :lua require("dap").down()
vim.keymap.set("n", "<C-S-k>", dap.up, { desc = "[dap] moving up the call stack" })


dap.listeners.after.event_initialized["dapui_config"] = function()
  require("dapui").open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  require("dapui").close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  require("dapui").close()
end
