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
  G = {} -- group
}

emoji_data.G.hand = {
  alias = "hand",
  items = {
    { "👍",
      {
        "thumbsUp",
        "like",
      },
    },
    { "👍",
      {
        "thumbsUp",
        "like",
      },
    },
    { "👎",
      {
        "thumbsDown",
        "dislike",
      },
    },
    { "👌",
      {
        "okHand",
        "ok",
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
    { "🙏", "please" },
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
    { "🤙",
      {
        "callMeHand",
      },
    },
    { "🤝",
      {
        "handshake",
        "deal",
      },
    },
  }
}

emoji_data.G.heart = {
  alias = "heart",
  items = {
    { "❣️",
      {
        "heartExclamation",
        "exclamationHeart"
      },
    },
    { "❤️",
      {
        "redHeart",
      },
    },
    { "💖",
      {
        "sparklingHeart",
      },
    },
    {
      "❤️‍🔥",
      {
        "heartOnFire",
        "fireHeart",
        "heart",
      }
    },
  }
}

emoji_data.G.flag = {
  alias = "flag",
  items = {
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
  }
}

emoji_data.G.face = {
  alias = "face",
  items = {
    { "😅",
      {
        "griningFaceWithSweat",
        "sweat",
        "sorry",
      },
    },
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
    { "😵‍💫",
      {
        "facewithSpiralEyes",
        "dizzy",
      },
    },
    { "😰",
      {
        "anxiousFaceWithSweat",
        "sweat",
        "bad",
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
    { "🤣",
      {
        "rollingOnTheFloorLaughing",
        "laughing",
        "happy",
      },
    },
    { "😵",
      {
        "faceWithCrossedOutEyes",
        "xd",
      },
    },
    { "😆",
      {
        "grinningSquintingFace",
        "smile",
        "happy",
        "xd",
      },
    },
    { "😝",
      {
        "squintingFaceWithTongue",
        "tongue",
        "xd",
      },
    },
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
    { "🫠",
      {
        "meltingFace",
        "happy",
      },
    },
    { "😑",
      {
        "expressionlessFace",
      },
    },
  }
}

emoji_data.G.animal = {
  alias = "animal",
  items = {
    { "🐞",
      {
        "ladyBeetle",
        "bug",
      },
    },
    { "🐛",
      {
        "bug",
      },
    },
    { "🦂",
      {
        "scorpion",
        "poison",
        "bug",
      },
    },
    { "🕷️",
      {
        "spider",
        "bug",
      },
    },
    { "🐝",
      {
        "honeybee",
        "bee",
        "bug",
      },
    },
    { "🐜",
      {
        "ant",
      },
    },
    { "🐌",
      {
        "snail",
        "slow",
      },
    },
    { "🐸",
      {
        "frog",
      },
    },
    { "🐢",
      {
        "turtle",
      },
    },
    { "🦋",
      {
        "butterfly",
        "fly",
      },
    },
    { "🐢",
      {
        "turtle",
      },
    },
    { "🐉",
      {
        "dragon",
      },
    },

  }
}

emoji_data.G.plant = {
  alias = "plant",
  items = {
    { "🌱", "seedling" },
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
  }
}

emoji_data.G.food = {
  alias = { "food", "snack" },
  items = {
    { "🍿",
      {
        "popcorn",
      },
    },
  }
}

emoji_data.G._other = {
  alias = "",
  items = {
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
    { "⚠", "warning" },
    { "🎉", "ya" },
    { "🎇",
      {
        "sparkler",
        "ya"
      },
    },
    { "❗", "exclamation" },
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
    { "🔎",
      {
        "magnifyingGlassTiltedright",
      },
    },
    { "🕵️‍♂️",
      {
        "manDetective",
        "detective",
        "letMeSee",
      },
    },
    { "", "handshake" },
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
    { "📄",
      {
        "pageFacingUp",
        "newFile",
        "file",
      },
    },
    { "⚙️",
      {
        "gear",
        "settings",
      },
    },
    { "📢", "announcement" },
    { "💬",
      {
        "speechBallon",
        "speech",
        "saySomething",
      },
    },
    { "👀",
      {
        "eyes",
        "look",
        "peek",
      },
    },
    { "👁️‍🗨️",
      {
        "eyeInSpeechBubble",
        "look",
        "peek",
      },
    },
    { "😈",
      {
        "smilingFaceWithHorns",
        "evil",
        "haha",
      },
    },
    { "👻",
      {
        "ghost",
      },
    },
    { "🙇",
      {
        "personBowing",
        "please",
        "sorry",
      },
    },
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
    { "👾",
      {
        "alienMonster",
        "monster",
      },
    },
    { "🌈", "rainbow" },
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
}

local M = {}
for _, group in pairs(emoji_data.G) do
  for _, e in ipairs(group.items) do
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

    if group.alias ~= "" then
      -- 每一個項目的abbr也套用該群組所有的別名
      if type(group.alias) == "string" then
        table.insert(M, emoji:new(word, group.alias))
      else
        if type(group.alias) == "table" then
          for _, alias in ipairs(group.alias) do
            table.insert(M, emoji:new(word, alias))
          end
        end
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
