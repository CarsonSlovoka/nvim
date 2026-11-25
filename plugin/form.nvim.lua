-- 簡單版本的參考: https://gist.github.com/CarsonSlovoka/7c1aad5a6ec59f94d50b9093bbdd773a

vim.pack.add({ "https://github.com/CarsonSlovoka/form.nvim" })
-- vim.cmd.packadd("form.nvim")
-- `:pu=nvim_get_runtime_file('**/form.nvim/*', v:true)`

vim.api.nvim_create_user_command('GMapQuery', function()
  -- `:pu=nvim_get_runtime_file('**/form.lua', v:false)`
  require('form').open({
    title = 'location',
    fields = {
      { name = 'latitude', label = '緯度', type = 'number', min = -90, max = 90, required = true },
      { name = 'longitude', label = '經度', type = 'number', min = -180, max = 180, required = true },
      { name = 'description', label = '描述', multiline = true, required = false },
      { name = 'label', label = '連結描述', required = false },
      { name = 'bufnr', label = '內容附加到指定buffer id', type = 'number', required = false },
    },
    format = function(data, ctx)
      return string.format([[
%s
[%s](https://www.google.com/maps/search/?api=1&query=%s,%s)
]], data.description or "",
        data.label or "", data.latitude, data.longitude
      )
    end,
    on_submit = function(data, ctx)
      local fmt_data = ctx.serialize()
      -- vim.api.nvim_put(vim.split(fmt_data, "\n"), "c", false, true) -- 這是填寫的表單，不能放這邊
      vim.fn.setreg('+', fmt_data)
      print(string.format('✅ 已將結果保存到剪貼簿:\n%s', fmt_data))
      if data.bufnr and vim.api.nvim_buf_is_valid(data.bufnr) then
        vim.api.nvim_buf_set_lines(data.bufnr, -1, -1, false, vim.split(fmt_data, "\n"))
        -- vim.api.nvim_buf_call(data.bufnr, function() vim.cmd('write') end)
      end
    end
  })
end, {})
