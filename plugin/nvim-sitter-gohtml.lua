-- vim.pack.add({ "https://github.com/CarsonSlovoka/tree-sitter-gohtml" }) -- 不真的載入它，只要下載其so檔案即可
-- vim.cmd.packadd("tree-sitter-gohtml")

-- 如果有不同於附檔名時才需要考慮
-- vim.filetype.add({
--   extension = {
--     -- extension 對應 filetype
--     gohtml = "gohtml",
--   },
-- })

-- vim.treesitter.language.add('gohtml') -- 載入相關的so檔案，此動作也可以不加倚靠`vim.treesitter.start`即可
