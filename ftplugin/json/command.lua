-- vim.api.nvim_create_user_command("FmtJSON",
vim.api.nvim_buf_create_user_command(vim.api.nvim_get_current_buf(), "FmtJSON",
  function()
    -- `:%`  表示對整個文件操作
    --  `!` 表示執行外部命令
    --  `jq .` 是格式化JSON的基本指令
    vim.cmd("%!jq .") -- :%!jq .
  end,
  {
    desc = "格式化json文件( 需要有jq工具 )"
  }
)
