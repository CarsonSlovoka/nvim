local filename = vim.api.nvim_buf_get_name(0)
if not filename:match("%.el$") then
  -- Note: 這些檔案nvim的filetype都會當成是lisp, 而我們只針對el的文件才格式化
  -- init.el       -- Emacs Lisp
  -- example.lisp  -- Common Lisp
  -- system.asd    -- Common Lisp ASDF
  -- example.lsp   -- Lisp
  return
end

local formatter = vim.fs.joinpath(
  vim.fn.stdpath("config"), "scripts", "format-elisp.el" -- ~/.config/nvim/scripts/format-elisp.el
)

-- 所謂的 equalprg 會影響到 選取後 = 的動作, 就可以拿來當成格式化
vim.bo.equalprg = table.concat({
  "emacs",
  "--batch",
  "--quick",
  "--script",
  vim.fn.shellescape(formatter),
}, " ")


-- 可寫在全域的定義，不需要特別針對某個buf
-- vim.api.nvim_create_autocmd({ "BufWritePre" },
--   {
--     buf = buf,
--     desc = "call equalprg for fmt",
--     callback = function()
--       if vim.bo.equalprg and vim.bo.equalprg ~= "" then
--         print("auto fmt from vim.bo.equalprg")
--         vim.cmd('normal! m"gg=G`"`') -- 先在原本的地方做標籤，gg=G之後再回到原本的標籤位置
--       end
--     end
--   }
-- )
