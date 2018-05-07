local log = ngx.log
local ERR = ngx.ERR

print("开始初始化模块以及加载配置")

local x      = os.clock()
local config = require "kafka.gateway.config"

if not config  then
  log(ERR, "parse configs error!");
end

print("初始化模块以及加载配置结束,耗时: "..(os.clock() - x).." s \\n  ")
