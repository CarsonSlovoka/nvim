local START_TIME = vim.uv.hrtime() -- 勿調整，用來得知nvim開啟的時間，如果要計算啟動花費時間會有用

vim.pack.add({ "https://github.com/projekt0n/github-nvim-theme" })
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


-- Note: 會將vim.pack.add的項目下載到: `$XDG_DATA_HOME/nvim/site/pack/core/opt/`底下
-- Tip: `:lua print(vim.fn.stdpath('data') .. '/site/pack/core/opt/')`   -- 👈 用這個查看路徑
-- Tip: 裡面會有git, 所以也可以cd到裡面看結果
-- ls ~/.local/share/nvim/site/pack/core/opt/nvim-treesitter/       -- 之後就可以找到下載的套件
-- vim.pack.del({ "nvim-treesitter" }) -- 如果不要，把vim.pack.add刪除，再用此命令也可以刪除該套件
-- rm -rf ~/.local/share/nvim/site/pack/core/opt/nvim-treesitter/   -- 也可以自己去刪除，之後將nvim-pack-lock.json對應的項目也刪除即可

-- vim.pack.add({
--   --  會有一個 nvim-pack-lock.json 來記錄用的版本
--   --  Note: 如果你用的是ssh的方式，含有passphrase會失敗，可以先用: `ssh-keygen -p -f ~/.ssh/myPrivateKey` 拿掉之後再試一次，之後可以再加回就好
--   "https://github.com/nvim-treesitter/nvim-treesitter",
-- })

vim.pack.add({ "https://github.com/nvim-lua/plenary.nvim" }) -- 有些套件需要用到它，所以要先確保它載入
vim.pack.add({
  -- Important: 確認過下載的內容以 nvim-pack-lock.json 的記錄為主, 所以只要確保該json的內容，再將目錄中的檔案重新刪除，再次啟動就會去下載對應的版本
  --   rm -rf ~/.local/share/nvim/site/pack/core/opt/
  --   ~~mkdir -v ~/.local/share/nvim/site/pack/core/opt~~ opt的目錄，如果有需要會主動創建，不需要自己建立

  -- 👇 如果還有其它複雜設定，可以考慮寫在 plugin/ 目錄之中
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter",
    -- version = "7caec274fd19c12b55902a5b795100d21531391f",
    -- version = "da8bf82a", -- 這樣也可以, 但是這樣實際上是在nvim-pack-lock.json中的version會生成，並且rev也會再帶出.
    rev = "7caec274" -- 用這樣更好, 如此version不會在 nvim-pack-lock.json 中出現
  },
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
    rev = "93d60a47"
  },
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter-context",
    rev = "adf4b6b0420b7be6c717ef0ac7993183d6c201b1"
  },
  {
    src = "https://github.com/MeanderingProgrammer/render-markdown.nvim",
    rev = "c7188a8f9d2953696b6303caccbf39c51fa2c1b1"
  },
  {
    -- cd ~/.local/share/nvim/site/pack/core/opt/gitsigns.nvim && git log
    src = "https://github.com/lewis6991/gitsigns.nvim",
    -- rev = "6bd2949" -- clone下來的可能是倉庫的主分支，用rev有時候無效
    rev = "0f00d07c2c3106ba6abd594ac1c17f211141b7b5",
  },
  {
    -- cd ~/.local/share/nvim/site/pack/core/opt/leap.nvim && git log
    -- leap. nvim: the repository has been moved to Codeberg.
    -- src = "https://github.com/ggandor/leap.nvim", 👈 這個會得到已經更換至codeberg的警告
    src = "https://codeberg.org/andyg/leap.nvim",
    -- rev = "f19d435" -- ❌ 2025-12-04 轉移到codeberg之後，這個節點不見了
    rev = "b960d5038c5c505c52e56a54490f9bbb1f0e6ef6", -- 2026-03-31 (Tue) 14:08:01 +0200
  },
  {
    -- cd ~/.local/share/nvim/site/pack/core/opt/nvim-web-devicons && git log
    src = "https://github.com/nvim-tree/nvim-web-devicons",
    -- 🤔 鎖版本有的時候會失敗，這時候可以cd到下載的目錄，然後checkout到要的版本. 將著將 nvim-pack-lock.json 對應的項目刪除即可, 再次啟動讓它自動來生成即可得到正確的對應
    --  57dfa94  2025-04-07 (Mon) +0200
    rev = "d7462543c9e366c0d196c7f67a945eaaf5d99414" -- 2026-03-11 (Wed) chore: update pre-commit hooks (#624)
  },
  {
    -- cd ~/.local/share/nvim/site/pack/core/opt/nvim-tree.lua && git log
    src = "https://github.com/nvim-tree/nvim-tree.lua",
    rev = "31503ad5d869fca61461d82a9126f62480ecb0ab" -- 2026-04-01 (Wed) feat!: drop support for Nvim 0.11
  },

  -- cd ~/.local/share/nvim/site/pack/core/opt/telescope.nvim && git log
  "https://github.com/nvim-telescope/telescope.nvim", -- 反正rev的內容還是看 nvim-pack-lock.json 所以就不再這邊再寫rev

  -- cd ~/.local/share/nvim/site/pack/core/opt/fzf-lua && git branch
  "https://github.com/ibhagwan/fzf-lua",

  -- cd ~/.local/share/nvim/site/pack/core/opt/lualine.nvim && git branch
  "https://github.com/nvim-lualine/lualine.nvim",
})

local function install_nvimWebDevicons()
  -- Caution: 有順序性不能將此設定寫在plugin之中
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
  { name = "nvimWebDevicons",   fn = install_nvimWebDevicons, delay = 0 },
  { name = "cmp_list",          fn = install_cmp_list,        delay = 0 },
  { name = "flutter_tools",     fn = install_flutter_tools,   delay = 5 },
  { name = "pantran.nvim",      fn = install_pantran,         delay = 5 },
  { name = "image.nvim",        fn = install_image,           delay = 5 },
  { name = "csvview.nvim",      fn = install_csvview,         delay = 5 },
  { name = "live-preview.nvim", fn = install_live_preview,    delay = 5 },
  { name = "xcodebuild.nvim",   fn = install_xcodebuild,      delay = 5 },
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
