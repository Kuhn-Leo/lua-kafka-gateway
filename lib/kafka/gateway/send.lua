local cjson        = require "kafka.gateway.json" --require "resty.libcjson"
local producer     = require "resty.kafka.producer"
local config       = require "kafka.gateway.config"

local log          = ngx.log
local ERR          = ngx.ERR
local json_encode  = cjson.encode
local msg_list     = ngx.ctx.messageList
local BROKER_LIST  = config.BROKER_LIST
local KAFKA_CONFIG = config.KAFKA_CONFIG

if msg_list then
  -- this is async producer_type and bp will be reused in the whole nginx worker
  local kafka_producer = producer:new(BROKER_LIST, KAFKA_CONFIG)
  for _, v in ipairs(msg_list) do
    if v then
      local topic = v["tpc"]
      local key   = v["sig"]
      local data  = json_encode(v)
      if topic then
        local ok, err = kafka_producer:send(topic, key, data)
        if not ok then
          log(ERR, "kafka err: " .. err)
          log(ERR, "err msg: " .. data)
        end
      end
    end
  end
end
