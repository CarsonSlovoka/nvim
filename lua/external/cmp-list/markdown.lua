local highlight = {}

--- https://github.com/orgs/community/discussions/16925
function highlight:new(abbr)
  self.__index = self
  local word = string.format('> [!%s]', string.upper(abbr))
  return setmetatable({
    word = word,
    kind = word,
    abbr = "hl." .. abbr,
    menu = "[highlight]"
  }, self)
end

local M = {}
for _, abbr in ipairs({
  "note", -- hl.<C-X><C-U>
  "tip",
  "important",
  "warning",
  "caution",
}) do
  table.insert(M, highlight:new(abbr))
end

return M
