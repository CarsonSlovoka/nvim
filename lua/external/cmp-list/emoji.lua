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
    { "👋",
      {
        "gestures",
        "hi",
      },
    },
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
    { "✍️",
      {
        "writing",
        "write",
        "handwrite",
      },
    },
    { "🤏",
      {
        "pinching",
        "little",
        "small",
        "tik",
      },
    },
    { "🤌",
      {
        "pinchedFingers",
        "cue",
      },
    },
    { "🙌",
      {
        "raisingHands",
        "ya",
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
    { "😄",
      {
        "grinningFaceWithSmilingEyes",
        "laughing",
        "happy",
      },
    },
    { "🤣",
      {
        "rollingOnTheFloorLaughing",
        "laughing",
        "happy",
      },
    },
    { "🤭",
      {
        "handOverMouth",
        "shySmile",
        "smile",
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
    { "🤫",
      {
        "shushingFace",
        "muted",
      },
    },
    { "😍",
      {
        "smilingFaceWithHeartEyes",
        "heart",
        "love",
        "wow",
      },
    },
    { "🥰",
      {
        "smilingFaceWithHearts",
        "heart",
        "love",
      },
    },
    { "🤩",
      {
        "starStruck",
        "wow",
      },
    },
    { "🤗",
      {
        "smilingFaceWithOpenHands",
        "smile",
        "happy",
        "huggingFace",
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
    { "🐘", "elephant" },
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

emoji_data.G.action = {
  alias = { "action" },
  items = {
    { "▶️",
      {
        "play",
      },
    },
    { "⏯️",
      {
        "playOrPause",
      },
    },
    { "⏸️",
      {
        "pause",
      },
    },
    { "⏹️",
      {
        "stop",
      },
    },
    { "⏳",
      {
        "hourglassNotDone",
        "loading",
        "waiting",
      },
    },
    { "💤",
      {
        "zzz",
      },
    },
    { "🚫",
      {
        "prohibited",
        "noEntry",
        "ban",
        "disable",
        "stop",
      },
    },
    { "⛔",
      {
        "noEntry",
        "ban",
        "disable",
        "stop",
      },
    },
    { "🔚",
      {
        "end",
        "exit",
        "quit",
      },
    },
    { "↩️",
      {
        "rightArrowCurvingLeft",
        "back",
      },
    },
    { "🔄",
      {
        "counterclockwiseArrowsButton",
        "refresh",
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
    { "🍎",
      {
        "redApple",
        "apple",
        "macOS",
      },
    },
  }
}

emoji_data.G.OS = {
  alias = { "OS", "platform" },
  items = {
    { "🐧",
      {
        "penguin",
        "linux",
      },
    },
    { "🪟",
      {
        "windows",
      },
    },
    { "",
      {
        "macOS",
        "iOS",
      },
    },
  }
}

emoji_data.G.Keyboard = {
  alias = { "keyboard", "key" },
  items = {
    {
      "⇧",
      {
        "shift"
      }
    },
    {
      "⌘",
      {
        "cmd",
        "window",
        "start",
      }
    },
    {
      "⌥",
      {
        "option",
        "alt",
      }
    },
    {
      "⌃",
      {
        "ctrl",
        "control",
      }
    },
  }
}


emoji_data.G.mood = {
  alias = { "mood", "feeling" },
  items = {
    { "💢",
      {
        "angerSymbol",
        "angry",
      },
    },
  }
}

emoji_data.G.item = {
  alias = "item",
  items = {
    { "🔹",
      {
        "smallBlueDiamond",
        "itemBlueDiamond",
        "itemDiamond",
      },
    },
    { "🔷",
      {
        "largeBlueDiamond",
        "itemBlueDiamond",
        "itemDiamond",
      },
    },
    { "🟩",
      {
        "greenSquare",
        "itemGreenSquare",
        "itemSquare",
      },
    },
    { "🟦",
      {
        "blueSquare",
        "itemBlueSquare",
        "itemSquare",
      },
    },
    { "🟥",
      {
        "redSquare",
        "itemRedSquare",
        "itemSquare",
        "stop",
        "terminate",
      },
    },
    { "🟧",
      {
        "orangeSquare",
        "itemOrangeSquare",
        "itemSquare",
      },
    },
    { "🔴",
      {
        "redCircle",
        "breakpoint",
      },
    },
    { "📌",
      {
        "pushpin",
        "pin",
        "breakpoint",
      },
    },
    { "📍",
      {
        "roundPushpin",
        "pin",
        "breakpoint",
      },
    },
  }
}


emoji_data.G.computer = {
  alias = "computer",
  items = {
    { "🖳",
      {
        "desktopComputer",
      },
    },
    { "🖥️",
      {
        "desktopComputer",
        "computer",
        "screen",
      },
    },
    { "🖥",
      {
        "desktopComputer",
        "disk",
      },
    },
    { "⌨️",
      {
        "keyboard",
        "typing",
      },
    },
    { "🖱️",
      {
        "computerMouse",
        "mouse",
      },
    },
    { "🕹️",
      {
        "joystick",
        "controller",
      },
    },
    { "🖴",
      {
        "hardDisk",
        "disk",
        "drive",
      },
    },
  }
}

local number_items = {}
for i = 0, 9 do -- sign_define 0️⃣, 1️⃣  .. 9️⃣
  -- 其中U+FE00-U+FE0f區間為變體選擇符(Variation Selectors)
  local emoji_number = vim.fn.nr2char(i + 48) .. string.format("️⃣") -- 從0x0030 (48) 開始，後面固定為U+FE0F U+20E3
  table.insert(number_items, { emoji_number, tostring(i) })
end
emoji_data.G.number = {
  alias = "number",
  items = number_items
}

local alphabet_items = {}
-- 🇦 🇧 .. 🇿
for i = 0, 25 do
  local lower_letter = vim.fn.nr2char(0x41 + i) -- A
  local upper_letter = vim.fn.nr2char(0x61 + i) -- a
  local emoji_letter = vim.fn.nr2char(0x1f1e6 + i)
  table.insert(alphabet_items,
    {
      emoji_letter,
      {
        lower_letter,
        upper_letter,
        "letter" .. lower_letter,
        "letter" .. upper_letter,
      }
    }
  )
end
emoji_data.G.letter = {
  alias = { "letter", "alphabet" },
  items = alphabet_items
}


emoji_data.G.voice = {
  alias = { "voice", "volume" },
  items = {
    { "📢",
      {
        "announcement",
        "loudSpeaker",
      },
    },
    { "🔇",
      {
        "muted",
      },
    },
    { "🔈",
      {
        "speakerLowVolume",
      },
    },
    { "🔉",
      {
        "speakerMediumVolume",
      },
    },
    { "🔊",
      {
        "speakerHighVolume",
      },
    },
    {
      "👄",
      {
        "month",
      }
    },
    { "🎧",
      {
        "headphone",
      },
    },
    { "🗣️",
      {
        "speakingHead",
      },
    },
    { "💬",
      {
        "speechBallon",
        "speech",
        "saySomething",
      },
    },
  }
}

emoji_data.G.tool = {
  alias = "tool",
  items = {
    { "⚙️",
      {
        "gear",
        "settings",
      },
    },
    { "🛠️",
      {
        "hammerAndWrench",
        "hammer",
        "wrench",
        "spanner",
      },
    },
    { "🔧",
      {
        "metalWrench",
        "spanner",
      },
    },
    { "🔨",
      {
        "hammer",
      },
    },
    { "🧰",
      {
        "toolbox",
      },
    },
    { "🪜",
      {
        "ladder",
      },
    },
  }
}

emoji_data.G.game = {
  alias = "game",
  items = {
    { "☠️",
      {
        "skullAndCrossbones",
        "bones",
        "gameOver",
        "die",
        "dead",
      },
    },
    {
      "🎲",
      {
        "gameDie",
        "die",
        "one",
      }
    },
    {
      "🏆",
      {
        "Trophy",
        "1st",
        "rank",
      }
    },
    {
      "🏅",
      {
        "sportsMedal",
        "medal",
        "1st",
      }
    },
    {
      "🎖️",
      {
        "militaryMedal",
        "medal",
      }
    },
    { "⚔️",
      {
        "crossedSwords",
        "swords",
      },
    },
    { "💯",
      {
        "hundredPoints",
        "100points",
      },
    },
    { "🎉",
      {
        "ya",
        "party",
      },
    },
    { "🎊",
      {
        "confettiBall",
        "party",
        "ya",
        "ball",
      },
    },
    { "🎇",
      {
        "sparkler",
        "ya"
      },
    },
    { "✨",
      {
        "sparkles",
        "features",
      },
    },
    { "🎈",
      {
        "balloon",
        "redBalloon",
      },
    },
  }
}

emoji_data.G.digraphs = {
  -- 在 :digraphs 就有的內容，只是將常用的整合在這
  alias = "digraphs",
  items = {
    { "〆",
      {
        ";_", -- 第一個項目為digraphs建好的內容
        "halfCheck",
      }
    },
    { "℃",
      {
        "oC",
      }
    },
    { "♫",
      {
        "M2",
        "music",
      }
    },
    { "★",
      {
        "*2",
        "star",
      }
    },
    { "☆",
      {
        "*1",
        "star",
      }
    },
    { "✓",
      {
        "OK",
        "check",
      }
    },
    { "✗",
      {
        "XX",
        "error",
      }
    },
    { "☻",
      {
        "0U",
        "smile",
      }
    },
  }
}

emoji_data.G._other = {
  alias = "",
  items = {
    { "🧙", "mage" },
    { "👷",
      {
        "worker",
        "employee",
      },
    },
    { "🕳️",
      {
        "hole",
      },
    },
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
    { "🆗",
      {
        "ok",
      },
    },
    { "✅",
      {
        "check",
        "ok",
      },
    },
    { "⚠️", -- U+26a0 U+fe0f (variation selectors)
      {
        "warning",
      },
    },
    { "⚠", "warning" },
    { "❗", "exclamation" },
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
  }
}

local M = {}
for _, group in pairs(emoji_data.G) do
  for _, e in ipairs(group.items) do
    local word = e[1]
    local abbr_data = e[2]
    if type(abbr_data) == "string" then
      table.insert(M, emoji:new(word, abbr_data))
    elseif type(abbr_data) == "table" then
      for _, abbr in ipairs(abbr_data) do
        table.insert(M, emoji:new(word, abbr))
      end
    end

    if group.alias ~= "" then
      -- 每一個項目的abbr也套用該群組所有的別名
      if type(group.alias) == "string" then
        table.insert(M, emoji:new(word, group.alias))
      elseif type(group.alias) == "table" then
        for _, alias in ipairs(group.alias) do
          table.insert(M, emoji:new(word, alias))
        end
      end
    end
  end
end


--- 搜尋匹配的表符符號
--- @param search_str string 如果給空值，則返回所有的表情符號
--- @return table|nil
function M.get_emoji(search_str)
  if search_str == "" then
    return nil
  end

  local matches = {}

  -- 將搜尋字串轉為小寫以進行不區分大小寫的比較
  search_str = string.lower(search_str)

  for _, e in ipairs(M) do
    -- print(vim.inspect(e))
    if string.find(string.lower(e.abbr), search_str) then
      table.insert(matches, e.word)
    end
  end

  if #matches > 0 then
    return matches
  else
    return nil
  end
end

-- M.get_emoji("ok")

-- :h digraphs
-- 使用 :digraphs 可以查看所有所有常用字表清單
-- vim.cmd("digraphs -- 0")      -- 撤銷 -- 打上原本的命令之後接一個0即可
vim.cmd("digraphs -- 128529")           -- 😑
vim.cmd("digraphs xd 128565")           -- 😵
vim.cmd("digraphs sm 128512 ha 128513") -- 😀 😁

vim.cmd("digraphs .. 128172")           -- 💬

vim.cmd("digraphs Ok 9989")             -- ✅ -- OK ✓
vim.cmd("digraphs xx 10060")            -- ❌ -- XX ✗

vim.cmd("digraphs hh 128072")           -- 👈 -- 原本的是 ─
vim.cmd("digraphs jj 128071")           -- 👇
vim.cmd("digraphs kk 128070")           -- 👆 -- 原本的是 ĸ
vim.cmd("digraphs ll 128073")           -- 👉

vim.cmd("digraphs rt 128640")           -- 🚀
vim.cmd("digraphs sg 128170")           -- 💪

-- 近似於
vim.cmd("digraphs ~~ 8776") -- ≈
vim.cmd("digraphs := 8786") -- ≒


-- 用 digraph_setlist 可以更直觀
vim.fn.digraph_setlist({
  { '!!', '❗' }, -- Error
  { '!w', '⚠' }, -- Warning -- ⚠️：U+26A0 + U+FE0F # digraphs 只能一個unicode字元，所以這不是完整的，只能顯示 ⚠ 可以再補上變體選擇符即可: U+FE00..U+FE0F -- https://zh.wikipedia.org/zh-tw/變體選擇符_(Unicode區段)
  { '!i', '💡' }, -- Idea
  { '!n', '📝' }, -- Note

  -- variation sequence
  -- | 名稱       | Unicode         | 用途                            | 常用程度 |
  -- |---         |---              |---                              |---       |
  -- | VS1–VS14   | U+FE00–U+FE0D   | 特定字形變體，例如部分數學符號  | 低       |
  -- | VS15       | U+FE0E          | 強制要求文字樣式（Text）        | 高       |
  -- | VS16       | U+FE0F          | 強制要求 Emoji 樣式             | 高       |
  -- | VS17–VS256 | U+E0100–U+E01EF | 主要用於漢字的異體字選擇（IVS） | 特殊用途 |
  { 'vT', vim.fn.nr2char(0xFE0E) }, -- VS15: Text
  { 'vE', vim.fn.nr2char(0xFE0F) }, -- VS16: Emoji
})


return M
