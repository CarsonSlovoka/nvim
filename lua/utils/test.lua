-- /usr/bin/lua5.1 test.lua

package.path = package.path .. ";../?.lua"

for _, testModule in ipairs({
  "utils.array_test",
  "utils.flag_test",
  "utils.path_test"
}) do
  print("🔷 run " .. testModule)
  require(testModule)
end
