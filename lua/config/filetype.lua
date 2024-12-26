local filetype = {}

function filetype.setup(options)
    -- 檢查是否有傳入 options
    if not options or type(options) ~= "table" then
        vim.notify("Invalid options supplied to filetype.setup", vim.log.levels.WARN)
        return
    end

    for _, opt in ipairs(options) do
        vim.api.nvim_create_augroup(opt.groupName,
                { clear = true } -- 如果已經存在就刪除
        )
        vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
            pattern = opt.pattern,
            callback = function()
                vim.bo.filetype = opt.filetype
            end,
            group = opt.groupName, -- 以上的這些內容，隸屬於此group
        })
    end
end

return filetype
