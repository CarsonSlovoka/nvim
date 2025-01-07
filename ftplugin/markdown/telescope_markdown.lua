local M = {}

local function generate_toc()
  local toc = {}
  local in_code_block = false

  for line_num = 1, vim.api.nvim_buf_line_count(0) do
    local line = vim.fn.getline(line_num)

    if line:match("^```") then
      in_code_block = not in_code_block
    end

    if not in_code_block then
      local header, title = line:match("^(#+)%s+(%S.*)$")
      if header then
        local level = #header
        table.insert(toc, {
          level = level,
          line = line_num,
          title = title
        })
      end
    end
  end
  return toc
end

function M.show_toc_with_telescope()
  local toc = generate_toc()
  if vim.tbl_isempty(toc) then
    vim.notify("未檢測到任何 Markdown 標題", vim.log.levels.INFO)
    return
  end

  local entries = {}
  for _, item in ipairs(toc) do
    table.insert(entries, {
      display = string.rep(" ", (item.level - 1) * 2) .. "- " .. item.title,
      ordinal = item.title,
      value = item
    })
  end

  require('telescope.pickers').new({}, {
    prompt_title = "Markdown TOC",
    finder = require('telescope.finders').new_table {
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry.value,
          display = entry.display,
          ordinal = entry.ordinal
        }
      end
    },
    sorter = require('telescope.config').values.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selected = action_state.get_selected_entry()
        if selected and selected.value then
          vim.api.nvim_win_set_cursor(0, { selected.value.line, 0 })
        end
      end)

      return true
    end
  })                          :find()
end

vim.keymap.set("n", "<leader>wt", M.show_toc_with_telescope, { noremap = true, silent = true })

-- return M

