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

function Example_buf_set_lines()
  vim.api.nvim_create_user_command("Examplebufsetlines",
    function()
      local buf = vim.api.nvim_get_current_buf()

      -- 加在結尾，如果空間不夠會自己補
      utils.buf.set_lines(buf, vim.api.nvim_buf_line_count(buf),
        {
          {
            { 'line1 col1 ', '@label' },
            { 'line1 col2',  'Yellow' }
          },
          {
            { "line2 col1 ", "Red" },
            { "line2 col2 ", "" }, -- 沒有給就是不套用hl_group
            { "line2 col3 ", "@label" }
          },
          {
            { "中文 ", "@label" },
            { "line2", "Red" }
          },
        }
      )

      -- 加在開頭，有機會覆蓋掉已經存在的文字
      utils.buf.set_lines(buf, 0,
        {
          {
            { '新增在頭 ', 'YellowBold' },
            { 'line1 col2', 'Yellow' }
          },
          {
            { "line2 col1 ", "Red" },
            { "line2 col2 ", "" }, -- 沒有給就是不套用hl_group
            { "line2 col3 ", "@label" }
          },
          {
            { "中文 ", "@label" },
            { "line2", "Red" }
          },
        }
      )
    end,
    {}
  )
end
