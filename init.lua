local START_TIME = vim.uv.hrtime() -- 勿調整，用來得知nvim開啟的時間，如果要計算啟動花費時間會有用

vim.pack.add({ "https://github.com/projekt0n/github-nvim-theme" })
-- https://github.com/projekt0n/github-nvim-theme/blob/c106c9472154d6b2c74b74565616b877ae8ed31d/README.md?plain=1#L170-L206
vim.cmd('colorscheme github_dark_default') -- 主題要先設定(可以先設定之後再補全它的實作)，不然如果自定義的調整在這之前，又會被此蓋掉

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
  { name = "nvimWebDevicons", fn = install_nvimWebDevicons, delay = 0 },

  { name = "xcodebuild.nvim", fn = install_xcodebuild,      delay = 5 },
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
