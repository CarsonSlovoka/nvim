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

require("config.input").fcitx.setup(
  "fcitx5-remote" -- which fcitx5-remote
)

-- pack/syntax/start/nvim-treesitter
require 'nvim-treesitter.configs'.setup { -- pack/syntax/start/nvim-treesitter/lua/configs.lua
  ensure_installed = {
    "bash",
    "lua",
    "go",
    "markdown", "markdown_inline" },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },

  incremental_selection = {
    enable = true,
    keymaps = {
      -- 這些快截鍵如果不是被偵測到的附檔名(即ensure_installed沒有的，或者用:checkHealth看)就不會有
      init_selection = "gnn", -- n模式 初始化當前的節點(從光標位置開始) 通常都會先用這個來開始
      node_incremental = "grn", -- x模式(v) -- gnn完了之後自動會被換行x模式，此時可以用grn，來將選擇往外「擴展」
      scope_incremental = "grc",
      node_decremental = "grm", -- 收縮選擇(可以看成grn的反悔)
    },
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
        ["io"] = "@block.inner", -- 任何區塊的內部
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
lspconfig.bashls.setup {}
lspconfig.markdown_oxide.setup {
  cmd = { os.getenv("HOME") .. "/.cargo/bin/markdown-oxide" }, -- 指定可執行檔的完整路徑
}
lspconfig.clangd.setup {}
lspconfig.lua_ls.setup {}

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
  end, { remap = true })
  -- F 類似f，只是它是往上找
  vim.keymap.set('', 'F', function()
    plugin_hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = false })
  end, { remap = true })

  -- t 往下找，定位在指定位置的「前」一個字母上
  vim.keymap.set('', 't', function()
    plugin_hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = false, hint_offset = -1 })
  end, { remap = true })

  -- T: 往上找，定位在指定位置的「後」一個字母上
  vim.keymap.set('', 'T', function()
    plugin_hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = false, hint_offset = 1 })
  end, { remap = true })
end

local plugin_gitsigns
status_ok, plugin_gitsigns = pcall(require, "gitsigns")
if status_ok then
  plugin_gitsigns.setup {
    signs = {
      add = { text = '┃' },
      change = { text = '┃' },
      delete = { text = '_' },
      topdelete = { text = '‾' },
      changedelete = { text = '~' },
      untracked = { text = '┆' },
    },
    signs_staged = {
      add = { text = '┃' },
      change = { text = '┃' },
      delete = { text = '_' },
      topdelete = { text = '‾' },
      changedelete = { text = '~' },
      untracked = { text = '┆' },
    },
    signs_staged_enable = true,
    signcolumn = true, -- Toggle with `:Gitsigns toggle_signs`
    numhl = false, -- Toggle with `:Gitsigns toggle_numhl`
    linehl = false, -- Toggle with `:Gitsigns toggle_linehl`
    word_diff = false, -- Toggle with `:Gitsigns toggle_word_diff`
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

    on_attach = function(bufnr)
      local function map(mode, l, r, opts)
        -- 簡化設定
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map('n', ']c', function()
        if vim.wo.diff then
          vim.cmd.normal({ ']c', bang = true })
        else
          plugin_gitsigns.nav_hunk('next')
        end
      end, { desc = '(git)往下找到異動處' })

      map('n', '[c', function()
        if vim.wo.diff then
          vim.cmd.normal({ '[c', bang = true })
        else
          plugin_gitsigns.nav_hunk('prev')
        end
      end, { desc = '(git)往上找到個異動處' })

      -- Actions
      -- map('n', '<leader>hs', plugin_gitsigns.stage_hunk)
      -- map('n', '<leader>hr', plugin_gitsigns.reset_hunk)
      -- map('v', '<leader>hs', function() plugin_gitsigns.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
      -- map('v', '<leader>hr', function() plugin_gitsigns.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
      -- map('n', '<leader>hS', plugin_gitsigns.stage_buffer)
      -- map('n', '<leader>hu', plugin_gitsigns.undo_stage_hunk)
      -- map('n', '<leader>hR', plugin_gitsigns.reset_buffer)
      -- map('n', '<leader>hn', plugin_gitsigns.next_hunk) -- 同等: plugin_gitsigns.nav_hunk('next')
      map('n', '<leader>hp', plugin_gitsigns.preview_hunk,
        { desc = '(git)Hunk x of x 開啟preview(光標處必需有異動才能開啟), 查看目前光標處的異動, 開啟後常與prev, next使用. 此指令與diffthis很像，但是專注於一列' })

      map('n', '<leader>hb', function()
        plugin_gitsigns.blame_line { full = true }
      end, { desc = '(git)blame 顯示光標處(不限於異動，所有都能)與最新一次commit時的差異' }
      )

      map('v', -- 由於<leader>t對我有用，所以為了避免影響已存在熱鍵的開啟效率，將此toogle設定在view下才可使用
        '<leader>tb', plugin_gitsigns.toggle_current_line_blame,
        { desc = "(git)可以瞭解這一列最後commit的訊息和時間點 ex: You, 6 days, ago - my commit message. 如果不想要浪費效能，建議不用的時候就可以關掉(再下一次指令)" })

      map('n', '<leader>hd', plugin_gitsigns.diffthis, { desc = '(git)查看當前文件的所有異動. 如果要看本次所有文件上的異動，可以使用:Telescope git_status' })
      map('n', '<leader>hD', function()
        plugin_gitsigns.diffthis('~')
      end) -- 有包含上一次的提交修改
      -- map('n', '<leader>td', plugin_gitsigns.toggle_deleted)

      -- Text object
      -- map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>') -- 選取而已，作用不大
    end
  }
end

local plugin_nvimWebDevicons
status_ok, plugin_nvimWebDevicons = pcall(require, "nvim-web-devicons") -- 只要這個插件有，不需要用require，nvim-tree就會自動導入，所以也不一定要寫這些配置
if status_ok then
  plugin_nvimWebDevicons.setup {
    -- 顏色不需要額外的項目就可以修改成功，但是icon要出現可能還需要額外的項目，例如: 使用github-nvim-theme後icon可以出現
    -- https://github.com/projekt0n/github-nvim-theme
    -- https://github.com/nvim-tree/nvim-web-devicons/blob/63f552a7f59badc6e6b6d22e603150f0d5abebb7/README.md?plain=1#L70-L125
    override = {
      zsh = {
        icon = "",
        color = "#428850",
        cterm_color = "65",
        name = "Zsh"
      }
    };
    color_icons = true;
    default = true;
    strict = true;
    variant = "light|dark";
    override_by_filename = {
      [".gitignore"] = {
        icon = "",
        color = "#f1502f",
        name = "Gitignore"
      },
      ["README.md"] = {
        icon = "🧙",
        color = "#00ff00",
        name = "README"
      }
    };
    override_by_extension = {
      ["log"] = {
        icon = "",
        color = "#ffff00",
        name = "Log"
      }
    };
    override_by_operating_system = {
      ["apple"] = {
        icon = "",
        color = "#A2AAAD",
        cterm_color = "248",
        name = "Apple",
      },
    };
  }
  -- set_default_icon(icon, color, cterm_color)
  -- plugin_nvimWebDevicons.set_default_icon('😃', '#6d8086', 65)
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
      -- :lua print("➜➜"") # 可以print這些試試，如果是亂碼，就是字型沒有提供，要安裝，並且改終端機的字型即可
      icons = { -- (可選)
        glyphs = {
          default = "", -- 預設找不到項目的圖標
          symlink = "",
          git = {
            unstaged = "",
            staged = "S",
            unmerged = "",
            renamed = "➜",
            deleted = "",
            untracked = "U", -- 自定前綴，定成U表示這個項目還沒有被git添加
          },
          folder = { -- 這些是預設，如果不喜歡，也可以自己改成喜歡的emoji
            default = "", -- 📁
            open = "📂", -- 
            empty = "",
            empty_open = "",
            symlink = "",
          },
        },
      },
    },
    filters = {
      dotfiles = true, -- 如果想要看到.開頭的檔案或目錄{.git/, .gitignore, .gitmodules, ...}，要設定成false
    },
  })
  vim.keymap.set("n", "<leader>t", ":NvimTreeOpen<CR>", { desc = "Open NvimTree" }) -- 可以先將TreeOpen到指定的位置，再用telescope去搜

  local nvim_treeAPI = require "nvim-tree.api"
  vim.api.nvim_create_user_command("CD",
    function(args)
      local path
      if #args.args > 0 then
        local params = vim.split(args.args, " ")
        path = params[1]
      else
        path = "~"
      end
      -- NOTE: 在nvim-tree上做CD的路徑和當前編輯的是不同的工作路徑, 如果有需要可以在nvim-tree: gf 複製絕對路徑後使用CD切換
      vim.cmd("cd " .. path)
      nvim_treeAPI.tree.open({ path = path })
      nvim_treeAPI.tree.change_root(path)
    end,
    {
      nargs = "?", -- 預設為0，不接受參數, 1: 一個, *多個,  ? 沒有或1個,  + 一個或多個
      desc = "更改工作目錄"
    }
  )
end

local plugin_telescope
status_ok, plugin_telescope = pcall(require, "telescope")
if status_ok then
  -- 初始化 Telescope
  plugin_telescope.setup({
    defaults = {
      -- 預設配置
      -- :lua print(vim.inspect(require('telescope.config').values.vimgrep_arguments))
      vimgrep_arguments = {
        "rg",
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--smart-case"
      },
      prompt_prefix = "🔍 ", -- 搜索框前的圖標
      selection_caret = " ", -- 選中時的指示符
      entry_prefix = "  ",
      sorting_strategy = "ascending",
      layout_strategy = "horizontal",
      layout_config = {
        prompt_position = "top",
        horizontal = {
          preview_width = 0.6,
        },
        vertical = {
          mirror = false,
        },
      },
      file_ignore_patterns = { "node_modules", ".git/" }, -- 忽略文件或目錄模式
      winblend = 0,
      border = {},
      borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
      path_display = { "truncate" },
      set_env = { ["COLORTERM"] = "truecolor" }, -- 修正配色
    },

    pickers = {
      -- 指定功能調整，如 find_files
      find_files = {
        hidden = true, -- 顯示隱藏文件
      },
      buffers = {
        ignore_current_buffer = true, -- 通常當前的文件已經曉得，不需要再列出來

        -- https://github.com/nvim-telescope/telescope.nvim/blob/2eca9ba22002184ac05eddbe47a7fe2d5a384dfc/doc/telescope.txt#L1462-L1467
        -- sort_lastused = true, -- 預設為false, 會將"當前"和"最後一次"使用的緩衝放到頂部
        sort_mru = true, -- 這個相當有用，它會將所有的都排序, 不會只像sort_lastused抓兩個而已, 因此如果不再意效能，可以都將其啟用
      }
    },

    extensions = {
      -- 如果需要擴展，可以在這裡註冊
    },
  })

  -- Telescope 配合 LSP 的符號檢視 (知道有哪些function之類的)
  local builtin = require("telescope.builtin")

  -- vim.api.nvim_set_keymap('n', '<Leader>s', ':Telescope lsp_document_symbols<CR>', { noremap = true, silent = true })
  -- https://github.com/nvim-telescope/telescope.nvim/blob/2eca9ba22002184ac05eddbe47a7fe2d5a384dfc/doc/telescope.txt#L1712-L1736
  -- 如果已經將:helptags ~/.config/nvim/pack/search/start/telescope.nvim/doc/ 也可以
  -- :help lsp_document_symbols
  -- :Telescope help_tags
  vim.keymap.set("n", "<leader>s",
    builtin.lsp_document_symbols,
    { desc = "watch variable, class, function, enum, ..." }
  )

  local utilsInput = require("utils.input")
  -- find . -mmin -480 -regex ".*\.\(sh\|md\)" -not -path "*/telescope.nvim/*" -not -path "*/.cache/*" -not -path "*/node_modules/*"
  -- find . -mmin -480 -regex ".*\.\(sh\|md\)" -not -path "*/telescope.nvim/*" -not -path "*/.cache/*"  -not -path "*/node_modules/*" -print0 | xargs -0 ls -lt
  -- 使用 Find 搜索具有特殊條件的文件 TODO: 當找不到檔案時，會用ls列出所有項目，需要設計一個都沒有符合的項目就不再繼續
  local function search_with_find()
    -- 讓使用者輸入一組附檔名
    local input = vim.fn.input("請輸入附檔名（例如: lua,sh,md:{mmin,amin,cmin,mtime,atime,ctime}:[+-]Number)", "|mmin:-480") -- 一開始給一個空白，避免str.split分離錯
    local paras = vim.split(input, '|')
    local input_exts = string.gsub(paras[1], "%s+$", "") -- 將結尾空白替換成""
    local timeOrMin = vim.split(paras[2], ':')

    -- 將輸入的附檔名分割成表
    local extensions = {}

    if input_exts and input_exts ~= " " then
      for ext in string.gmatch(input_exts, "[^,]+") do
        table.insert(extensions, ext)
      end
    end

    -- 如果沒有輸入任何附檔名則使用預設值
    if #extensions == 0 then
      -- 以下可以自己新增其它的附檔名
      extensions = {
        "sh",
        "lua",
        "md",
        "go",
        "c", "c++", "h",
        "ts", "js",
        "html",
        "scss", "sass", "css",
        "py",
        "json",
        "toml", "xml",
        "bat"
      }
    end

    --[[ 打印每個擴展名
    for _, ext in ipairs(extensions) do
      print(ext)
    end
    print(timeOrMin[1])
    print(timeOrMin[2])
    ]]--

    -- 動態構建 -name 條件
    local name_conditions = {}
    for _, ext in ipairs(extensions) do
      table.insert(name_conditions, "-name '*." .. ext .. "'")
    end

    -- 構建 find 命令
    local find_cmd = table.concat({
      "find .",
      "\\(", -- 開始文件類型條件組
      --[[
      "-name '*.sh'",
      "-o -name '*.lua'",
      "-o -name '*.md'",
      --]]
      table.concat(name_conditions, " -o "),
      "\\)", -- 結束文件類型條件組
      -- "-mmin -" .. mmin, -- 時間限制
      "-" .. timeOrMin[1] .. " " .. timeOrMin[2],
      "-type f", -- 只匹配文件 (這很重要，因為我們用了ls -t才能排時間，因此ls的時候要排目錄都拿掉，不然會影響到)
      --[[
      "-a", -- AND 操作符
      "\\(", -- 開始擴展名檢查條件組
      "-regex '.*\\.[^/]*$'", -- 確保文件有擴展名
      "\\)",
      ]]--

      -- 以下可以自己要忽略目錄的目錄
      "-not -path '*/telescope.nvim/*'", -- 忽略目錄
      "-not -path '*/.cache/*'",
      "-not -path '*/node_modules/*'",
      "-print0", -- 使用 null 分隔輸出
    }, " ")

    -- 完整命令（加入排序）
    local cmd = {
      "bash",
      "-c",
      find_cmd .. " | xargs -0 ls -t 2>/dev/null"
    }

    -- print(table.concat(cmd, " "))
    -- find . \( -name '*.lua' -o -name '*.md' \) -mmin -480 -not -path '*/telescope.nvim/*' -not -path '*/.cache/*' -not -path '*/node_modules/*' -exec ls -1rt "{}" +
    -- find . \( -name '*.lua' -o -name '*.md' \) -mmin -480 -not -path '*/telescope.nvim/*' -not -path '*/.cache/*' -not -path '*/node_modules/*' -print0 | xargs -0 ls -t 2>/dev/null


    -- 用 Telescope 呈現
    builtin.find_files({
      find_command = cmd,
      prompt_title = "Find (時間排序)",
    })
  end

  -- 我的自定義: search_with_find
  vim.keymap.set("n", "<leader>fr", search_with_find, { desc = "[Find Recent]" })

  -- 搜索當前工作目錄下的文件
  vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "[Find Files]" })
  vim.keymap.set("n", "<leader>eff", function()
    local extensions = utilsInput.extension()
    -- 動態生成 `--glob` 條件
    local glob_args = {}
    for _, ext in ipairs(extensions) do
      table.insert(glob_args, "--glob")
      table.insert(glob_args, "*." .. ext)
    end
    builtin.find_files({
      prompt_title = "查找指定類型的文件",
      -- find_command = { "--glob", "*.lua", "--glob", "*.sh" }
      find_command = vim.list_extend({
        "rg", "--files",
        "--with-filename",
        "--color=never",
        "--no-heading",
        "--line-number",
        "--column",
        "--smart-case"
      }, glob_args)
    })
  end, { desc = "查找指定類型的文件" })

  -- 搜索文本
  vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "[Live Grep]" })
  vim.keymap.set("n", "<leader>efg", function()
    builtin.live_grep({
      prompt_title = "search content by extension",
      additional_args = function()
        local extensions = utilsInput.extension()
        local glob_args = {}
        for _, ext in ipairs(extensions) do
          table.insert(glob_args, "--glob")
          table.insert(glob_args, "*." .. ext)
        end
        return vim.list_extend({
          "--with-filename",
          "--color=never",
          "--no-heading",
          "--line-number",
          "--column",
          "--smart-case"
        }, glob_args)
      end,
    })
  end, { desc = "search content by extension" })

  -- 搜索已打開的 buffer
  -- :help telescope.builtin.buffers
  vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "可以找到最近開啟的buffer" })

  -- 搜索幫助文檔
  -- 記得要將plugin相關的doc加入才行
  -- :helptags ~/.config/nvim/pack/GROUP/start/XXX_PLUGIN/doc/
  vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "[Help Tags]" })

  vim.keymap.set("n",
    "<C-S-f>", -- Ctrl+Shift+f
    builtin.current_buffer_fuzzy_find,
    { desc = "在當前文件進行搜尋" }
  )

  local telescope_bookmark = require "config.telescope_bookmark"
  vim.api.nvim_create_user_command("TelescopeBookmarks", telescope_bookmark.show, {})
  vim.keymap.set("n", "<leader>bk", telescope_bookmark.show, { noremap = true, silent = true, desc = "Telescope 書籤選擇" })
  vim.api.nvim_create_user_command("BkSave", function()
    telescope_bookmark.save {
      verbose = true
    }
  end, { desc = "如果想要永久的保存訪問過的時間，請手動呼叫此方法" })
  vim.api.nvim_create_user_command("BkAdd", function(args)
    local params = vim.split(args.args, " ")
    local name = params[1]
    -- local name = vim.fn.input("bookmarkName: ")
    local filepath = vim.fn.expand("%:p")
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    if not telescope_bookmark.add(name, filepath, row, col) then
      return
    end
    telescope_bookmark.save {}
    local filename = vim.fn.expand("%:t")
    vim.notify("✅ 書籤已成功保存: " .. name ..
      "filename: " .. filename ..
      " (行: " .. row .. ", 列: " .. col .. ")", vim.log.levels.INFO)
  end, {
    nargs = 1,
    desc = "加入書籤"
  })
  vim.api.nvim_create_user_command("BkAddDir", function(args)
    local params = vim.split(args.args, " ")
    local name = params[1]
    local dirPath = vim.fn.expand("%:p:h")
    if telescope_bookmark.add(name, dirPath) then
      return
    end
    telescope_bookmark.save {}
    vim.notify("✅已成功建立書籤: " .. name .. "path:" .. dirPath, vim.log.levels.INFO)
  end, {
    nargs = 1,
    desc = "添加目錄到書籤"
  })
end


-- theme
-- https://github.com/projekt0n/github-nvim-theme/blob/c106c9472154d6b2c74b74565616b877ae8ed31d/README.md?plain=1#L170-L206
vim.cmd('colorscheme github_dark_default')


-- other

-- other indent-blankline.nvim
local plugin_ibl
status_ok, plugin_ibl = pcall(require, "ibl") -- pack/other/start/indent-blankline.nvim/lua/ibl
if status_ok then
  vim.api.nvim_create_user_command("Ibl",
    function(args)
      if #args.args == 0 then
        -- 採用最簡單的配置
        plugin_ibl.setup()
      else
        local highlight = {
          "RainbowRed",
          "RainbowYellow",
          "RainbowBlue",
          "RainbowOrange",
          "RainbowGreen",
          "RainbowViolet",
          "RainbowCyan",
        }
        local hooks = require "ibl.hooks"
        hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
          vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
          vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
          vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
          vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
          vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
          vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
          vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
        end)

        plugin_ibl.setup {
          indent = {
            highlight = highlight
          }
        }
      end
    end,
    {
      nargs = "?",
      desc = "setup: indent-blankline.nvim; 有參數會用彩色模式; 不加參數為簡單模式; 開啟之後可以再次使用指令來切換彩色或簡單模式"
    }
  )
end
