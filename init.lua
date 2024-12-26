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
    }
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
