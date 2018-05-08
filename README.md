# lua-kafka-gateway
a h5 api gateway for kafka

### 安装openresty

[1] 安装依赖包   
```shell
$ yum install -y gcc gcc-c++ readline-devel pcre-devel openssl-devel tcl perl
```

[2] 安装 [openresty](https://openresty.org/en/download.html)   

click [openresty-1.13.6.1.tar.gz](https://openresty.org/download/openresty-1.13.6.1.tar.gz) start download

```shell
$ tar -xvf openresty-VERSION.tar.gz
$ cd openresty-VERSION/
$ ./configure -j2
$ make -j2
$ sudo make install
```

where VERSION should be replaced by a concrete version number of OpenResty, like 1.13.6.1.

[3] 环境变量   
better also add the following line to your ~/.bashrc or ~/.bash_profile file.

```
export PATH=/usr/local/openresty/bin:$PATH
```

### Start

```shell
$ cd /path/to/lua-kafka-gateway
$ sh ./bin/start.sh
```

### Stop

```shell
$ cd /path/to/lua-kafka-gateway
$ sh ./bin/stop.sh
```