--- cmd.lua 此腳本的內容用來幫助nvim_create_user_command, nvim_create_autocmd等內容


local osUtils = require("utils.os")

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

--- 返回echo字串，前後可以給上空行的數量
--- @param startLn number
--- @param msg string
--- @param endLn number
--- @return string
function M.echoMsg(startLn, msg, endLn)
  if osUtils.IsWindows then
    -- echo. & echo. & echo msg & echo. & echo .
    local prefix = ""
    -- :lua print(string.sub(string.rep("echo. & ", 2), 1, -3)) -- sub和rep對空字串這樣都不會有問題，得到空字串而已, 只是還是考量&的串接所以還是要判別有沒有給startLn, endLn
    if startLn > 0 then
      prefix = string.rep("echo. & ", startLn)
      if #msg == 0 and endLn == 0 then
        return string.sub(string.rep("echo. & ", startLn), 1, -3) -- 之所以用sub是不要最後的&, 如果是1, -2表示不要最後一個, 而用1, -3是因為我們最後還有多一個空白
      end
    end
    local suffix = ""
    if endLn > 0 then
      if #msg > 0 or #prefix > 0 then
        suffix = " & "
      end
      suffix = suffix .. string.sub(string.rep("echo. & ", endLn), 1, -3)
    end
    return prefix .. " echo " .. msg .. suffix
  end

  -- 'echo -e "\\n\\n msg  \\n\\n"',
  return string.format('echo -e "%s%s%s"',
    string.rep("\\n", startLn),
    msg,
    string.rep("\\n", endLn)
  )
end

function M.is_qf_open()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    -- local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
    -- if buftype == "quickfix" then -- 寫成這樣可行
    if vim.bo[buf].buftype == "quickfix" then -- 不過用這種寫法比較乾淨
      return true
    end
  end
  return false
end

function M.open_qflist_if_not_open()
  if not M.is_qf_open() then
    vim.cmd("copen")
  end
end

return M
