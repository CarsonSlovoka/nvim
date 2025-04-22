local M = {}

--- @param concat string|nil  "\n", ...
--- @return string|table
function M.get_selected_text(concat)
  local mode = vim.fn.mode()

  local start_pos
  local end_pos
  if mode == 'v' or mode == 'V' then
    -- 以下是在keymap的清況下，'<, '>會是前一次的結果
    -- vim.api.nvim_input("<ESC>") -- 這種清況下，就算先嘗試離開，此時的getpos("'<")也還是之前的結果
    start_pos = vim.fn.getpos("v") -- 視覺模式的起點. 在V模式下的col不是1，而是取決於當前的cursor其col
    end_pos = vim.fn.getpos(".")   -- 當前光標的位置當作終點. 在V模式下的col不是1，而是取決於當前的cursor其col
    if mode == "V" then            -- 雖然是V但是cursor在哪一欄還是有影響！
      -- print("🧊 ", vim.inspect(start_pos), vim.inspect(end_pos))
      start_pos[3] = 1
      end_pos[3] = vim.fn.strlen(vim.fn.getline(end_pos[2])) -- col的位置抓該cursor所在列的最後一欄
      -- print("🌳 ", vim.inspect(start_pos), vim.inspect(end_pos))
    end
  else
    -- 如果是command所觸發，'<與'>都是目前的結果
    start_pos = vim.fn.getpos("'<") -- 抓取之前選取的起點
    end_pos = vim.fn.getpos("'>")
  end

  local line1, col1 = start_pos[2], start_pos[3]
  local line2, col2 = end_pos[2], end_pos[3]
  local lines = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
  if #lines == 0 then
    return ""
  end

  -- 同列
  if line1 == line2 then
    return string.sub(lines[1], col1, col2)
  end

  -- return table.concat(lines, '')

  local l_start = string.sub(lines[1], col1)       -- col1的位置是有包含的, col2省略會取到結束
  local l_end = string.sub(lines[#lines], 1, col2) -- sub可以0或1開始都行, 往後取col2個

  -- 二列
  if line2 - line1 == 1 then
    if concat then
      return table.concat({ l_start, l_end }, concat)
    else
      return { l_start, l_end, }
    end
  end

  -- 兩列以上
  -- print("lines", vim.inspect(lines))
  -- print("unpack", vim.inspect(unpack(lines, 2, #lines - 1)))
  -- ⚠ unpack如果不是在最後一個參數，它的其它結果將會被丟棄！ https://stackoverflow.com/a/32439840/9935654
  -- print(vim.inspect({ unpack({ 1, 2, 3 }), "Test" })) -- 1, Test
  -- print(vim.inspect({ "AAA", unpack({ 1, 2, 3 }) })) -- AAA, 1, 2, 3
  local result_table = { l_start, unpack(lines, 2, #lines - 1) }
  table.insert(result_table, l_end)
  if concat then
    return table.concat({ l_start, unpack(lines, 2, #lines - 1), l_end }, concat)
  else
    -- return { l_start, unpack(lines, 2, #lines - 1), l_end } -- 這是錯的，中間的部份不是放在最尾會只有一項而已！
    return result_table
  end
end

-- vim.api.nvim_create_user_command("Test123", function()
--     print(M.get_selected_text("✅"))
--     print(vim.inspect(M.get_selected_text()))
--   end,
--   {
--     range = true,
--   }
-- )

return M
