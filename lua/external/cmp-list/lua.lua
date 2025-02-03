local kind = {}
kind.table = "table"

return {
  {
    word = "vim.loop.fs_stat(filepath) ~= nil",
    info = "fileExists"
  },

  { word = "vim.api.nvim_feedkeys('Hello', 'i', true)" },
  { word = 'vim.api.nvim_put({ "Line 1", "Line 2" }, "c", true, true)' },

  {
    word = 'table.concat({"line1", "line2"}, ",")',
    kind = kind.table,
    info = "用,來串接table，成為一個字串"
  },
}
