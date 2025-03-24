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
