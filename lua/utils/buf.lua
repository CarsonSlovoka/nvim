local M = {}

--- NOTE: <C-W>v 分割視窗或者編輯，效果都還是有
--- 缺點是如此的設計，每一列的顏色只能有一個, 如果同列需要有多個顏色可以考慮使用 `set_lines`
---
--- @param buf integer vim.api.nvim_get_current_buf()
--- @param lnum integer vim.api.nvim_buf_line_count(buf)
--- @param msgs table  {{'line1', '@label'}, {'line2', 'ERROR'}}
function M.appendbufline(buf, lnum, msgs)
  local ns_id_hl = vim.api.nvim_create_namespace('carson.buffer.help') -- Creates a new namespace or gets an existing one.
  for _, msg in ipairs(msgs) do
    local text, hl_group = msg[1], msg[2]

    vim.fn.appendbufline(buf, lnum, text)
    vim.api.nvim_buf_set_extmark(buf, ns_id_hl, lnum, 0, { end_col = #text, hl_group = hl_group }) -- 💡
    lnum = lnum + 1
  end
end

--- @class HighlightEntry
--- @field line_num integer
--- @field start_col integer
--- @field end_col integer
--- @field hl_group string hl_group Normal, ERROR, @label, `:Telescope highlights`


--- 寫入buf同時可以指定寫入內容所屬的hl_group
---
--- 類似於 `vim.api.nvim_echo` 但是它只能print, 而且換行是用\n
---
--- @param buf integer vim.api.nvim_get_current_buf()
--- @param l_start integer write statline
---   - 加在結尾: `vim.api.nvim_buf_line_count(buf)` 如果空間不夠會自己補
---   - ⚠️ 加在開頭: `0` 有機會覆蓋掉已經存在的文字
---
--- @param msgs table  { {{'line1 col1', 'Normal'}, {'line1 col2', 'ERROR'}}, {{"line2", ""}} }
---   ⚠️ 當遇到該錯誤: *replacement string' item contains newlines*
---   可以可慮將newline都移除: `msg:gsub('\n', '')`
function M.set_lines(buf, l_start, msgs)
  --- @type HighlightEntry[]
  local highlight_positions = {}

  local lines = {}            -- 記錄每一列的內容
  for n_row, row in ipairs(msgs) do
    local full_line = ""      -- 該列的所有內容
    local row_highlights = {} -- 該列所有要被highlight的區域
    local cur_col = 0

    -- 處理每一列，將每一個segments合併
    for _, segment in ipairs(row) do
      local text, hl_group = segment[1], segment[2]

      full_line = full_line .. text
      if hl_group and hl_group ~= "" then
        table.insert(row_highlights, {
          start_col = cur_col,
          end_col = cur_col + #text,
          hl_group = hl_group,
        })
      end
      cur_col = cur_col + #text
    end
    table.insert(lines, full_line)

    for _, hl in ipairs(row_highlights) do
      table.insert(highlight_positions, {
        line_num = l_start + n_row - 1,
        start_col = hl.start_col,
        end_col = hl.end_col,
        hl_group = hl.hl_group,
      })
    end
  end

  -- 先寫入所有該寫入的資料
  -- vim.api.nvim_buf_set_lines(buf, l_start, -1, false, lines) 用-1之後的內容都會被清空
  vim.api.nvim_buf_set_lines(buf, l_start, l_start + #msgs, false, lines) -- WARN: 如果該地區已經有文字，是直接覆蓋

  -- 處理顏色突顯
  local ns_id_hl = vim.api.nvim_create_namespace('carson.buffer.help')
  for _, hl in ipairs(highlight_positions) do
    if hl.line_num >= 0 then
      vim.hl.range(buf, ns_id_hl, hl.hl_group, { hl.line_num, hl.start_col }, { hl.line_num, hl.end_col })
    else
      vim.notify("空間不足, 無法使用顏色突顯", vim.log.levels.INFO)
      break
    end
  end
end

return M
