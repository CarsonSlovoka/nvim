-- https://github.com/godotengine/godot
-- https://godotengine.org
-- https://godotengine.org/download/macos/

-- https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html?utm_source=chatgpt.com
--
-- Use line feed (LF) characters to break lines, not CRLF or CR. (editor default)
-- Use one line feed character at the end of each file. (editor default)
-- Use UTF-8 encoding without a byte order mark. (editor default)
-- Use Tabs instead of spaces for indentation. (editor default)

-- https://github.com/godotengine/godot/blob/4e8c061c9b4a778102a085d9d10f64b3c6be0f87/.editorconfig#L1-L21

vim.bo.expandtab = false -- Tab
vim.bo.tabstop = 4
vim.bo.softtabstop = 4
vim.bo.shiftwidth = 4

vim.bo.textwidth = 120

vim.bo.fileformat = "unix"
vim.bo.fileencoding = "utf-8"
vim.bo.bomb = false
vim.bo.endofline = true
-- vim.bo.fixendofline = true
