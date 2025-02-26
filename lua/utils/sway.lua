local M = {}

--- 取得到name, pid的資訊
--- @return table
function M.get_tree()
  local handle = io.popen("swaymsg -t get_tree")
  if not handle then
    vim.notify("無法執行 swaymsg ", vim.log.levels.ERROR)
    return {}
  end

  local result = handle:read("*a")
  handle:close()

  local windows = {}
  local json = vim.fn.json_decode(result)
  if not json then
    vim.notify("無法解析 swaymsg 輸出", vim.log.levels.ERROR)
    return {}
  end


  -- 因為可能還有子節點，所以寫成函數來遞歸呼叫
  local function traverse_nodes(nodes)
    for _, node in ipairs(nodes) do
      if node.pid and node.name then
        table.insert(windows, {
          name = node.name,
          pid = node.pid
        })
      end

      if node.nodes then
        traverse_nodes(node.nodes)
      end

      if node.floating_nodes then
        traverse_nodes(node.floating_nodes)
      end
    end
  end

  traverse_nodes(json.nodes)
  return windows
end

--- @return number? 0: ok, otherwise error
function M.set_window_opacity(pid, opacity)
  -- 驗證透明度範圍
  opacity = tonumber(opacity)
  if not opacity or opacity < 0 or opacity > 1 then
    vim.notify("透明度必須在 0 到 1 之間", vim.log.levels.ERROR)
    return -1
  end

  -- 執行 swaymsg 命令
  local cmd = string.format('swaymsg "[pid=%s]" opacity %f', pid, opacity)
  return os.execute(cmd)
end

return M
