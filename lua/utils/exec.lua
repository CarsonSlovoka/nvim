local exec = {}

function exec.ExecuteSelection()
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
    local command = table.concat(lines, "\n")
    print(command)

    -- 非同步執行命令，無輸出到文本
    local curDir = vim.fn.expand("%:p:h")
    vim.loop.spawn("sh", {
        args = { "-c", command },
        cwd = curDir -- (optional) 設定工作目錄
    }, function(code, signal)
        if code ~= 0 then
            vim.schedule(function()
                print("執行失敗，錯誤代碼:", code, "信號:", signal)
            end)
        end
    end)
end

return exec
