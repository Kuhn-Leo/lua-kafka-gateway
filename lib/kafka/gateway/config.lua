-- kafka broker list
local broker_list = {
  {
    host = "127.0.0.1",
    port = 9002
  }, {
    host = "127.0.0.1",
    port = 9002
  }, {
    host = "127.0.0.1",
    port = 9002
  }
}

-- kafka topics
local kafka_topics = {
  sms    = "kafka_topic_sms",
  email  = "kafka_topic_email",
  wechat = "kafka_topic_wechat"
}

-- md5 key sorts
local md5_key  = "oifsoifosdfsdifodsfs"
local md5_list = {
  sms    = {"a", "b", "c"},
  email  = {"a", "b", "c"},
  wechat = {"a", "b", "c"}
}

-- kafka config  one ngx worker one kafka client or producer instance
local kafka_config = {
  producer_type     = "async",
  socket_timeout    = 6000,
  max_retry         = 2,
  refresh_interval  = 600*1000,
  keepalive_timeout = 600*1000,
  keepalive_size    = 40,
  max_buffering     = 1000000,
  flush_time        = 100,
  batch_num         = 500
}

return {
  BROKER_LIST  = broker_list,
  KAFKA_CONFIG = kafka_config,
  KAFKA_TOPICS = kafka_topics,
  MD5_KEY  = md5_key,
  MD5_LIST = md5_list,
  TIMESTAMP_LENGTH = 13
}
