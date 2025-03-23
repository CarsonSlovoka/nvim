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
  { "❌", "error" },
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
  { "🤔", "confused" },
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

return M
