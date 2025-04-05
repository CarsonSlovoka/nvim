local emoji = {}

function emoji:new(word, abbr)
  self.__index = self
  return setmetatable({
    word = word,
    kind = word, -- 因為通常都用縮寫，所以為了要讓word可以被更容易看到就放在type
    abbr = "emoji." .. abbr,
    menu = "[Emoji]"
  }, self)
end

local emoji_data = {
  { "⭐", "star" },
  { "❌",
    {
      "crossMark",
      "error",
    },
  },
  { "✖️",
    {
      "multiply",
      "cross",
    },
  },
  { "❓",
    {
      "questionMark",
      "red question mark",
    },
  },
  { "✅",
    {
      "check",
      "ok",
    },
  },
  { "👌",
    {
      "okHand",
      "ok",
    },
  },
  { "⚠", "warning" },
  { "🎉", "ya" },
  { "❗", "exclamation" },
  { "❣️",
    {
      "heartExclamation",
      "exclamationHeart"
    },
  },
  { "❤️",
    {
      "redHeart",
      "heart",
    },
  },
  { "💯",
    {
      "hundredPoints",
      "100points",
    },
  },
  { "💥",
    {
      "collision",
      "explode",
      "boom",
    },
  },
  { "⁉️",
    {
      "exclamationQuestion",
      "questionExclamation",
    },
  },
  { "👆",
    {
      "ptUp",
      "potintingUp",
      "up",
    },
  },
  { "👇",
    {
      "ptDown",
      "down",
    },
  },
  { "👈",
    {
      "ptLeft",
      "left",
    },
  },
  { "👉",
    {
      "ptRight",
      "right",
    },
  },
  { "←", "arLeft" }, -- arrow
  { "↑", "arUp" },
  { "→", "arRight" },
  { "↓", "arDown" },
  { "💡",
    {
      "lightBulb",
      "tip",
      "idea",
    },
  },
  { "🚀", "rocket" },
  { "🧙", "mage" },
  { "🐘", "elephant" },
  { "📁", "folder" },
  { "📂", "folderOpen" },
  { "📦",
    {
      "package",
      "box",
    },
  },
  { "🥡",
    {
      "takeoutBox",
      "box",
    },
  },
  { "📝", "memo" },
  { "📢", "announcement" },
  { "😅", "sorry" },
  { "😡", "angry" },
  { "😢",
    {
      "cryingFace",
      "sad",
    },
  },
  { "😭",
    {
      "loudlyCryingFace",
      "crying",
    },
  },
  { "🥺",
    {
      "pleadingFace",
      "please",
    },
  },
  { "🥹",
    {
      "faceHoldingBackTears",
      "pleadingFace",
      "thanks",
    },
  },
  { "🙂", "smiling" },
  { "😊", "smilingWithSmilingEyes" },
  { "😊", "smilingFacewithHalo" },
  { "😇", "pleadingFace" },
  { "😎",
    {
      "smilingFaceWithSunGlasses",
      "sunGlasses",
    },
  },
  { "🤔",
    {
      "confused",
      "thinking",
    },
  },
  { "🥳",
    {
      "partyFace",
      "party",
    },
  },
  { "🫣",
    {
      "facewithPeekingEye",
      "peek",
      "hide",
    },
  },
  { "🙏", "please" },
  { "🙇",
    {
      "personBowing",
      "please",
      "sorry",
    },
  },
  { "👊",
    {
      "oncomingFist",
      "fist",
      "punch",
    },
  },
  { "💪",
    {
      "flexedBiceps",
      "strong",
    },
  },
  { "🤝", "handshake" },
  { "🔥", "fire" },
  { "🔑", "key" },
  { "🔒", "locked" },
  { "✨",
    {
      "sparkles",
      "features",
    },
  },
  { "⚡",
    {
      "fast",
      "lighting",
    },
  },
  { "🌈", "rainbow" },
  { "🌳",
    {
      "deciduousTree",
      "tree",
    },
  },
  { "🌲",
    {
      "evergreenTree",
      "christmas",
      "tree",
    },
  },
  { "🧊",
    {
      "ice",
      "cold",
    },
  },
  { "❄️",
    {
      "snowflake",
      "christmas",
      "ice",
    },
  },
  { "☃️",
    {
      "snowman",
      "christmas",
    },
  },
  { "⛄",
    {
      "snowmanWithoutSnow",
      "christmas",
    },
  },
  { "🎅",
    {
      "santaClaus",
      "christmas",
    },
  },
  { "🌱", "seedling" },
  { "♻️", "recycle" },
  { "🚮",
    {
      "LitterInBinsign",
      "trash",
      "recycle",
    },
  },
  { "🗑️",
    {
      "wastebasket",
      "trash",
      "recycle",
    },
  },
  { "🏠", "home" },
  { "🏰", "castle" },
  { "🏯", "castleJapanese" },
  { "🔗", "link" },
  { "⚓", "anchor" },
  { "🚢", "ship" },
  { "⛴️", "shipFerry" },
  { "📡", "satelliteAntenna" },
  { "🌐", "globeWithMeridians" },
  { "🌎", "globeAsiaAustralia" },
  { "🌎", "globeAmericas" },
  { "🌍", "globeEuropeAfrica" },
  { "🗽", "statueOfLiberty" },
  { "🪝", "hook" },
  { "🆔",
    {
      "id",
      "IDButton",
      "button",
    },
  },
  { "🆑",
    {
      "CLButton",
      "button",
      "clear",
    },
  },
  { "🆘",
    {
      "SOS",
      "help",
    },
  },
  { "🅰️",
    {
      "A",
      "button",
    },
  },
  { "🅱️",
    {
      "B",
      "button",
    },
  },
  { "🔹",
    {
      "smallBlueDiamond",
      "itemBlueDiamond",
      "itemDiamond",
      "item",
    },
  },
  { "🔷",
    {
      "largeBlueDiamond",
      "itemBlueDiamond",
      "itemDiamond",
      "item",
    },
  },
  { "🟩",
    {
      "greenSquare",
      "itemGreenSquare",
      "itemSquare",
      "item",
    },
  },
  { "🟦",
    {
      "blueSquare",
      "itemBlueSquare",
      "itemSquare",
      "item",
    },
  },
  { "🟥",
    {
      "redSquare",
      "itemRedSquare",
      "itemSquare",
      "item",
    },
  },
  { "🟧",
    {
      "orangeSquare",
      "itemOrangeSquare",
      "itemSquare",
      "item",
    },
  },
  { "🏳️",
    {
      "whiteFlag",
      "flag",
    },
  },
  { "🏴",
    {
      "blackFlag",
      "flag",
    },
  },
  { "🚩",
    {
      "triangularFlag",
      "flag",
    },
  },
  { "🏁",
    {
      "chequeredFlag",
      "flag",
    },
  },
  { "⚔️",
    {
      "crossedSwords",
      "swords",
    },
  },
  { "☠️",
    {
      "skullAndCrossbones",
      "bones",
      "gameOver",
      "die",
      "dead",
    },
  },
  { "♦️",
    {
      "diamondSuit",
      "itemRedDiamond",
      "itemDiamond",
      "item",
      "card",
    },
  },
  {
    "♣️",
    {
      "clubSuit",
      "card",
    }
  },
  {
    "♥️",
    {
      "heartSuit",
      "heart",
      "card",
    }
  },
  {
    "♠️",
    {
      "spadeSuit",
      "card",
    }
  },
  {
    "🃏",
    {
      "joker",
      "card",
    }
  },
  {
    "🎲",
    {
      "gameDie",
      "die",
      "one",
    }
  },
}

local M = {}
for _, e in ipairs(emoji_data) do
  local word = e[1]
  local abbr_data = e[2]
  if type(abbr_data) == "string" then
    table.insert(M, emoji:new(word, abbr_data))
  else
    if type(abbr_data) == "table" then
      for _, abbr in ipairs(abbr_data) do
        table.insert(M, emoji:new(word, abbr))
      end
    end
  end
end


--- 搜尋匹配的表符符號
--- @param search_str string 如果給空值，則返回所有的表情符號
--- @return table
function M.get_emoji(search_str)
  local matches = {}

  -- 將搜尋字串轉為小寫以進行不區分大小寫的比較
  search_str = string.lower(search_str)

  -- 遍歷 emoji_data 表格
  for _, emoji_entry in ipairs(emoji_data) do
    local emoji = emoji_entry[1]        -- 表情符號本身
    local descriptions = emoji_entry[2] -- 描述（可能是字串或表格）

    -- 如果描述是單一字串
    if type(descriptions) == "string" then
      -- if search_str == "" or string.lower(descriptions) == search_str then
      if search_str == "" or string.find(string.lower(descriptions), search_str) then
        table.insert(matches, emoji)
      end
      -- 如果描述是一個表格
    elseif type(descriptions) == "table" then
      for _, desc in ipairs(descriptions) do
        if search_str == "" or string.find(string.lower(desc), search_str) then
          table.insert(matches, emoji)
          break -- 找到匹配後跳出內部迴圈
        end
      end
    end
  end

  if #matches > 0 then
    return matches
  else
    return nil
  end
end

return M
