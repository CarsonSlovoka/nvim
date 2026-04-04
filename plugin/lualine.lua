local ok, m = pcall(require, "lualine")
if not ok then
  vim.notify("Failed to load lualine", vim.log.levels.ERROR)
  return
end
m.setup {
  sections = {
    lualine_c = {
      {
        'filename',
        -- 以下都是預設，其實可以直將path改成4即可
        file_status = true,     -- Displays file status (readonly status, modified status)
        newfile_status = false, -- Display new file status (new file means no write after created)
        path = 4,               -- 0: Just the filename
        -- 1: Relative path
        -- 2: Absolute path
        -- 3: Absolute path, with tilde as the home directory
        -- 4: Filename and parent dir, with tilde as the home directory

        shorting_target = 40, -- Shortens path to leave 40 spaces in the window
        -- for other components. (terrible name, any suggestions?)
        symbols = {
          modified = '[+]',      -- Text to show when the file is modified.
          readonly = '[-]',      -- Text to show when the file is non-modifiable or readonly.
          unnamed = '[No Name]', -- Text to show for unnamed buffers.
          newfile = '[New]',     -- Text to show for newly created file before first write
        }
      }
    },
    lualine_x = {
      -- indent settings
      function()
        local indent_style = vim.opt_local.expandtab:get() and "Space" or "Tab"
        if indent_style == "Space" then
          local indent_size = vim.opt_local.tabstop:get()
          return indent_size .. " spaces"
        end
        return indent_style
      end,
      -- 'encoding', -- 這也可，但是預設不會顯示bomb
      {
        'encoding',
        show_bomb = true
      },
      'fileformat', 'filetype',
    },
  }
}
