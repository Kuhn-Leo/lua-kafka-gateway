local cjson  = require "kafka.gateway.json" --require "resty.libcjson"
local ngx    = ngx
local encode = cjson.encode
local text   = encode({
  status = 1
})

ngx.say(text)
