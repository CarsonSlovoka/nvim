local options = {}

function options.setup()
    vim.g.mapleader = "," -- 預設是 \

    vim.opt.expandtab = true  -- 使用空白代替Tab
    vim.opt.tabstop = 2       -- Tab鍵等於2個空白
    vim.opt.softtabstop = 2   -- 在插入模式下，Tab鍵也等於2空白
    vim.opt.shiftwidth = 2    -- 自動縮進時使用 2 個空白

    vim.opt.wrap = false -- 禁止長行自動換行

    vim.g.editorconfig = false -- 預設是啟用的, 如果沒有禁用會得到: Error executing lua callback: root must be either "true" or "false"
end

return options
