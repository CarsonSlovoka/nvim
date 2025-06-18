; :TSInstall lua
; 即如果key的數值為lua, 它會將
(pair
  key: (string) @_key
  value: (string) @injection.content
  (#eq? @_key "\"lua\"")
  (#set! injection.language "lua"))

; :TSInstall javascript
; 如果沒有安裝, 那麼用 :Inspect 還是會沒查看到
; (pair
;   key: (string) @_key
;   value: (string) @injection.content
;   (#eq? @_key "\"js\"")
;   (#set! injection.language "javascript"))
