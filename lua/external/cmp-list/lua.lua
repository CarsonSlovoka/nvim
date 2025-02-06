local kind = {
  table = "table",
  string = "string",
  buffer = "buffer",
}


return {
  {
    word = "vim.loop.fs_stat(filepath) ~= nil",
    info = "fileExists"
  },
  {
    word = 'vim.fn.line(".")',
    info = "光標所在的列位置，首列為: 1",
  },
  {
    word = 'vim.api.nvim_buf_set_extmark({buffer}, {ns_id}, {line}, {col}, {opts})',
    info = "替某個位子加上特別的顏色突顯\n" ..
        "或做到在列後，增加虛擬的註記，例如該行的修改時間等等\n" ..
        "line: 0 表示第1列\n" ..
        "col: 0表示第1列\n" ..
        "回傳值是一個id，如果沒用到可以不用接收",
    user_data = {
      example = [[
local mark_id = vim.api.nvim_buf_set_extmark(0, ns_id, vim.fun.line('.') - 1, 0, {}})

-- 或者做標記
vim.api.nvim_buf_set_extmark(buf, ns_id,
  start_line
  0, -- col
  {
    end_row = start_line + 1, -- 只標記這一列
    hl_group = '@label'       -- 如果給的hl_group沒有突顯，會先用syntax的突顯
  }
)
]]
    }
  },

  { word = "vim.api.nvim_feedkeys('Hello', 'i', true)" },
  { word = 'vim.api.nvim_put({ "Line 1", "Line 2" }, "c", true, true)' },

  -- table
  {
    word = 'table.concat({"line1", "line2"}, ",")',
    kind = kind.table,
    info = "用,來串接table，成為一個字串"
  },
  {
    word = 'unpack(table)',
    kind = kind.table,
    info = "用,來串接table，成為一個字串",
    user_data = {
      example = [[
local a = {1, 2, 3}
local b = {4, 5, 6}
print(vim.inspect(
  unpack(a),
  unpack(b),
))
]]
    }
  },

  -- buffer
  {
    word = 'vim.api.nvim_buf_clear_namespace(buffer, ns_id, line_start, line_end)',
    kind = kind.buffer,
    info = 'vim.api.nvim_create_namespace("myNameSpace")\n' ..
        'vim.api.nvim_buf_clear_namespace(0, "myNameSpace", 0, -1)',

  },

  -- string
  {
    word = 'vim.split("aa\\nbb\\ncc", "\\n", { plain = true })',
    info = '分割字符串',
    kind = kind.string,
    user_data = {
      example = 'print(vim.inspect(vim.split("aa\\nbb\\ncc", "\\n", { plain = true })))'
    }
  }
}
