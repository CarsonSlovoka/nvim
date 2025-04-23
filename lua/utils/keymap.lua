local M = {}

--- @param opts {noremap: boolean, silent: boolean, desc: string} desc如果沒有給，呈現的內容會放入cmd的指令
function M.keymap(mode, key, cmd, opts)
  opts = opts or {}
  opts.noremap = opts.noremap ~= nil and opts.noremap or true -- true不會再往下傳遞
  opts.silent = opts.silent ~= nil and opts.silent or true
  vim.keymap.set(mode, key, cmd, opts)
end

return M
