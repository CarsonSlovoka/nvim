local dap = require("dap")

---@class HtmlRunConfig
---@field type "html"
---@field name string
---@field action "open"|"server"
---@field port? integer|string|fun():integer|string

---@param value string
---@return string
local function url_encode(value)
  -- local new_string, replace_count = value:gsub(...)
  -- return value:gsub("[^%w%-_%.~]", function(char) return string.format("%%%02X", string.byte(char)) end) -- 可行，但會有警告，因為回傳值只寫一個
  local encoded = value:gsub("[^%w%-_%.~]", function(char)
    return string.format("%%%02X", string.byte(char))
  end)
  return encoded
end

---@param config HtmlRunConfig
---@return integer
local function get_port(config)
  local port = config.port or 8000

  if type(port) == "function" then
    port = port()
  end

  port = tonumber(port) or 8000

  return port
end

---@return string
local function get_python_cmd()
  if vim.fn.executable("python3") == 1 then
    return "python3"
  end

  return "python"
end

dap.adapters.html = function(_, config)
  ---@cast config HtmlRunConfig

  local html_path = vim.fn.expand("%:p")
  local html_name = vim.fn.expand("%:t")
  local html_dir = vim.fn.expand("%:p:h")

  if html_path == "" then
    vim.notify("No html file found", vim.log.levels.ERROR)
    return
  end

  if config.action == "open" then
    vim.ui.open(html_path)
    return
  end

  if config.action == "server" then
    local port = get_port(config)
    local python = get_python_cmd()

    local url = string.format(
      "http://localhost:%d/%s",
      port,
      url_encode(html_name)
    )

    vim.cmd("topleft new")

    vim.fn.jobstart({
      python, "-m", "http.server",
      tostring(port),
      "-d", html_dir,
    }, {
      term = true,
    })

    vim.cmd("startinsert")

    vim.defer_fn(function()
      vim.ui.open(url)
    end, 500)

    return
  end

  vim.notify("Unknown html action: " .. tostring(config.action), vim.log.levels.ERROR)
end

dap.configurations.html = {}

for _, config in ipairs({
  {
    type = "html",
    name = "🌐   open current html",
    action = "open",
  },
  {
    type = "html",
    name = "📡🌐 open current html with http.server",
    action = "server",
    port = function()
      local input = vim.fn.input("http.server port: ", "8000")
      return tonumber(input) or 8000
    end,
  },
}) do
  table.insert(dap.configurations.html, config)
end
