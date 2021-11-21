---
title: Linux高性能服务器编程
date: 2021-11-07 12:51:43
tags:
---

![封面](/images/linuxgaoxingneng.png)
[linux源码阅读](https://elixir.bootlin.com/linux/latest/source)

<!--more -->


# 一、TCP/IP协议详解

### 1. TCP/IP协议族
### 2. IP协议详解
### 3. TCP协议详解
### 4. TCP/IP通信案例：访问Internet上的Web服务器

# 二、深入解析高性能服务器编程

### 5.1 socket地址的api

* 主机字节序和网络字节序
    * 主机字节序就是指 数据在内存的排列顺序问题，小端字节序是指整数的高字节存储在内存的高地址出，低位字节存储在内存的低地址处。大端字节序相反
    ```c++
    union
    {
        int value;
        char union_bytes[sizeof(int)];
    } test;
    // 小端字节序：value = 0X01020304 union_bytes: [4, 3, 2, 1]
    ```
    * 网络字节序：用来保证发送端与接受端能正确解释数据的。发送端总是把要发送的数据转化成大端字节序数据后再发送。（因此大端字节序也称为网络字节序）
    ```c++
    // 以下方法可以用来转化位网络字节序数据。
    include<netinet/in.h>
    unsigned long int htonl(unsigned long int hostlong);
    unsigned short int htons(unsigned short int hostshort);
    unsigned long int ntohl(unsigned long int netlong);
    unsigned short int ntohs(unsigned short int netshort);
    ```
* 通用的socket地址，**所有socket编程接口使用的地址参数的类型都是sockaddr**
    * `socket`地址的结构体一般是`sockaddr`，其定义如下：
        ```c++
        include <bits/socket.h>
        struct sockaddr
        {
            sa_family_t sa_family;      // 地址族类型，如TCP/IPv4协议族（PF_INET）对应的地址族为`AF_INET`
            char sa_data[14];           // 存放socket地址的值，如PF_INET为16bit端口号和32bit地址，共6字节
        }
        ```
    * `sockaddr`只有14字节数据，为了容纳多数协议族的地址值，有个新的结构体`sockaddr_storage`
        ```c++
        include <bits/socket.h>
        struct sockaddr_storage
        {
            sa_family_t sa_family;
            unsigned long int__sa_align;
            char __ss_padding[128-sizeof(__ss_align)];
        }
        ```
* 专用的socket地址，为了方便的使用上面的结构体，为各个协议族专门提供的，如**TCP/IP协议族中的IPv4的专用地址结构体**:
    ```c++
    struct sockaddr_in
    {
        sa_family_t sin_family;     // 地址族
        u_int16_t sin_prot;         // 端口号
        struct in_addr sin_addr;    // IPv4地址结构体 };
    struct in_addr {
        u_int32_t s_addr;   // IPv4地址
    };
    ```
* ip地址转换函数，点分**十进制字符串**转化为**网络字节序整数**表示的IPv4地址。
    ```c++
    #include <arpa/inet.h>
    in_addr_t inet_addr(const char* strptr);        // 将点分串转为整数
    int inet_aton(const cahr* cp, struct in_addr* inp); // inp用来接受结果
    char *inet_ntoa(struct in_addr in);             // 整数转为字符串，但不可重入，返回的结果指向一块静态内存
    // 以下还适用于IPv6地址
    int inet_pton(int af, const char* src, void* dst);
    const char* inet_ntop(int af, const void* src, char* dst, socklen_t cnt);   // cnt指定目标存储单元大小
    // ipv4和ipv6地址大小
    #include<netinet/in.h>
    #define INET_ADDRSTRLEN 16
    #define INET6_ADDRSTRLEN 46
    ```

### 5.2 socket的使用

* 创建socket
    ```c++
    #include<sys/types.h>
    #include<sys/socket.h>
    int socket(int domain, int type, int protocol);
    ```
    * `domain`参数为协议族，如Ipv4`PF_INET`
    * `type`为服务类型。如`SOCK_STREAM`(TCP协议),`SOCK_DGRAM`(UPD协议)；`SOCK_NONBLOCK`（非阻塞），`SOCK_CLOEXEC`(fork后子进程关闭)（和前面的作与运算）。
    * `protocol`具体的协议，通常为默认协议。
* 命名socket，一般由服务端程序发起。
    ```c++
    #include<sys/types.h>
    #include<sys/socket.h>
    int bind(int sockfd, const struct sockaddr* my_addr, socklen_t addrlen);
    ```
    * 该方法将`my_addr`所指的`socket`地址分配给未命名的`sockfd`文件描述符，`addrlen`参数指的是`socket`地址的长度。
    * 常见错误：`EACCES`绑定受保护的地址(0-1023端口)，`EADDRINUSE`绑定的地址正在使用。
* 监听socket
    ```c++
    #include<sys/socket.h>
    int listen(int sockfd, int backlog);
    ```
    * `sockfd`是已经绑定了`socket`地址的文件描述符，`backlog`表示内核监听队列的最大长度。超过该值，服务端将不受理新的客户端连接(2.2版本后是处于完全连接状态的socket的上限)。
* 接受连接
    ```c++
    #include<sys/types.h>
    #include<sys/socket.h>
    int accept(int sockfd, const struct sockaddr* my_addr, socklen_t *addrlen);
    ```
    * 文中还简单的进行了个实验，判断在连接有异常的情况下，`accept`函数的执行结果，结果如下：无论客户端出现了何异常，并不会影响`accept`的结果，只会影响连接的状态。
    * 若服务端在sleep时，客户端断开，服务端状态会置为`CLOSE_WAIT`，客户端状态置为`FIN_WAIT2`；服务端苏醒过来后，服务端关闭连接，客户端状态置为`TIME_WAIT`。
* 发起连接
    ```c++
    #include<sys/types.h>
    #include<sys/socket.h>
    int connect(int sockfd, const struct sockaddr* serv_addr, socklen_t addrlen);
    ```
    * `serv_addr`参数是服务器监听的socket地址。
    * 常见异常：`ECONNREFUSED`目标端口不存在。`ETIMEDOUT`连接超时。
* 关闭连接
    ```c++
    #include<unistd.h>
    int close(int fd);  // 据说只是将引用减1(子进程可能还有引用)
    /////////////////
    #include<sys/socket.h>
    int shutdown(int sockfd, int howto);    // 立即终止连接
    ```
    * `fd`和`sockfd`都是带关闭的socket。`howto`可以选择关闭读或者写或者全关。

### 5.3 TCP数据读写

* 可使用`sudo tcpdump-ntx-i eth0 port 23456`之类的命令来抓取客户端和服务端交换的tcp报文段。

* TPC数据读写接口
    ```c++
    #include<sys/tyeps.h>
    #include<sys/socket.h>
    ssize_t recv(int sockfd, void* buff, size_t len, int flags);
    ssize_t send(int sockfs, const void* buff, size_t len, int flags);
    ```

* `recv`函数，`buff`和`len`分别表示缓冲区的位置和大小，`recv`成功时返回**读取到的长度**，出错时返回`-1`,返回`0`意味着通信对方已经关闭连接了。
* `send`函数，`send`成功时返回实际写入的数据的长度，失败则返回`-1`并设置`errno`。
* 参数中的`flags`，是一个控制参数，可以为多个标志位的逻辑或，例如控制接收发送紧急数据，操作是否是阻塞的等。


### 5.4 UPD数据读写

* UPD数据读写接口
    ```c++
    #include<sys/types.h>
    #include<sys/socket.h>
    ssize_t recvfrom(int sockfd, void* buff, size_t len, int flags, struct sockaddr* src_addr, socklen_t* addrlen);
    ssize_t sendto(int sockfs, const void* buff, size_t len, int flags, const struct sockaddr* dest_addr, socklen_t addr_len);
    ```

* `recvfrom`函数，udp通信没有连接的概念，每次读数据时都需要发送端的`socket`地址(`src_addr`)，`addrlen`是该地址的长度。其他参数与返回值和`recv`函数一致。
* `sendto`函数，`dest_addr`指的是接受端的地址。 其他值与`send`接口一致。
* 这两个接口也可以用于面向连接的socket读写，只需要把最后两个参数置为None即可。

### 5.5 通用数据读写

* 通用数据读写接口
    ```c++
    #include<sys/socket.h>
    ssize_t recvmsg(int sockfd, struct msghdr* msg, int flags);
    ssize_t sendmsg(int sockfd, struct msghdr* msg, int flags);
    ```
* 其中，`msghdr`结构体定义如下
    ```c++
    struct iovec
    {
        void* iov_base; // 内存起始地址
        size_t iov_len; // 这块内存的长度
    }
    struct msghdr
    {
        void* msg_name; // socket地址
        socklen_t msg_namelen; // socket地址的长度
        struct iovec* msg_iov; // 分散的内存块
        int msg_iovlen;        // 分散内存块的数量
        void* msg_control;      // 指向辅助数据的起始位置   (十三章讨论)
        socklen_t msg_controllen;   // 辅助数据的大小
        int msg_flags;      // 复制函数中的flags参数，并在调用过程中更新
    }
    ```

* 带外标记，表示有紧急数据，可以通过系统`sockatmark`来判断读取到的数据是否是带外数据。

### 5.6 socket选项

*  读取和设置socket文件描述符属性的方法：
    ```c++
    #include<sys/socket.h>
    int getsockopt(int sockfd, int level, int option_name, void* option_value, socklen_t* restrict option_len);
    int setsockopt(int sockfd, int level, int option_name, const void* option_value, socklen_t option_len);
    ```
* 其中`level`表示操作的协议的属性，比如`IPv4`, `IPv6`, `TCP`等。`option_name`表示选项的名字，后面的表示选项的值和长度。
* 部分的选项只能在：**服务器监听前或客户端连接前**设置，包括`SO_DEBUG`, `SO_DONTROUTE`, `SO_KEEPALIVE`, `SO_LINGER`, `SO_OOBINLINE`, `SO_RECVBUF`, `SO_REVLOWAT`, `SO_SNDBUF`, `SO_SNDLOWAT`, `TCP_MAXSEG`, `TCP_NODELAY`。

部分选项简述：

* `SO_REUSEADDR`: 可以快速回收socket地址，即使它处于`TIME_WAIT`状态。
* `SO_RCVBUF`和`SO_SNDBUF`: 表示tcp接受缓冲区和发送缓冲区的大小。(但是系统会处理这个大小)
* `SO_RCVLOWAT`和`SO_SNDLOWAT`: （低水位标记）判断socket是否可读或可写。(默认为1字节)
* `SO_LINGER`: 可以控制关闭tcp连接时的行为

### 5.7 信息获取

* 获取socket连接的地址信息有一下方法，地址将存储与`address`参数制定的内存中。成功时返回0，失败返回-1。
    ```c++
    #include<sys/socket.h>
    int getsockname(int sockfd, struct sockaddr* address, socklen_t* address_len);
    int getpeername(int sockfd, struct sockaddr* address, socklen_t* address_len);
    ```

* `gethostbyname`可以根据主机名获取主机的完整信息。`gethostbyaddr`可以根据IP地址获取主机的完整信息。两者返回的是`hostent`结构体的指针，定义如下：
    ```c++
    #include<netdb.h>
    struct hostent
    {
        char* h_name;       //主机名
        char** h_aliases;   // 主机名列表
        int h_addrtype;     // 地址类型
        int h_length;       // 地址长度
        char** h_addr_list;     // 网络字节序 的主机IPO地址列表
    }
    ```
* `getservberbyname`根据名称获取某个服务的完整信息。`getservbyport`函数根据端口号获取某个服务的完整信息。(/etc/services)，两者返回的是`servent`结构体指针，定义如下：
    ```c++
    #include<netdb.h>
    struct servent
    {
        char* s_name;       // 服务名称
        char** s_aliases;   // 服务的别名列表
        int s_port;       // 端口列表
        char* s_proto;     // 服务类型(tcp/udp)
    }
    ```
* `getaddrinfo`可以通过主机名获得IP地址，也能通过服务名获得端口号。
* `getnameinfo`可以通过socket地址获得以字符串表示的主机名。
* `strerror`函数可以将错误码转换成易读的字符串形式。

