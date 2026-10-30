vim.pack.add({ "https://github.com/CarsonSlovoka/pen.nvim" })
-- vim.cmd.packadd("pen.nvim")
local db_path = {
  vim.fn.stdpath('data') .. "/pen.nvim/" .. "project.tsv",
  vim.fn.stdpath('data') .. "/pen.nvim/" .. "config.tsv",
  vim.fn.stdpath('data') .. "/pen.nvim/" .. "dir.tsv",
  vim.fn.stdpath('data') .. "/pen.nvim/" .. "note.tsv",

  vim.fn.stdpath('data') .. "/pen.nvim/" .. "help.tsv",
  vim.fn.stdpath('data') .. "/pen.nvim/" .. "6.tsv",
  vim.fn.stdpath('data') .. "/pen.nvim/" .. "tmp.tsv",

  vim.fn.stdpath('data') .. "/pen.nvim/" .. "test.tsv",
  vim.fn.stdpath('data') .. "/pen.nvim/" .. "todo.tsv",
}

require("pen").setup({
  db_path = db_path,

  -- 以下全可選：自訂書籤列表的顯示欄位與對齊
  display = {
    columns = {
      { field = "index",  width = 4,  align = "right",  hl = "Comment" }, -- 僅在 :PenOpen（無 index）時有值
      { field = "source", width = 16, hl = "Comment" },                   -- 僅在 :PenOpen（無 index）時有值
      { field = "note",   width = 40 },
      { field = "file",   width = 15, path = ":t",      hl = { fg = "#88ccff", italic = true } },
      { field = "file",   width = 60, path = "relative" }, -- absolute (:p), basename (:t), relative (:.)
      { field = "line",   width = 6,  align = "left",   hl = { fg = "#aaaaaa" } },
      { field = "col",    width = 4,  align = "left",   hl = { fg = "#aaaaaa" } },
      -- { format = function(bm) return bm.note end, width = 30, align = "left" }, -- Tip: 自定義其它欄位
    },
    separator = "  ",
  },
  preview = {
    context = 8,      -- 預覽時顯示書籤行前後各幾行. preview關閉時，可以用{, }來再調整context的大小
    auto_open = true, -- 進入書籤列表時是否自動開啟預覽
    syntax = true,
  },
})

local config = require("pen").get_config()
local pen_bookmark = require("pen.bookmark")
local ask_note = function(prompt)
  return vim.fn.input(prompt)
end


vim.keymap.set("n", "<leader>mm", function() require("pen.ui").open(nil, config) end, { desc = "Pen bookmark (all)" })
vim.keymap.set("n", "<leader>bk", function() require("pen.ui").open(nil, config) end, { desc = "Pen bookmark (all)" })
for i = 1, #db_path do
  local filename = vim.fn.fnamemodify(db_path[i], ":t:r")

  -- open
  -- vim.keymap.set("n", "<leader>m", function() require("pen.ui").open(2, config) end, { desc = "Pen bookmark: 2" })
  vim.keymap.set("n", "<leader>m" .. i,
    function()
      require("pen.ui").open(i, config)
    end,
    { desc = "Pen bookmark: " .. i }
  )

  -- add
  -- vim.keymap.set("n", "<leader>ma1", function() pen_bookmark.add(1, ask_note, config) end, { desc = "Add bookmark to 1" })
  vim.keymap.set("n", "<leader>ma" .. i,
    function()
      local note = ask_note(string.format("[%s] Note:", filename))
      if note ~= "" then
        pen_bookmark.add(i, note, config)
      end
    end,
    { desc = "Add bookmark to " .. i })
end
