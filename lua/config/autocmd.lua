local M = {
  autosave = true,
}

local create_autocmd = vim.api.nvim_create_autocmd

local function setup()
  if M.autosave then
    create_autocmd(
      {
        "TextChanged", -- 如果用x, ce, undo, redo...也會觸發
        "InsertLeave",
      },
      {

        pattern = "*",
        -- command="silent write"
        callback = function()
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
  end

  -- trim_trailing_whitespace
  create_autocmd(
    "BufwritePre", -- 在寫入前執行的動作
    {
      pattern = "*",
      callback = function()
        -- 其實就是使用vim的取代%s/.../...
        -- \s\+  \s+ 任意空白字符(空格, 制表符等)一個或多個
        -- 取代為空白
        -- e flags, 如果發生錯誤的時候不報錯
        vim.cmd([[%s/\s\+$//e]])
      end
    }
  )

  create_autocmd(
    "FileType",
    {
      pattern = "*",       -- :set ft?

      callback = function()
        vim.opt_local.expandtab = true         -- 使用空白代替Tab
        vim.opt_local.tabstop = 4              -- Tab鍵等於4個空白
        vim.opt_local.softtabstop = 4          -- 在插入模式下，Tab鍵也等於4空白
        vim.opt_local.shiftwidth = 4           -- 自動縮進時使用 4 個空白
      end
    }
  )
  create_autocmd(
    "FileType",
    {
      pattern = { "md", "yml", "yaml", "json", "json5", "js", "mjs", "ts", "mts", "css", "html", "gohtml", "gotmpl", "toml", "scss", "sass", "xml", "lua", "vue", "sh" },
      callback = function()
        vim.opt_local.tabstop = 2
        vim.opt_local.softtabstop = 2
        vim.opt_local.shiftwidth = 2
      end
    }
  )
  create_autocmd(
    "FileType",
    {
      -- pattern = "go",
      pattern = { "go", "puml", "nsi", "nsh", "Makefile", "mk" },
      callback = function()
        vim.opt_local.expandtab = false
        -- 以下還是可以設定，如果你想要讓tab看起來隔比較密(緊)可以考慮以下
        -- vim.opt_local.tabstop = 2
        -- vim.opt_local.softtabstop = 2
        -- vim.opt_local.shiftwidth = 2
      end
    }
  )
end

return {
  setup = setup
}
