local utils = require("utils")

--- 測試的時候，可以做command複製出去，再執行即可
function Example_buf_appendbufline()
  vim.api.nvim_create_user_command("Examplebufappendbufline",
    function()
      local buf = vim.api.nvim_get_current_buf()

      utils.buf.appendbufline(buf, vim.api.nvim_buf_line_count(buf), {
        { '從尾結開始加入', "@label" },
        { 'Line2', "ERROR" },
      })

      utils.buf.appendbufline(buf, 0, {
        { '放在開頭', "@label" },
        { 'Line2', "ERROR" },
      })


      utils.buf.appendbufline(buf, 0, { { '中文 line1', '@label' }, { '黃色 line2', 'YellowBold' } })
    end,
    {}
  )
end
