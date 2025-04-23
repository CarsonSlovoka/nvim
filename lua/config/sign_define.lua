-- :help sign_define
-- `:sign list` Lists all defined signs and their attributes.


local function sign_define_marks()
  -- vim.fn.sign_define("MarkPin1", { text = "0️⃣", }) -- 0️⃣ 這是由三個unicode碼點所主成: U+0030 U+FE0F U+20E3
  -- vim.fn.sign_define("MarkPina", { text = "a", })
  -- vim.fn.sign_define("MarkPinA", { text = "🇦", })
  for i = 0, 9 do -- sign_define 0️⃣, 1️⃣  .. 9️⃣
    -- 其中U+FE00-U+FE0f區間為變體選擇符(Variation Selectors)
    local text = vim.fn.nr2char(i + 48) .. string.format("️⃣") -- 從0x0030 (48) 開始，後面固定為U+FE0F U+20E3
    vim.fn.sign_define("MarkPin" .. i, { text = text, })
  end

  -- 定義小寫字母 a-z
  for i = 97, 122 do -- ASCII: a=97, z=122
    local letter = string.char(i)
    vim.fn.sign_define("MarkPin" .. letter, { text = letter, })
  end

  -- 定義大寫字母 🇦 🇧 .. 🇿
  for i = 0, 25 do -- ASCII: A=65, Z=90
    local letter = vim.fn.nr2char(0x41 + i)
    -- local text = string.char(0x1f1e6 + i) -- 不能超過0xffff樣
    local text = vim.fn.nr2char(0x1f1e6 + i)
    vim.fn.sign_define("MarkPin" .. letter, { text = text, })
  end

  local strRegs = '0123456789' ..
      'abcdefghijklmnopqrstuvwxyz' ..
      'ABCDEFGHIJKLMNOPQRSTUVWXYZ' ..
      '^' .. -- 前一次編輯的位置
      '<>'   -- < 選取的開始, > 選取的結束


  vim.fn.sign_define("MarkPin^", { text = "✍️" })
  vim.fn.sign_define("MarkPin<", { text = "<" })
  vim.fn.sign_define("MarkPin>", { text = ">" })
  local group = "carson_sign_mark_group" -- 前面補上我的名子，防止可能重覆的考量

  for i = 1, #strRegs do
    local mark = strRegs:sub(i, i)
    vim.keymap.set("n", "m" .. mark,
      function()
        local sign_id = vim.api.nvim_create_namespace(group .. "_" .. mark) -- 如果不存在會創鍵，如果已經存在就會得到該id

        -- 獲取當前列號
        local line = vim.api.nvim_win_get_cursor(0)[1]

        -- 清除該 mark 的舊 sign
        vim.fn.sign_unplace(group, { buffer = vim.fn.bufnr(), id = sign_id })

        -- 放置新 sign
        vim.fn.sign_place(sign_id, group, "MarkPin" .. mark, vim.fn.bufnr(), { lnum = line }) -- priority = 10

        -- 返回原始 mark 命令
        return "m" .. mark
      end,
      {
        desc = "mark " .. mark .. "(新增sign_define於列號旁)",
        expr = true,
        noremap = false,
      }
    )
  end
end

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

sign_define_marks()
