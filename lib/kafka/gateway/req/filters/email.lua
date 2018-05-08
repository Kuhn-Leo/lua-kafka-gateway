local util               = require "kafka.gateway.util"
local config             = require "kafka.gateway.config"

local log                = ngx.log
local ERR                = ngx.ERR
local request_time       = util.request_time
local check_email        = util.check_email
local get_args           = util.get_args
local get_ip             = util.get_ip
local get_uid            = util.get_uid
local is_array           = util.is_array
local get_md5_sig        = util.get_md5_sig
local topics             = config.KAFKA_TOPICS
local ipairs             = ipairs

-- 检查参数合法性
local args = get_args()

if not args then
  log(ERR, "json error")
  return ngx.exit(ngx.HTTP_BAD_REQUEST)
end

-- 解析args
local msgs = args["msg"]

if not is_array(msgs) then
  log(ERR, "req args error!\n")
  return ngx.exit(ngx.HTTP_BAD_REQUEST)
end

local msg_list = {}
local ip  = get_ip()
local t   = request_time()
local uid = get_uid()

for _, msg in ipairs(msgs) do
  local check_staus = check_email(msg)
  local item = {}
  if check_staus then
    item["tpc"] = topics.email
    item["ip"]  = ip
    item["t"]   = t
    item["uid"] = uid
    item["msg"] = msg
    item["sig"] = get_md5_sig(msg)
    table.insert(msg_list, item)
  end
end

if not msg_list or msg_list[1] == nil then
  log(ERR, "msg_list error!\n")
  return ngx.exit(ngx.HTTP_BAD_REQUEST)
end

ngx.ctx.messageList = msg_list
