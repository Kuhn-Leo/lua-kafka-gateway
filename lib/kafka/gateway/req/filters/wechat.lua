local util               = require "util"
local config             = require "kafka.gateway.config"

local log                = ngx.log
local ERR                = ngx.ERR
local request_time       = util.request_time
local inflate_body       = util.inflate_body
local check_wechat       = util.check_wechat
local get_args           = util.get_args
local get_ip             = util.get_ip
local is_array           = util.is_array
local get_md5_sig        = util.get_md5_sig
local topics             = config.KAFKA_TOPICS
local ipairs             = ipairs

----------------------------------------------------
-- 1. 检查是否zlib压缩,如果压缩，解压重新设置body参数
----------------------------------------------------
inflate_body()

----------------------------------------------------
-- 2. 检查参数合法性
----------------------------------------------------
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

for _, msg in ipairs(msgs) do
  local check_staus = check_wechat(msg)
  local item = {}
  if check_staus then
    item["tpc"] = topics.wechat
    item["ip"]  = ip
    item["t"]   = t
    item["sig"] = get_md5_sig(msg)
    table.insert(msg_list, item)
  end
end

if not msg_list or msg_list[1] == nil then
  log(ERR, "msg_list error!\n")
  return ngx.exit(ngx.HTTP_BAD_REQUEST)
end

ngx.ctx.messageList = msg_list
