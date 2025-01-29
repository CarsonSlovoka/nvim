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
end

return {
  setup = setup
}
