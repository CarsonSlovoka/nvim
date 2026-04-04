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
      -- debug的步驟: 以下可參考: ../lua/external/dap/dart.lua
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

vim.defer_fn(function()
  vim.pack.add({ "https://github.com/nvim-flutter/flutter-tools.nvim" })
  install_flutter_tools()
end, 1000)
