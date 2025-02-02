function ListMonths()
  -- 當沒有keymap綁定時，可以使用 :=ListMonths() 這種方式來呼叫
  local function show_func()
    local months = { 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December' }
    vim.fn.complete(vim.fn.col('.'), months) -- 這個只能在insert模式下用
  end
  if vim.api.nvim_get_mode().mode ~= "i" then
    vim.cmd('startinsert')
    vim.defer_fn(show_func, 100) -- 延遲啟動 100 毫秒
  else
    show_func()
  end
end

-- vim.keymap.set('i', '<F5>', ListMonths, { noremap = true, silent = true })

--[[
function Foo()
  -- :=Foo()
  vim.api.nvim_put({
    "Hello world",
    "Line 2"
  }, 'c', true, true)
  -- vim.api.nvim_feedkeys('Hello World!', 'i', true) -- 沒用
end
]] --


function ConfirmTest()
  local choice = vim.fn.confirm("Do you want to continue?", "&Yes\n&No\n&Cancel", 2)

  if choice == 1 then
    print("You chose Yes")
  elseif choice == 2 then
    print("You chose No")
  elseif choice == 3 then
    print("You chose Cancel")
  end
end
