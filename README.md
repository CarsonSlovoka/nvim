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
├── doc/                             -- ✅ nvim的幫助文檔(可用:help找尋關聯tag)
├── pack/
│   ├── syntax/start/
│   │          ├── nvim-treesitter/             -- ✅ 語法高亮
│   │          └── nvim-treesitter-textobjects  -- ✅ visual下的選取, 移動(function, class), 參數交換 (需要先裝nvim-treesitter以及lsp之後才能有效使用) (ad8f0a47) 
│   │          
│   ├── lsp/start/                   -- ✅ language server protocol
│   │       │
│   │       └── nvim-lspconfig/      -- ✅ 語言協議(語言伺服器要額外安裝, 每個語言的裝法不同), 配合好該語言的伺服器，即可在編輯完成後，做檢查之類的 (v1.2.0左右)
│   │
│   ├── git/start/                   -- ✅ git
│   │       │
│   │       └── gitsigns.nvim/       -- ✅ 編輯的時候，可以看到git上的異動(新增, 刪除, 修改...) (v1.0.0.prelease  5582fbd)
│   │
│   ├── motion/start/                -- ✅ 移動相關
│   │          ├── hop.nvim          -- ✅ 使用模糊搜尋來快速移動. 熱鍵f, F, t, T (v2.7.2左右)
│   │          └── precongnition.nvim-- ✅ 可以幫助您學習vi,它會提示可以如何移動  (v1.1.0左右)
│   │
│   └── tree/start/                  -- ✅ 導覧相關
│            └── nvim-tree.lua       -- ✅ 左測目錄導覽(還可創建目錄,重新命名,...) (v1.10.0.prelease 7b870f16c) 
│            
├── ftplugin/                        -- ✅ 依據附檔名才會載入的插件
│   │
│   └── markdown/                    -- ✅ markdown編輯, toc相關
│   
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


### [nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects)

```bash
git clone https://github.com/nvim-treesitter/nvim-treesitter-textobjects.git ~/.config/nvim/pack/syntax/start/nvim-treesitter-textobjects
```

---

此插件只要裝好就可以了，配置了話，要直接在[nvim-treesitter](#nvim-treesitter)的設定新增`textobjects`再輸入想要的內容即可

```lua
require 'nvim-treesitter.configs'.setup {
    textobjects = {
        select = {
            -- ...
        },
        move = {
            -- ...
        },
        swap = {
            -- ...
        }
    }
}
```

```yaml
:TSUpdate
```

測試用腳本

```go
package main

import (
	"fmt"
)

// Add is a simple function that adds two integers.
func Add(a int, b int) int {
	result := a + b
	return result
}

// Subtract is a simple function that subtracts one integer from another.
func Subtract(a int, b int) int {
	return a - b
}

type Calculator struct {
	Name string
}

// Multiply multiplies two integers.
func (c Calculator) Multiply(a int, b int) int {
	return a * b
}

func main() {
	calculator := Calculator{Name: "Basic Calculator"}
	fmt.Println(calculator.Multiply(3, 4))
}
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

#### python

```bash
pyenv virtualenv 3.13.0 pyright-env
pyenv activate pyright-env
pyenv versions # check switch
python -m pip install --upgrade pip
pip install pyright
pip freeze
# nodeenv==1.9.1
# pyright==1.1.391
# typing_extensions==4.12.2
pyenv deactivate
which pyright | wl-copy
# vim.g.lsp_pyright_path = vim.fn.expand('~/.pyenv/shims/pyright') # 貼上路徑

# 進入nvim之前要啟用虛擬環境, 才會有作用, 而且相關的python套件也要在該虛擬環境有，不然也沒辦法做檢測
pyenv activate pyright-env
nivm ~/test.py
```

建議安裝在全局上，可以省得麻煩
```bash
pyenv install 3.13.0
pyenv global 3.13.0
pip install pyright
pip freeze | grep pyright
# pyright==1.1.391
which pyright | wl-copy
# vim.g.lsp_pyright_path = vim.fn.expand('~/.pyenv/shims/pyright') # 貼上路徑 
```

## motion

```bash
mkdir -pv ~/.config/nvim/pack/motion/start/
```

### [precognition](https://github.com/tris203/precognition.nvim.git)

```bash
git clone https://github.com/tris203/precognition.nvim.git ~/.config/nvim/pack/motion/start/precognition.nvim
```

> 插件特色: https://www.youtube.com/watch?v=7hQZhHve4HI


### [hop.nvim](https://github.com/smoka7/hop.nvim)


```bash
git clone https://github.com/smoka7/hop.nvim.git ~/.config/nvim/pack/motion/start/hop.nvim
```

## git

```bash
mkdir -pv ~/.config/nvim/pack/git/start/
```

### [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim)

```bash
git clone https://github.com/lewis6991/gitsigns.nvim.git ~/.config/nvim/pack/git/start/gitsigns.nvim
```


## tree

```bash
mkdir -pv ~/.config/nvim/pack/tree/start/
```

### [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua)

```bash
git clone https://github.com/nvim-tree/nvim-tree.lua.git ~/.config/nvim/pack/tree/start/nvim-tree.lua
```
