-- 用的是 vim.api.nvim_set_hl(0, ...) 當ns_id為0指的是global的設定，因此只需要做一次，不需要每次開啟此filetype文件都動作

if vim.g.ftplugin_markdown_highlight_init_done then
  return
end

-- 以下兩個沒用
-- :echo synIDattr(synID(line("."), col("."), 1), "name")
-- :lua print(vim.fn.synID(vim.fn.line("."), vim.fn.col("."), 1))

-- :Inspect 可以查看出 vim.api.nvim_buf_add_highlight 所使用的顏色
-- :Inspect
-- vim.cmd("match YellowBold /\\*[^\\*]*\\*/") -- 用match的項目，無法被:Inspect查出來

-- bg: #1e2727, #2b384c
vim.api.nvim_set_hl(0, '@markup.italic.markdown_inline', { fg = '#ffffff', bg = "#1c2532", italic = true })
vim.api.nvim_set_hl(0, '@markup.strong.markdown_inline', { fg = '#ffffff', bg = "#1c2532", bold = true })


for _, hl in ipairs {
  -- { fg = '#00e7e7', bg = '#1e2727', bold = true },
  { fg = '#ffcb6b', bg = '#0d253f', bold = true },
  -- { fg = '#c792ea', bold = true },
  -- { fg = '#69ff94', bg = '#2e3440', bold = true },
  -- { fg = '#ff5555', bold = true },
  -- { fg = '#82aaff', bold = true },
  -- { fg = '#f8f8f2', bg = '#2d1b4e', bold = true },
  -- { fg = '#ff9f43', bg = '#252535', bold = true },
} do
  vim.api.nvim_set_hl(0, '@markup.raw.markdown_inline', { fg = hl.fg, bg = hl.bg, bold = hl.bold })
  vim.api.nvim_set_hl(0, 'RenderMarkdownCodeInline', { fg = hl.fg, bg = hl.bg, bold = hl.bold })
end

-- codeblock
vim.api.nvim_set_hl(0, 'RenderMarkdownCode', { bg = "#292a2d" })

-- heading
vim.api.nvim_set_hl(0, 'RenderMarkdownH1Bg', { fg = "#ffffff", bg = "#08b416" })
vim.api.nvim_set_hl(0, 'RenderMarkdownH2Bg', { fg = "#000000", bg = "#b49b1f", })
vim.api.nvim_set_hl(0, 'RenderMarkdownH3Bg', { bg = "#2f9cb4", })

vim.g.ftplugin_markdown_highlight_init_done = true
