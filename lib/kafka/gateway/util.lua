local cjson            = require "kafka.gateway.json" --require "resty.libcjson"
local config           = require "kafka.gateway.config"
local json_encode      = cjson.encode
local json_decode      = cjson.decode
local md5              = ngx.md5
local MD5_KEY          = config.MD5_KEY

local getmetatable     = getmetatable
local tonumber         = tonumber
local rawget           = rawget
local insert           = table.insert
local ipairs           = ipairs
local pairs            = pairs
local lower            = string.lower
local find             = string.find
local type             = type
local ngx              = ngx
local req              = ngx.req
local log              = ngx.log
local re_match         = ngx.re.match
local re_gmatch        = ngx.re.gmatch
local req_read_body    = req.read_body
local get_uri_args     = req.get_uri_args
local get_body_data    = req.get_body_data
local get_post_args    = req.get_post_args

local NOTICE           = ngx.NOTICE


local multipart_mt = {}


function multipart_mt:__tostring()
  return self.data
end


function multipart_mt:__index(name)
  local json = rawget(self, "json")
  if json then
    return json[name]
  end

  return nil
end

local function combine_arg(to, arg)
  if type(arg) ~= "table" or getmetatable(arg) == multipart_mt then
    insert(to, #to + 1, arg)

  else
    for k, v in pairs(arg) do
      local t = to[k]

      if not t then
        to[k] = v

      else
        if type(t) == "table" and getmetatable(t) ~= multipart_mt then
          combine_arg(t, v)

        else
          to[k] = { t }
          combine_arg(to[k], v)
        end
      end
    end
  end
end

local function combine(args)
  local to = {}

  if type(args) ~= "table" then
    return to
  end

  for _, arg in ipairs(args) do
    combine_arg(to, arg)
  end

  return to
end

local infer

local function infer_value(value, field)
  if not value or type(field) ~= "table" then
    return value
  end

  if value == "" then
    return ngx.null
  end

  if field.type == "number" or field.type == "integer" then
    return tonumber(value) or value

  elseif field.type == "boolean" then
    if value == "true" then
      return true

    elseif value == "false" then
      return false
    end

  elseif field.type == "array" or field.type == "set" then
    if type(value) ~= "table" then
      value = { value }
    end

    for i, item in ipairs(value) do
      value[i] = infer_value(item, field.elements)
    end

  elseif field.type == "foreign" then
    if type(value) == "table" then
      return infer(value, field.schema)
    end

  elseif field.type == "map" then
    if type(value) == "table" then
      for k, v in pairs(value) do
        value[k] = infer_value(v, field.elements)
      end
    end

  elseif field.type == "record" then
    if type(value) == "table" then
      for k, v in pairs(value) do
        value[k] = infer_value(v, field.fields[k])
      end
    end
  end

  return value
end


infer = function(args, schema)
  if not args then
    return
  end

  if not schema then
    return args
  end

  for field_name, field in schema:each_field() do
    local value = args[field_name]
    if value then
      args[field_name] = infer_value(value, field)
    end
  end

  return args
end

local function decode_array_arg(name, value, container)
  container = container or {}

  if type(name) ~= "string" then
    container[name] = value
    return container[name]
  end

  local indexes = {}
  local count   = 0
  local search  = name

  while true do
    local captures, err = re_match(search, [[(.+)\[(\d*)\]$]], "ajos")
    if captures then
      search = captures[1]
      count = count + 1
      indexes[count] = tonumber(captures[2])

    elseif err then
      log(NOTICE, err)
      break

    else
      break
    end
  end

  if count == 0 then
    container[name] = value
    return container[name]
  end

  container[search] = {}
  container = container[search]

  for i = count, 1, -1 do
    local index = indexes[i]

    if i == 1 then
      if index then
        insert(container, index, value)
        return container[index]
      end

      if type(value) == "table" and getmetatable(value) ~= multipart_mt then
        for j, v in ipairs(value) do
          insert(container, j, v)
        end

      else
        container[#container + 1] = value
      end

      return container

    else
      if not container[index or 1] then
        container[index or 1] = {}
        container = container[index or 1]
      end
    end
  end
end


local function decode_arg(name, value)
  if type(name) ~= "string" or re_match(name, [[^\.+|\.$]], "jos") then
    return { name = value }
  end

  local iterator, err = re_gmatch(name, [[[^.]+]], "jos")
  if not iterator then
    if err then
      log(NOTICE, err)
    end

    return decode_array_arg(name, value)
  end

  local names = {}
  local count = 0

  while true do
    local captures, err = iterator()
    if captures then
      count = count + 1
      names[count] = captures[0]

    elseif err then
      log(NOTICE, err)
      break

    else
      break
    end
  end

  if count == 0 then
    return decode_array_arg(name, value)
  end

  local container = {}
  local bucket = container

  for i = 1, count do
    if i == count then
      decode_array_arg(names[i], value, bucket)
      return container

    else
      bucket = decode_array_arg(names[i], {}, bucket)
    end
  end
end


local function decode(args, schema)
  local i = 0
  local r = {}

  if type(args) ~= "table" then
    return r
  end

  for name, value in pairs(args) do
    i = i + 1
    r[i] = decode_arg(name, value)
  end

  return infer(combine(r), schema)
end


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
  local args

  local content_type = ngx.var.content_type
  if not content_type then
    local uargs = get_uri_args()
    args = decode(uargs)
    return args
  end

  local content_type_lower = lower(content_type)

  if find(content_type_lower, "application/x-www-form-urlencoded", 1, true) == 1 then
    req_read_body()
    local pargs, err = get_post_args()
    if pargs then
      args = decode(pargs)
    elseif err then
      log(NOTICE, err)
    end

  elseif find(content_type_lower, "application/json", 1, true) == 1 then
    req_read_body()

    -- we don't support file i/o in case the body is
    -- buffered to a file, and that is how we want it.
    local body_data = get_body_data()
    if body_data then
      local pargs, err = json_decode(body_data)
      if pargs then
        args = pargs
      elseif err then
        log(NOTICE, err)
      end
    end

  else
    req_read_body()

    -- we don't support file i/o in case the body is
    -- buffered to a file, and that is how we want it.
    local body_data = get_body_data()

    if body_data then
      args.body = body_data
    end
  end

  return args
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
