---
title: redis设计与实现
date: 2021-07-31 12:50:05
tags: [服务端开发, 数据库]
---
新版书籍百度云链接[提取码：sk5i](https://pan.baidu.com/s/1p7OVAURwtFfB4ztx8bnHPQ)

旧版书籍的[github地址](https://github.com/huangz1990/redisbook)

![封面](/images/redisshejiyushixian.jpg)

这本书更多的是讲原理与实现
待我学会怎么用了再来补。。。

<!--more -->

# 一、数据结构与对象


### 1. 字符串

* redis构建了SDS(simple dynamic string)类型来存储可被修改的字符串值，其格式的定义如下:
    ```c++
    struct __attribute__ ((__packed__)) sdshdr32 {
        uint32_t len; /* used */
        uint32_t alloc; /* excluding the header and null terminator */
        unsigned char flags; /* 3 lsb of type, 5 unused bits */
        char buf[];
    };
    ```