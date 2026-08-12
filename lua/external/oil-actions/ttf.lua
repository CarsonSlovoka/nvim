local M = {
  {
    label = "Validate",
    children = {
      {
        label = "font-validator",
        callback = function(path)
          if vim.fn.executable('font-validator') == 1 then
            vim.cmd("topleft split | terminal font-validator " .. vim.fn.shellescape(path))
          else
            vim.schedule(function()
              vim.notify("font-validator not found", vim.log.levels.ERROR)
            end)
          end
        end,
      },
      {
        label = "ots (OpenType Sanitizer)",
        callback = function(path)
          vim.system(
            { "ots-sanitize", path },
            { text = true },
            function(obj)
              vim.schedule(function()
                if obj.code == 0 then
                  vim.notify("ots: OK", vim.log.levels.INFO)
                else
                  vim.notify("ots failed:\n" .. (obj.stderr or ""), vim.log.levels.ERROR)
                end
              end)
            end
          )
        end,
      },
    },
  },
  {
    label = "Convert",
    children = {
      {
        label = "to WOFF2",
        callback = function(path)
          local ext = vim.fn.fnamemodify(path, ":e")
          local out = path:gsub(string.format("%%.%s$", ext), ".woff2")
          local cmd = { "woff2_compress", path }
          print(table.concat(cmd, " "))
          vim.system(cmd, {}, function(r)
            if r.code == 0 then
              -- vim.notify("\n ✅ Converted to " .. out) -- Caution: 會報錯: nvim_echo must not be called in a fast event context stack 在 Neovim 中，Fast Event Context（快速事件上下文）不允許直接執行會改變 UI、觸發螢幕繪製或更動編輯器狀態的API
              vim.schedule(function() -- 用schedule來發送可解決
                vim.notify("✅ Converted to " .. out)
              end)
            else
              vim.schedule(function()
                vim.notify(
                  ("Unzip failed:\n%s"):format(r.stderr or r.stdout or "unknown"),
                  vim.log.levels.ERROR
                )
              end)
            end
          end)
        end,
      },
    },
  },
}

-- 副檔名別名（otf 直接用 ttf 的選單）
-- require("external.oil-actions.actions").actions_by_ext.otf = M

return M
