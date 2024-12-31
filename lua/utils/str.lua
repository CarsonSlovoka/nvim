local str = {}

function str.split(input, sep)
  local result = {}
  if not input or input == "" then
    return result
  end

  for s in string.gmatch(input, "([^" .. sep .. "]+)") do
    table.insert(result, s)
  end
  return result
end


return str
