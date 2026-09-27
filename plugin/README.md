在此目錄的lua都會被自動執行

# Plugin

## 載入時機

當使用 `nvim -u my_init.lua -l myscript.lua` 時

其實都會載入`~/.config/nvim/plugin/`目錄中的內容，不過會先載入-u的init才會開始陸續plugin的內容

因此如果是一些平常-l使都不會用到的插件，建議不要寫在此目錄中，或者用`vim.g`的方式，判別有設定才會載入之類的

## Debug

可以用這樣的方式來觀察觸發的事件，來決定是否想要用該plugin

```vim
set verbosefile=~/temp.nvim.log | set verbose=9
set verbose=0  " 關閉
```

## 大量使用到 CursorMoved 的插件

### 內建插件

`:help plugins.txt`

- matchparen: 考慮用`:NoMatchParen`, `:DoMatchParen`來禁用或啟用

### 第三方Plugin

- [csvview](csvview.lua): 非csv的filetype也會觸發
- [nvim-treesitter-context](nvim-treesitter-context.lua)
- [nvim-treesitter-textobjects](nvim-treesitter-textobjects.lua)
- [lualine](lualine.lua)

若速度考量，可考慮不用這些插件

## Update

> nvim -u NORC -l update.lua

```lua
-- update.lua
vim.pack.update({
    "nvim-treesitter",
    "nvim-treesitter-context",
    "nvim-treesitter-textobjects",
  },
  {
    force = true,        -- ❗ 這很重要，如果要用nvim -l的方式跑，少了confirm會只有fetch不會主動checkout過去❗
    -- offline = true,   -- 如果已經clone下來了, 就可以不需要網路. 預設是false
    target = "lockfile", -- 或者指定的版本. 所以先在 ../nvim-pack-lock.json 中寫好要的rev版本即可
  }
)
```

> [!WARNING] 當不用-l的方式跑，也就是在nvim使用中，貼上命令. 有用ssh時會遇到: `Permission denied (publickey)`的錯誤
>
> 而加了`force = true` 時，會沒有看到錯誤，但實際上也是沒有成功的

# treesitter


## vim.treesitter.start

瞭解內建: treesitter 的運作原理

nvim核心從0.12開始就已經全面採用它

而以在: nvim/runtime/lua/vim/treesitter.lua 看到

實際的位置可以這樣查詢

```vim
:echom nvim_get_runtime_file('lua/vim/treesitter.lua', v:true)
```

也因此其實可以

```lua
require("vim.treesitter")
```

就等同能得到該模組

但通常都是直接寫

```lua
vim.treesitter
```

這是因為在 [runtime/lua/vim/_meta.lua](https://github.com/neovim/neovim/blob/ac1a06021de60ae2b94ac23aa51729c867f57ce0/runtime/lua/vim/_meta.lua#L95) 做了以下的動作

```lua
vim.treesitter = require('vim.treesitter')
```

因此這兩者都是相同的


---

在設定上，通常都只要這樣就能直接使用

```lua
local parsers = {
  "bash",
  "lua",
  -- ...
}

require("nvim-treesitter").install(parsers):wait(300000)

vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    if pcall(vim.treesitter.start, args.buf) then
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end
})
```

其中的autocmd提到了: `vim.treesitter.start`

這個主要是去取得parser, 和在parser加入highlight

```lua
---@param lang string? Language of the parser (default: from buffer filetype) 預設的lang用的是filetype (在get_parser中的get_lang會實作)
function M.start(bufnr, lang)
  bufnr = vim._resolve_bufnr(bufnr)
   -- ...
  local parser = assert(M.get_parser(bufnr, lang))
  M.highlighter.new(parser)
end
```

在get_parser的動作


```lua
-- runtime/lua/vim/treesitter.lua
-- 有兩重點:
-- 1. get_lang
-- 2. _create_parser
function M.get_parser(bufnr, lang, opts)
  opts = opts or {}

  bufnr = vim._resolve_bufnr(bufnr)

  if not valid_lang(lang) then
    lang = M.language.get_lang(vim.bo[bufnr].filetype) -- 👈 底下有get_lang的定義
  end

  if not valid_lang(lang) then
    -- ...
  elseif parsers[bufnr] == nil or parsers[bufnr]:lang() ~= lang then
    local status, res = pcall(M._create_parser, bufnr, lang, opts) -- 👈 _create_parser 是載入動態連結庫的地方
    -- 失敗就回 nil, err
    parsers[bufnr] = res
  end

  parsers[bufnr]:register_cbs(opts.buf_attach_cbs)

  return parsers[bufnr]
end

-- 1. get_lang
-- runtime/lua/vim/treesitter/language.lua
function M.get_lang(filetype)
  -- ...
  if ft_to_lang[filetype] then -- 這個map的內容是由register而來

    return ft_to_lang[filetype]
  end

  -- 👇 跑到了以下，就表示ft_to_lang找不到，也就是沒有register (register如果有裝 nvim-treesitter 的插件，它的: nvim-treesitter/plugin/filetypes.lua 中就會註冊常見的項目
  -- 但如果沒有註冊也沒有關係，底下會再考慮用附檔名來當filetype
  filetype = assert(vim.split(filetype, '.', { plain = true })[1]) -- 如果有子filetype, 它只抓第一個
  return ft_to_lang[filetype] or filetype  -- 因此最後的lang有可能是用此filetype或者是它對應到的lang
end

-- runtime/lua/vim/language.lua
-- ft_to_lang的內容是由register而來
function M.register(lang, filetype)
  vim.validate('lang', lang, 'string')
  vim.validate('filetype', filetype, { 'string', 'table' })

  for _, f in ipairs(ensure_list(filetype)) do
    if f ~= '' then
      ft_to_lang[f] = lang
    end
  end
end

-- 2. _create_parser 會發現其實當中也已經包含了 treesitter.language.add 在內
-- runtime/lua/vim/treesitter.lua
function M._create_parser(buf, lang, opts)
  local self = LanguageTree.new(buf, lang, opts) -- 👈 裡面會跑add
  -- nvim_buf_attach on_bytes ...
  return self
end

-- runtime/lua/vim/languagetree.lua
function LanguageTree.new(source, lang, opts)
  assert(language.add(lang))
end

-- runtime/lua/vim/treesitter/language.lua
function M.add(lang, opts)
  -- ...

  vim.validate('lang', lang, 'string')
  vim.validate('path', path, 'string', true)
  vim.validate('symbol_name', symbol_name, 'string', true)

  -- parser names are assumed to be lowercase (consistent behavior on case-insensitive file systems)
  lang = lang:lower()

  if vim._ts_has_language(lang) then
    return true
  end

  if path == nil then
    -- ...

    local fname = 'parser/' .. lang .. '.*'
    local paths = api.nvim_get_runtime_file(fname, false) -- 👈 這邊就會曉得，它抓的是所有runtime path下: parser/<lang>/.*
    --  ...
    path = paths[1]
  end

  local res = loadparser(path, lang, symbol_name) -- 這邊載入so, wasm之類的
  return res,
    res == nil and string.format('Cannot load parser %s for language "%s"', path, lang) or nil
end

-- runtime/lua/vim/treesitter/language.lua
-- 這可以發現可以載入wasm，或者是so相關的檔案. 實作在C中實現
local function loadparser(path, lang, symbol_name)
  if vim.endswith(path, '.wasm') then
    return vim._ts_add_language_from_wasm and vim._ts_add_language_from_wasm(path, lang)
  else
    return vim._ts_add_language_from_object(path, lang, symbol_name)
  end
end
```

---

在register可以寫成這樣: `vim.treesitter.language.register`

能這樣用是因為:

```lua
vim.treesitter = require('vim.treesitter')
-- 在treesitter中又做了
local M = vim._defer_require('vim.treesitter', {
  -- ...
  language = ..., --- @module 'vim.treesitter.language'
  languagetree = ..., --- @module 'vim.treesitter.languagetree'
  query = ..., --- @module 'vim.treesitter.query'
})
```

但你會發現其實設定檔都沒有寫register, 這是因為插件: `nvim-treesitter` 裡面做了

在它的filetypes.lua有寫到

> [!TIP] 用此指令可以查位置: `:echom nvim_get_runtime_file('plugin/filetypes.lua', v:true)`

```lua
-- nvim-treesitter/plugin/filetypes.lua
local filetypes = {
  angular = { 'htmlangular' },
  bash = { 'sh' },
  -- ...
  typescript = { 'ts' },
  -- ...
  vhs = { 'tape' },
  xml = { 'xsd', 'xslt', 'svg' },
  xresources = { 'xdefaults' },
}

for lang, ft in pairs(filetypes) do
  vim.treesitter.language.register(lang, ft)
end
```

而插件的plugin目錄是會在啟動自動載入的, 所以才會沒感覺需要寫或者設定

---

`require("nvim-treesitter").install(parsers):wait(300000)` 這的事情, 會去下載然後生成出相關的so檔案, 並放入在runtime path中的parser目錄. 所以之後`vim.treesitter.start`就可以直接用了

```vim
:pu=nvim_get_runtime_file('parser/*.so', v:true)  " 在mac用的是so, windows用的是dll
```

```lua
-- nvim-treesitter/lua/nvim-treesitter/install.lua
local function install(languages, options)
  -- ...

  local tasks = {} ---@type async.TaskFun<[], []>[]
  local done = 0
  for _, lang in ipairs(languages) do
    if options.force or not vim.list_contains(installed, lang) then
      tasks[#tasks + 1] = a.async(--[[@async]] function()
        a.schedule()
        if install_lang(lang, cache_dir, install_dir, options.generate) then -- 這邊會安裝
          done = done + 1
        end
      end)
    end
  end

  -- ...
end

local function install_lang(lang, cache_dir, install_dir, generate)
  if installing[lang] then
    local success = vim.wait(INSTALL_TIMEOUT, function()
      return not installing[lang]
    end)
    return success
  end

  installing[lang] = true
  local err = try_install_lang(lang, cache_dir, install_dir, generate)
  installing[lang] = nil
  return not err
end

local function try_install_lang(lang, cache_dir, install_dir, generate)
  local logger = log.new('install/' .. lang)

  local repo = get_parser_install_info(lang)
  local project_name = 'tree-sitter-' .. lang
  if repo then
    local revision = repo.revision

    local compile_location ---@type string
    if repo.path then
      compile_location = fs.normalize(repo.path)
    else
       --- ...

      local err = do_download(logger, repo.url, project_name, cache_dir, revision, project_dir)
       --- ...
    end

    --- ...

    do -- generate parser from grammar
      if repo.generate or generate then
        local err = do_generate(logger, repo, compile_location) -- 執行指令: `tree-sitter generate --abi ...`
        if err then
          return err
        end
      end
    end

    do -- compile parser
      local err = do_compile(logger, compile_location) -- 執行指令 `tree-sitter build -o parser.so`
      if err then
        return err
      end
    end

    do -- install parser
      local parser_lib_name = fs.joinpath(compile_location, 'parser.so')
      local install_location = fs.joinpath(install_dir, lang) .. '.so'
      local err = do_install(logger, parser_lib_name, install_location)
      if err then
        return err
      end

      local revfile = fs.joinpath(config.get_install_dir('parser-info') or '', lang .. '.revision')
      util.write_file(revfile, revision or '')
    end
  end

  do -- install queries
    local query_src = M.get_package_path('runtime', 'queries', lang)
    local query_dir = fs.joinpath(config.get_install_dir('queries'), lang)
    local task ---@type function

    --- ...
    if task then
      local err = task(logger, query_src, query_dir)
      if err then
        return err
      end
    end
  end

  -- clean up
  --- ...

  logger:info('Language installed')
end
```

### 結論

如果so, wasm, ...的檔案已經在runtimepath中`parser/<lang>/*.{so,dll,wasm...}`可以找到，那麼接下來只要直接使用`vim.treesitter.start`即可抓到它的語法

```vim
:pu=nvim_get_runtime_file('**/parser/*.so', v:true)
```

```
vim.treesitter.start(buf, 'mylang')
  → get_parser(buf, 'mylang')
    →（這個 buf 還沒有 mylang 的 parser. lang找不到預設用附檔名）
    → _create_parser()
      → LanguageTree.new()
        → assert(language.add('mylang')) -- 載入相關so
        → vim._create_ts_parser('mylang')
  → highlighter.new(parser)
```

---

> [!NOTE] 至於相關的高亮，則是在其scm中控制

```vim
:pu=nvim_get_runtime_file('**/*.scm', v:true)
:pu=nvim_get_runtime_file('queries/**/*.scm', v:true)
```

## function

| 函式                     | 做什麼                                          |
|---                       |---                                              |
| add(lang,  opts)         | 載入 parser 函式庫（.so / .wasm）               |
| register(lang, filetype) | 建立 filetype → parser 名稱對應，不載入任何檔案 |
| get_lang(filetype)       | 查「這個 filetype 該用哪個 parser 名」          |
| get_filetypes(lang)      | 反查「這個 parser 對應哪些 filetype」           |
| inspect(lang)            | 先 add，再回傳 ABI、node 名稱等資訊             |



```vim
lua print(vim.treesitter.language.get_lang("sh")) -- bash
lua print(vim.inspect(vim.treesitter.language.get_filetypes("markdown"))) -- { "markdown", "pandoc" }
lua print(vim.inspect(vim.treesitter.language.inspect('lua'))) -- 可以看到 abi_version (Application Binary Interface), 可以曉得這些so的檔案是哪一個版本編譯出來的
:pu=v:lua.vim.inspect(v:lua.vim.treesitter.language.inspect('lua'))
lua print(vim.treesitter.language_version)           -- 這份 Neovim 能吃的最新 ABI
lua print(vim.treesitter.minimum_language_version)   -- 能吃的最舊 ABI
```


## 高亮流程

```
buffer 文字
    │
    ▼
language.add('lua')          -- 載入 parser.so（上一則討論的）
    │
    ▼
LanguageTree:parse()         -- 增量建 AST，注入語言也在這裡展開
    │
    ▼
query.get('lua', 'highlights')
    │                        -- 讀 queries/lua/highlights.scm
    ▼
query:iter_captures(root, buf, 可見列起, 可見列迄)
    │
    ▼
每個 capture
  @function / @keyword / @string ...
    │
    ▼
nvim_buf_set_extmark(..., {
  hl_group = '@function.lua' 或 '@function',
  ephemeral = true,
  priority = 100,
})
    │
    ▼
redraw 時 decoration provider 把這些 extmark 畫上螢幕
```
