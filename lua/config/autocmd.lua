local M = {
  autosave = true,
}

local create_autocmd = vim.api.nvim.create_autocmd

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
            vim.cmd("silent write")
            vim.notify(string.format("%s %s 已保存",
              os.date("%Y-%m-%d %H:%M:%S"),
              vim.api.nvim_buf_get_name(0)
            ), vim.log.levels.INFO)
            -- elseif not vim.bo.modified then
            --  vim.notify("未檢測到變更，跳過保存", vim.log.levels.DEBUG)
            -- else
            --  vim.notify(string.format("跳過保存，因為 buftype 為 '%s'", buftype), vim.log.levels.WARN)
          end
        end,
      })
  end

return {
  setup = setup
}
