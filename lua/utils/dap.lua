local M = {}

---@param prompt string
---@return function
function M.input_arguments(prompt)
  return function()
    return coroutine.create(
      function(dap_run_co)
        local args = {}
        vim.ui.input(
          { prompt = prompt },
          function(input)
            args = vim.split(input or "", " ")
            coroutine.resume(dap_run_co, args)
          end
        )
      end
    )
  end
end

---@param prompt string?
---@return string[]
function M.ask_args(prompt)
  local input = vim.fn.input(prompt or "args: ")
  return vim.split(input, "%s+", { trimempty = true, })
end

---@return string[]
function M.get_args(config)
  local args = config.args or {}

  if type(args) == "function" then
    args = args()
  end

  if type(args) == "string" then
    args = vim.split(args, "%s+", { trimempty = true })
  end

  return args
end

return M
