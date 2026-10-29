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
    local path = vim.fn.exepath("shfmt")
    local version = vim.fn.system({ "shfmt", "--version" }):gsub("%s+$", "")
    -- shfmt --version
    -- v3.14.1
    vim.health.ok(string.format("shfmt found: %s (%s)", path, version))

    if vim.bo[vim.fn.bufnr('#')].filetype == "sh" then
      vim.health.info(string.format("vim.bo.equalprg = %s", vim.bo.equalprg))
    end
  end
end

return M
