if vim.fn.executable("shfmt") == 0 then
  if not vim.g.shfmt_missing_notified then
    vim.g.shfmt_missing_notified = true -- 想測試時可以再手動改 `:lua vim.g.shfmt_missing_notified=false`

    -- vim.health.warn() -- 不能寫這. :checkhealth 會需要一個可以實際被 require 的模組

    vim.notify(
      "shfmt not found. Run `:checkhealth carson-nvim.fmt` for install instructions.",
      vim.log.levels.WARN,
      { title = "shfmt" }
    )
  end
  return
end

-- :verbose setlocal equalprg?
vim.bo.equalprg = "shfmt -ln bash -i 2"
