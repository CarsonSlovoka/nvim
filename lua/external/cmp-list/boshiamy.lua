local boshiamy = {}

function boshiamy:new(word, kind, abbr)
  self.__index = self
  return setmetatable({
    word = word,
    kind = kind,
    abbr = "oek." .. abbr, -- 用oek來: 嘸 來表達縮寫
    menu = "[boshiamy]"
  }, self)
end

local my_table = {
  { "觀察", "rmr nja" },
  { "觀看", "rmr hmo" },
}


-- 函數：將字符串按空格分隔成表
local function split(str)
  local result = {}
  for word in str:gmatch("%S+") do
    table.insert(result, word)
  end
  return result
end

-- 函數：將中文字拆成單個字符
local function split_chars(str)
  local chars = {}
  -- UTF-8用到1~6byte
  -- 目前只有前4byte有用
  -- %z: 表示 0 (空字符)
  -- \1-\127 ASCII 1~127
  -- 如果是2字節，首字節: 194-223 0xC2-0xDF 0b110_00010~0b110_11111
  -- ... 以此類推: https://zh.wikipedia.org/zh-tw/UTF-8
  -- for char in str:gmatch("[\0-\127\194-\223][\128-\191]?|[\224-\239][\128-\191]{2}|[\240-\244][\128-\191]{3}") do
  for char in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    table.insert(chars, char)
  end
  return chars
end

--- 計算重複項
local char_to_code = {}

local M = {}
for _, entry in ipairs(my_table) do
  local word = entry[1]           -- 中文詞彙
  local codes = entry[2]          -- 碼位字符串
  local chars = split_chars(word) -- 將詞彙拆成單字
  local code_list = split(codes)  -- 將碼位拆成列表

  -- 確保字數和碼位數匹配
  if #chars == #code_list then
    for i, char in ipairs(chars) do
      -- 如果該字還沒記錄過，加入結果
      if not char_to_code[char] then
        char_to_code[char] = 1 -- 記錄出現了幾次
      else
        char_to_code[char] = char_to_code[char] + 1
        char = char .. "_" .. char_to_code[char]                -- 相同的word，就算都插入到table之中，還是只能出現一筆，因此為了都可以呈現，就將後面的用_%d來表示
      end
      local code = code_list[i]                                 -- 輸入法碼位
      local kind = string.format("%s %s %s", char, word, codes) -- 這個用來提示
      table.insert(M, boshiamy:new(char, kind, code))
    end
  end
end
return M
