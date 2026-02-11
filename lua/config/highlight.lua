vim.api.nvim_set_hl(0, "@breakpoint", { bg = "#40252b" })
vim.api.nvim_set_hl(0, "@onbreakpoint", { bg = "#2a5091" })

-- 當使用Inspect來查看json5Key它會顯示link to @Tag 這是因為@label也是link to @Tag
-- 即 :Inspect 會顯示 link to 的原型
vim.api.nvim_set_hl(0, "json5Key", { link = "@label" }) -- 用filetype=jsonc其實就用不太到這個
vim.api.nvim_set_hl(0, "@property.jsonc", { link = "@tag" })

vim.api.nvim_set_hl(0, "sqlkeyword", { link = "Statement" })
vim.api.nvim_set_hl(0, "@operator.sql", { link = "sqlOperator" })

vim.api.nvim_set_hl(0, "Search", { bg = "#ff520d", fg = "#ffffff", bold = true, italic = true }) -- 改變顏色時要考慮: CursorColumn, CursorLine等顏色, 以及鼠標該字詞(hover)時的高亮

local function set_highlight(name, fg, bg, opts)
  local val = { fg = fg, bg = bg }
  if opts then
    for k, v in pairs(opts) do
      val[k] = v
    end
  end
  vim.api.nvim_set_hl(0, name, val)
  -- vim.api.nvim_set_hl(0, "YellowBoldItalic", {
  --   fg = "#000000",
  --   bg = "#ffff00",
  --   bold = true,
  --   italic = true
  -- })
end

-- 基本顏色定義
local colors = {
  Yellow = { fg = "#000000", bg = "#ffff00" },
  Red    = { fg = "#ffffff", bg = "#ff0000" },
  Green  = { fg = "#000000", bg = "#00ff00" },
  Blue   = { fg = "#ffffff", bg = "#0000ff" },
  Purple = { fg = "#ffffff", bg = "#800080" },
  Cyan   = { fg = "#000000", bg = "#00ffff" },
  White  = { fg = "#000000", bg = "#ffffff" },
  Gray   = { fg = "#000000", bg = "#808080" },
}

-- 設定所有高亮組
for color_name, color_vals in pairs(colors) do
  -- 基本樣式
  set_highlight(color_name, color_vals.fg, color_vals.bg)

  -- strikethrough
  set_highlight(color_name .. "Strikethrough", color_vals.fg, color_vals.bg, { strikethrough = true })

  -- blend 我沒看出效果
  -- set_highlight(color_name .. "Blend", color_vals.fg, color_vals.bg, { blend = 0 })
  -- set_highlight(color_name .. "Blend50", color_vals.fg, color_vals.bg, { blend = 50 })
  -- set_highlight(color_name .. "Blend100", color_vals.fg, color_vals.bg, { blend = 100 })

  -- 粗體樣式
  set_highlight(color_name .. "Bold", color_vals.fg, color_vals.bg, { bold = true })

  -- 粗體+斜體樣式
  set_highlight(color_name .. "BoldItalic", color_vals.fg, color_vals.bg, {
    bold = true,
    italic = true
  })
end
