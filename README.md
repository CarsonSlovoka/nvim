# 目錄構

- ✅ 表示目前已經有實作
- 沒有標記的部份就只是目前規劃

```
~/.config/nvim/
├── init.lua                         -- ✅ 主入口配置文件
├── lua/                             -- ✅ Lua 配置模組的根目錄
│   ├── plugins/                     -- 插件相關的配置
│   │   ├── init.lua                 -- 插件管理器 (packer.nvim 或 lazy.nvim) 的配置
│   │   ├── lsp.lua                  -- LSP 客戶端的配置
│   │   ├── treesitter.lua           -- Treesitter 的配置
│   │   ├── telescope.lua            -- Telescope 的配置
│   │   └── ...                      -- 其他插件的配置
│   ├── config/                      -- ✅ 基本設定
│   │   ├── options.lua              -- ✅ 基本選項 (e.g., 編輯器行為、外觀設定)
│   │   ├── commands.lua             -- ✅ 自定義的命令(:MyCommand, ...)
│   │   ├── keymaps.lua              -- ✅ 鍵位綁定
│   │   ├── autocmds.lua             -- 自動命令 (autocommands)
│   │   └── ...                      -- 其他相關設定
│   ├── ui/                          -- 用戶界面相關配置
│   │   ├── colorscheme.lua          -- 配色方案
│   │   ├── statusline.lua           -- 狀態欄配置
│   │   ├── tabline.lua              -- 標籤欄配置
│   │   └── ...                      -- 其他界面配置
│   ├── lsp/                         -- LSP 配置
│   │   ├── init.lua                 -- LSP 加載邏輯
│   │   ├── servers/                 -- 不同 LSP 伺服器的配置
│   │   │   ├── lua_ls.lua           -- 示例：Lua 語言伺服器
│   │   │   ├── pyright.lua          -- 示例：Python 語言伺服器
│   │   │   └── ...                  -- 其他伺服器配置
│   └── utils/                       -- 實用工具函數
│       ├── exec.lua                 -- ✅ 執行工作相關
│       ├── init.lua                 -- 工具函數的加載
│       ├── mappings.lua             -- 鍵位綁定相關工具
│       └── ...                      -- 其他工具
├── after/                           -- 用於延遲加載的配置
│   ├── ftplugin/                    -- 文件類型相關的配置
│   ├── syntax/                      -- 語法高亮相關配置
│   └── ...                          -- 其他延遲加載配置
└── README.md                        -- ✅ 簡單說明文件
```
