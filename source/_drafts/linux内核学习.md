---
title: linux内核学习
date: 2021-08-28 12:22:05
tags: 服务端开发
---

最初是想研究学习一下`tcp`的实现细节，直接来看linux内核的源码了。

[源码](https://github.com/torvalds/linux)
参考书籍: [linux内核源码剖析]()
<!--more -->


# 1. 网络相关
* `socket`位于应用程序和协议栈之间，对应用程序屏蔽了与协议相关实现的具体细节。为应用程序提供了一个访问网络和进程间通信的通用接口。
* 它的结构体定义在`include/linux/net.h`中，如下所示：
```c++
/**
 *  struct socket - general BSD socket
 *  @state: socket state (%SS_CONNECTED, etc)
 *  @type: socket type (%SOCK_STREAM, etc)
 *  @flags: socket flags (%SOCK_NOSPACE, etc)
 *  @ops: protocol specific socket operations
 *  @file: File back pointer for gc
 *  @sk: internal networking protocol agnostic socket representation
 *  @wq: wait queue for several uses
 */
struct socket {
    socket_state            state;  // 套接口的状态
    short                   type;   // 套接口类型
    unsigned long           flags;  // 标志位
    struct file             *file;  // 相关的file结构指针
    struct sock             *sk;    // 指向传输控制块
    const struct proto_ops  *ops;   // 用来将套接口层系统调用映射到相应的传输层协议实现。
    struct socket_wq        wq;     // 等待该套解耦的进程队列
};
```
