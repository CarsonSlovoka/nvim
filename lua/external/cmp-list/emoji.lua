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
  { "❓", "redQuestionMark" },
  { "✅", "check" },
  { "⚠", "warning" },
  { "🎉", "ya" },
  { "❗", "exclamation" },
  { "👆", "pointingUp" },
  { "👇", "pointingDown" },
  { "👈", "pointingLeft" },
  { "👉", "pointingRight" },
  { "←", "arrowLeft" },
  { "↑", "arrowUp" },
  { "→", "arrowRight" },
  { "↓", "arrowDown" },
  { "💡", "tip" },
  { "🚀", "rocket" },
  { "🧙", "mage" },
  { "🐘", "elephant" },
  { "📁", "folder" },
  { "📂", "folderOpen" },
  { "📝", "memo" },
  { "📢", "announcement" },
  { "😅", "sorry" },
  { "😡", "angry" },
  { "🙂", "smiling" },
  { "😊", "smilingWithSmilingEyes" },
  { "🥺", "pleadingFace" },
  { "🤔", "confused" },
  { "🙏", "please" },
  { "🤝", "handshake" },
  { "🔥", "fire" },
  { "🔑", "key" },
  { "🔒", "locked" },
  { "⚡", "fast" },
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
  local abbr = e[2]
  table.insert(M, emoji:new(word, abbr))
end

return M
