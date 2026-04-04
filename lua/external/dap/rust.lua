local dap = require('dap')
local dapui = require('dapui')
local utils = require("utils.utils")

dap.adapters.codelldb = {
  type = 'server',
  port = "${port}",
  executable = {
    -- https://github.com/vadimcn/codelldb/releases
    -- 在releases的頁面下載對應平台的vsix, 然後可以重新命名為zip,然後解壓
    -- mkdir -pv ~/codelldb
    -- wget https://github.com/vadimcn/codelldb/releases/download/v1.12.1/codelldb-darwin-arm64.vsix -O ~/codelldb/codelldb.zip
    -- cd ~/codelldb
    -- unzip ~/codelldb
    command = vim.fn.expand('~/codelldb/extension/adapter/codelldb'),
    args = { "--port", "${port}" },
  }
}


---@return string
local function get_rust_executable()
  -- 🟧 是否有git
  local git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
  if vim.v.shell_error ~= 0 then
    vim.notify("Not in a Git repository", vim.log.levels.ERROR)
    return ""
  end

  -- 🟧 確認 Cargo.toml 存在
  local cargo_toml = git_root .. "/Cargo.toml" -- 這是絕對路徑
  if vim.fn.filereadable(cargo_toml) ~= 1 then
    vim.notify("Cargo.toml not found", vim.log.levels.ERROR)
    return ""
  end

  -- vim.cmd("cd " .. git_root) -- 都是絕對路徑不需要

  -- 🟧 從 Cargo.toml 讀取 [package] name
  local crate_name = nil
  local lines = vim.fn.readfile(cargo_toml)
  local in_package = false

  for _, line in ipairs(lines) do
    local trimmed = vim.trim(line)

    if trimmed:match("^%[package%]") then
      in_package = true
    elseif in_package and trimmed:match("^%[") then
      -- 離開 [package] 區塊
      in_package = false
    elseif in_package and trimmed:match("^name%s*=%s*") then
      -- name = "xxx" 或 name = 'xxx'
      crate_name = trimmed:match('name%s*=%s*["\']([^"\']+)["\']')
      if crate_name then break end
    end
  end

  if not crate_name or crate_name == "" then
    vim.notify("Unable to parse package name from Cargo.toml", vim.log.levels.ERROR)
    return ""
  end

  -- 🟧 是否要重新build
  vim.ui.select( -- 其實可以直接重新build, 如果沒有異動, cargo就曉得，不會再build一次
    { "Y", "N" },
    {
      prompt = "rebuild?",
      format_item = function(item)
        return item
      end,
    },
    function(choice)
      if choice == "Y" then
        vim.cmd("!cargo build") -- 不用在Cargo.toml的目錄也沒差，它會自動找
      end
    end
  )

  -- 🟧 開始找執行檔路徑
  -- 用 fd 找 target/ 裡的第一個匹配的可執行檔
  -- -I 忽略 .gitignore
  -- -t x 只找 executable
  -- --glob 避免 shell 展開
  local workDir = git_root .. "/target"
  local fd_cmd = string.format(
    'realpath $(fd -t x -I %s %s | head -n 1)', -- TODO: 這可能有問題, rust中一個專案也可以有多個 bin 所以其實需要只定要哪一個bin
    crate_name, workDir,
    vim.fn.shellescape(git_root)
  )

  local exec_path = vim.fn.system(fd_cmd):gsub("\n$", "")

  if vim.v.shell_error ~= 0 or exec_path == "" then
    vim.notify(
      "Executable file not found:\n" ..
      " crate name = " .. crate_name .. "\n" ..
      "Search path = " .. git_root .. "/target\n" ..
      "Please execute cargo build first",
      vim.log.levels.ERROR
    )
    return ""
  end

  return exec_path
end

dap.configurations.rust = {
  {
    name = "rustc -g and run (for simple single file)",
    type = "codelldb",
    request = "launch",
    program = function()
      local filepath = vim.fn.expand("%")
      local exe_path = vim.fn.expand("%:r") -- 如果沒有用rustc -o 指定名稱，出來的執行檔名稱和原來的rs一樣，只是沒有附檔名
      vim.cmd("!rustc -g " .. filepath)     -- Important 要debug一定要加上-g, 也就是`-C debuginfo=2`才能，不然會直接執行完，也進不去任何的中斷點
      return vim.fn.input('Path to executable: ', exe_path, 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  },
  {
    name = "Debug (input: exe_path)",
    type = "codelldb",
    request = "launch",
    program = function()
      -- return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/target/debug/', 'file')
      return vim.fn.input('Path to executable: ', get_rust_executable(), 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  },
  {
    name = "Debug (input: exe_path, args)",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input('Path to executable: ', get_rust_executable(), 'file')
    end,
    args = utils.dap.input_arguments("input arguments:"),
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  },
  {
    name = "Debug (input: exe_path [bin])",
    -- Tip: 如果是有多個bin的情況下: `cargo run --bin my-bin` 可透過這種方式來選擇要執行的程式
    type = "codelldb",
    request = "launch",
    program = function()
      -- 其實也不一定是在target/debug下，如果是不同的platform, 會是target/<platform>/debug 不過可以用..來往上
      -- Tip: 如果之前輸入過，可以在command時用Ctrl_F可以開啟歷史記錄來選擇
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/target/debug/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  },
  {
    name = "Debug (input: exe_path, args [bin])",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/target/debug/', 'file')
    end,
    args = utils.dap.input_arguments("input arguments:"),
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  },
  {
    name = "test (input: exe_path [bin])",
    type = "codelldb",
    request = "launch",
    program = function()
      -- 其實test也是和一般的bin一樣，差別只是要去找test所build出來的執行檔位置而已，通常會放在deubg/deps之中
      -- Tip: 可以透過找尋執行檔(x) 然後再用時間來排序，即可找到test所構建出來的執行檔: `fd . -t x target/debug/deps/ -X ls -lht`
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/target/debug/deps', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  },
  {
    name = "test (input: exe_path, args [bin])",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/target/debug/deps', 'file')
    end,
    args = utils.dap.input_arguments("input arguments:"),
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  },
}
