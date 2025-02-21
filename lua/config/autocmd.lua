local M = {
  autoSave = true,
  autoReformat = true,
  callback = function(module) end
}

local create_autocmd = vim.api.nvim_create_autocmd
local groupName = {
  editorconfig = "carson.editorconfig",
  highlightSpecial = "highlightSpecial",
}
vim.api.nvim_create_augroup(groupName.editorconfig, { clear = true })
vim.api.nvim_create_augroup(groupName.highlightSpecial, {})


function M.setup(opts)
  for k, v in pairs(opts) do
    if M[k] ~= nil then
      M[k] = v
    end
  end

  -- print(vim.inspect(M))

  create_autocmd(
    {
      -- "TextChanged", -- 如果用x, ce, undo, redo...也會觸發 -- 不要新增，否則redo會因為儲檔後無法復原
      "InsertLeave",
    },
    {

      pattern = "*",
      -- command="silent write"
      callback = function()
        if not M.autoSave then
          return
        end
        -- 獲取當前緩衝區的 buftype
        -- 因為只有 `buftype` 為空的緩衝區才可以執行 `:write` 命令。如果 `buftype` 為其它值（如 `nofile`、`help`、`prompt` 等），應該跳過保存操作
        local buftype = vim.api.nvim_buf_get_option(0, "buftype")

        -- 當 buftype 為空時才執行保存
        if buftype == "" and
            vim.bo.modified -- 可以曉得是否真的有異動
        then
          -- 先手動觸發 BufWritePre 自動命令
          vim.api.nvim_exec_autocmds("BufWritePre", {
            pattern = vim.fn.expand("%") -- 當前文件路徑
          })

          vim.cmd("silent write")
          vim.notify(string.format("%s %s saved",
            os.date("%Y-%m-%d %H:%M:%S"),
            vim.api.nvim_buf_get_name(0)
          ), vim.log.levels.INFO)
          -- elseif not vim.bo.modified then
          --  vim.notify("未檢測到變更，跳過保存", vim.log.levels.DEBUG)
          -- else
          --  vim.notify(string.format("跳過保存，因為 buftype 為 '%s'", buftype), vim.log.levels.WARN)
        end
      end,
    }
  )

  create_autocmd(
    { "BufRead", "BufNewFile" },
    {
      -- group = vim.api.nvim_create_augroup("highlightSpecial", {}),
      group = groupName.highlightSpecial,
      pattern = "*",
      callback = function()
        local groupCJKWhiteSpace = "CJKFullWidthSpace"
        vim.fn.matchadd(groupCJKWhiteSpace, '　') -- 創建群組(群組名稱如果不存在似乎會自己建立)對應關係: 匹配U+3000
        -- vim.fn.matchadd(groupCJKWhiteSpace, 'A') -- 可以這樣添加其他要內容

        -- 設定此群組的高亮
        vim.api.nvim_set_hl(0, groupCJKWhiteSpace, {
          -- bg = 'red',   -- 背景色
          -- fg = 'white', -- 前景色
          bg = "#a6a6a6",
          fg = '#00ffff',
          -- 你也可以添加其他屬性，例如：
          -- bold = true,
          -- italic = true,
          -- underline = true
        })

        local groupTODO = "TODO"
        -- vim.fn.matchadd(groupTODO, 'TODO:? .*') -- 無效
        vim.fn.matchadd(groupTODO, 'TODO .*')
        vim.api.nvim_set_hl(0, groupTODO, { fg = "#8bb33d", italic = true })
      end
    }
  )

  -- 自定義命名空間（用於高亮）
  local ns_highlight_hex_or_rgb = vim.api.nvim_create_namespace('carson_color_highlights')
  create_autocmd({
    "BufEnter", "TextChanged", "TextChangedI",
    "InsertLeave",
  }, {
    pattern = "*",
    desc = '將文字 #xxxxxx 給予顏色',
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      -- 清空之前的高亮（避免重複）
      -- vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)

      -- 遍歷每一行
      for lnum, line in ipairs(lines) do
        -- 匹配 #RRGGBB 或 #RGB 格式的顏色代碼
        for color in line:gmatch('#%x%x%x%x%x%x') do
          -- 找到顏色代碼的起始和結束位置
          local start_col = line:find(color, 1, true) - 1
          local end_col = start_col + #color

          -- 動態創建高亮組，背景色設為該顏色
          local hl_group = 'Color_' .. color:sub(2) -- 去掉 # 作為高亮組名
          vim.api.nvim_set_hl(0, hl_group, { bg = color })

          -- 應用高亮到緩衝區
          vim.api.nvim_buf_add_highlight(buf, ns_highlight_hex_or_rgb, hl_group, lnum - 1, start_col, end_col)
        end
      end
    end,
  })

  -- 進入插入模式時只清除 color_highlights 命名空間的高亮
  vim.api.nvim_create_autocmd("InsertEnter", {
    pattern = "*",
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_clear_namespace(buf, ns_highlight_hex_or_rgb, 0, -1)
    end,
  })


  -- trim_trailing_whitespace
  create_autocmd(
    "BufwritePre", -- 在寫入前執行的動作
    {
      desc = "去除結尾多餘的space, tab",
      pattern = "*",
      callback = function()
        -- 其實就是使用vim的取代%s/.../...
        -- \s\+  \s+ 任意空白字符(空格, 制表符等)一個或多個
        -- 取代為空白
        -- e flags, 如果發生錯誤的時候不報錯
        vim.cmd([[%s/\s\+$//e]])
        if M.autoReformat then
          -- 檢查是否有LSP客戶端附加到當前的緩衝區
          local clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
          local has_formatter = false
          for _, client in ipairs(clients) do
            -- 也就檢查是否有支持格式化的功能
            if client:supports_method("textDocument/formatting") then
              has_formatter = true
              break
            end
          end

          if has_formatter then
            vim.lsp.buf.format({
              async = false,
              timeout_ms = 3000,
            })
            vim.notify("lsp.buf.format done", vim.log.levels.INFO)
          else
            -- vim.notify("No LSP formatter available for current file, skipping format", vim.log.levels.WARN)
          end
        end
      end
    }
  )

  create_autocmd(
    "FileType",
    {
      group = groupName.editorconfig,
      pattern = "*", -- :set ft?

      callback = function()
        if vim.o.fileformat ~= "unix" then
          print(string.format("set fileformat from `%s` to `unix`", vim.o.fileformat)) -- 提示使用者有被自動轉換，使其如果不滿意還可以自己再轉回去
          vim.o.fileformat = "unix"
        end
        vim.opt_local.expandtab = true -- 使用空白代替Tab
        vim.opt_local.tabstop = 4      -- Tab鍵等於4個空白
        vim.opt_local.softtabstop = 4  -- 在插入模式下，Tab鍵也等於4空白
        vim.opt_local.shiftwidth = 4   -- 自動縮進時使用 4 個空白
      end,
      desc = "indent_style=Space, indent_size=4"
    }
  )
  create_autocmd(
    "FileType",
    {
      group = groupName.editorconfig,
      pattern = { "md", "yml", "yaml", "json", "json5", "js", "mjs", "ts", "mts", "css", "html", "gohtml", "gotmpl", "toml", "scss", "sass", "xml", "lua", "vue", "sh" },
      callback = function()
        vim.opt_local.tabstop = 2
        vim.opt_local.softtabstop = 2
        vim.opt_local.shiftwidth = 2
      end,
      desc = "indent_style=Space, indent_size=2"
    }
  )
  create_autocmd(
    "FileType",
    {
      group = groupName.editorconfig,
      -- pattern = "go",
      pattern = { "go", "puml", "nsi", "nsh", "Makefile", "mk" },
      callback = function()
        vim.opt_local.expandtab = false
        -- 以下還是可以設定，如果你想要讓tab看起來隔比較密(緊)可以考慮以下
        -- vim.opt_local.tabstop = 2
        -- vim.opt_local.softtabstop = 2
        -- vim.opt_local.shiftwidth = 2
      end,
      desc = "indent_style=tab"
    }
  )
  create_autocmd(
    "FileType",
    {
      group = groupName.editorconfig,
      pattern = {
        "dosbatch" -- bat
      },
      callback = function()
        vim.o.fileformat = "dos"
      end,
      desc = "fileformat=dos crlf"
    }
  )


  --[[ 以下是vs2010的mfc專案可能會有這樣的需求，你可以把這段放到 my-customize.lua 自己添加
  (因為不曉得是不是所有rc, rc2都是如此，為了避免有爭議，讓使用者自己在 my-customize.lua 中新增 )
  vim.api.nvim_create_autocmd(
    "FileType",
    {
      -- group = groupName.editorconfig,
      pattern = {
        "rc",
        "conf" -- "rc2"
      },
      callback = function()
        vim.o.fileencoding = "utf-16le"
        vim.o.fileformat = "dos"
      end,
      desc = "crlf, utf-16le"
    }
  )

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    pattern = { "resource.h" },
    callback = function()
      vim.o.fileencoding = "utf-16le"
      vim.o.fileformat = "dos"
    end,
    desc = "crlf, utf-16le"
  })
  --]]


  if opts.callback then
    opts.callback(M)
  end
end

return M
