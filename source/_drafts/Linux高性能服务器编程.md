---
title: Linux高性能服务器编程
date: 2021-11-07 12:51:43
tags:
---

![封面](/images/linuxgaoxingneng.png)

<!--more -->


# 一、TCP/IP协议详解

### 1. TCP/IP协议族
### 2. IP协议详解
### 3. TCP协议详解
### 4. TCP/IP通信案例：访问Internet上的Web服务器

# 二、深入解析高性能服务器编程

### 5. socket地址的api

* 主机字节序和网络字节序
    * 主机字节序就是指 数据在内存的排列顺序问题，小端字节序是指整数的高字节存储在内存的高地址出，低位字节存储在内存的低地址处。大端字节序相反
    ```c
    union
    {
        int value;
        char union_bytes[sizeof(int)];
    } test;
    // 小端字节序：value = 0X01020304 union_bytes: [4, 3, 2, 1]
    ```
    * 网络字节序：用来保证发送端与接受端能正确解释数据的。发送端总是把要发送的数据转化成大端字节序数据后再发送。（因此大端字节序也称为网络字节序）
    ```c
    // 以下方法可以用来转化位网络字节序数据。
    include<netinet/in.h>
    unsigned long int htonl(unsigned long int hostlong);
    unsigned short int htons(unsigned short int hostshort);
    unsigned long int ntohl(unsigned long int netlong);
    unsigned short int ntohs(unsigned short int netshort);
    ```
* 