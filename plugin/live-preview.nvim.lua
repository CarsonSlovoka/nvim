vim.defer_fn(function()
  --- 可以用瀏覽器預覽html, svg, md, ...
  --- Warn: 目前的版本如果在start時，直接編輯檔案或當掉
  --- Usage: `git show -p 80f572a2:README.md | bat -l vim -P -r 1334:1340`
  vim.pack.add({ "https://github.com/brianhuster/live-preview.nvim" })
  -- :che livepreview 可以看到預設的設定, port預設是5500
  require('livepreview.config').set()
end, 1000)
