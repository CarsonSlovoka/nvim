--- 翻譯工具(能直接取代)
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

vim.defer_fn(function()
  vim.pack.add({ "https://github.com/potamides/pantran.nvim" })
  install_pantran()
end, 1000)
