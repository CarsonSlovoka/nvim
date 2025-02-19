local M = {}

--- @param helpMsgs table
function M.showHelpAtQuickFix(helpMsgs)
  local quickFixList = {}

  for idx, message in ipairs(helpMsgs) do
    table.insert(quickFixList, {
      text = message, -- 快速修復條目的訊息
      -- filename = '',     -- 如果有具體的檔案路徑，可以填入檔案名稱
      lnum = idx,     -- 其實也可以不用給
      -- bufnr = 0,
    })
  end

  -- 將 Quickfix 條目設定到 Quickfix 列表
  vim.fn.setqflist(quickFixList, 'r') -- 'r' 表示覆蓋當前列表
  vim.cmd('copen')
end

return M
