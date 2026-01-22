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

return M
