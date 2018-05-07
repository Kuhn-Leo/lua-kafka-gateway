local json   = require "cjson"
local ngx    = ngx
local encode = json.encode
local text   = encode({
  status = 1
})

ngx.say(text)
