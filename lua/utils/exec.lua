local exec = {}

---@param cmd string? The command to be executed in sh -c
function exec.ExecuteSelection(cmd)
  local command = cmd
  if command == nil then
    -- 獲取選取範圍的起始和結束位置
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")

    local start_row, start_col = start_pos[2], start_pos[3]
    local end_row, end_col = end_pos[2], end_pos[3]

    -- 獲取選中的行內容
    local lines = vim.fn.getline(start_row, end_row)
    if not lines or #lines == 0 then
      return -- 如果選取內容為空，直接結束
    end

    -- 修正第一行和最後一行的選取範圍
    if #lines == 1 then
      lines[1] = string.sub(lines[1], start_col, end_col)
    else
      lines[1] = string.sub(lines[1], start_col)
      lines[#lines] = string.sub(lines[#lines], 1, end_col)
    end

    -- 合併行內容為單一命令字串
    command = table.concat(lines, "\n")
  end
  print(command) -- NOTE: print 如果太長的時候，就需要按下Enter才可以繼續

  -- 非同步執行命令，無輸出到文本
  local curDir = vim.fn.expand("%:p:h")

  -- 以下的作法沒辦法呈現stdout真實的內容
  -- vim.uv.spawn("sh", {
  --   args = { "-c", command },
  --   cwd = curDir
  -- }, function(code, signal)
  --   if code ~= 0 then
  --     vim.schedule(function()
  --       print("執行失敗，錯誤代碼:", code, "信號:", signal)
  --     end)
  --   end
  -- end)


  -- 以下方法可行，但是用jobstart會比較簡潔
  -- local stdout = vim.uv.new_pipe(false) -- 建立 stdout pipe
  -- local function on_stdout(err, data)
  --   if err then
  --     vim.schedule(function()
  --       print("stdout 讀取錯誤:", err)
  --     end)
  --     return
  --   end
  --   if data then
  --     vim.schedule(function()
  --       -- print("stdout 輸出:", vim.inspect(data)) -- 輸出 stdout 內容. 有個缺點，如果輸出有\n不會自動換行顯示，都會合在一列
  --       vim.api.nvim_echo({ { data, "Normal" }, }, false, {}) -- TIP: 輸出有\n, 會換行
  --     end)
  --   end
  -- end
  --
  -- vim.uv.spawn("sh", {
  --   args = { "-c", command },
  --   cwd = curDir,
  --   stdio = { nil, stdout, nil } -- 設定 stdio：stdin, stdout, stderr
  -- }, function(code, signal)
  --   stdout:read_stop()
  --   stdout:close()
  --   if code ~= 0 then
  --     vim.schedule(function()
  --       print("執行失敗，錯誤代碼:", code, "信號:", signal)
  --     end)
  --   end
  -- end)
  -- stdout:read_start(on_stdout) -- 啟動讀取 stdout

  -- vim.fn.jobstart("sh -c " .. command, -- WARN: command要用''包起來不然執行的指令會不完整！
  -- vim.cmd("tabnew | setlocal buftype=nofile")
  -- vim.fn.jobstart(string.format("sh -c %q", command), -- 這個多列的情況有的會有問題

  local stdout_msg = ""
  local stderr_msg = ""
  vim.fn.jobstart(string.format("sh -c '\n%s\n'", command),
    {
      -- term = true, -- 如果用term，只要前面先用tabnew之後的stdout, stderr都可以直接在終端輸出，不需要再自己處理，只是最後會需要再按一次Enter來結束, 不過也是可以在on_exit時用nvim_buf_delete來刪除，但是輸出的訊息就會來不急看
      cwd = curDir,           -- (optional) 設定工作目錄
      stdout_buffered = true, -- 緩衝 stdout，一次性傳給回調
      stderr_buffered = true,
      on_stdout = function(_, data, _)
        -- if #data == 0 then return end -- 這不準，有的是 { "" }
        if #data == 0 or (#data == 1 and data[1] == "") then
          return
        end

        -- -- 統一輸出
        -- vim.api.nvim_echo({
        --   { "stdout\n",               "@label" },
        --   { table.concat(data, "\n"), "Normal" }, -- TIP: 輸出有\n, 會換行
        -- }, false, {})

        stdout_msg = table.concat(data, "\n")
      end,
      on_stderr = function(_, data, _)
        if #data == 0 or (#data == 1 and data[1] == "") then
          return
        end
        -- vim.api.nvim_echo({
        --   { "stderr\n",               "@label" },
        --   -- { "❌ " .. table.concat(data, "\n"), "Normal" }, -- 不見得stderr就是有問題，有的程式會有stdout, stderr都會輸出
        --   { table.concat(data, "\n"), "Normal" },
        -- }, false, {})

        stderr_msg = table.concat(data, "\n")
      end,

      -- -- 就算定義了on_stdout, on_stderr, 還是可以再處理on_exit, 但覺得不太需要
      on_exit = function(id, code, signal)
        -- if code ~= 0 then
        --   print("執行失敗，錯誤代碼:", code, "信號:", signal, id)
        -- else
        --   print("執行成功！")
        -- end
        local out_msg = {}
        if stdout_msg ~= "" then
          table.insert(out_msg, { "stdout\n", "@label" })
          table.insert(out_msg, { stdout_msg .. "\n", "Normal" })
        end
        if stderr_msg ~= "" then
          table.insert(out_msg, { "stderr\n", "@label" })
          table.insert(out_msg, { stderr_msg .. "\n", "Normal" })
        end
        vim.api.nvim_echo(out_msg, false, {})
      end,
    })
end

return exec
