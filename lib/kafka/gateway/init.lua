local log = ngx.log
local ERR = ngx.ERR

print("开始初始化模块以及加载配置")

local uuid   = require "resty.jit-uuid"
local x      = os.clock()
local config = require "kafka.config"

if not config  then
  log(ERR, "parse configs error!");
end

uuid.seed()

print("初始化模块以及加载配置结束,耗时: "..(os.clock() - x).." s \\n  ")
