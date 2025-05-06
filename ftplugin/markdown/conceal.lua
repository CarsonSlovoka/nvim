-- set conceallevel=2
-- set concealcursor=n
-- syntac clear
-- vim.cmd([[ syntax match MyGroup "lambda" conceal cchar=λ ]]) -- ⚠️ 注意！直接這樣寫會沒效，推測是因為文本還沒載入的關係, 即便寫到了~/.config/nvim/after/ftplugin/markdown/conceal.lua之中也是如此
-- print("before")


-- vim.opt_local.conceallevel = 2
-- -- vim.opt_local.concealcursor = ""
-- vim.api.nvim_create_autocmd({ "BufEnter" }, {
--   pattern = "*.md",
--   callback = function()
--     -- vim.cmd([[ syntax match MyGroup "lambda" conceal cchar=λ containedin=ALL]]) -- containedin 允許規則在其它語法組中生效
--     vim.cmd([[ syntax match MyGroup /\cTODO/ conceal cchar=📝 containedin=ALL]])
--     -- vim.cmd("syntax sync fromstart")
--   end,
-- })
