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

  local qf_list = vim.fn.getqflist({ id = 0, all = 1 })
  -- 將 Quickfix 條目設定到 Quickfix 列表
  -- vim.fn.setqflist(quickFixList, 'r') -- 'r' 表示覆蓋當前列表, 這樣title也會被覆蓋
  vim.fn.setqflist({}, 'r', { title = qf_list.title, items = quickFixList, user_data = qf_list.user_data })

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

--- @deprecated 建議用`get_cmp_config`來取代
---
--- 得到補全的清單
--- @param argLead string
--- @param cmp_table table
function M.get_complete_list(argLead, cmp_table)
  local completions = {}
  if #argLead == 0 then
    for key in pairs(cmp_table) do
      table.insert(completions, "--" .. key)
    end
    return completions
  end

  -- 如果當前輸入的是選項名稱（以 -- 開頭但還沒到 =）
  if argLead:match("^%-%-") and not argLead:match("=") then
    for key in pairs(cmp_table) do
      if key:find(argLead:sub(3), 1, true) == 1 then
        table.insert(completions, "--" .. key)
      end
    end
    -- 如果已經輸入 --xxx=，則補全值
  elseif argLead:match("^%-%-.*=") then
    local opt = argLead:match("^%-%-(.*)=")
    local cmp_item = cmp_table[opt]
    if cmp_item then
      if type(cmp_item) == "table" then -- array的情況
        -- 插入每一項
        for _, val in ipairs(cmp_item) do
          if val:find(argLead:match("=(.*)$"), 1, true) == 1 then
            table.insert(completions, "--" .. opt .. "=" .. val)
          end
        end
      elseif type(cmp_item) == "string" then
        -- file_ignore_patterns 的補全
        if cmp_item:find(argLead:match("=(.*)$"), 1, true) == 1 then
          table.insert(completions, "--" .. opt .. "=" .. cmp_item)
        end
      end
    end
  end

  return completions
end

--- 解析 [complete](https://github.com/CarsonSlovoka/nvim/blob/b201ef3fd87/lua/config/commands.lua#L3618-L3654) 所提供的參數
---
---@param fargs string[]
---@param update boolean?
function M.get_cmp_config(fargs, update)
  update = update or false

  local config = {}
  -- 倒序遍歷 fargs (使得如果update為true時，會直接異動fargs)
  for i = #fargs, 1, -1 do
    local arg = fargs[i]
    local key, value = arg:match('^(.-)=(.*)$')
    if key then
      config[key] = value
      if update then
        table.remove(fargs, i) -- 移除匹配的項目
      end
    end
  end
  return config
end

--- 得到已經輸入過的選項, 之後可以篩選，使得已經輸入過的選項不會再出現
---@param cmd_line string
---@return table
function M.get_exist_comps(cmd_line)
  -- 使得已經輸入過的選項，不會再出現
  local exist_comps = {}
  for _, key in ipairs(vim.split(cmd_line, '%s+')) do
    local k, _ = key:match('^(.-)=(.*)$')
    if k then
      exist_comps[k .. "="] = true
    end
  end
  return exist_comps
end

return M
