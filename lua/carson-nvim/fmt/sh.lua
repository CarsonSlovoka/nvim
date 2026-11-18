local M = {}
M.check = function()
  vim.health.start("carson-nvim.fmt.sh (shell formatter)")

  if vim.fn.executable("shfmt") == 0 then
    vim.health.warn("`shfmt` not found in $PATH", {
      [[
Install with Go:
  `go install mvdan.cc/sh/v3/cmd/shfmt@latest`
Or with your package manager:
  `brew install shfmt`          # macOS
  `apt install shfmt`           # Debian/Ubuntu
  `pacman -S shfmt`             # Arch
  `scoop install shfmt`         # Windows
Then restart Neovim or :checkhealth again.]],
      "Docs: https://github.com/mvdan/sh",
      '`vim.bo.equalprg = "shfmt -ln bash -i 2"`'
    })
  else
    local path                        = vim.fn.exepath("shfmt")
    local version                     = vim.fn.system({ "shfmt", "--version" }):gsub("%s+$", "")
    -- shfmt --version
    -- v3.14.1
    local minimal_support_zsh_version = "3.13.0"                   -- 此版本開始支援zsh
    local cur_ver                     = vim.version.parse(version) -- 3.14.1 或 v3.14.1 => 3.14.1 前面的v會幫忙拿掉
    if vim.version.cmp(minimal_support_zsh_version, tostring(cur_ver)) == 1 then
      vim.health.warn(string.format("shfmt found: %s (%s) < %s", path, cur_ver, minimal_support_zsh_version))
    else
      vim.health.ok(string.format("shfmt found: %s (%s)", path, cur_ver))
    end

    if vim.bo[vim.fn.bufnr('#')].filetype == "sh" then
      vim.health.info(string.format("vim.bo.equalprg = %s", vim.bo.equalprg))
    end
  end
end

return M
