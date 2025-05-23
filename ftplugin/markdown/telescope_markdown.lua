local M = {}

M.config = {
  preview_number_lines = 10
}

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

  -- 取得當前文件的內容
  local markdown_buffer = vim.api.nvim_get_current_buf()

  -- 找到當前光標所在或最近的標題索引
  local cur_line = vim.api.nvim_win_get_cursor(0)[1]
  local selected_idx = 1
  for i, item in ipairs(toc) do
    if item.line <= cur_line then
      selected_idx = i
    else
      break
    end
  end

  local entries = {}
  for _, item in ipairs(toc) do
    table.insert(entries, {
      display = string.rep(" ", (item.level - 1) * 2) .. "- " .. item.title,
      ordinal = item.title,
      value = item
    })
  end

  local previewers = require("telescope.previewers")
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

    default_selection_index = selected_idx, -- 透過這個可以設定預設選中的項目，預設為1 (如果是0不會選任何項)

    previewer = previewers.new_buffer_previewer({
      define_preview = function(self, entry, _)
        local selected_line = entry.value.line
        -- local buffer = vim.api.nvim_get_current_buf() -- 這個是telescope的buffer內容，而不是當前文件的文本內容
        local total_lines = vim.api.nvim_buf_line_count(markdown_buffer)

        local start_line = math.max(selected_line - M.config.preview_number_lines, 1)
        local end_line = math.min(selected_line + M.config.preview_number_lines, total_lines)

        local preview_lines = vim.api.nvim_buf_get_lines(markdown_buffer,
          start_line - 1, -- vim.api的索引是0-based, lua是1開始
          end_line,
          false
        )

        --[[ 添加上下文信息
        local context_header = {
          string.rep("-", 40),
          string.format("Preview around line %d", selected_line),
          string.rep("-", 40)
        }--]]

        -- 在每行前添加行號
        local numbered_lines = {}
        for i, line in ipairs(preview_lines) do
          local line_num = start_line + i - 1
          local prefix
          -- 高亮選中的行
          if line_num == selected_line then
            prefix = string.format("%6d 👉 | ", line_num)
          else
            prefix = string.format("%6d    | ", line_num)
          end
          table.insert(numbered_lines, prefix .. " " .. line)
        end

        -- 合併所有內容
        -- local final_content = vim.list_extend(context_header, numbered_lines)
        local final_content = numbered_lines

        -- 設置預覽緩衝區的內容
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, final_content)

        -- 可選：設置語法高亮
        -- vim.api.nvim_buf_set_option(self.state.bufnr, 'syntax', 'markdown') -- 就會變的很慢，上下移動就沒有那麼順了
      end
    }),

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
  }):find()
end

vim.keymap.set("n", "<leader>wt", M.show_toc_with_telescope, { noremap = true, silent = true })

-- return M
