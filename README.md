# Version

```
NVIM v0.10.2
Build type: RelWithDebInfo
LuaJIT 2.1.1713484068
```

# INSTALL

```sh
mkdir -p ~/.config/nvim
git clone https://github.com/CarsonSlovoka/nvim.git ~/.config/nvim
cd ~/.config/nvim
git submodule update --init --recursive
```

# 目錄結構

- ✅ 表示目前已經有實作
- 沒有標記的部份就只是目前規劃

```
~/.config/nvim/
├── init.lua                         -- ✅ 主入口配置文件
├── pack/
│   ├── syntax/start/
│   │          │
│   │          └── nvim-treesitter/  -- ✅ 語法高亮
│   │          
│   ├── syntax/lsp/                  -- ✅ language server protocol
│   │          └── nvim-lspconfig/   -- ✅ 語言協議(語言伺服器要額外安裝, 每個語言的裝法不同), 配合好該語言的伺服器，即可在編輯完成後，做檢查之類的
├── ftplugin/                        -- ✅ 依據附檔名才會載入的插件
│   ├── markdown/                    -- ✅ markdown編輯, toc相關
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

# pack

```
:help runtimepath
:help :packadd
    pack/*/start/{name}
```

```bash
for dir in ./pack/*; do du -hs "$dir"; done
```

## nvim-treesitter

```bash
mkdir -p ~/.config/nvim/pack/syntax/start/ # 建立一個syntax的群組
git clone https://github.com/nvim-treesitter/nvim-treesitter.git ~/.config/nvim/pack/syntax/start/nvim-treesitter
```

```yaml
# 此項目是nvim-treesitter所提供的: https://github.com/nvim-treesitter/nvim-treesitter/blob/096babebf6daef2a046650883082ed2b3dcc5b67/lua/nvim-treesitter/health.lua#L117-L174
:checkhealth
```

[![treesitter_health](.img/treesitter_health.webp)](./pack/syntax/start/nvim-treesitter/lua/nvim-treesitter/health.lua)

```yaml
# 更新
:TSUpdate
```

## lsp

1. 下載lsp
2. 安裝語言伺服器
3. 編輯init.lua: `require'lspconfig'.gopls.setup{}`

![lsp_checkhealth](.img/lsp_checkhealth.webp)

### 下載lsp(language server protocol)

```bash
## 這個只是protocol, 至於server還是要再另外安裝
mkdir -p ~/.config/nvim/pack/lsp/start
git clone https://github.com/neovim/nvim-lspconfig.git ~/.config/nvim/pack/lsp/start/nvim-lspconfig
```

### 安裝語言伺服器

#### go

```
go install golang.org/x/tools/gopls@latest
which gopls
# $GOPATH/bin/gopls
```
