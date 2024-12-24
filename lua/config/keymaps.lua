local keymaps = {}

local exec = require("utils.exec")

local function setup_normal()
    -- 複製文件的絕對路徑
    vim.keymap.set('n', -- normal mode
            '<leader>cwd',
            ':let @+=expand("%:p")<CR>', -- % 表示當前的文件名, :p (轉成絕對路徑)
            { noremap = true, silent = true }
    )
end

local function setup_visual()
    -- 將所有內容複製到剪貼簿
    vim.keymap.set('v', -- Visual 模式
            '<leader>c', -- 快捷鍵為 <leader>c
            '"+y', -- 將選中的內容複製到系統剪貼板
            { noremap = true, silent = true }
    )

    vim.keymap.set('x',
            '<leader>r',
            -- [[:lua ExecuteSelection()<CR>]],
            function()
                exec.ExecuteSelection()
            end,
            { noremap = true, silent = true }
    )
end

function keymaps.setup()
    setup_normal()
    setup_visual()
end

return keymaps
