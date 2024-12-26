local HOME = os.getenv("HOME")

-- runtimepath
local runtimepath = vim.api.nvim_get_option("runtimepath")
vim.opt.runtimepath = runtimepath .. ",~/.vim,~/.vim/after"
vim.opt.packpath = vim.opt.runtimepath:get()

-- python
vim.g.python3_host_prog = vim.fn.expand("~/.pyenv/versions/neovim3/bin/python")

-- vim
local vimrcPath = HOME .. "/.vimrc"
if vim.fn.filereadable(vimrcPath) == 1 then
    vim.cmd("source " .. vimrcPath)
end

-- config
require("config.options").setup()
require "config.filetype".setup {
    (
            {
                pattern = "*/doc/*.txt",
                filetype = "help",
                groupName = "DocHelp"
            }
    )
}
require("config.keymaps").setup()
require("config.commands").setup()


-- pack/syntax/start/nvim-treesitter
require 'nvim-treesitter.configs'.setup { -- pack/syntax/start/nvim-treesitter/lua/configs.lua
    ensure_installed = {
        "lua",
        "go",
        "markdown", "markdown_inline" },
    highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
    },

    -- 配置 textobjects 模塊, 須要插件: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
    -- pack/syntax/start/nvim-treesitter-textobjects/lua/nvim-treesitter/textobjects/
    textobjects = {
        select = { -- visual模式才有效
            enable = true, -- 啟用 textobjects
            lookahead = true, -- 向前查找，可以更智能選擇
            keymaps = {
                -- 標準鍵位示例（根據需要調整）
                ["af"] = "@function.outer", -- 整個函數塊
                ["if"] = "@function.inner", -- 函數內部
                ["ac"] = "@class.outer", -- 整個類別塊
                ["ic"] = "@class.inner", -- 類別內部
                ["ao"] = "@block.outer", -- 任何區塊的外部
                ["io"] = "@block.inner" -- 任何區塊的內部
            },
        },
        move = { -- 此功能還好，可以用hop來取代
            enable = true,
            set_jumps = true, -- 記錄跳轉位置
            goto_next_start = {
                ["]m"] = "@function.outer", -- 跳到下一個函數的開始
                ["]]"] = "@class.outer" -- 跳到下一個類別的開始
            },
            goto_next_end = {
                ["]M"] = "@function.outer", -- 跳到下一個函數的結束
                ["]["] = "@class.outer" -- 跳到下一個類別的結束
            },
            goto_previous_start = {
                ["[m"] = "@function.outer", -- 跳到上一個函數的開始
                ["[["] = "@class.outer" -- 跳到上一個類別的開始
            },
            goto_previous_end = {
                ["[M"] = "@function.outer", -- 跳到上一個函數的結束
                ["[]"] = "@class.outer" -- 跳到上一個類別的結束
            },
        },
        swap = { -- 不錯用，可以快速交換參數
            enable = true,
            swap_next = {
                ["<leader>a"] = "@parameter.inner", -- 與下一個參數交換
            },
            swap_previous = {
                ["<leader>A"] = "@parameter.inner", -- 與上一個參數交換
            },
        },
    },
}

local lspconfig = require 'lspconfig'
lspconfig.pyright.setup {}
vim.g.lsp_pyright_path = vim.fn.expand('~/.pyenv/shims/pyright')
lspconfig.gopls.setup {}
-- lspconfig.tsserver.setup{}

-- 加載 precognition 插件
local status_ok, precognition = pcall(require, "precognition")
if not status_ok then
    vim.notify("Failed to load precognition.nvim", vim.log.levels.ERROR)
    return
end
-- 配置 precognition
precognition.setup({
    -- 以下是 https://github.com/tris203/precognition.nvim/blob/531971e6d883e99b1572bf47294e22988d8fbec0/README.md?plain=1#L22-L46 的預設配置
    startVisible = true,
    showBlankVirtLine = true,
    highlightColor = { link = "Comment" },
    hints = {
        Caret = { text = "^", prio = 2 },
        Dollar = { text = "$", prio = 1 },
        MatchingPair = { text = "%", prio = 5 },
        Zero = { text = "0", prio = 1 },
        w = { text = "w", prio = 10 },
        b = { text = "b", prio = 9 },
        e = { text = "e", prio = 8 },
        W = { text = "W", prio = 7 },
        B = { text = "B", prio = 6 },
        E = { text = "E", prio = 5 },
    },
    gutterHints = {
        G = { text = "G", prio = 10 },
        gg = { text = "gg", prio = 9 },
        PrevParagraph = { text = "{", prio = 8 },
        NextParagraph = { text = "}", prio = 8 },
    },
    disabled_fts = {
        "startify",
    },
})


local plugin_hop
status_ok, plugin_hop = pcall(require, "hop") -- pack/motion/start/hop.nvim/lua/hop/
if status_ok then
    plugin_hop.setup {
        keys = 'etovxqpdygfblzhckisuran'
    }
    -- https://github.com/smoka7/hop.nvim/blob/efe58182f71fbe592f82fb211ab026f2819e855d/README.md?plain=1#L90-L112
    local directions = require('hop.hint').HintDirection
    -- f 往下找，準確的定位
    vim.keymap.set('', 'f', function()
        plugin_hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = false })
    end, {remap=true})
    -- F 類似f，只是它是往上找
    vim.keymap.set('', 'F', function()
        plugin_hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = false })
    end, {remap=true})

    -- t 往下找，定位在指定位置的「前」一個字母上
    vim.keymap.set('', 't', function()
        plugin_hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = false, hint_offset = -1 })
    end, {remap=true})

    -- T: 往上找，定位在指定位置的「後」一個字母上
    vim.keymap.set('', 'T', function()
        plugin_hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = false, hint_offset = 1 })
    end, {remap=true})
end


local plugin_gitsigns
status_ok, plugin_gitsigns = pcall(require, "gitsigns")
if status_ok then
    plugin_gitsigns.setup {
        signs = {
            add          = { text = '┃' },
            change       = { text = '┃' },
            delete       = { text = '_' },
            topdelete    = { text = '‾' },
            changedelete = { text = '~' },
            untracked    = { text = '┆' },
        },
        signs_staged = {
            add          = { text = '┃' },
            change       = { text = '┃' },
            delete       = { text = '_' },
            topdelete    = { text = '‾' },
            changedelete = { text = '~' },
            untracked    = { text = '┆' },
        },
        signs_staged_enable = true,
        signcolumn = true,  -- Toggle with `:Gitsigns toggle_signs`
        numhl      = false, -- Toggle with `:Gitsigns toggle_numhl`
        linehl     = false, -- Toggle with `:Gitsigns toggle_linehl`
        word_diff  = false, -- Toggle with `:Gitsigns toggle_word_diff`
        watch_gitdir = {
            follow_files = true
        },
        auto_attach = true,
        attach_to_untracked = false,
        current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
        current_line_blame_opts = {
            virt_text = true,
            virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
            delay = 1000,
            ignore_whitespace = false,
            virt_text_priority = 100,
            use_focus = true,
        },
        current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
        sign_priority = 6,
        update_debounce = 100,
        status_formatter = nil, -- Use default
        max_file_length = 40000, -- Disable if file is longer than this (in lines)
        preview_config = {
            -- Options passed to nvim_open_win
            border = 'single',
            style = 'minimal',
            relative = 'cursor',
            row = 0,
            col = 1
        },
    }
end

local plugin_nvimTree
status_ok, plugin_nvimTree = pcall(require, "nvim-tree")
if status_ok then
    --[[
    USAGE:

    :NvimTreeOpen

    g?
    ]]--
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    -- optionally enable 24-bit colour
    vim.opt.termguicolors = true

    plugin_nvimTree.setup({
        sort = {
            sorter = "case_sensitive",
        },
        view = {
            width = 30,
        },
        renderer = {
            group_empty = true,
        },
        filters = {
            dotfiles = true,
        },
    })
end
