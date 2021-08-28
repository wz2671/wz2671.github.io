---
title: 《redis开发与运维》笔记
date: 2021-08-01 22:09:25
tags: [服务端开发, 数据库]
---

[参考书籍](https://github.com/7-sevens/Developer-Books/blob/master/Redis/Redis%E5%BC%80%E5%8F%91%E4%B8%8E%E8%BF%90%E7%BB%B4.pdf)


![封面](/images/rediskaifayuyunwei.jpg)


<!--more -->

# 一、初始redis

### 1. redis特性

* Redis全程是(REmote Dictionary Server)
* 速度快
    * 所有数据都是存放在内存中的
    * 使用c语言实现
    * 单线程架构
    * 源代码集性能与优雅于一身
* 基于键值对的方式组织数据，提供了五种数据结构: 字符串，哈希，列表，集合，有序集合
* 提供了许多额外功能
    * 键过期功能
    * 发布订阅功能
    * 支持Lua脚本
    * 提供了简单的事务功能
    * 提供了流水线(Pipeline)功能
* 简单稳定
* 客户端语言多，支持c, c++, python等
* 持久化
* 主从复制
* 高可用和分布式

### 2. redis启动和使用

* 有三种方法启动Redis：默认配置，运行配置，配置文件
    ```bash
    wenzhou@WZSUPER:/mnt/c/Users/wenzhou$ redis-server --port 6000
    15:C 01 Aug 2021 22:58:33.126 # oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo
    15:C 01 Aug 2021 22:58:33.126 # Redis version=5.0.3, bits=64, commit=00000000, modified=0, pid=15, just started
    15:C 01 Aug 2021 22:58:33.126 # Configuration loaded
    15:M 01 Aug 2021 22:58:33.127 * Increased maximum number of open files to 10032 (it was originally set to 1024).
                    _._
            _.-``__ ''-._
        _.-``    `.  `_.  ''-._           Redis 5.0.3 (00000000/0) 64 bit
    .-`` .-```.  ```\/    _.,_ ''-._
    (    '      ,       .-`  | `,    )     Running in standalone mode
    |`-._`-...-` __...-.``-._|'` _.-'|     Port: 6000
    |    `-._   `._    /     _.-'    |     PID: 15
    `-._    `-._  `-./  _.-'    _.-'
    |`-._`-._    `-.__.-'    _.-'_.-'|
    |    `-._`-._        _.-'_.-'    |           http://redis.io
    `-._    `-._`-.__.-'_.-'    _.-'
    |`-._`-._    `-.__.-'    _.-'_.-'|
    |    `-._`-._        _.-'_.-'    |
    `-._    `-._`-.__.-'_.-'    _.-'
        `-._    `-.__.-'    _.-'
            `-._        _.-'
                `-.__.-'

    15:M 01 Aug 2021 22:58:33.130 # WARNING: The TCP backlog setting of 511 cannot be enforced because /proc/sys/net/core/somaxconn is set to the lower value of 128.
    15:M 01 Aug 2021 22:58:33.130 # Server initialized
    15:M 01 Aug 2021 22:58:33.130 # WARNING overcommit_memory is set to 0! Background save may fail under low memory condition. To fix this issue add 'vm.overcommit_memory = 1' to /etc/sysctl.conf and then reboot or run the command 'sysctl vm.overcommit_memory=1' for this to take effect.
    15:M 01 Aug 2021 22:58:33.130 * DB loaded from disk: 0.000 seconds
    15:M 01 Aug 2021 22:58:33.130 * Ready to accept connections
    ```
* 客户端连接
    ```bash
    wenzhou@WZSUPER:/mnt/c/Users/wenzhou$ redis-cli -p 6000
    127.0.0.1:6000> set hello world
    OK
    127.0.0.1:6000> get hello
    "world"
    127.0.0.1:6000>
    ```
* 停止服务，redis关闭时，会断开与客户端的连接，持久化文件生成
    ```bash
    # 客户端执行shutdown，并不保存数据
    127.0.0.1:6000> shutdown nosave
    not connected>
    ```
    ```bash
    # 服务关闭
    15:M 01 Aug 2021 23:01:58.735 # User requested shutdown...
    15:M 01 Aug 2021 23:01:58.735 # Redis is now ready to exit, bye bye...
    ```
