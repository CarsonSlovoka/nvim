local kind = {
  notify = "notify"
}

local M = {
  {
    word = [[echo 'notify-send' "title" "body"' | at 01:30 02/28/2025]],
    kind = kind.notify,
    info = "notify",
    abbr = "Notify-send hh:mm MM/DD/YYYY",
    user_data = {
      example = [[
echo 'notify-send "title" "body"' | at 08:00
echo 'notify-send "title" "body"' | at 08:00 tomorrow
echo 'notify-send "title" "body"' | at not + 1 hour
]]
    }
  },
  {
    word = [[atq]],
    kind = kind.notify,
    info = "at -c <id>",
    abbr = "NotifySendList",
    user_data = {
      example = [[
atrm 11 # 刪除指定的排程編號
]]
    }
  }
}

return M
