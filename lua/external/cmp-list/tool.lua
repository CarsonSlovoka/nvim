local kind = {
  tool = "tool",
}

local desc = {
  mkvToMp4 = [[
# 轉檔
# 如果確定當前工作目錄只有一個mkv檔案，可以直接用*.mkv
ffmpeg -i *.mkv -c:v copy -c:a copy output.mp4

# 要檢示可以透過 `vlc`
vlc output.mp4
vlc output.mkv
]]
}


local M = {
  {
    word = 'cwebp -q 11 "input.png" -o "output.webp"',
    kind = kind.tool,
    abbr = kind.tool .. ".png2webp",
    info = "cwebp -q <quality> <input> -o <output>"
  },
  {
    word = 'grim -c -g "$(slurp)" - | convert - -shave 3x3 PNG:- | wl-copy',
    kind = kind.tool,
    abbr = kind.tool .. ".printScreen",
    info = [[
截圖，保存在剪貼簿之中
需要用到 `grim`, `slurp`, `convert`等工具
]]
  },
  {
    word = 'wl-paste --type image/png | cwebp -q 11 -o output.webp -- -',
    kind = kind.tool,
    abbr = kind.tool .. ".saveClipboardImgToWebp",
    info = "需要先將圖片保存在剪貼簿之中"
  },
  {
    word = 'file ~/*.webp',
    kind = kind.tool,
    abbr = kind.tool .. ".fileInfo",
    info = [[
查看檔案資訊, 如果是圖片，輸出如下
my.webp: RIFF (little-endian) data, Web/P image, VP8 encoding, 944x936, Scaling: [none]x[none], YUV color, decoders should clamp
]]
  },

  -- wf-recorder
  {
    word = 'wf-recorder -g "$(slurp)" --audio --file="$(realpath ~/Documents/output.mkv)"',
    kind = kind.tool,
    abbr = kind.tool .. '.recSelection',
    -- menu = "💡",
    info = [[
錄螢幕, 可選擇區域
( 注意！ 如果要選區域，輸出格式只能是mkv)

]],
    user_data = {
      example = [[
wf-recorder -g "$(slurp)" --file=output.mkv
]] .. desc.mkvToMp4
    }
  },
  {
    word = 'wf-recorder --audio --file="$(realpath ~/Documents/output.mkv)"',
    kind = kind.tool,
    abbr = kind.tool .. '.recScreen',
    -- menu = "💡",
    info = [[
錄整個螢幕
(有多個螢幕時可挑)
]],
    user_data = {
      example = [[
wf-recorder --audio --file=output.mp4
]] .. desc.mkvToMp4
    }
  },
}

return M
