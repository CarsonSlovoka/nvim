local START_TIME = vim.loop.hrtime() -- 勿調整，用來得知nvim開啟的時間，如果要計算啟動花費時間會有用

local osUtils = require("utils.os")
local array = require("utils.array")
local completion = require("utils.complete")
local cmdUtils = require("utils.cmd")
local rangeUtils = require("utils.range")

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
require("config.autocmd").setup({
  callback = function(m)
    vim.api.nvim_create_user_command(
      "ToggleFMT",
      function()
        m.autoReformat = not m.autoReformat
        vim.notify("autoReformat: " .. vim.inspect(m.autoReformat), vim.log.levels.INFO)
      end,
      { desc = "切換自動格式化" }
    )
    vim.api.nvim_create_user_command(
      "SetAutoFmt",
      function(args)
        m.autoReformat = args.fargs[1] == "1"
        vim.notify("autoReformat: " .. vim.inspect(m.autoReformat), vim.log.levels.INFO)
      end,
      {
        nargs = 1,
        complete = function()
          return {
            "1",
            "0"
          }
        end,
        desc = "enable autoReformat"
      }
    )
    vim.api.nvim_create_user_command(
      "SetAutoSave",
      function(args)
        m.autoSave = args.fargs[1] == "1"
        vim.notify("autoSave: " .. vim.inspect(m.autoSave), vim.log.levels.INFO)
      end,
      {
        nargs = 1,
        complete = function() -- complete 不能直接回傳一個table，一定要用一個function來包裝
          return {
            "1",
            "0"
          }
        end,
        desc = "enable autoSave"
      }
    )
  end
})

-- windows的系統不適用，所以只在非windows系統使用
if not osUtils.IsWindows then
  require("config.input").fcitx.setup(
    "fcitx5-remote" -- which fcitx5-remote
  )
end

local function install_nvimTreesitter()
  -- pack/syntax/start/nvim-treesitter
  local status_ok, m = pcall(require, "nvim-treesitter.configs")
  if not status_ok then
    return
  end
  m.setup { -- pack/syntax/start/nvim-treesitter/lua/configs.lua
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
        init_selection = "gnn",   -- n模式 初始化當前的節點(從光標位置開始) 通常都會先用這個來開始
        node_incremental = "grn", -- x模式(v) -- gnn完了之後自動會被換行x模式，此時可以用grn，來將選擇往外「擴展」
        scope_incremental = "grc",
        node_decremental = "grm", -- 收縮選擇(可以看成grn的反悔)
      },
    },

    -- 配置 textobjects 模塊, 須要插件: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
    -- pack/syntax/start/nvim-treesitter-textobjects/lua/nvim-treesitter/textobjects/
    textobjects = {       -- 其實透過visual a{ 等已經很好用了，可以考慮不用textobjects
      select = {          -- visual模式才有效
        enable = true,    -- 啟用 textobjects
        lookahead = true, -- 向前查找，可以更智能選擇
        keymaps = {
          -- 標準鍵位示例（根據需要調整）
          ["af"] = "@function.outer", -- 整個函數塊
          ["if"] = "@function.inner", -- 函數內部
          ["ac"] = "@class.outer",    -- 整個類別塊
          ["ic"] = "@class.inner",    -- 類別內部
          ["ao"] = "@block.outer",    -- 任何區塊的外部
          ["io"] = "@block.inner",    -- 任何區塊的內部
        },
      },
      move = {                        -- 此功能還好，可以用hop來取代
        enable = true,
        set_jumps = true,             -- 記錄跳轉位置
        goto_next_start = {
          ["]m"] = "@function.outer", -- 跳到下一個函數的開始
          ["]]"] = "@class.outer"     -- 跳到下一個類別的開始
        },
        goto_next_end = {
          ["]M"] = "@function.outer", -- 跳到下一個函數的結束
          ["]["] = "@class.outer"     -- 跳到下一個類別的結束
        },
        goto_previous_start = {
          ["[m"] = "@function.outer", -- 跳到上一個函數的開始
          ["[["] = "@class.outer"     -- 跳到上一個類別的開始
        },
        goto_previous_end = {
          ["[M"] = "@function.outer", -- 跳到上一個函數的結束
          ["[]"] = "@class.outer"     -- 跳到上一個類別的結束
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
end


local function install_lspconfig()
  local ok, m = pcall(require, "lspconfig")
  if not ok then
    vim.notify("Failed to load lspconfig", vim.log.levels.ERROR)
    return
  end
  m.pyright.setup {}
  local pyright_path
  if osUtils.IsWindows then
    -- 透過powershell的gcm來找pyright.exe的路徑
    pyright_path = vim.fn.system('powershell -Command "(gcm pyright).Source"')
  else
    pyright_path = vim.fn.expand('~/.pyenv/shims/pyright')
  end
  vim.g.lsp_pyright_path = pyright_path
  m.gopls.setup {}
  -- m.tsserver.setup {} Deprecated servers: tsserver -> ts_ls
  m.ts_ls.setup {}
  m.bashls.setup {}

  m.markdown_oxide.setup {                                              -- 請安裝rust後透過cargo來取得
    cmd = { osUtils.GetExePathFromHome("/.cargo/bin/markdown-oxide") }, -- 指定可執行檔的完整路徑
  }
  m.clangd.setup {}
  m.lua_ls.setup {
    settings = {
      Lua = {
        runtime = {
          version = 'LuaJIT',
          path = "/usr/bin/lua5.1",
        },
        diagnostics = {
          -- 告訴 LSP `vim` 是一個全域變數
          globals = { 'vim' }
        }
      }
    }
  }
  -- m.jsonls.setup {} -- https://github.com/microsoft/vscode-json-languageservice 可以考慮安裝


  -- 新增切換虛擬文本診斷的命令
  local diagnosticVirtualTextEnable = false
  vim.api.nvim_create_user_command(
    "ToggleDiagnosticVirtualText",
    function(args)
      if diagnosticVirtualTextEnable then
        vim.diagnostic.config({
          virtual_text = false
        })
      else
        -- 診斷訊息顯示在行尾
        vim.diagnostic.config({
          virtual_text = {
            prefix = '●', -- 前綴符號
            suffix = '',
            format = function(diagnostic)
              -- print(vim.inspect(diagnostic))
              return string.format([[
  code: %s
  source: %s
  message: %s
]],
                diagnostic.code,
                diagnostic.source,
                diagnostic.message
              )
            end,
          }
        })
      end
      diagnosticVirtualTextEnable = not diagnosticVirtualTextEnable
      if #args.fargs == 0 then
        vim.notify("diagnosticVirtualTextEnable: " .. tostring(diagnosticVirtualTextEnable), vim.log.levels.INFO)
      end
    end,
    {
      nargs = "?",
      desc = "切換診斷虛擬文本顯示"
    }
  )
  vim.cmd("ToggleDiagnosticVirtualText --quite") -- 因為我的預設值設定為false，所以這樣相當改成預設會啟用

  --- @type boolean|nil
  local diagnosticHoverAutocmdId = false
  vim.o.updatetime = 250
  vim.api.nvim_create_user_command(
    "ToggleDiagnosticHover",
    function(args)
      if diagnosticHoverAutocmdId then
        -- 如果已經存在，則刪除特定的自動命令
        vim.api.nvim_del_autocmd(diagnosticHoverAutocmdId)
        diagnosticHoverAutocmdId = nil
      else
        -- 創建新的自動命令，並保存其ID
        diagnosticHoverAutocmdId = vim.api.nvim_create_autocmd(
          { "CursorHold", "CursorHoldI" }, {
            callback = function()
              vim.diagnostic.open_float(nil, { focus = false })
            end
          })
      end

      if #args.fargs == 0 then
        vim.notify("DiagnosticHoverEnable: " .. tostring(diagnosticHoverAutocmdId ~= nil), vim.log.levels.INFO)
      end
    end,
    {
      nargs = "?",
      desc = "切換診斷懸停顯示"
    }
  )
  vim.cmd("ToggleDiagnosticHover --quite")

  vim.api.nvim_create_user_command(
    "SetDiagnostics",
    function(args)
      if args.fargs[1] == "1" then
        vim.diagnostic.enable()
        vim.notify("diagnostic enable", vim.log.levels.INFO)
      elseif args.fargs[1] == "0" then
        -- vim.diagnostic.disable() -- 已被棄用
        vim.diagnostic.enable(false)
        vim.notify("diagnostic disable", vim.log.levels.INFO)
      end
    end,
    {
      nargs = 1,
      complete = function()
        return { "1", "0" }
      end,
      desc = "set diagnostic"
    }
  )
end


local function install_precognition()
  -- 加載 precognition 插件
  local ok, m = pcall(require, "precognition")
  if not ok then
    vim.notify("Failed to load precognition.nvim", vim.log.levels.ERROR)
    return
  end
  -- 配置 precognition
  m.setup({
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
end


local function install_hop()
  local status_ok, m = pcall(require, "hop") -- pack/motion/start/hop.nvim/lua/hop/
  if not status_ok then
    vim.notify("Failed to load hop", vim.log.levels.ERROR)
    return
  end
  m.setup {
    -- keys 可以定義少一點，但是這樣按到兩個鍵的可能性也會增加
    keys = 'abcdefghijklmnopqrstuvwxyz'
  }
  -- https://github.com/smoka7/hop.nvim/blob/efe58182f71fbe592f82fb211ab026f2819e855d/README.md?plain=1#L90-L112
  local directions = require('hop.hint').HintDirection

  vim.keymap.set('', 'f', function()
    m.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true })
  end, { desc = "往下找，準確的定位(僅目前列)", remap = true })

  vim.keymap.set('', 'F', function()
    m.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true })
  end, { desc = "往上找，準確的定位(僅目前列)", remap = true })

  -- t 往下找，定位在指定位置的「前」一個字母上
  vim.keymap.set('', 't', function()
    -- m.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = false, hint_offset = -1 }) -- 往下找，定位在指定位置的「前」一個字母上
    m.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = false })
  end, { desc = "往下找，準確的定位", remap = true })

  vim.keymap.set('', 'T', function()
    -- m.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = false, hint_offset = 1 }) -- 往上找，定位在指定位置的「後」一個字母上
    m.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = false })
  end, { desc = "往上找，準確的定位", remap = true })
end

local function install_gitsigns()
  local ok, plugin = pcall(require, "gitsigns")
  if not ok then
    vim.notify("Failed to load gitsigns", vim.log.levels.ERROR)
    return
  end

  plugin.setup {
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
    numhl = false,     -- Toggle with `:Gitsigns toggle_numhl`
    linehl = false,    -- Toggle with `:Gitsigns toggle_linehl`
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
    status_formatter = nil,  -- Use default
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
          plugin.nav_hunk('next')
        end
      end, { desc = '(git)往下找到異動處' })

      map('n', '[c', function()
        if vim.wo.diff then
          vim.cmd.normal({ '[c', bang = true })
        else
          plugin.nav_hunk('prev')
        end
      end, { desc = '(git)往上找到個異動處' })

      -- Actions
      -- map('n', '<leader>hs', plugin.stage_hunk)
      -- map('n', '<leader>hr', plugin.reset_hunk)
      -- map('v', '<leader>hs', function() plugin.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
      -- map('v', '<leader>hr', function() plugin.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
      -- map('n', '<leader>hS', plugin.stage_buffer)
      -- map('n', '<leader>hu', plugin.undo_stage_hunk)
      -- map('n', '<leader>hR', plugin.reset_buffer)
      -- map('n', '<leader>hn', plugin.next_hunk) -- 同等: plugin.nav_hunk('next')
      map('n', '<leader>hp', plugin.preview_hunk,
        { desc = '(git)Hunk x of x 開啟preview(光標處必需有異動才能開啟), 查看目前光標處的異動, 開啟後常與prev, next使用. 此指令與diffthis很像，但是專注於一列' })

      map('n', '<leader>hb', function()
        plugin.blame_line { full = true }
      end, { desc = '(git)blame 顯示光標處(不限於異動，所有都能)與最新一次commit時的差異' }
      )

      map('v', -- 由於<leader>t對我有用，所以為了避免影響已存在熱鍵的開啟效率，將此toogle設定在view下才可使用
        '<leader>tb', plugin.toggle_current_line_blame,
        { desc = "(git)可以瞭解這一列最後commit的訊息和時間點 ex: You, 6 days, ago - my commit message. 如果不想要浪費效能，建議不用的時候就可以關掉(再下一次指令)" })

      map('n', '<leader>hd', plugin.diffthis,
        { desc = '(git)查看當前文件的所有異動. 如果要看本次所有文件上的異動，可以使用:Telescope git_status' })
      map('n', '<leader>hD', function()
        plugin.diffthis('~')
      end) -- 有包含上一次的提交修改
      -- map('n', '<leader>td', plugin_gitsigns.toggle_deleted)

      -- Text object
      -- map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>') -- 選取而已，作用不大
    end
  }
end


local function install_nvimWebDevicons()
  local ok, m = pcall(require, "nvim-web-devicons") -- 只要這個插件有，不需要用require，nvim-tree就會自動導入，所以也不一定要寫這些配置
  if not ok then
    vim.notify("Failed to load nvim-web-devicons", vim.log.levels.ERROR)
    return
  end
  m.setup {
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
    },
    color_icons = true,
    default = true,
    strict = true,
    variant = "light|dark",
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
    },
    override_by_extension = {
      ["log"] = {
        icon = "",
        color = "#ffff00",
        name = "Log"
      }
    },
    override_by_operating_system = {
      ["apple"] = {
        icon = "",
        color = "#A2AAAD",
        cterm_color = "248",
        name = "Apple",
      },
    },
  }
  -- set_default_icon(icon, color, cterm_color)
  -- m.set_default_icon('😃', '#6d8086', 65)
end


local function install_nvim_tree()
  local ok, m = pcall(require, "nvim-tree")
  if not ok then
    vim.notify("Failed to load nvim-tree", vim.log.levels.ERROR)
    return
  end

  --[[
  USAGE:

  :NvimTreeOpen

  g?
  ]] --
  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwPlugin = 1

  -- optionally enable 24-bit colour
  vim.opt.termguicolors = true

  m.setup({
    sort = {
      sorter = "case_sensitive",
    },
    view = {
      width = 30,
    },
    renderer = {
      -- highlight_opened_files = "name", -- :help highlight_opened_files
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
  -- vim.keymap.set("n", "<leader>t", ":NvimTreeOpen<CR>", { desc = "Open NvimTree" }) -- 可以先將TreeOpen到指定的位置，再用telescope去搜
  vim.keymap.set("n", "<leader>t", ":NvimTreeToggle<CR>", { desc = "toggle NvimTree" })

  local nvim_treeAPI = require "nvim-tree.api"
  vim.keymap.set("n", "<A-t>", function()
      local cur_file_path = vim.fn.expand("%:p")
      vim.cmd("tabnew " .. cur_file_path)
    end,
    { desc = "在新的頁籤開啟當前的文件" }
  )
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


local function install_telescope()
  local ok, m = pcall(require, "telescope")
  if not ok then
    vim.notify("Failed to load telescope", vim.log.levels.ERROR)
    return
  end
  -- 初始化 Telescope
  -- vertical, horizontal. vertical有助於看到整個名稱(但是preview會被壓縮，不過因為我們定義了 <C-p> 為 toggle_preview所以用成horizontal要看清整個名稱也很方便)
  local telescope_layout_strategy = "horizontal"
  local telescope_file_ignore_patterns = {
    "node_modules",
    -- ".git/", -- agit, bgit這種也會匹配到
    "%.git/", -- 這種是精確匹配. 因為 % 會轉譯，也就是.並非任一字元，而是真的匹配.
    -- "^pack\\", -- 忽略pack目錄, 再打指令的時候用一個 \  就好，此外不能用成 /
  }           -- 忽略文件或目錄模式
  m.setup({
    defaults = {
      -- 預設配置
      -- :lua print(vim.inspect(require('telescope.config').values.vimgrep_arguments))
      vimgrep_arguments = {
        "rg", -- man rg
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--smart-case",
        "--fixed-strings" -- 啟用精準匹配
      },
      prompt_prefix = "🔍 ", -- 搜索框前的圖標
      selection_caret = " ", -- 選中時的指示符
      entry_prefix = "  ",
      sorting_strategy = "ascending",
      layout_strategy = telescope_layout_strategy,
      layout_config = {
        prompt_position = "top",
        horizontal = {
          preview_width = 0.6,
        },
        vertical = {
          mirror = true,        -- 翻轉，會影響提示輸入寬的位置, 為false時輸入在中間, preview在上
          width = 0.8,          -- 視窗寬度佔比
          height = 0.9,         -- 視窗高度佔比
          preview_height = 0.5, -- 預覽區域佔整個視窗的比例
          preview_cutoff = 0,   -- 當結果數量少於此值時隱藏預覽, 設為0保證永遠顯示
        },
      },
      file_ignore_patterns = telescope_file_ignore_patterns,
      winblend = 0,
      border = {},
      borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
      path_display = { "truncate" },
      set_env = { ["COLORTERM"] = "truecolor" },                          -- 修正配色
      mappings = {
        n = {                                                             -- 一般模式
          ["<C-p>"] = require('telescope.actions.layout').toggle_preview, -- 切換預覽

          -- ["<leader>l"] = function(prompt_bufnr)                                               -- 用<leader>也可以
          --   local picker = require('telescope.actions.state').get_current_picker(prompt_bufnr) -- 這是mirror的toggle
          --   picker.layout_strategy = "horizontal"
          -- end
        },
        i = {                                                             -- 插入模式
          ["<C-p>"] = require('telescope.actions.layout').toggle_preview, -- 切換預覽
          ["<C-x>"] = function(
          -- prompt_bufnr
          )
            local action_state = require("telescope.actions.state")
            local entry = action_state.get_selected_entry()
            if not entry then
              return
            end

            local commit_sha = entry.value
            -- vim.cmd("tabnew | r !git show " .. commit_sha)

            -- 獲取 Git 根目錄
            local git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
            if vim.v.shell_error ~= 0 then
              vim.notify("Not in a Git repository", vim.log.levels.ERROR)
              return
            end

            -- 執行 git show --name-only 命令，獲取異動檔案列表
            local files = vim.fn.systemlist("git show --name-only --pretty=format: " .. commit_sha)

            -- 獲取 commit 提交訊息（第一行，通常是標題）
            local commit_message = vim.fn.systemlist("git show --pretty=format:%s " .. commit_sha)[1] or
                "No commit message"

            -- 過濾空行並構建 quickfix list 條目
            local qf_entries = {
              { text = string.format("[%s] %s", commit_sha, commit_message) },
              { text = 'term git show --name-only ' .. commit_sha },
              { text = 'term git show ' .. commit_sha .. "  " .. "用i往下走到底可以看到完整內容" },
            }
            for _, file_relativepath in ipairs(files) do
              if file_relativepath ~= "" then -- 忽略空行
                local abs_path = git_root .. "/" .. file_relativepath
                table.insert(qf_entries, {
                  -- filename = file_relativepath, -- 這個僅在git的目錄使用能找到, 如果路徑不在此，得到的清單路徑會是錯的
                  filename = abs_path, -- qflist的路徑(filename)如果是對的，就會自動依據當前的工作目錄去變化
                  lnum = 1,
                  -- text = "File changed in commit " .. commit_sha
                })
              end
            end

            -- 將結果寫入 quickfix list
            if #qf_entries > 0 then
              vim.fn.setqflist(qf_entries)
              vim.cmd("copen") -- 自動打開 quickfix list 視窗
              -- require("telescope.actions").close(prompt_bufnr) -- 關閉 Telescope 視窗, 已經關閉了，不需要再關，不然反而會錯
            else
              vim.notify("No files changed in this commit", vim.log.levels.WARN)
            end
          end
        },
      },
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
    ]] --

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
      ]] --

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


  vim.api.nvim_create_user_command("TelescopeConfig", function(args)
      -- vim.g.tellescope_... 並沒有這些東西，所以如果想要後面再修改這些配置，只能重新setup
      -- local layout_strategy = vim.g.telescope_layout_strategy or "vertical"
      -- local file_ignore_patterns = vim.g.telescope_file_ignore_patterns or { "%.git/" }

      -- 解析 args.args
      local arg_str = args.args
      -- for opt, val in arg_str:gmatch("--(%S+)=([^%s]+)") do -- 使用這種opt的--也會被納入
      for opt, val in arg_str:gmatch("--([a-zA-Z0-9_]+)=([^%s]+)") do
        -- print(opt, val)
        if opt == "layout_strategy" then
          -- 如果有 --layout_strategy=xxx，更新 layout_strategy
          telescope_layout_strategy = val
        elseif opt == "file_ignore_patterns" then
          -- 如果有 --file_ignore_patterns=xxx，將 xxx 以 ; 分割成 table
          local patterns = {}
          for pattern in val:gmatch("[^;]+") do
            table.insert(patterns, pattern)
          end
          telescope_file_ignore_patterns = patterns
        end
      end

      -- 應用配置到 Telescope
      m.setup {
        defaults = {
          layout_strategy = telescope_layout_strategy,
          file_ignore_patterns = telescope_file_ignore_patterns,
        },
      }

      -- 輸出當前配置（可選，方便除錯）
      print("Layout strategy: " .. telescope_layout_strategy)
      print("File ignore patterns: " .. table.concat(telescope_file_ignore_patterns, ", "))
    end,
    {
      desc = "可以調整其相關設定{layout_strategy, file_ignore_patterns, ...}請善用TAB來選擇",
      nargs = "+",
      complete = function(argLead)
        return cmdUtils.get_complete_list(argLead, {
          file_ignore_patterns = table.concat(telescope_file_ignore_patterns or { "%.git/" }, ";"),
          layout_strategy = { "vertical", "horizontal" },
        })
      end,
    })

  -- 我的自定義: search_with_find
  vim.keymap.set("n", "<leader>fr", search_with_find, { desc = "[Find Recent]" })

  -- 搜索當前工作目錄下的文件
  vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "[Find Files]" })
  vim.api.nvim_create_user_command("FindFiles", function(args)
    local opt = {}
    opt.cwd = "."
    if #args.fargs > 0 then
      if args.fargs[1] == "-h" then
        local help = {
          'FindFiles cwd search_file search_dirs...',
          'FindFiles . tags',
          'FindFiles . opt lua/ -- 可能是options.lua也會找到',
          'FindFiles ~ *.{ttf,otf} ~/.fonts/',
          'FindFiles . *.{md,lua} docs/ lua/',
          'FindFiles . README.md docs/ lua/',
          'FindFiles ~ *.myType -- 如果你想要找某一個目錄，你只要確定該目錄下有某一個類型的檔案，接著用開始搜尋的時候，再用篩選去找結果',
        }
        -- vim.notify(table.concat(help, '\n'), vim.log.levels.INFO)
        cmdUtils.showHelpAtQuickFix(help)
        return
      end
      opt.cwd = args.fargs[1]
    end
    if #args.fargs > 1 then
      opt.search_file = vim.split(args.fargs[2], "　", { plain = true })[1]
    end
    if #args.fargs > 2 then
      opt.search_dirs = {}
      for i = 3, #args.fargs do
        table.insert(opt.search_dirs, args.fargs[i])
      end
    end
    -- print(vim.inspect(opt))
    builtin.find_files(opt)
  end, {
    nargs = "*",
    desc = "同Telescope find_files但可以只定搜尋的工作路徑",
    complete = function(argLead, cmdLine, _)
      local parts = vim.split(cmdLine, "%s+")
      local argc = #parts - 1
      local dirs = completion.getDirOnly(argLead)

      if argc == 1 then
        return dirs
      elseif argc == 2 then
        return {
          "search_file",
          ".gitmodules",
          "tags",
          "*.{ttf,otf}",
          "Fira*.ttf",
          "F*.{ttf,otf}",
          "README.md",
        }
      else
        return dirs -- 後面的全部都當成search_dirs
      end
    end
  })

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
  vim.api.nvim_create_user_command("Livegrep", function(args)
    local opt = {}
    if #args.fargs > 0 then
      if args.fargs[1] == "-h" then
        local help = {
          'Livegrep cwd glob_pattern search_dirs...',
          'Livegrep . *.lua lua/ ftplugin/    -- 只在當前的lua, ftplugin兩個目錄中找尋所有lua檔案',
          'Livegrep . key*.lua                -- 例如keymap.lua, key.lua都會被搜到',
          'Livegrep . *.{txt,git}|LICENSE     -- 對附檔名為txt,git以及文件名稱為LICENSE的檔案做內容的搜尋',
          'Livegrep . *.lua|*.md              -- 搜尋所有附檔名為lua,md的文件內容',
          'Livegrep ~ *.{md,sh}',
          'Livegrep . !*.lua                  -- 不找lua檔案',
          'Livegrep . !*.lua|*.md             -- 不找lua和txt檔案',
          'Livegrep . LICENSE                 -- 只找LICENSE文件',
        }
        cmdUtils.showHelpAtQuickFix(help)
        return
      end
      opt.cwd = args.fargs[1] or "."
    end

    if #args.fargs > 1 then
      -- opt.glob_pattern = args.fargs[2] -- 如果是字串，似乎只能一種條件而已
      -- 改成table可以有多個條件
      local glob_pattern_table = vim.split(args.fargs[2], "|", { plain = true }) -- 目前已經將complete的這種方式移除，所以此情況已經不會出現，只是保留此寫法來當作參考
      local glob_pattern = {}
      for _, pattern in ipairs(glob_pattern_table) do
        table.insert(glob_pattern, vim.split(pattern, "　")[1]) -- 只要資料，不要描述
      end
      opt.glob_pattern = glob_pattern
    end


    if #args.fargs > 2 then
      opt.search_dirs = {}
      for i = 3, #args.fargs do
        table.insert(opt.search_dirs, args.fargs[i])
      end
    end
    -- print(vim.inspect(opt))
    builtin.live_grep(opt)
  end, {
    nargs = "*",
    desc = "同Telescope live_grep但可以只定搜尋的工作路徑",
    complete = function(argLead, cmdLine, _)
      local parts = vim.split(cmdLine, "%s+")
      local argc = #parts - 1
      local dirs = completion.getDirOnly(argLead)

      if argc == 1 then
        return dirs
      elseif argc == 2 then
        return {
          "glob_pattern",
          "*.lua",
          "README.md",
          "!*.lua",
          "*.lua|*.md",
        }
      else
        return dirs -- search_dirs
      end
    end
  })

  vim.keymap.set("n",
    "<C-S-f>", -- Ctrl+Shift+f
    -- 'gy:Livegrep <C-R>"<CR>', -- 在tree之中的gy可以複製絕對路徑, Livegrep是我們上面自定義的command <-- 無效
    function()
      require "nvim-tree.api".fs.copy.absolute_path()
      local path = vim.fn.getreg('"')
      builtin.live_grep({ cwd = path })
    end,
    { desc = "在nvim-tree之中可以在某一個目錄進行文本搜尋" }
  )


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
    "<A-f>", -- Alt+f
    builtin.current_buffer_fuzzy_find,
    { desc = "在當前文件進行搜尋" }
  )

  vim.keymap.set("v",
    "<A-f>",
    -- '""y:Telescope current_buffer_fuzzy_find<CR><C-R>"', -- y的預設就會寫入到暫存器的"所以不需要再特別描述
    'y:Telescope current_buffer_fuzzy_find<CR><C-R>"',
    { desc = "用當前選中的文字進行搜尋" }
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
    local force = false
    -- local name = vim.fn.input("bookmarkName: ")
    local name = ""
    if (#params > 0 and params[#params] == "-f") then
      -- 如果有-f，其參數一定在最後
      force = true
      table.remove(params, #params) -- 如此剩下的參數只剩下name
    end

    if args.range > 0 and (#params == 0 or params[1] == "") then
      -- local range_start, range_end = args.line1, args.line2
      -- local lines = vim.api.nvim_buf_get_lines(0, range_start - 1, range_end, false)
      -- name = table.concat(lines, "\n"):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "") -- 先併成一列，移除多餘的空白
      name = rangeUtils.get_selected_text():gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
      if name == "" then
        vim.notify("錯誤：選取範圍為空", vim.log.levels.ERROR)
        return
      end
    else
      -- 沒有 range 的清況，要求必須提供名稱
      if #params == 0 or params[1] == "" then
        vim.notify("錯誤：請提供書籤名稱", vim.log.levels.ERROR)
        return
      end
      name = params[1]
    end

    local filepath = vim.fn.expand("%:p")
    local row, col = unpack(vim.api.nvim_win_get_cursor(0)) -- for lua5.4: table.unpack https://stackoverflow.com/a/65655296/9935654
    if not telescope_bookmark.add(name, filepath, row, col, { force = force }) then
      return
    end
    telescope_bookmark.save {}
    local filename = vim.fn.expand("%:t")
    vim.notify("✅ 書籤已成功保存: " .. name ..
      " filename: " .. filename ..
      " (行: " .. row .. ", 列: " .. col .. ")", vim.log.levels.INFO)
  end, {
    -- nargs = "+", -- 至少1個, 因為改成了range，所以參數就變成可選
    nargs = "*",
    range = true,
    complete = function()
      return {
        "-f",
      }
    end,
    desc = "加入書籤"
  })
  vim.api.nvim_create_user_command("BkAddDir", function(args)
    -- local name = vim.split(args.args, " ")[1]
    local name = args.fargs[1]
    local force = args.fargs[2] == "-f"
    local dirPath = vim.fn.expand("%:p:h")
    if not telescope_bookmark.add(name, dirPath, nil, nil, { force = force }) then
      return
    end
    telescope_bookmark.save {}
    vim.notify("✅已成功建立書籤: " .. name .. "path:" .. dirPath, vim.log.levels.INFO)
  end, {
    nargs = "+",
    complete = function()
      return {
        "-f",
      }
    end,
    desc = "添加目錄到書籤. 如果想要強制覆蓋可以加上-f參數"
  })
  vim.api.nvim_create_user_command("MyLivegrep", function(args)
    local opt = {}
    opt.cwd = "."
    opt.glob_pattern = args.fargs[1] or nil

    opt.search_dirs = {}
    local seen_dirs = {}      -- 防止相同的目錄被重加
    for i = 2, #args.fargs do -- 這樣就算#args.fargs不足i的開始也不會有錯誤，即#args.fargs在一開始若已經小於i就不會執行for
      local dir = args.fargs[i]
      table.insert(opt.search_dirs, dir)
      seen_dirs[dir] = true
    end

    -- -- 讀取 bookmark.lua 檔案
    local bookmark_path = vim.fn.stdpath('config') .. '/bookmark.lua' -- 假設檔案在 ~/.config/nvim/
    local ok, bookmarks = pcall(function()
      return dofile(bookmark_path)
    end)

    if ok and bookmarks then
      for _, bookmark in ipairs(bookmarks) do
        local path = bookmark.path
        local dir
        -- 檢查路徑是否存在
        if vim.fn.isdirectory(path) == 1 then
          -- 如果是目錄，直接加入
          dir = path
        elseif vim.fn.filereadable(path) == 1 then
          -- 如果是檔案，取得其父目錄
          dir = vim.fn.fnamemodify(path, ':h')
        end

        -- 只有在未見過該目錄時才加入
        if dir and not seen_dirs[dir] then
          table.insert(opt.search_dirs, dir)
          seen_dirs[dir] = true
        end
      end
    end

    -- for _, dir in ipairs({
    --   -- "~/.config/nvim/lua/ftplugin/", -- ok
    --   -- "~/.config/nvim/lua/lua/", -- ok
    --   -- "~/.config/nvim/lua/init.lua", -- 似乎不行
    --   -- "~/.config/nvim/doc/*.md", -- 似乎不行
    -- }) do
    --   table.insert(opt.search_dirs, dir)
    -- end

    -- print(vim.inspect(opt))
    require("telescope.builtin").live_grep(opt)
  end, {
    nargs = "*",
    desc = "只搜尋自定義的目錄的內容 (目錄內容來至於bookmark.lua)",
    complete = function(argLead, cmdLine, _)
      local parts = vim.split(cmdLine, "%s+")
      local argc = #parts - 1
      if argc == 1 then
        return {
          "!*.{exe,scm}",
          "*.{html,js,sass,scss,gohtml,css}",
          "*.{go,gohtml,gotmpl,md}",
          "*.{lua,md}",
          "*.lua",
          "lin*.md",
          "README.md",
        }
      else
        return completion.getDirOnly(argLead) -- search_dirs
      end
    end
  })

  vim.api.nvim_create_user_command("Gitst", function()
    require("telescope.builtin").git_status()
  end, {
    desc = "git status"
  })
end


local function install_ibl()
  local ok, m = pcall(require, "ibl") -- pack/other/start/indent-blankline.nvim/lua/ibl
  if not ok then
    vim.notify("Failed to load ibl", vim.log.levels.ERROR)
    return
  end

  vim.api.nvim_create_user_command("Ibl",
    function(args)
      if #args.args == 0 then
        -- 採用最簡單的配置
        m.setup()
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

        m.setup {
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


local function install_lualine()
  local ok, m = pcall(require, "lualine")
  if not ok then
    vim.notify("Failed to load lualine", vim.log.levels.ERROR)
    return
  end
  m.setup {
    sections = {
      lualine_c = {
        {
          'filename',
          -- 以下都是預設，其實可以直將path改成4即可
          file_status = true,     -- Displays file status (readonly status, modified status)
          newfile_status = false, -- Display new file status (new file means no write after created)
          path = 4,               -- 0: Just the filename
          -- 1: Relative path
          -- 2: Absolute path
          -- 3: Absolute path, with tilde as the home directory
          -- 4: Filename and parent dir, with tilde as the home directory

          shorting_target = 40, -- Shortens path to leave 40 spaces in the window
          -- for other components. (terrible name, any suggestions?)
          symbols = {
            modified = '[+]',      -- Text to show when the file is modified.
            readonly = '[-]',      -- Text to show when the file is non-modifiable or readonly.
            unnamed = '[No Name]', -- Text to show for unnamed buffers.
            newfile = '[New]',     -- Text to show for newly created file before first write
          }
        }
      },
      lualine_x = {
        -- indent settings
        function()
          local indent_style = vim.opt_local.expandtab:get() and "Space" or "Tab"
          if indent_style == "Space" then
            local indent_size = vim.opt_local.tabstop:get()
            return indent_size .. " spaces"
          end
          return indent_style
        end,
        'encoding', 'fileformat', 'filetype',
      },
    }
  }
end

local function install_atq()
  local ok, m = pcall(require, "atq")
  if not ok then
    return
  end

  -- :lua require"atq".help()
  -- :lua require"atq".add()
  m.setup()

  --[[
  vim.keymap.set("n",
    "<leader>test",
    function()
    end,
    { desc = "test only" }
  )
  --]]
end


local function install_renderMarkdown()
  local ok, m = pcall(require, "render-markdown")
  if not ok then
    vim.notify("Failed to load render-markdown", vim.log.levels.ERROR)
    return
  end
  m.setup({})
end

local function install_cmp_list()
  local ok, m = pcall(require, "cmp-list")
  if not ok then
    vim.notify("Failed to load cmp-list", vim.log.levels.ERROR)
    return
  end

  m.setup({
    presets = function(
    -- default_config
    )
      return m.deep_merge({}, {
        _global = array.Merge(
          require('external.cmp-list.nvim-cmd'), -- vim中的command相關 :
          require('external.cmp-list.tool'),
          require('external.cmp-list.emoji')
        ),
        sh = array.Merge(
          require('external.cmp-list.sh'),
          require('external.cmp-list.notify')
        ),
        lua = array.Merge(
          require('external.cmp-list.lua'),
          require('external.cmp-list.vim-fn')
        ),
        markdown = array.Merge(
          require('external.cmp-list.markdown')
        ),
      })
    end
  })

  local mWindow = require("cmp-list.window")
  vim.keymap.set(
    "n",
    "<Leader>p",
    mWindow.toggle_floating_window,
    {
      desc = "toogle cmp-list preview window",
      noremap = true,
      silent = true
    }

  )
end


install_nvimTreesitter()
install_lspconfig()
-- install_precognition()
install_hop()
install_gitsigns()
install_nvimWebDevicons()
install_nvim_tree()
install_telescope()

-- theme
-- https://github.com/projekt0n/github-nvim-theme/blob/c106c9472154d6b2c74b74565616b877ae8ed31d/README.md?plain=1#L170-L206
vim.cmd('colorscheme github_dark_default')
install_ibl()
install_lualine()
-- install_atq() -- 可以用command: NotifySend 即可
install_renderMarkdown()
install_cmp_list()

require("global-func")  -- 自定義的一些全域函數，可以使用 :=MyGlobalFunc() 的這種方式來調用

vim.defer_fn(function() -- 因為裡面要計算出，啟動nvim的時間，所以用defer放到最後才執行
  require("config.menu").setup {
    start_time = START_TIME
  } -- 起始畫面
end, 0)

pcall(require, "my-customize") -- 如果有一些自定義的設定，可以自己新增一個my-customize.lua來覆寫
