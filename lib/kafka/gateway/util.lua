local zlib             = require "ffi-zlib"
local cjson            = require "cjson.safe"
local config           = require "kafka.gateway.config"
local json_encode      = cjson.encode
local md5              = ngx.md5
local MD5_KEY          = config.MD5_KEY

local _M = {}

-- 是否为数组
function _M.is_array(t)
  if type(t) ~= "table" then
    return false
  end
  local i = 0
  for _ in pairs(t) do
    i = i + 1
    if t[i] == nil and t[tostring(i)] == nil then
      return false
    end
  end
  return true
end

-- 获得服务端时间
function _M.request_time()
  local ngx_time = ngx.time()
  return os.date("%Y-%m-%d %H:%M:%S", ngx_time)
end

-- 获取http请求(get|post)参数
function _M.get_args()
  local args = {}
  local m = ngx.var.request_method
  if "GET" == m then
    args = ngx.req.get_uri_args()
  elseif "POST" == m then
    ngx.req.read_body()  -- log_by_lua 阶段不能使用
    args = ngx.req.get_post_args()
  end
  return args
end

-- 获取http请求编码
function _M.get_countent_encoding()
  return  ngx.req.get_headers()["Content-Encoding"]
end

-- 解压body（gzip 压缩）
function _M.inflate_body()
  local encoding =  _M.get_countent_encoding()
  if encoding == "gzip" then
    ngx.req.read_body()  -- log_by_lua 阶段不能使用
    local body = ngx.req.get_body_data()
    if body then
      local stream = zlib.inflate()
      local inflated = stream(body)
      ngx.req.set_body_data(inflated)
    end
  end
end

-- 获得client ip
function _M.get_ip()
  local ip = ngx.req.get_headers()["X-Real-IP"]
  if not ip then
    ip = ngx.req.get_headers()["x_forwarded_for"]
  end
  if not ip then
    ip = ngx.var.remote_addr
  end
  return ip
end

-- string split ,in function  string.gsub not jit ,please use ngx.reg.gsub
function _M.split(str, delimiter)
  if str == nil or str =='' or delimiter == nil then
    return nil
  end

  local rt = {}
  string.gsub(str, '[^'..delimiter..']+', function(w) table.insert(rt, w) end)
  return rt
end

-- 获取MD5签名
function _M.get_md5_sig(arg)
  local v = json_encode(arg)
  v = MD5_KEY .. v .. MD5_KEY
  return md5(v)
end

-- 短信消息体检查
function _M.check_sms()
  return true
end

-- 邮件消息体检查
function _M.check_email()
  return true
end

-- 微信消息体检查
function _M.check_wechat()
  return true
end

return _M
