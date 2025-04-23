local M = {
  autoSave = true,
  autoReformat = true,
  callback = function(module) end
}
local create_autocmd = vim.api.nvim_create_autocmd
local groupName = {
  editorconfig = "carson.editorconfig",
  highlightHexColor = "carson.highlightHexColor",
  highlightSpecial = "highlightSpecial",
}
for key, name in pairs(groupName) do
  if name == groupName.editorconfig then
    vim.api.nvim_create_augroup(name, { clear = true })
  else
    vim.api.nvim_create_augroup(name, {})
  end
end


function M.setup(opts)
  for k, v in pairs(opts) do
    if M[k] ~= nil then
      M[k] = v
    end
  end

  -- print(vim.inspect(M))

  vim.keymap.set("i", "<C-O>", function()
      if not M.autoSave then
        return "<C-O>"
      end
      -- local orgSetting = M.autoSave
      M.autoSave = false -- 因為<C-O>會暫時離開Insert模式，就會導致觸發了InsertLeave的事件，這不是我們所期望的，因此就先關閉
      -- print("🧊", M.autoSave)
      vim.defer_fn(function()
        -- M.autoSave = orgSetting -- 可行，但是多此一舉
        M.autoSave = true
        -- print("🔥", M.autoSave)
      end, 50)
      return "<C-O>"
    end,
    {
      desc = "若AutoSave開啟，則暫時關閉後再開啟. 並執行預設行為: execute one command, return to Insert mode",
      noremap = false, -- 允許遞歸映射以執行原始 <C-O> 行為
      expr = true,
    }
  )
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
        -- local buftype = vim.api.nvim_buf_get_option(0, "buftype"  )
        local buftype = vim.api.nvim_get_option_value("buftype", { buf = 0 })

        -- 當 buftype 為空時才執行保存: 你可以嘗試用telescope的輸入視窗用insert，此時的buftype是prompt就不是空的
        if buftype == "" and
            vim.bo.modified -- 可以曉得是否真的有異動
        then
          if M.autoReformat and vim.bo.filetype == "python" then
            vim.cmd("FmtPython --reload=0")
            vim.defer_fn(function()
              vim.cmd("silent e")
            end, 50) -- 要等到InsertLeave才能重載，不然會有錯
            return   -- 它是透過外部工具來格式化，會有reload，沒辦法保存tag，所以不需要後續動作
          end

          -- 先手動觸發 BufWritePre 自動命令 (去除多餘的空白、格式化、保存tag等等)
          vim.api.nvim_exec_autocmds("BufWritePre", {
            pattern = vim.fn.expand("%") -- 當前文件路徑
          })

          vim.cmd("silent write") -- 如果文件是被外部工具改變這時候用write就會被尋問是否要載入
          vim.notify(
            string.format("%s %s saved.", os.date("%Y-%m-%d %H:%M:%S"), vim.fn.expand('%')),
            vim.log.levels.INFO
          )
          vim.api.nvim_input("i<ESC>") -- 手動觸發再離開，為了讓`^標籤可以不被lsp格式化影響

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
    -- "InsertLeave",
  }, {
    desc = '將文字 #RRGGBB 給予顏色. 例如: #ff0000  #00ff00 #0000ff',
    pattern = "*",
    group = groupName.highlightHexColor,
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      -- 清空之前的高亮（避免重複）
      -- vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1) -- 這會清除所有，可能會勿清
      vim.api.nvim_buf_clear_namespace(buf, ns_highlight_hex_or_rgb, 0, -1) -- 清理還是需要的，不然刪除後再打上其它內容還是會有突顯

      -- 遍歷每一行
      for lnum, line in ipairs(lines) do
        -- 匹配 #RRGGBB
        for color in line:gmatch('#%x%x%x%x%x%x') do
          -- 找到顏色代碼的起始和結束位置
          local start_col = line:find(color, 1, true) - 1
          local end_col = start_col + #color

          -- 動態創建高亮組，背景色設為該顏色
          local hl_group = 'Color_' .. color:sub(2) -- 去掉 # 作為高亮組名
          vim.api.nvim_set_hl(0, hl_group, { bg = color })

          -- 應用高亮到緩衝區
          -- vim.api.nvim_buf_add_highlight(buf, ns_highlight_hex_or_rgb, hl_group, lnum - 1, start_col, end_col) -- DEPRECATED IN 0.11 https://neovim.io/doc/user/deprecated.html
          vim.api.nvim_buf_set_extmark(buf, ns_highlight_hex_or_rgb, lnum - 1, start_col,
            {
              end_col = end_col,
              hl_group = hl_group,
            }
          )
        end
      end
    end,
  })

  --[[ 我是覺得不必要清除，就算在insert下顯示也不是什麼壞事
  -- 進入插入模式時只清除 color_highlights 命名空間的高亮
  vim.api.nvim_create_autocmd("InsertEnter", {
    desc = '插入模式下取消hex的顏色突顯',
    pattern = "*",
    group = groupName.highlightHexColor,
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_clear_namespace(buf, ns_highlight_hex_or_rgb, 0, -1)
    end,
  })
  --]]


  -- trim_trailing_whitespace
  create_autocmd(
    "BufWritePre", -- 在寫入前執行的動作
    {
      desc = "格式化和去除結尾多餘的space, tab",
      pattern = "*",
      callback = function()
        local has_formatter = M.autoReformat and vim.bo.filetype == "python" -- 如果是python用外部工具來格式化
        if M.autoReformat then
          -- 檢查是否有LSP客戶端附加到當前的緩衝區
          local clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
          if not has_formatter then
            for _, client in ipairs(clients) do
              -- 也就檢查是否有支持格式化的功能
              if client:supports_method("textDocument/formatting") then
                has_formatter = true
                break
              end
            end
          end

          -- lsp格式化 和 保存標籤
          if has_formatter and vim.bo.filetype ~= "python" then                         -- 這部份是保存標籤，而由於python是用外部工具來格式化，保存標籤的這段不適用它
            -- 保存當前所有用戶定義的標記 (a-z, A-Z)
            local marks = vim.fn.getmarklist('%')                                       -- 獲取當前緩衝區的標籤 -- 這個只會保存小寫的內容a-Z
            for char in string.gmatch("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ^.", ".") do -- 大寫的用這樣來取得
              -- for char in string.gmatch("[0-9A-Z]", ".") do -- ❌ 這是錯的，這也只會得到: [, 0, 9, A, -, Z, ]
              -- print(char)
              local mark = "'" .. char
              local pos = vim.fn.getpos(mark)
              -- lua print(vim.inspect(vim.fn.getpos("'^")))
              -- 如果標籤有效（pos[2] 是行號，pos[3] 是列號）
              if pos[2] ~= 0 or pos[3] ~= 0 then
                -- marks[mark] = pos
                table.insert(marks, {
                  mark = mark,
                  pos = pos,
                })
              end
            end
            --[[ 顯式處理特殊標籤 '^ 和 '. 似乎沒有效，改用vim.api.nvim_input("i<ESC>")的方式來觸發`^
            for _, mark in ipairs({ "'^", "'." }) do
              local pos = vim.fn.getpos(mark)
              if pos[2] ~= 0 or pos[3] ~= 0 then
                marks[mark] = pos
              end
            end
            --]]
            -- print(vim.inspect(marks))

            -- vim.cmd("FmtPython") -- 不能再這邊格式化，因為裡面也會save, 這樣會導致一直有BufWritePre

            vim.lsp.buf.format({
              async = false,
              timeout_ms = 3000,
            })
            local fmt_msg = string.format("%s lsp.buf.format done", os.date("%Y-%m-%d %H:%M:%S"))
            vim.notify(fmt_msg, vim.log.levels.INFO)

            -- 恢復標籤
            for _, mark in ipairs(marks) do
              -- if mark.mark:match("^'[0-9a-zA-Z^.]") then
              --   vim.fn.setpos(mark.mark, mark.pos)
              -- end
              vim.fn.setpos(mark.mark, mark.pos)
            end
          else
            vim.notify("No LSP formatter available for current file, skipping format. Turn off msg `:SetAutFmt 0`",
              vim.log.levels.WARN)
          end
        end

        if not has_formatter then
          -- 如果有格式化，多餘的空白，應該都會被除掉，所以這個動作只需要在沒有格式化的文件使用即可
          -- 其實就是使用vim的取代%s/.../...
          -- \s\+  \s+ 任意空白字符(空格, 制表符等)一個或多個
          -- 取代為空白
          -- e flags, 如果發生錯誤的時候不報錯
          vim.cmd([[%s/\s\+$//e]])
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
        if not vim.bo.readonly and vim.o.fileformat ~= "unix" then
          print(string.format("set fileformat from `%s` to `unix`", vim.o.fileformat)) -- 提示使用者有被自動轉換，使其如果不滿意還可以自己再轉回去
          vim.o.fileformat = "unix"
        end
        vim.opt_local.expandtab = true -- 使用空白代替Tab :set et?  -- :set expandtab -- :set et
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
        vim.opt_local.expandtab = false -- :set noexpandtab -- :set noet
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

  create_autocmd("TermOpen",
    {
      callback = function()
        -- https://neovim.io/doc/user/terminal.html#terminal-config
        vim.opt_local.number = true
        vim.opt_local.relativenumber = true
      end,
      desc = "set number, set relaivenumber"
    }
  )

  create_autocmd('LspAttach', {
    -- https://neovim.io/doc/user/lsp.html
    desc = "auto-completion. 在`.`的時候會自動觸發補全 Note: Use CTRL-Y to select an item.",
    group = vim.api.nvim_create_augroup('my.lsp', {}),
    callback = function(args)
      local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
      -- if client:supports_method('textDocument/implementation') then
      --   -- Create a keymap for vim.lsp.buf.implementation ...
      -- end
      -- Enable auto-completion. Note: Use CTRL-Y to select an item. |complete_CTRL-Y|
      if client:supports_method('textDocument/completion') then
        -- Optional: trigger autocompletion on EVERY keypress. May be slow!
        -- local chars = {}; for i = 32, 126 do table.insert(chars, string.char(i)) end
        -- client.server_capabilities.completionProvider.triggerCharacters = chars
        vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
      end
      -- -- Auto-format ("lint") on save.
      -- -- Usually not needed if server supports "textDocument/willSaveWaitUntil".
      -- if not client:supports_method('textDocument/willSaveWaitUntil')
      --     and client:supports_method('textDocument/formatting') then
      --   vim.api.nvim_create_autocmd('BufWritePre', {
      --     group = vim.api.nvim_create_augroup('my.lsp', { clear = false }),
      --     buffer = args.buf,
      --     callback = function()
      --       vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 1000 })
      --     end,
      --   })
      -- end
    end,
  })

  -- :h compl-autocomplete

  --[[ 以下是vs2010的mfc專案可能會有這樣的需求，你可以把這段放到 my-customize.lua 自己添加
  (因為不曉得是不是所有rc, rc2都是如此，為了避免有爭議，讓使用者自己在 my-customize.lua 中新增 )
  vim.api.nvim_create_autocmd(
    "FileType",
    {
      -- group = groupName.editorconfig,
      pattern = {
        "rc",
        -- "conf" -- "rc2" -- .ignore的檔案也是conf -- 因此不建議調整，通常這種檔案都會有bom，所以fileencoding如果有ucs-bom是可以直接識別，而不需要特別告知
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
