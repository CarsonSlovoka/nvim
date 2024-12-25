-- 生成 TOC 數據
local function generate_toc()
    local toc = {}
    for line_num = 1, vim.api.nvim_buf_line_count(0) do
        local line = vim.fn.getline(line_num)
        local header = line:match("^(#+)%s+(.*)")
        if header then
            -- header:match("^#+") 可能是 ###
            -- #header:match("^#+") 是計算長度, 所以level會是數字
            local level = #header:match("^#+")
            table.insert(toc, {
                level = level,
                line = line_num,
                title = line:match("^#+%s+(.*)") -- 去除#[space], 不要匹配主文字即可
            })
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
vim.keymap.set("n", "<leader>t", show_toc_window, { noremap = true, silent = true })