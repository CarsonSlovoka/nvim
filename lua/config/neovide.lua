if not vim.g.neovide then
  return
end

-- https://neovide.dev/configuration.html
-- :lua vim.print(vim.g.neovide_version) -- 也可以進入的時候用打command的方式來查看
-- vim.print(vim.g.neovide_version)

-- font
-- vim.o.guifont="FiraCode Nerd Font Mono:h14:w4"
vim.o.guifont = "FiraCode Nerd Font Mono:h14"

-- vim.g.neovide_scale_factor = 1.0

-- vim.g.neovide_transparency = 0.8

-- vim.g.neovide_cursor_animation_length = 0.1

vim.api.nvim_create_user_command(
  "NeovideSetScale",
  function(args)
    vim.g.neovide_scale_factor = tonumber(args.fargs[1])
  end,
  {
    nargs = 1,
    complete = function()
      return {
        "1.0",
        "0.5",
        "1.5",
        "3"
      }
    end,
    desc = "scale_factor 改變縮放比例"
  }
)

vim.api.nvim_create_user_command(
  "NeovideSetTransparency",
  function(args)
    vim.g.neovide_transparency = tonumber(args.fargs[1])
  end,
  {
    nargs = 1,
    complete = function()
      return {
        "1.0",
        "0.8",
        "0.5",
        "0.2",
        "0.05",
        "0",
      }
    end,
    desc = "transparency 改變alpha的透明度"
  }
)
