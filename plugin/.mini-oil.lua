-- Note: 這個腳本只是想要瞭解oil.nvim的精神

if true then
  return
end

local M = {}
local uv = vim.loop

local state = {
  cwd = nil,
  entries = {},  -- 真實資料
  line_map = {}, -- 行號 → entry
}

-- ========= utils =========

local function join(...)
  return table.concat({ ... }, "/")
end

-- ========= read dir =========

local function read_dir(path)
  local handle = uv.fs_scandir(path)
  local result = {}

  if not handle then return result end

  while true do
    local name, t = uv.fs_scandir_next(handle)
    if not name then break end

    table.insert(result, {
      name = name,
      path = join(path, name),
      type = t, -- "file" or "directory"
    })
  end

  table.sort(result, function(a, b)
    if a.type ~= b.type then
      return a.type == "directory"
    end
    return a.name < b.name
  end)

  return result
end

-- ========= render =========

local function render(buf)
  local lines = {}
  state.line_map = {}

  for i, item in ipairs(state.entries) do
    local text = item.name
    if item.type == "directory" then
      text = text .. "/"
    end

    lines[i] = text
    state.line_map[i] = item
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  vim.bo[buf].modified = false -- 強制改成false, 使得讓其曉得buffer是沒有修改過的，否則只要是可以被寫入的檔案有異動, 離開就會得到錯誤: `E162: No write since last change`
end

-- ========= parse buffer =========

local function parse_lines(lines)
  local result = {}

  for _, line in ipairs(lines) do
    if line ~= "" then
      local is_dir = line:sub(-1) == "/"
      local name = line:gsub("/$", "")

      table.insert(result, {
        name = name,
        type = is_dir and "directory" or "file",
      })
    end
  end

  return result
end

-- ========= diff =========

local function compute_diff(old, new)
  local ops = {}

  local old_map = {}
  for _, e in ipairs(old) do
    old_map[e.name] = e
  end

  local new_map = {}
  for _, e in ipairs(new) do
    new_map[e.name] = e
  end

  local deleted = {}
  local created = {}

  for name, e in pairs(old_map) do
    if not new_map[name] then
      table.insert(deleted, e)
    end
  end

  for name, e in pairs(new_map) do
    if not old_map[name] then
      table.insert(created, e)
    end
  end

  -- rename heuristic
  if #deleted == 1 and #created == 1 then
    table.insert(ops, {
      type = "rename",
      from = deleted[1],
      to = created[1],
    })
    return ops
  end

  for _, e in ipairs(deleted) do
    table.insert(ops, {
      type = "delete",
      entry = e,
    })
  end

  for _, e in ipairs(created) do
    table.insert(ops, {
      type = "create",
      entry = e,
    })
  end

  return ops
end

-- ========= apply =========

local function apply_ops(cwd, ops)
  for _, op in ipairs(ops) do
    if op.type == "delete" then
      local full = join(cwd, op.entry.name)
      local stat = uv.fs_stat(full)

      if stat then
        if stat.type == "directory" then
          uv.fs_rmdir(full)
        else
          uv.fs_unlink(full)
        end
      end
    elseif op.type == "create" then
      local full = join(cwd, op.entry.name)

      if op.entry.type == "directory" then
        uv.fs_mkdir(full, 493) -- 0755
      else
        local fd = uv.fs_open(full, "w", 420)
        if fd then uv.fs_close(fd) end
      end
    elseif op.type == "rename" then
      local old_path = join(cwd, op.from.name)
      local new_path = join(cwd, op.to.name)

      uv.fs_rename(old_path, new_path)
    end
  end
end

-- ========= write =========

local function on_write(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  local new_entries = parse_lines(lines)
  local ops = compute_diff(state.entries, new_entries)

  apply_ops(state.cwd, ops)

  -- refresh
  state.entries = read_dir(state.cwd)
  render(buf)
end

-- ========= enter =========

local function enter(buf)
  local line_nr = vim.api.nvim_win_get_cursor(0)[1]
  local entry = state.line_map[line_nr]

  if not entry then return end

  if entry.type == "directory" then
    -- TODO 目前沒辦法有jumplist,進入dict後沒辦法回來
    state.cwd = entry.path
    state.entries = read_dir(state.cwd)
    render(buf)
  else
    vim.cmd("edit " .. vim.fn.fnameescape(entry.path))
  end
end

-- ========= main =========

function M.open(path)
  path = path or vim.fn.getcwd()

  state.cwd = path
  state.entries = read_dir(path)

  vim.cmd("enew")
  local buf = vim.api.nvim_get_current_buf()

  -- vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].buftype = "acwrite"
  --  :w
  --  ↓
  -- (1) 有沒有 file name？
  --  ↓
  -- (2) buftype 是什麼？
  --      ├─ ""        → 寫入磁碟
  --      ├─ "acwrite" → 觸發 BufWriteCmd
  --      ├─ "nofile"  → 通常不允許寫
  vim.api.nvim_buf_set_name(buf, "mini-oil://" .. path) -- 因此隨便給一個filename, 反正已經設定了acwrite

  render(buf)

  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      on_write(buf)
    end,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = buf,
    callback = function()
      if vim.bo[buf].modified then
        print("⚠️ changes not saved")
      end
    end,
  })

  vim.keymap.set("n", "<CR>", function()
    enter(buf)
  end, { buffer = buf })

  vim.keymap.set("n", "q", function()
    vim.api.nvim_buf_delete(buf, { force = true })
  end, { buffer = buf })
end

vim.api.nvim_create_user_command("MiniOil", function(opts)
  M.open(opts.args ~= "" and opts.args or nil)
end, { nargs = "?" })

return M
