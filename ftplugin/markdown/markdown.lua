-- 生成 TOC 數據
local function generate_toc()
    local toc = {}
    local in_code_block = false -- 標記是否在程式碼塊中

    for line_num = 1, vim.api.nvim_buf_line_count(0) do
        local line = vim.fn.getline(line_num)

        -- 檢查是否進入或退出程式碼塊
        if line:match("^```") then
            in_code_block = not in_code_block
        end

        -- 忽略程式碼塊中的內容
        if not in_code_block then
            -- 嚴格匹配 Markdown 標題格式
            local header, title = line:match("^(#+)%s+(%S.*)$")
            if header then
                local level = #header -- #表示取長度
                table.insert(toc, {
                    level = level,
                    line = line_num,
                    title = title -- 已去除#[空白]
                })
            end
        end
    end
    return toc
end


-- 顯示 TOC 浮動窗口
local function show_toc_window()
    local toc = generate_toc()
    if vim.tbl_isempty(toc) then
        vim.notify("沒有檢測到任何 Markdown 標題!", vim.log.levels.INFO)
        return
    end

    local buf = vim.api.nvim_create_buf(false, true)
    local opts = {
        relative = "editor",
        width = math.floor(vim.o.columns * 0.4),
        height = math.min(#toc + 2, 20),
        row = math.floor(vim.o.lines * 0.2),
        col = math.floor(vim.o.columns * 0.3),
        style = "minimal",
        border = "rounded",
    }
    local win = vim.api.nvim_open_win(buf, true, opts)

    local lines = {}
    for _, item in ipairs(toc) do
        table.insert(lines,
                string.rep(" ", (item.level - 1) * 2) ..
                        "- " .. item.title ..
                        " (line " .. item.line .. ")"
        )
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- 綁定選擇功能
    vim.keymap.set("n", "<CR>", function()
        local current_line = vim.api.nvim_win_get_cursor(0)[1]
        if toc[current_line] then
            vim.api.nvim_win_close(win, true) -- 關閉窗口
            vim.api.nvim_win_set_cursor(0, { toc[current_line].line, 0 }) -- 跳轉
        end
    end, { noremap = true, silent = true, buffer = buf })
end

-- 熱鍵綁定
vim.keymap.set("n", "<leader>wt", show_toc_window, { noremap = true, silent = true })
