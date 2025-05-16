package.path = package.path ..
    ";../?.lua" ..                                          -- utils.array
    ";../testing/?.lua" ..                                  -- testing.lua
    ";" .. os.getenv("HOME") .. "/neovim/runtime/lua/?.lua" -- ~/neovim/runtime/lua/vim/inspect.lua

local t      = require("testing")

-- match_extension: 最佳解答: vim.regex https://stackoverflow.com/a/79624556/9935654

local function Example_match_extension()
  -- https://stackoverflow.com/a/79624653/9935654
  local function match_extension(str, suffixes)
    -- convert to hash table
    local suffix_set = {}
    for _, suffix in ipairs(suffixes) do
      suffix_set[suffix] = true
    end

    -- local ext = str:match("%.(%w+)$") -- not work at `tar.gz`
    local ext = str:match("%.([%w.]+)$")

    if suffix_set[ext] then
      return true, ext
    end

    return false, nil
  end

  for _, file in ipairs({
    "/test/file.mp4",
    "/test/file.tar.gz",
  }) do
    local suffixes = { "mp4", "mkv", "avi", "mov", "flv", "wmv", "tar.gz" }
    local is_match, matched_suffix = match_extension(file:lower(), suffixes)
    if is_match then
      print("match: " .. matched_suffix)
    else
      print("no match")
      return false
    end
  end
  return true
  -- output:
  --
end

local function Example_match_extension_2()
  -- https://stackoverflow.com/a/79624543/9935654
  local function match_extension(str, suffixes)
    for _, suffix in ipairs(suffixes) do
      if #str >= #suffix then
        if str:sub(#str - #suffix + 1) == suffix then
          return true, suffix
        end
      end
    end
    return false, nil
  end

  local myFile = "/test/file.mp4"
  if match_extension(myFile:lower(), { ".mp4", ".mkv", ".avi", ".mov", ".flv", ".wmv" }) then
    print("match")
  else
    return false
  end
  return true
  -- Output:
  -- match
end


t.RunTest({
  Example_match_extension, -- /usr/bin/lua5.1 regex_test.lua 1
  Example_match_extension_2
}, arg[1])
