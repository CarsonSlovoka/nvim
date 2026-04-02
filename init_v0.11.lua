-- Caution: 此腳本已棄用, 保留只為了當成參考

local START_TIME = vim.uv.hrtime() -- 勿調整，用來得知nvim開啟的時間，如果要計算啟動花費時間會有用

-- theme: https://github.com/projekt0n/github-nvim-theme
-- https://github.com/projekt0n/github-nvim-theme/blob/c106c9472154d6b2c74b74565616b877ae8ed31d/README.md?plain=1#L170-L206
vim.cmd('colorscheme github_dark_default') -- 主題要先設定(可以先設定之後再補全它的實作)，不然如果自定義的調整在這之前，又會被此蓋掉

local array = require("utils.array")
local completion = require("utils.complete")
local cmdUtils = require("utils.cmd")
local utils = require("utils.utils")

local HOME = os.getenv("HOME")

-- runtimepath
-- local runtimepath = vim.api.nvim_get_option("runtimepath")
local runtimepath = vim.api.nvim_get_option_value("runtimepath", {})
vim.opt.runtimepath = runtimepath .. ",~/.vim,~/.vim/after"
vim.opt.packpath = vim.opt.runtimepath:get()

-- vim
local vimrcPath = HOME .. "/.vimrc"
if vim.fn.filereadable(vimrcPath) == 1 then
  vim.cmd("source " .. vimrcPath)
end

-- config
require("config.sign_define")
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
require("config.commands_windows")

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
        if args.fargs[1] == "-" then
          -- toggle
          m.autoSave = not m.autoSave
        else
          m.autoSave = args.fargs[1] == "1"
        end
        vim.notify("autoSave: " .. vim.inspect(m.autoSave), vim.log.levels.INFO)
      end,
      {
        nargs = 1,
        complete = function() -- complete 不能直接回傳一個table，一定要用一個function來包裝
          return {
            "1",
            "0",
            "-",
          }
        end,
        desc = "enable autoSave"
      }
    )

    vim.keymap.set({ "n" }, "<C-s>",
      function()
        vim.cmd("SetAutoSave -")
      end,
      {
        -- 自動保存，在頻繁編輯下，一離開insert就保存可能會造成負擔，所以讓其可以被容易切換
        desc = "toggle autosave"
      }
    )
  end
})

if vim.uv.os_uname().sysname == "Linux" then
  require("config.input").fcitx.setup(
    "fcitx5-remote" -- which fcitx5-remote
  )
elseif vim.uv.os_uname().sysname == "Darwin" then
  require("config.input").sim.setup()
end

local function install_nvimTreesitter()
  -- pack/syntax/start/nvim-treesitter
  local status_ok, m = pcall(require, "nvim-treesitter.configs")
  if not status_ok then
    return
  end

  ---@type table
  local parser_list = require("nvim-treesitter.parsers").get_parser_configs()
  -- ~~https://github.com/nvim-treesitter/nvim-treesitter/blob/42fc28ba918343ebfd5565147a42a26580579482/lua/nvim-treesitter/parsers.lua#L60-L83~~
  -- 目前沒有辦法再透過這樣的方式(get_parser_configs)來裝, 因為現行的它在程式中是直接調用，導致: `local parsers = require('nvim-treesitter.parsers')` 得到的內容都是固定的
  -- https://github.com/nvim-treesitter/nvim-treesitter/blob/99dfc5acefd7728cec4ad0d0a6a9720f2c2896ff/lua/nvim-treesitter/config.lua#L139-L151
  -- 👇 目前以下已無效果
  parser_list.strings = { -- :TSInstall strings -- 如果反悔可以用 :TSUninstall strings 來解除
    install_info = {
      revision = '62ee9e1f538df04a178be7090a1428101481d714',
      url = "https://github.com/CarsonSlovoka/tree-sitter-strings",
      -- url = vim.fn.expand("~/tree_sitter_strings"), -- 本機的一直沒有嘗試成功🤔
      files = { "src/parser.c" },
    },
    filetype = "strings", -- Neovim filetype
    maintainers = { "@Carson" },
  }
  -- :TSModuleInfo -- 可以查看安裝的情況

  -- 底下的內容確定不用加(至少來源從github來是如此)
  -- vim.treesitter.language.add('strings',
  --   -- { path = vim.fn.expand("~/.config/nvim/pack/syntax/start/nvim-treesitter/parser/strings.so") },
  --   -- { path = vim.fn.expand("~/tree-sitter-strings/strings.so") }
  -- )

  -- 以下沒用
  -- if "test" then
  --   -- 💡💡 如果只是要讓一個新的項目，沿用某一種已經設計好的filetype, 只需要在 after/syntax/ 之中新增相對應的項目即可，例如: after/syntax/ttx/syntax.lua
  --
  --   -- 新增一個ttx的解析，其本質與xml是相同的，只是讓filetype可以真正的被設定成ttx也能有效果(不想要用xml來表示)
  --   parser_list.ttx = { -- https://github.com/nvim-treesitter/nvim-treesitter/blob/42fc28ba918343ebfd5565147a42a26580579482/lua/nvim-treesitter/parsers.lua#L2678-L2685
  --     install_info = {
  --       url = "https://github.com/tree-sitter-grammars/tree-sitter-xml",
  --       files = { "src/parser.c", "src/scanner.c" },
  --       location = "xml",
  --     },
  --     filetype = "ttx", -- 加了也沒用
  --     maintainers = { "@ObserverOfTime" },
  --   }
  --
  --   require("nvim-treesitter.parsers")
  --   vim.treesitter.language.register("xml", "ttx") -- lang, filetype
  -- end


  -- 💡 如果只是要syntax的突顯，預設nvim就已經有很多種格式，不再需要特別安裝: https://github.com/neovim/neovim/tree/af6b3d6/runtime/syntax
  -- 💡 如果是markdown的codeblock要有突顯，才需要考慮 nvim-treesitter.parsers 安裝, 因為它會有多定義出來的highlight
  -- 💡 已存在的第三方parser參考:
  --    - ~~舊版: https://github.com/nvim-treesitter/nvim-treesitter/blob/42fc28ba918343ebfd5565147a42a26580579482/lua/nvim-treesitter/parsers.lua#L69-L2764~~
  --    - 新版(有新增該版本的雜湊值): https://github.com/nvim-treesitter/nvim-treesitter/blob/99dfc5acefd7728cec4ad0d0a6a9720f2c2896ff/lua/nvim-treesitter/parsers.lua#L1-L2693
  -- Caution: ensure_installed已經不可用: https://github.com/nvim-treesitter/nvim-treesitter/blob/99dfc5acefd7728cec4ad0d0a6a9720f2c2896ff/README.md?plain=1#L59-L69
  m.setup {              -- pack/syntax/start/nvim-treesitter/lua/configs.lua
    ensure_installed = { -- 寫在這邊的項目就不需要再用 :TSInstall 去裝，它會自動裝
      -- ~~:TSModuleInfo 也可以找有哪些內容能裝~~ 已經沒有作用
      -- :TSInstall bash lua go gotmpl python xml json jsonc markdown markdown_inline dart elixir sql diff html latex yaml
      -- :TSInstall all # 👈 Warn: 不要用這個，會裝所有可以裝的項目，會太多
      "bash",
      "lua",

      "go",
      "gotmpl", -- https://github.com/ngalaiko/tree-sitter-go-template -- https://github.com/nvim-treesitter/nvim-treesitter/blob/42fc28ba918343ebfd5565147a42a26580579482/lua/nvim-treesitter/parsers.lua#L896-L902

      "python", -- 為了在markdown突顯

      -- "ttx",
      "xml",

      -- vscode-json-language-server 就有json, jsonc的lsp, 不過沒有json5的lsp
      "json",  -- 為了md上的codeblock突顯
      "jsonc", -- 高亮可以 https://github.com/nvim-treesitter/nvim-treesitter/blob/42fc28ba918343ebfd5565147a42a26580579482/lua/nvim-treesitter/parsers.lua#L1212-L1220
      -- "json5", -- 覺得它的高亮不好，並且也沒有lsp的支持 -- https://github.com/nvim-treesitter/nvim-treesitter/blob/42fc28ba918343ebfd5565147a42a26580579482/lua/nvim-treesitter/parsers.lua#L1204-L1210

      "markdown", "markdown_inline",
      -- "strings" -- ~/.config/nvim/pack/syntax/start/nvim-treesitter/parser/strings.so 會在此地方產生相關的so文件

      "dart",
      "swift",

      "elixir", -- 可用在vhs的demo.tap上: https://github.com/charmbracelet/vhs/blob/517bcda0faf416728bcf6b7fe489eb0e2469d9b5/README.md?plain=1#L719-L737

      "sql",    -- 獲得比較好的highlight

      "diff",   -- gitdiff: https://github.com/the-mikedavis/tree-sitter-diff  (目前前面不可以有多的空白)

      "html",
      "latex",
      "yaml"
    },
    sync_install = false,
    auto_install = false,
    ignore_install = {},
    modules = {},
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
    fold = {
      -- vim.opt.foldmethod = "expr"
      -- vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
      enable = true,
    }
  }
end


local function install_nvimTreesitterContext()
  local status_ok, m = pcall(require, "treesitter-context")
  if not status_ok then
    return
  end
  m.setup {
    enable = true,            -- Enable this plugin (Can be enabled/disabled later via commands): TSContext: enable, disable, toggle
    multiwindow = false,      -- Enable multiwindow support.
    max_lines = 0,            -- How many lines the window should span. Values <= 0 mean no limit.
    min_window_height = 0,    -- Minimum editor window height to enable context. Values <= 0 mean no limit.
    line_numbers = true,
    multiline_threshold = 20, -- Maximum number of lines to show for a single context
    trim_scope = 'outer',     -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
    mode = 'cursor',          -- Line used to calculate context. Choices: 'cursor', 'topline'
    -- Separator between context and content. Should be a single character string, like '-'.
    -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
    separator = nil,
    zindex = 20,     -- The Z-index of the context window
    on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
  }
end

local function install_nvimTreesitterTextobjects()
  if not pcall(require, "nvim-treesitter-textobjects") then
    vim.notify("Failed to load nvim-treesitter-textobjects", vim.log.levels.WARN)
    return
  end

  -- Important: 只要使用的時候，有報錯，例如: `Parser could not be created for buffer 81 and language "swift"` 那麼就使用 :TSInstall swift 即可解決

  -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects/blob/baa6b4ec28c8be5e4a96f9b1b6ae9db85ec422f8/README.md?plain=1#L43-L163
  -- Tip: 也可以參考 [minimal_init.lua](https://github.com/nvim-treesitter/nvim-treesitter-textobjects/blob/baa6b4ec28c8be5e4a96f9b1b6ae9db85ec422f8/scripts/minimal_init.lua#L28-L436)
  -- ~/.config/nvim/pack/syntax/start/nvim-treesitter-textobjects/scripts/minimal_init.lua
  require("nvim-treesitter-textobjects").setup {
    select = {
      -- Automatically jump forward to textobj, similar to targets.vim
      lookahead = true,
      -- You can choose the select mode (default is charwise 'v')
      --
      -- Can also be a function which gets passed a table with the keys
      -- * query_string: eg '@function.inner'
      -- * method: eg 'v' or 'o'
      -- and should return the mode ('v', 'V', or '<c-v>') or a table
      -- mapping query_strings to modes.
      selection_modes = {
        ['@parameter.outer'] = 'v', -- charwise
        ['@function.outer'] = 'V',  -- linewise
        -- ['@class.outer'] = '<c-v>', -- blockwise
      },
      -- If you set this to `true` (default is `false`) then any textobject is
      -- extended to include preceding or succeeding whitespace. Succeeding
      -- whitespace has priority in order to act similarly to eg the built-in
      -- `ap`.
      --
      -- Can also be a function which gets passed a table with the keys
      -- * query_string: eg '@function.inner'
      -- * selection_mode: eg 'v'
      -- and should return true of false
      include_surrounding_whitespace = false,
    },
    move = {
      -- whether to set jumps in the jumplist
      set_jumps = true
    }
  }

  -- keymaps: select
  -- You can use the capture groups defined in `textobjects.scm`
  local select = require "nvim-treesitter-textobjects.select"
  vim.keymap.set({ "x", "o" }, "am", function()
    select.select_textobject("@function.outer", "textobjects")
  end)
  vim.keymap.set({ "x", "o" }, "im", function()
    select.select_textobject("@function.inner", "textobjects")
  end)
  vim.keymap.set({ "x", "o" }, "ac", function()
    select.select_textobject("@class.outer", "textobjects")
  end)
  vim.keymap.set({ "x", "o" }, "ic", function()
    select.select_textobject("@class.inner", "textobjects")
  end)
  -- You can also use captures from other query groups like `locals.scm`
  -- vim.keymap.set({ "x", "o" }, "as", function()
  --   select.select_textobject("@local.scope", "locals")
  -- end)

  -- keymaps: swap
  local swap = require("nvim-treesitter-textobjects.swap")
  vim.keymap.set('n', ')a', function()
    swap.swap_next('@parameter.inner')
  end)
  vim.keymap.set('n', '(a', function()
    swap.swap_previous('@parameter.inner')
  end)

  -- keymaps: move
  local move = require("nvim-treesitter-textobjects.move")

  -- You can also pass a list to group multiple queries.
  vim.keymap.set({ "n", "x", "o" }, "]o", function()
    move.goto_next_start({ "@loop.inner", "@loop.outer" }, "textobjects")
  end)


  local ts_repeat_move = require "nvim-treesitter-textobjects.repeatable_move"
  -- Repeat movement with ; and ,
  -- ensure ; goes forward and , goes backward regardless of the last direction
  -- vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move_next)
  -- vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_previous)
end

local function install_lspconfig()
  -- ⭐ 如果你的neovim是透過source來生成，那麼所有內建的lua都會被放到 /usr/share/nvim/runtime/lua 目錄下，例如:
  --        ~/neovim/runtime/lua/vim/lsp.lua  # 假設你的neovim是clone到家目錄下，那麼此lsp.lua由source建立完成之後，就會被放到以下的目錄
  -- /usr/share/nvim/runtime/lua/vim/lsp.lua  # 而這些檔案正是nvim啟動時候會載入的檔案，如果你真想要debug，可以直接修改這些檔案來print出一些想要看到的資訊
  -- local ok, m = pcall(require, "lspconfig") -- 👈 用neovim內建的lsp即可，頂多去參考nvim-lspconfig這插件的設定即可, 但不需要真的載入該插件


  -- 🧙 ~/.local/state/nvim/lsp.log -- 在:checkhealth其實就可以看到log的路徑和目前log所佔的大小
  -- :h vim.lsp.log_levels
  -- vim.lsp.set_log_level("ERROR") -- 這樣可行，但我覺得用字串不太好
  -- vim.lsp.set_log_level(vim.log.levels.OFF) -- 可以改用變數 -- 🧙 如果有需要可以自己加在my-customize.lua之中

  -- 使用virtual_lines比virtualText或者是diagnostic.open_float的方式都好，所以不再需要這些指令
  --   -- 新增切換虛擬文本診斷的命令
  --   local diagnosticVirtualTextEnable = false
  --   vim.api.nvim_create_user_command(
  --     "ToggleDiagnosticVirtualText",
  --     function(args)
  --       if diagnosticVirtualTextEnable then
  --         vim.diagnostic.config({
  --           virtual_text = false
  --         })
  --       else
  --         -- 診斷訊息顯示在行尾
  --         vim.diagnostic.config({
  --           virtual_text = {
  --             prefix = '●', -- 前綴符號
  --             suffix = '',
  --             format = function(diagnostic)
  --               -- print(vim.inspect(diagnostic))
  --               return string.format([[
  --   code: %s
  --   source: %s
  --   message: %s
  -- ]],
  --                 diagnostic.code,
  --                 diagnostic.source,
  --                 diagnostic.message
  --               )
  --             end,
  --           }
  --         })
  --       end
  --       diagnosticVirtualTextEnable = not diagnosticVirtualTextEnable
  --       if #args.fargs == 0 then
  --         vim.notify("diagnosticVirtualTextEnable: " .. tostring(diagnosticVirtualTextEnable), vim.log.levels.INFO)
  --       end
  --     end,
  --     {
  --       nargs = "?",
  --       desc = "切換診斷虛擬文本顯示"
  --     }
  --   )
  --   vim.cmd("ToggleDiagnosticVirtualText --quite") -- 因為我的預設值設定為false，所以這樣相當改成預設會啟用
  --
  --   --- @type number|nil
  --   local diagnosticHoverAutocmdId
  --   vim.o.updatetime = 250
  --   vim.api.nvim_create_user_command(
  --     "ToggleDiagnosticHover",
  --     function(args)
  --       if diagnosticHoverAutocmdId then
  --         -- 如果已經存在，則刪除特定的自動命令
  --         vim.api.nvim_del_autocmd(diagnosticHoverAutocmdId)
  --         diagnosticHoverAutocmdId = nil
  --       else
  --         -- 創建新的自動命令，並保存其ID
  --         diagnosticHoverAutocmdId = vim.api.nvim_create_autocmd(
  --           { "CursorHold", "CursorHoldI" }, {
  --             callback = function()
  --               vim.diagnostic.open_float(nil, { focus = false })
  --             end
  --           })
  --       end
  --
  --       if #args.fargs == 0 then
  --         vim.notify("DiagnosticHoverEnable: " .. tostring(diagnosticHoverAutocmdId ~= nil), vim.log.levels.INFO)
  --       end
  --     end,
  --     {
  --       nargs = "?",
  --       desc = "切換診斷懸停顯示"
  --     }
  --   )
  --   vim.cmd("ToggleDiagnosticHover --quite")
  vim.diagnostic.config({
    virtual_lines = {
      current_line = true
    },
    -- virtual_text = false,
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = "",
        [vim.diagnostic.severity.WARN] = "",
        [vim.diagnostic.severity.INFO] = "󰋼", -- 💠󰋼 -- 例如: markdown中的連結不存在: Unresolved reference
        [vim.diagnostic.severity.HINT] = "󰌵",
      },
    },
    float = {
      border = "rounded",
      format = function(d) -- 用熱鍵 ]d 會顯示 :h ]d
        return ("%s (%s) [%s]"):format(d.message, d.source, d.code or d.user_data.lsp.code)
      end,
    },
    underline = true,
    jump = {
      float = true,
    },
  })

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

  vim.keymap.set("n", "gbh", function()
      vim.lsp.buf.hover()
    end,
    {
      desc = "💪 vim.lsp.buf.hover() 查看定義與使用方法 (可用<C-W><C-W>跳到出來的窗口)"
    }
  )

  vim.api.nvim_create_user_command(
    "LspBufDocSymbol",
    function(args)
      -- :lua vim.lsp.buf.document_symbol() -- 👈 可以如此，預設會直接寫到location list去
      vim.lsp.buf.document_symbol({
        on_list = function(result)
          local target_kind = args.fargs[1] or "Function"
          -- print(vim.inspect(result))
          local symbols = result.items or {}
          local list = {}

          local cur_line = vim.fn.line(".")
          local select_idx = 0
          for i, symbol in ipairs(symbols) do -- i從1開始
            if symbol.kind == target_kind then
              if symbol.lnum <= cur_line then
                select_idx = i
              end
              table.insert(list, {
                filename = vim.api.nvim_buf_get_name(0),
                lnum = symbol.lnum,
                col = symbol.col,
                text = symbol.text,
              })
            end
          end

          -- vim.fn.setqflist(list, 'r')
          vim.fn.setloclist(0, list, 'r')
          vim.cmd('lopen')
          if select_idx > 0 then         -- 不能是 :cc 0 只能是正整數
            -- vim.cmd('cc ' .. select_idx) -- 可以不用copen也來cc
            vim.cmd('ll ' .. select_idx) -- location list用ll qflist用cc
          end
        end
      })
    end,
    {
      desc = 'for item in vim.lsp.buf.document_symbol.items if item.kind == "Function"',
      nargs = "?",
      complete = function()
        -- local kind_table = {}
        vim.lsp.buf.document_symbol({
          on_list = function(result) -- 這個不會傳到外層，獨立的一個session，變數不共用
            local kind_table = {}
            for _, symbol in ipairs(result.items) do
              if kind_table[symbol.kind] == nil then
                kind_table[symbol.kind] = true
              end
            end
            local kinds = {}
            for kind, _ in pairs(kind_table) do
              table.insert(kinds, kind)
            end

            vim.w.cur_lsp_buf_document_symbol = table.concat(kinds, ",") -- 會有延遲到補全，但總比都沒有好
          end
        })
        local cmp = {}

        if vim.w.cur_lsp_buf_document_symbol then
          cmp = vim.split(vim.w.cur_lsp_buf_document_symbol, ",")
        end
        return cmp
      end
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


local function install_leap()
  local ok, _ = pcall(require, "leap")
  if not ok then
    vim.notify("Failed to load leap", vim.log.levels.ERROR)
    return
  end
  vim.go.ignorecase = true
  require('leap').setup({
    -- cd pack/motion/start/leap.nvim && git show f19d4359:lua/leap/main.lua | bat -l lua -P -r 79:83
    case_sensitive = false, -- 第一鍵不區分大小寫, 第二個按鍵還是會分, 如果要第二鍵不分要讓vim.go.ignorecase為true
  })

  vim.keymap.set({ 'n', 'x', 'o' }, 's', '<Plug>(leap)')
  vim.keymap.set('n', 'S', '<Plug>(leap-from-window)')
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
          -- 例如在: gitsigns.diffthis 的視窗開啟時 (<leader>hd)
          vim.cmd.normal({ vim.v.count1 .. ']c', bang = true })
        else
          -- Warn: 用以下方式，有的跳轉是不對的
          -- for _ = 1, vim.v.count1 do
          --   plugin.nav_hunk('next')
          -- end
          plugin.nav_hunk('next', { count = vim.v.count1 })
        end
      end, { desc = '(git)往下找到異動處' })

      map('n', '[c', function()
        if vim.wo.diff then
          vim.cmd.normal({ vim.v.count1 .. '[c', bang = true })
        else
          plugin.nav_hunk('prev', { count = vim.v.count1 })
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
      -- 也可以考慮用 <C-W>T  把目前視窗「搬」到新 tab (原本視窗會消失)
      vim.cmd("tabnew " .. cur_file_path) -- 會保留原本視窗，新 tab 顯示相同 buffer
    end,
    { desc = "在新的頁籤開啟當前的文件" }
  )
  vim.api.nvim_create_user_command("CD",
    function(args)
      --- @type string
      local path
      if args.range == 0 then
        if #args.args > 0 then
          path = args.fargs[1]
        else
          path = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
          if vim.v.shell_error ~= 0 then
            path = "~"
          end
        end
      else
        -- range
        path = table.concat(utils.range.get_selected_text(), "")
      end
      -- NOTE: 在nvim-tree上做CD的路徑和當前編輯的是不同的工作路徑, 如果有需要可以在nvim-tree: gf 複製絕對路徑後使用CD切換
      vim.cmd("cd " .. path)
      nvim_treeAPI.tree.open({ path = path })
      nvim_treeAPI.tree.change_root(path)
    end,
    {
      nargs = "?", -- 預設為0，不接受參數, 1: 一個, *多個,  ? 沒有或1個,  + 一個或多個
      desc = "更改工作目錄",
      range = true,
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
  local actions = require "telescope.actions"
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
      set_env = { ["COLORTERM"] = "truecolor" }, -- 修正配色
      mappings = {
        -- TIP: https://github.com/nvim-telescope/telescope.nvim/blob/b4da76be54691e854d3e0e02c36b0245f945c2c7/lua/telescope/mappings.lua#L133-L233
        n = {                                                             -- 一般模式
          ["<C-p>"] = require('telescope.actions.layout').toggle_preview, -- 切換預覽

          -- ["<leader>l"] = function(prompt_bufnr)                                               -- 用<leader>也可以
          --   local picker = require('telescope.actions.state').get_current_picker(prompt_bufnr) -- 這是mirror的toggle
          --   picker.layout_strategy = "horizontal"
          -- end
          ["K"] = actions.preview_scrolling_up,
          ["J"] = actions.preview_scrolling_down,
          ["H"] = actions.preview_scrolling_left,
          ["L"] = actions.preview_scrolling_right,
        },
        i = { -- 插入模式
          ["<C-k>"] = actions.preview_scrolling_up,
          ["<C-j>"] = actions.preview_scrolling_down,
          ["<C-h>"] = actions.preview_scrolling_left,
          ["<C-l>"] = actions.preview_scrolling_right,

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
  -- vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "可以找到最近開啟的buffer" })

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

  vim.api.nvim_create_user_command("TelescopeBookmarks", require "config.telescope_bookmark".show, {})
  vim.keymap.set("n", "<leader>bk", require "config.telescope_bookmark".show,
    { noremap = true, silent = true, desc = "Telescope 書籤選擇" })
  vim.api.nvim_create_user_command("MyLivegrep", function(args)
    local opt = {}
    local no_auto_dir = false
    for i = 1, #args.fargs do
      local str = args.fargs[i]
      -- string.sub(str, 1, 2) == "--" 這個也行
      if str:match("^%-%-no%-auto%-dir") then
        no_auto_dir = true
        table.remove(args.fargs, i)
        break
      end
    end

    opt.cwd = "."
    opt.glob_pattern = args.fargs[1] or nil

    opt.search_dirs = {}
    local seen_dirs = {}      -- 防止相同的目錄被重加
    for i = 2, #args.fargs do -- 這樣就算#args.fargs不足i的開始也不會有錯誤，即#args.fargs在一開始若已經小於i就不會執行for
      local dir = args.fargs[i]
      table.insert(opt.search_dirs, dir)
      seen_dirs[dir] = true
    end

    --[[ ~~讀取 bookmark.lua 檔案~~ 已經棄用，因為書籤可會會被切換，所以用抓取telescope_bookmark.table的內容才對
    -- local bookmark_path = vim.fn.stdpath('config') .. '/bookmark.lua' -- 假設檔案在 ~/.config/nvim/
    -- local ok, bookmarks = pcall(function()
    --   return dofile(bookmark_path)
    -- end)
    --
    -- for _, bookmark in ipairs(bookmarks) do
    --]]

    -- print(vim.inspect(telescope_bookmark.table))
    for _, bookmark in ipairs(require "config.telescope_bookmark".table) do
      local path = bookmark.path
      local dir
      -- 檢查路徑是否存在
      if vim.fn.isdirectory(path) == 1 then
        -- 如果是目錄，直接加入
        dir = path
      elseif not no_auto_dir and vim.fn.filereadable(path) == 1 then
        -- 如果是檔案，取得其父目錄
        dir = vim.fn.fnamemodify(path, ':h')
      end

      -- 只有在未見過該目錄時才加入
      if dir and not seen_dirs[dir]
          and dir ~= os.getenv("HOME") -- 如果已經有家目錄，找的範圍就已經很大了，其實已經沒什麼意義了
      then
        table.insert(opt.search_dirs, dir)
        seen_dirs[dir] = true
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
      if string.sub(argLead, 1, 2) == "--" then
        return {
          "--no-auto-dir"
        }
      end

      local parts = vim.split(cmdLine, "%s+")
      local argc = #parts - 1

      -- 不要因為可選項影響了自動完成
      for i = 1, #parts do
        if string.sub(parts[i], 1, 2) == "--" then
          argc = argc - 1
        end
      end

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

  vim.api.nvim_create_user_command("MyFindFiles", function(args)
    local opt = {}
    local no_auto_dir = false
    for i = 1, #args.fargs do
      local str = args.fargs[i]
      -- string.sub(str, 1, 2) == "--" 這個也行
      if str:match("^%-%-no%-auto%-dir") then
        no_auto_dir = true
        table.remove(args.fargs, i)
        break
      end
    end

    opt.cwd = "."
    opt.search_file = args.fargs[1] or nil
    opt.search_dirs = {}
    local seen_dirs = {}
    for i = 2, #args.fargs do
      local dir = args.fargs[i]
      table.insert(opt.search_dirs, args.fargs[i])
      seen_dirs[dir] = true
    end

    for _, bookmark in ipairs(require "config.telescope_bookmark".table) do
      local path = bookmark.path
      local dir
      -- 檢查路徑是否存在
      if vim.fn.isdirectory(path) == 1 then
        -- 如果是目錄，直接加入
        dir = path
      elseif not no_auto_dir and vim.fn.filereadable(path) == 1 then
        -- 如果是檔案，取得其父目錄
        dir = vim.fn.fnamemodify(path, ':h')
      end

      -- 只有在未見過該目錄時才加入
      if dir and not seen_dirs[dir]
          and dir ~= os.getenv("HOME") -- 如果已經有家目錄，找的範圍就已經很大了，其實已經沒什麼意義了
      then
        table.insert(opt.search_dirs, dir)
        seen_dirs[dir] = true
      end
    end

    -- print(vim.inspect(opt))
    builtin.find_files(opt)
  end, {
    nargs = "*",
    desc = "只搜尋自定義的目錄 (目錄內容來至於bookmark.lua)",
    complete = function(argLead, cmdLine, _)
      if string.sub(argLead, 1, 2) == "--" then
        return {
          "--no-auto-dir"
        }
      end

      local parts = vim.split(cmdLine, "%s+")
      local argc = #parts - 1

      -- 不要因為可選項影響了自動完成
      for i = 1, #parts do
        if string.sub(parts[i], 1, 2) == "--" then
          argc = argc - 1
        end
      end

      if argc == 1 then
        return {
          ".gitmodules",
          "tags",
          "*.{ttf,otf}",
          "Fira*.ttf",
          "F*.{ttf,otf}",
          "README.md",
        }
      else
        return completion.getDirOnly(argLead) -- 後面的全部都當成search_dirs
      end
    end
  })
end


local function install_fzf_lua()
  if not pcall(require, "fzf-lua") then
    vim.notify("Failed to load fzf-lua", vim.log.levels.ERROR)
    return
  end
  -- https://github.com/ibhagwan/fzf-lua
  -- :checkhealth fzf_lua
  require("fzf-lua").setup({
    winopts = {
      row = 10,
      col = 0,
      preview = {
        hidden = false, -- 啟動時顯示預覽
      },
      fullscreen = true,
    },
    keymap = {
      builtin = {
        -- ['<C-p>'] = 'preview-up', 👈 預設就是如此
        -- ['<C-n>'] = 'preview-down',
        -- ['<A-h>'] = 'preview-page-left', 沒有這選項
        -- ['<A-l>'] = 'preview-page-right',
        ['<A-p>'] = 'preview-page-up',
        ['<A-n>'] = 'preview-page-down',
        ['<C-t>'] = 'toggle-preview', -- 用 Ctrl+T 來 toggle 預覽視窗（隱藏/顯示）
      },
    },
    buffers = {
      actions = {
        -- ["alt-d"] = require("fzf-lua.actions").buf_del, -- 刪除 buffer, 但之後離開視窗了
        ["alt-d"] = function(selected, opts) -- 使其可以像require("telescope.builtin").buffers那樣也可以用alt-d來刪除
          require("fzf-lua.actions").buf_del(selected, opts)

          -- 再重新載入 buffer 清單，保持 fzf 視窗不關閉
          require("fzf-lua").buffers({ fzf_opts = { ["--no-clear"] = "" }, resume = true })
        end
      },
      winopts = {
        preview = {
          vertical = "down:50%", -- preview 顯示在下方，高度 50%（可調整）
          -- border = "rounded",    -- 邊框樣式（可選）
          layout = "vertical",   -- 確保使用垂直佈局 👈 這個才是將preview, 放在下方的關鍵
        },
      },
    }
  })
  vim.keymap.set('n', '<leader>st',
    function()
      local cur_dir = vim.fn.expand("%:p:h")
      vim.cmd("cd " .. cur_dir)
      -- require("telescope.builtin").git_status()
      require("fzf-lua").git_status({ resume = true })
    end,
    {
      desc = "git status"
    }
  )
  vim.keymap.set("n", "<leader>fb", function()
      require("fzf-lua").buffers({ resume = true })
      -- vim.api.nvim_input("<F5>") -- ~~toggle-preview-cw buffer的檔案路徑會比較長,所以將preview改到下方~~ 這可行，但是很取巧，直接對buffers.winopts設定是比較好的做法
    end,
    {
      desc = "可以找到最近開啟的buffer. support: Fuzzy Search"
    }
  )
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
        -- 'encoding', -- 這也可，但是預設不會顯示bomb
        {
          'encoding',
          show_bomb = true
        },
        'fileformat', 'filetype',
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
  -- m.setup({})
  m.setup({
    -- 預設就是true, 除非不想要TSInstall它們，也不想要看到警告，才需要考慮將其設定為false
    -- html = { enabled = true },
    -- latex = { enabled = false }, -- ⚠️ WARNING none installed: { "utftex", "latex2text" } => brew install utftex  就可解決
    -- yaml = { enabled = true },
  })

  -- vim.api.nvim_create_user_command("RenderMarkdownToggle",
  --   function()
  --     local state = require('render-markdown.state')
  --     local enabled = state.enabled
  --     require('render-markdown').toggle()
  --     if enabled then -- 如果當下啟用，表示要關閉它，此時要調整conceallevel設定為0讓它都能看到
  --       vim.cmd("set conceallevel=0")
  --       vim.opt_local.conceallevel = 0
  --
  --       -- else -- 另一種狀態表示要啟用, 那麼render-markdown會自動將conceallevel改為3
  --     end
  --   end,
  --   {
  --     desc = "RenderMarkdown disable/enable"
  --   }
  -- )
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

  -- 如果有需要可以用以下的方式在不同的lua檔案新增自己要的內容
  -- m.config.presets["text"] = utils.array.Merge(
  --   {
  --     { word = 'a123', kind = "test" },
  --   }
  -- )
  -- m.config.presets["_global"] = utils.array.Merge(
  --   m.config.presets._global,
  --   {
  --     { word = 'test12345', kind = "abcd" },
  --   }
  -- )

  -- 🧙 👇 可以用以下的方式在自定的lua檔案新增，例如: my-customize 新增自定義的嘸蝦米查找列表
  -- require("cmp-list").config.presets["_global"] = require("utils.utils").array.Merge(
  --   require("cmp-list").config.presets._global,
  --   require('external.cmp-list.boshiamy').setup({ { "觀察", "rmr nja" }, { "觀看", "rmr hmo" }, })
  -- )
  -- print(vim.inspect(m.config.presets["_global"]))

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
  -- vim.cmd("SetCmpListEnablePreviewWindow 0")
end


local function install_dapui()
  local dapui = require "dapui" -- https://github.com/rcarriga/nvim-dap-ui
  dapui.setup({
    layouts = {
      -- scopes, breakpoints, stacks, watches, repl, console 共有這些可以設定: https://github.com/rcarriga/nvim-dap-ui/blob/73a26abf4941aa27da59820fd6b028ebcdbcf932/lua/dapui/init.lua#L90-L96
      -- 而每一個元素可以是這幾種的組合而成
      {
        elements = {
          -- { id = "scopes", size = 0.5 }, -- 調整 Scopes 的大小
          "scopes",
          -- "breakpoints",
          -- "stacks",
          "watches",
        },
        size = 5, -- 檢視的列(沒用到那麼多還是會佔那樣的空間)
        position = "bottom",
      },
      -- {
      --   elements = { "repl", "console" },
      --   size = 0.25,
      --   position = "bottom",
      -- },
    },
  })
  vim.api.nvim_create_user_command("DapUIOpen",
    function()
      dapui.open()
    end,
    { desc = "dapui.open()" }
  )
  vim.api.nvim_create_user_command("DapUIClose",
    function()
      dapui.close()
    end,
    { desc = "dapui.close()" }
  )

  for _, e in ipairs({
    -- :DapU*stac*s 再搭配Tab來選
    "scopes",
    "breakpoints",
    "stacks",
    "watches",
    "repl",
    "console"
  }) do
    vim.api.nvim_create_user_command("DapUI" .. e,
      function()
        dapui.float_element(e, {
          width = math.ceil(vim.api.nvim_win_get_width(0) * 3 / 4),
          height = math.ceil(vim.api.nvim_win_get_height(0) / 2),
          enter = true
        })
      end,
      {
        desc = "Open DAP " .. e .. "若要永久固定可以將其放到tab上"
      }
    )
  end

  vim.api.nvim_create_user_command("DapUI",
    function(args)
      local elem = args.fargs[1]
      vim.cmd("e DAP " ..
        elem:sub(1, 1):upper() .. -- 首字母大小
        elem:sub(2)
      )
    end,
    {
      desc = ":e DAP {Breakpoints, Scopes, Stacks, Watches, Repl}",
      nargs = 1,
      complete = function(arg_lead)
        return vim.tbl_filter(function(name)
          return name:match(arg_lead)
        end, {
          "scopes",
          "breakpoints",
          "stacks",
          "watches",
          "repl",
        })
      end
    }
  )
end


local function install_nvim_dap()
  -- :helptags ALL
  local ok, dap = pcall(require, "dap")
  if not ok then
    vim.notify("Failed to load dap", vim.log.levels.ERROR)
    return
  end

  install_dapui()

  require("external.dap.go")

  -- dap.configurations.<filetype>
  --
  require("dap").adapters.custom = {
    type = 'executable',
    command = "echo", -- 找一個不重要的指令, 為了通過require("dap")而已 -- 這個工具在 Linux / macOS / Windows shell 都有
  }

  require("external.dap._tutorial") -- 教學測試用
  require("external.dap.dart")
  require("external.dap.lua")
  require("external.dap.opentype")
  require("external.dap.python")
  require("external.dap.swift")
  require("external.dap.javascript")
  require("external.dap.rust")

  require("external.dap.ttx")

  require("external.dap.keymap")


  vim.api.nvim_create_user_command("DapSetBreakpoint",
    function()
      vim.ui.input(
        { prompt = "Condition (ex: i == 5 || i == 9 ): " },
        function(condition)
          dap.set_breakpoint(condition) -- 例如在for迴圈後使用 i == 5
        end
      )
    end,
    {
      desc = "Conditional Breakpoint"
    }
  )
  vim.keymap.set("n", "<leader>bc", function()
    vim.cmd("DapSetBreakpoint")
  end, { desc = "Conditional Breakpoint" })
end

--- 只要將flutter-tools放到pack下就可以了，它的flutter-tools/lsp/init.lua在開啟dart相關專案就會自動啟動
--- https://github.com/nvim-flutter/flutter-tools.nvim/blob/8fa438f36fa6cb747a93557d67ec30ef63715c20/lua/flutter-tools/lsp/init.lua#L17
--- 因此若沒有要debug而只要很基礎的lsp支持, 甚至可以不寫
local function install_flutter_tools()
  local ok, m = pcall(require, "flutter-tools")
  if not ok then
    vim.notify("Failed to load flutter-tools", vim.log.levels.WARN)
    return
  end
  -- https://github.com/nvim-flutter/flutter-tools.nvim/blob/8fa438f36fa6cb747a93557d67ec30ef63715c20/README.md?plain=1#L198-L298
  m.setup { -- https://github.com/nvim-flutter/flutter-tools.nvim/blob/8fa438f36fa6cb747a93557d67ec30ef63715c20/lua/flutter-tools/config.lua#L71-L130
    -- flutter_path = vim.fn.expand("~/development/flutter/bin/flutter"), -- 如果已經能在PATH找到，預設就會自己抓了，不需要再特別寫
    root_patterns = { ".git", "pubspec.yaml" },

    -- fvm = false,   -- fvm是用來對 Flutter 做版本管理. 預設為不啟用

    ui = {
      border = "rounded",
      notification_style = 'native',
    },

    decorations = {
      statusline = {
        app_version = false,
        device = true,
        project_config = false,
      }
    },

    widget_guides = {
      enabled = true, -- 啟用 Widget 指引 -- 啟用後return會有相關的線條導引之類的: https://github.com/nvim-flutter/flutter-tools.nvim?tab=readme-ov-file#widget-guides-experimental-default-disabled
    },
    closing_tags = {
      highlight = "@comment", -- https://github.com/nvim-flutter/flutter-tools.nvim?tab=readme-ov-file#closing-tags
      prefix = "🔹",
      priority = 10,
      enabled = true
    },
    debugger = {
      -- debug的步驟: 以下可參考: lua/external/dap/dart.lua
      -- 1. 先使用 :FlutterRun 來選擇對應的device,
      -- 2. 在 main.dart 使用 :lua require("dap").continue() 也可以用 :DapContinue (此內容已經被加到F5)
      --    2.1 選擇 launch flutter 或 connect flutter 都可以
      -- 3. 等待啟動(可能要10~20之間)
      -- (在debug中，如果進入到thread中，想再繼續，請使用 :DapContinue 並選擇1: Resume Stopped thread) 即可
      enabled = true, -- 👈 這要設定才可以使用dap, 不然問完要使用哪一個device啟動後就沒下文了
      exception_breakpoints = {},
      evaluate_to_string_in_debug_views = true,
      -- register_configurations = function(paths)
      --   require("dap").configurations.dart = {
      --     -- your custom configuration
      --   }
      -- end,
    },
    lsp = {
      debug = require("flutter-tools.config").debug_levels.WARN,
      color = {
        enabled = true,
        background = false,
        foreground = false,
        virtual_text = true,
        virtual_text_str = "■",
        background_color = nil,
      },
    },
  }
end

local function install_ccc()
  -- -- vim.opt.termguicolors = true

  local ok, ccc = pcall(require, "ccc")
  if not ok then
    vim.notify("Failed to load ccc", vim.log.levels.WARN)
    return
  end
  -- local mapping = ccc.mapping

  ccc.setup({
    highlighter = {
      auto_enable = true,
      lsp = true,
    },
  })
end

local function install_pantran()
  local ok, _ = pcall(require, "pantran")
  if not ok then
    vim.notify("Failed to load pantran", vim.log.levels.WARN)
    return
  end

  -- :'<,'>Pantran mode=hover target=zh -- target是要看engine來決定
  -- google: (缺點是如果是一些程式語言的語法，它可以也會一併翻，或者將 ", [ 變成全形，deepl的狀況會比較少)
  -- :'<,'>Pantran engine=google mode=hover target=ja
  -- :'<,'>Pantran engine=google mode=hover target=zh-CN
  -- :'<,'>Pantran engine=google mode=hover target=zh-TW
  -- :'<,'>Pantran mode=replace source=zh-TW target=en -- 將中文轉成英文, 並直接取代

  -- deepl: languages supported: https://developers.deepl.com/docs/getting-started/supported-languages
  -- 注意！supported-languages有區分 source 和 target
  -- :'<,'>Pantran engine=deepl mode=hover target=zh
  -- :'<,'>Pantran engine=deepl mode=hover target=zh-HANS  (簡體中文)
  -- :'<,'>Pantran engine=deepl mode=hover target=zh-HANT  (繁體中文)
  -- :'<,'>Pantran mode=replace source=ZH target=JA engine=deepl  -- source只有ZH, 無特別再區分ZH-HANS, ZH-HANT 而target可以有區分
  require("pantran").setup {
    -- Default engine to use for translation. To list valid engine names run
    -- `:lua =vim.tbl_keys(require("pantran.engines"))`.
    default_engine = "google", -- "deepl", -- https://github.com/potamides/pantran.nvim/blob/b87c3ae48cba4659587fb75abd847e5b7a7c9ca0/doc/README.md?plain=1#L17-L19
    -- Configuration for individual engines goes here.
    engines = {
      yandex = {
        -- Default languages can be defined on a per engine basis. In this case
        -- `:lua require("pantran.async").run(function()
        -- vim.pretty_print(require("pantran.engines").yandex:languages()) end)`
        -- can be used to list available language identifiers.
        default_source = "auto",
        default_target = "en",
      },
      -- google = { -- 用google預設是用非官方的端點，才會是免費的，如果要用官方的要去申請api-key
      --   default_target = "zh" -- 使用ui的時候看到的還是英文
      -- }
      deepl = {
        -- https://github.com/potamides/pantran.nvim/blob/b87c3ae48cba4659587fb75abd847e5b7a7c9ca0/lua/pantran/engines/deepl.lua#L75-L85
        -- 付費endpoint: https://api.deepl.com/v2/translate
        -- 免費endpoint: https://api-free.deepl.com/v2/translate
        free_api = true, -- 預設就是，這是因為deepl它免費和附費用的endpoint不同的關係

        -- auth_key:
        -- 使用secret-tool來儲放auth_key: `secret-tool store --label="DEEPL" DEEPL API_KEY`
        -- 接著設定環境變數，例如:.bashrc加入: `export DEEPL_AUTH_KEY="$(secret-tool lookup DEEPL API_KEY )"`
        -- 這樣的好處是至少不會用明碼來保存key
        auth_key = os.getenv("DEEPL_AUTH_KEY")
      }
    },
    controls = {
      mappings = {
        edit = {
          n = {
            -- Use this table to add additional mappings for the normal mode in
            -- the translation window. Either strings or function references are
            -- supported.
            ["j"] = "gj",
            ["k"] = "gk"
          },
          i = {
            -- Similar table but for insert mode. Using 'false' disables
            -- existing keybindings.
            ["<C-y>"] = false,
            ["<C-a>"] = require("pantran.ui.actions").yank_close_translation
          }
        },
        -- Keybindings here are used in the selection window.
        select = {
          n = {
            -- ...
          }
        }
      }
    }
  }

  vim.api.nvim_create_user_command(
    "PantranLangs",
    function()
      require("pantran.async").run(
        function()
          -- 這好像不對，感覺只是呈現此結果: https://github.com/potamides/pantran.nvim/blob/b87c3ae48cba4659587fb75abd847e5b7a7c9ca0/lua/pantran/engines/fallback/google.lua#L17-L128
          -- vim.pretty_print(require("pantran.engines").yandex:languages())
          print(vim.inspect(require("pantran.engines").yandex:languages()))
        end
      )
    end,
    {
      nargs = 0,
      desc = "顯示在目前Pantran下的引擎其所有可用的語言",
    }
  )
end

local function install_image()
  -- 如果是在 kitty 終端機啟動，就會有這個環境變數
  if os.getenv("KITTY_PID") == nil then
    return
  end
  -- print("Running in Kitty terminal")

  local ok, _ = pcall(require, "image")
  if not ok then
    vim.notify("Failed to load image", vim.log.levels.WARN)
    return
  end

  -- 啟動kitty後，如果查看markdown沒有看到圖片
  -- 1. 關閉nvim後，啟動kitty先嘗試看看圖片是否能正常顯示: `kitty +kitten icat https://sw.kovidgoyal.net/kitty/_static/kitty.svg`
  -- 2. 如果有看到，那麼可以再該markdown文件用 :e 重新載入頁面應該就會出現
  local config = {
    backend = "kitty",
    -- processor 的magick_cli, magick_rock 不是指執行檔，而是image.nvim裡面的子lua腳本
    -- 如果用的是magick_cli只需要convert, identify兩個執行檔即可: https://github.com/3rd/image.nvim/blob/4c51d6202628b3b51e368152c053c3fb5c5f76f2/lua/image/processors/magick_cli.lua#L3-L10
    -- convert, identify 都在裝完 imagemagick 就會取得
    processor = "magick_cli", -- or "magick_rock"
    integrations = {
      markdown = {
        enabled = true,
        clear_in_insert_mode = false,
        download_remote_images = true,
        only_render_image_at_cursor = true,
        only_render_image_at_cursor_mode = "inline", -- popup, inline
        floating_windows = false,                    -- if true, images will be rendered in floating markdown windows
        filetypes = { "markdown", "vimwiki" },       -- markdown extensions (ie. quarto) can go here
      },
      neorg = {
        enabled = true,
        filetypes = { "norg" },
      },
      typst = {
        enabled = true,
        filetypes = { "typst" },
      },
      html = {
        enabled = false,
      },
      css = {
        enabled = false,
      },
    },
    max_width = nil,
    max_height = nil,
    max_width_window_percentage = nil,
    max_height_window_percentage = 50,
    window_overlap_clear_enabled = false,    -- toggles images when windows are overlapped
    window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "snacks_notif", "scrollview", "scrollview_sign" },
    editor_only_render_when_focused = false, -- auto show/hide images when the editor gains/looses focus
    tmux_show_only_in_active_window = false, -- auto show/hide images in the correct Tmux window (needs visual-activity off)
    hijack_file_patterns = {
      "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif",
      "*.ico" -- 👈 這個會影響到 gf 時候是否能看到, 而markdown中的image連結則不受此影響，沒有加也看的到
    },        -- render image files as images when opened
  }
  require("image").setup(config)


  vim.api.nvim_create_user_command("ImageToggle",
    function()
      if require("image").is_enabled() then
        require("image").disable()
      else
        require("image").enable()
      end
      vim.notify("image.nvim is_enabled: " .. tostring(require("image").is_enabled()), vim.log.levels.INFO)
    end,
    {
      nargs = 0,
      desc = "image.nvim toggle"
    }
  )
  vim.api.nvim_create_user_command("DisplayImageSettings",
    function(args)
      -- TIP: 可透過 :lua print(vim.inspect(require("image").get_images())) 查看圖片，以及瞭解設定

      local cfg = utils.cmd.get_cmp_config(args.fargs)
      local markdown_config = config.integrations.markdown

      ---@type boolean
      local at_cursor
      if cfg["at_cursor"] == "toggle" then
        at_cursor = not markdown_config.only_render_image_at_cursor
      elseif cfg["at_cursor"] then
        at_cursor = cfg["at_cursor"] == "1"
      else
        at_cursor = true
      end

      ---@type string "inline" or "popup"
      local cursor_mode
      if not at_cursor and cfg["at_cursor"] ~= nil then
        -- 只有變成inline時可以全部顯示
        cursor_mode = "inline"
      else
        cursor_mode = cfg["cursor_mode"] or "inline"
      end

      markdown_config.only_render_image_at_cursor = at_cursor

      if cursor_mode == "inline" or cursor_mode == "popup" then
        markdown_config.only_render_image_at_cursor_mode = cursor_mode
      else
        vim.api.nvim_echo({
          { '❌ cursor_mode should be ', "Normal" },
          { 'inline', '@label' },
          { ' or ', "Normal" },
          { 'popup', '@label' },
        }, false, {})
      end


      if cfg["enabled"] then
        -- WARN: 直接改此設定值不能從disabled變成enable, 所以後面還需要調用 enable() 或 disable
        if cfg["enabled"] == "toggle" then
          markdown_config.enabled = not markdown_config.enabled
        else
          markdown_config.enabled = cfg["enabled"] == "1" or false
        end
      end

      for _, key in ipairs({ "max_height", "max_width" }) do
        if cfg[key] then
          config[key] = cfg[key] == "nil" and nil or tonumber(cfg[key])
        end
      end

      -- 目前image.nvim似乎沒有提供其它的config可以再改裡面的設定，所以只能重新setup
      -- print(vim.inspect(config))

      if cfg["enabled"] then
        if markdown_config.enabled then
          require("image").enable()
        else
          require("image").disable()
        end
      end

      require("image").setup(config)
    end,
    {
      nargs = '*',
      desc = "image.nvim.setup(...)",
      complete = function(arg_lead, cmd_line)
        local comps = {}
        local argc = #(vim.split(cmd_line, '%s+')) - 1
        local prefix, suffix = arg_lead:match('^(.-)=(.*)$')

        -- 使得已經輸入過的選項，不會再出現
        local exist_comps = {}
        if argc > 1 then
          for _, key in ipairs(vim.split(cmd_line, '%s+')) do
            local k, _ = key:match('^(.-)=(.*)$')
            if k then
              exist_comps[k .. "="] = true
            end
          end
        end

        if not prefix then
          suffix = arg_lead
          prefix = ''
        end
        local need_add_prefix = true
        if argc == 0 or not arg_lead:match('=') then
          comps = vim.tbl_filter(function(item) return not exist_comps[item] end, -- 過濾已輸入過的選項
            {
              'enabled=', 'at_cursor=', 'cursor_mode=',
              'max_width=', 'max_height=',
            }) -- 全選項

          need_add_prefix = false
        elseif prefix == "at_cursor" or prefix == "enabled" then
          comps = {
            "1",
            "0",
            "toggle",
          }
        elseif prefix == "cursor_mode" then
          comps = {
            "popup",
            "inline",
          }
        elseif prefix == "max_width" or prefix == 'max_height' then
          comps = { -- %
            "nil",
            '5',
            '20',
            '50',
          }
        end
        if need_add_prefix then
          for i, comp in ipairs(comps) do
            comps[i] = prefix .. "=" .. comp
          end
        end

        local input = need_add_prefix and prefix .. "=" .. suffix or suffix
        -- return vim.tbl_filter(function(item) return vim.startswith(item, input) end, comps) -- 比較嚴格的匹配
        return vim.tbl_filter(function(item) return item:match(input) end, comps) -- 改用match比較自由
      end
    }
  )
end

local function install_csvview()
  local ok, csvview = pcall(require, "csvview")
  if not ok then
    vim.notify("Failed to load csvview", vim.log.levels.WARN)
    return
  end
  csvview.setup()
  -- USAGE:
  -- :CsvViewEnable
  -- :CsvViewDisable
  -- :CsvViewToggle
end

local function install_live_preview()
  -- :che livepreview 可以看到預設的設定, port預設是5500
  require('livepreview.config').set()
end

local function install_xcodebuild()
  -- 此插件，我覺得不需要裝，它做了很多功能，但是都可以透過手動自己來執行
  -- 而且就算要debug: 可完全透過: `xcrun lldb-dap` 用attach的方式即可
  if not pcall(require, "xcodebuild") then
    return
  end

  -- ~/.config/nvim/lua/external/dap/swift.lua
  -- require("dap").adapters.lldb_dap = {
  --   name = 'lldb_dap',
  --   type = 'executable',
  --   command = '/usr/bin/xcrun',
  --   args = { 'lldb-dap' },
  -- }

  -- `:lua require("xcodebuild.integrations.dap").build_and_debug()` 這個抓的好像就直接用 dap.configurations 的第一個項目，不曉得要怎麼換

  require("xcodebuild").setup({
    -- put some options here or leave it empty to use default settings
    -- https://github.com/wojciech-kulik/xcodebuild.nvim/wiki/Configuration#-default-config
    codelldb = {
      enabled = false,     -- enable codelldb dap adapter for Swift debugging
      port = 13000,        -- port used by codelldb adapter
      codelldb_path = nil, -- path to codelldb binary, REQUIRED, example: "/Users/xyz/tools/codelldb/extension/adapter/codelldb"


      lldb_lib_path = "/Applications/Xcode_26.0.1.app/Contents/SharedFrameworks/LLDB.framework/Versions/A/LLDB", -- 👈 CAUTION: 這個要自己換掉
    },

    -- :help xcodebuild.remote-debugger
    integrations = {
      pymobiledevice = {
        enabled = true,
      },
    }
  })
end

local installs = {
  {
    name = "registers",
    fn = function()
      local registers = require("registers_spy")
      vim.keymap.set('n', '<leader>r', registers.toggle,
        {
          desc = "Toggle registers sidebar",
          noremap = true,
          silent = true
        }
      )
      vim.api.nvim_create_user_command(
        "RegSpy",
        function(args)
          registers.registers = args.fargs[1]
        end,
        {
          nargs = 1,
          complete = function()
            return {
              registers.DEFAULT_REGISTER,
              '"abcdefg123',
              '"*+-.:/=%#'
            }
          end,
          desc = "registers spy"
        }
      )
    end,
    delay = 0
  },
  {
    name = "cmd_center",
    fn = function()
      require("cmd_center")
    end,
    delay = 0
  },
  {
    name = "config.telescope_bookmark",
    fn = function()
      require "config.telescope_bookmark"
    end,
    delay = 0
  },
  {
    name = "config.highlight",
    fn = function()
      require("config.highlight")
    end,
    delay = 0
  },
  { name = "nvimTreesitter",              fn = install_nvimTreesitter,            delay = 0 },
  { name = "nvim-treesitter-textobjects", fn = install_nvimTreesitterTextobjects, delay = 0 },
  { name = "treesitter-context",          fn = install_nvimTreesitterContext,     delay = 0 },

  { name = "lspconfig",                   fn = install_lspconfig,                 delay = 0 },
  {
    name = "lspconfig",
    fn = function()
      install_lspconfig()
      vim.lsp.enable({
        'pyright',
        'gopls',
        'ts_ls', -- javascript, typescript

        -- html, css, json, eslint: https://github.com/hrsh7th/vscode-langservers-extracted
        -- 👆裡面有 vscode-{html,css,json,eslint}-language-server 四個執行檔
        'html',
        "cssls",
        "jsonls",
        "bashls",
        "markdown_oxide",
        "clangd",
        "lua_ls",
        "sqls",      -- 用處其實不高，可以考慮移除
        "sourcekit", -- swift

        "denols"     -- deno
      })
    end,
    delay = 0
  },

  -- { name = "precognition",    fn = install_precognition,    delay = 0 },
  -- { name = "hop",             fn = install_hop,             delay = 0 },
  { name = "leap",            fn = install_leap,            delay = 0 },
  { name = "gitsigns",        fn = install_gitsigns,        delay = 0 },
  { name = "nvimWebDevicons", fn = install_nvimWebDevicons, delay = 0 },
  { name = "nvim_tree",       fn = install_nvim_tree,       delay = 0 },
  { name = "telescope",       fn = install_telescope,       delay = 0 },
  { name = "fzf_lua",         fn = install_fzf_lua,         delay = 0 },
  {
    name = "ibl",
    fn = function()
      install_ibl()
    end,
    delay = 5
  },
  { name = "lualine",           fn = install_lualine,        delay = 0 },
  -- { name = "atq",            fn = install_atq,            delay = 0 }, -- 可以用command: NotifySend 即可
  { name = "renderMarkdown",    fn = install_renderMarkdown, delay = 0 },
  { name = "cmp_list",          fn = install_cmp_list,       delay = 0 },
  { name = "nvim_dap",          fn = install_nvim_dap,       delay = 5 },
  { name = "flutter_tools",     fn = install_flutter_tools,  delay = 5 },
  { name = "create color code", fn = install_ccc,            delay = 0 },
  { name = "pantran.nvim",      fn = install_pantran,        delay = 5 },
  { name = "image.nvim",        fn = install_image,          delay = 5 },
  { name = "csvview.nvim",      fn = install_csvview,        delay = 5 },
  { name = "live-preview.nvim", fn = install_live_preview,   delay = 5 },
  { name = "xcodebuild.nvim",   fn = install_xcodebuild,     delay = 5 },
  {
    name = "global-func",
    fn = function()
      require("global-func") -- 自定義的一些全域函數，可以使用 :=MyGlobalFunc() 的這種方式來調用
    end,
    delay = 0
  },
}

local show_time = false
for _, install in ipairs(installs) do
  if install.delay > 0 then
    vim.defer_fn(function()
      local time_ms = utils.time.it(install.fn)
      if show_time then
        print(string.format("%s (deferred) cost: %.5f ms", install.name, time_ms))
      end
    end, install.delay)
  else
    local time_ms = utils.time.it(install.fn)
    if show_time then
      print(string.format("%s cost: %.5f ms", install.name, time_ms))
    end
  end
end


vim.defer_fn(function() -- 因為裡面要計算出，啟動nvim的時間，所以用defer放到最後才執行
  require("config.menu").setup {
    start_time = START_TIME
  } -- 起始畫面
end, 0)

pcall(require, "my-customize") -- 如果有一些自定義的設定，可以自己新增一個my-customize.lua來覆寫

-- require("utils.all_test")
