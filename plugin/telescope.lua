local completion = require("utils.complete")
local cmdUtils = require("utils.cmd")

local _, m = pcall(require, "telescope")


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
