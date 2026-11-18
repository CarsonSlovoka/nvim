if vim.fn.executable("shfmt") == 0 then
  if not vim.g.shfmt_missing_notified then
    vim.g.shfmt_missing_notified = true

    vim.notify(
      "shfmt not found. Run `:checkhealth carson-nvim.fmt` for install instructions.",
      vim.log.levels.WARN,
      { title = "shfmt" }
    )
  end
  return
end

-- :verbose setlocal equalprg?
vim.bo.equalprg = "shfmt -ln zsh -i 2"
