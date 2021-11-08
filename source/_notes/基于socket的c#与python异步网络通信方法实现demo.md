---
title: 基于socket的c#与python异步网络通信方法实现demo
date: 2020-07-19 20:32:50
tags: 
---

[原文链接](https://blog.csdn.net/wz2671/article/details/107448828)

<!--more -->


## 1. 本文主要内容
初次接触网络通信部分内容时踩了不少坑，历经磕绊总算摸索出了靠谱有效的实现异步通信的解决方法，在此做简单记录，之后若有需要可以节约这段时间。

首先进行一下简要说明：
1. **异步网络通信**指的是客户端在发送请求等待接收数据时，不必一直阻塞直到收到服务端回复才能进行下一步处理，在发送完数据之后就可以执行其他操作了，等到接收到相应回复，再通过回调函数来处理消息内容。与之相对的就是**同步**消息收发策略。
2. 不管是何种语言，谁是服务端，谁是客户端，其收发消息时的流程步骤都是类似的，大体包括：根据ip和端口号创建socket，发送方对将数据打包写入socket，接收方解析数据并处理。
3. TCP之类的可靠传输协议，只能保证数据完整，有序的从传输方到接收方，并不管数据本身是什么，该交给那个方法处理，想要解析收到的数据，只有靠自己定义消息格式并建立相应的打包及解析方法才能识别具体是什么内容，对应哪条回复等等之类。

在我之前想用它来进行通信时，曾天真地以为我这儿把消息写到网络流里去了，那儿就应该收到这条消息的内容，可以直接处理了。
但实际上，虽然数据可以有序、完整的被接收，但是并不会每次就正好接收到一条另一端发送的完整消息，而是存在分包、粘包的情况，因此，无论是服务端，还是客户端，都要对该问题进行处理。

在本文中，以TCP为通信协议，c#端为客户端，向python服务端发起连接请求，然后服务器进行回复，客户端对回复内容再进行处理，那么该简单处理流程如下文所示。

***

## 2. 通信策略
* 为了让接收方知道这条消息的起止位置，在消息的头部加入一个4字节整型，用来标识这段消息的长度，假如我们需要发送字符串`Hello world!`消息给服务器，那么我们写入`socket`中的数据应如下表所示（实际传输的就最后一行的字节数组）：
<table border="1" cellspacing="0" bordercolor="#000000" width = "80%">
    <tr>
        <td> 0 </td> <td> 1 </td> <td> 2 </td> <td> 3 </td> <td> 4 </td> <td> 5 </td> <td> 6 </td> <td> 7 </td>
        <td> 8 </td> <td> 9 </td> <td> 10 </td> <td> 11 </td> <td> 12 </td> <td> 13 </td> <td> 14 </td> <td> 15 </td> </td>
    </tr>
    <tr>
        <th colspan="4"> 消息长度 </th>
        <th colspan="12"> 内容 </th>
    </tr>
      <tr>
        <th colspan="4"> 16 </th>
        <td> H</td> <td> e </td> <td> l </td> <td> l </td> <td> o </td> <td>   </td> <td> w </td> <td> o </td> <td> r </td> <td> l </td> <td> d</td> <td> ! </td> 
    </tr>
      <tr>
      <td> 16 </td> <td> 0 </td> <td> 0 </td> <td> 0 </td>  <td> 72</td> <td> 101 </td> <td> 108 </td> <td> 108 </td> <td> 111 </td> <td> 32 </td> <td> 119 </td> <td> 111 </td> <td> 114 </td> <td> 108 </td> <td> 100 </td> <td> 33 </td> 
    </tr>

* 接收方就需要根据首部的长度，判断当前消息的完整内容，如果当前接收内容小于消息长度，就继续接收直到这个消息完整，若大于消息长度，那么将这条消息的内容提取出来，将后面的消息进行合并再重新解析。

***
## 3. C#端收发数据
以下是c#端建立连接以及收发数据的示意代码：

```csharp
// NetworkDemo.cs
using System.Collections;
using System;
using System.IO;
using System.Net.Sockets;



public class NetworkDemo
{

    public String host = "127.0.0.1";
    public Int32 port = 2000;


    public Queue events;

    internal Boolean socketReady = false;

    byte[] receivedBuff;
    int receivedBuffSize = 2048;

    TcpClient tcpSocket;
    NetworkStream netstream;
    BinaryWriter writer;

    // 处理粘包，分包相关变量
    const int msgHeadLen = sizeof(int);
    int currDataLen = 0;      // 报文长度
    int currReceLen = 0;      // 报文内容接受不完整 currReceLen < currDataLen

    public NetworkDemo()
    {
        SetupSocket();
        receivedBuff = new byte[receivedBuffSize];
        Receive(receivedBuff, 0, receivedBuffSize, UnPackRawData);
        events = new Queue();
    }

    public void SetupSocket()
    {
        try
        {
            tcpSocket = new TcpClient(host, port);

            netstream = tcpSocket.GetStream();
            writer = new BinaryWriter(netstream);
            socketReady = true;
        }
        catch (Exception e)
        {
            Console.WriteLine("Socket error:" + e);
        }
    }

    public void CloseSocket()
    {
        if (!socketReady)
            return;
        writer.Close();
        netstream.Close();
        tcpSocket.Close();
        socketReady = false;
    }


    private bool IsSocketReady()
    {
        // 如果连接尚未创立，尝试建立新连接
        if (!socketReady)
        {
            SetupSocket();
        }
        return socketReady;
    }

    public void Send(byte[] data, int len)
    {
        if (!IsSocketReady())
            return;
        //Console.WriteLine(data);

        try
        { 
            writer.Write(len + sizeof(int));
            writer.Write(data, 0, len);     // 发送data[0 : len]
            writer.Flush();
        }
        catch (Exception e)
        {
            Console.WriteLine("Socket error:" + e);
            socketReady = false;
        }

    }

    public void Receive(byte[] rec_buffer, int offset, int len, AsyncCallback callback)
    {
        // 异步读取消息，callback函数是回调函数，收到数据后会调用它
        if (IsSocketReady())
            try
            { 
                netstream.BeginRead(rec_buffer, offset, len, callback, null);
            }
            catch (Exception e)
            {
                Console.WriteLine("Socket error:" + e);
                socketReady = false;
            }

    }

    public void UnPackRawData(IAsyncResult result)
    {
        // 从netstream中读到的数据个数
        int receiveLen = netstream.EndRead(result);
        receiveLen += currReceLen;    // 和之前未处理完的数据拼接
        currReceLen = 0;              // 每次有效的数据都是从头开始
        // 前4个字节是消息长度
        while (receiveLen > currReceLen)
        { 
            // 循环处理直至没有消息或只有一个不完整的消息
            if (receiveLen - currReceLen < msgHeadLen)
            {
                // 报文头部接收不完整，将它拷贝到头部
                // 重置已接收消息长度，并退出循环
                Array.Copy(receivedBuff, currReceLen, receivedBuff, 0, receiveLen-currDataLen);
                currReceLen = receiveLen - currReceLen;
                break;
            }
            else
            {
                // 头部完整，先解析报文长度
                currDataLen = BitConverter.ToInt32(receivedBuff, currReceLen);
                if (currDataLen > receivedBuffSize)
                {
                    // 当前消息大于缓冲区长度，待处理
                    Console.WriteLine("消息长度大于缓冲区长度");
                }
                else if (currReceLen + currDataLen > receiveLen)
                {
                    // 接收到的数据仍然不完整，继续异步调用接收数据
                    Array.Copy(receivedBuff, currReceLen, receivedBuff, 0, receiveLen - currReceLen);
                    currReceLen = receiveLen - currReceLen;
                    break;
                }
                else if (currReceLen + currDataLen == receiveLen)
                {
                    // 已接收到报文的长度和 报文的原始长度正好相等，将数据解析成事件
                    // 添加到事件队列中，并重新异步接受新数据
                    ShowReceivedData(receivedBuff, currReceLen+msgHeadLen, currDataLen- msgHeadLen);
                    currReceLen = 0;
                    break;
                }
                else
                {
                    // 接收到不止一条消息，逐个处理
                    ShowReceivedData(receivedBuff, currReceLen + msgHeadLen, currDataLen - msgHeadLen);
                    currReceLen += currDataLen;
                }
            }
        }

        // 不管有没有分包，继续接收（从之前已经缓冲位置开始）
        Receive(receivedBuff, currReceLen, receivedBuffSize - currReceLen, UnPackRawData);
    }

    public void ShowReceivedData(byte[] data, int offset, int len)
    {
        Console.WriteLine(System.Text.Encoding.ASCII.GetString(data, offset, len));
    }
}

```

```csharp
// main.cs
using System;
using System.Text;

class Program
{
    static void Main(string[] args)
    {
        double last_send_time = 0;
        double send_delay_time = 1e-6;
        string message = "Hello world!";

        byte[] send_buff = new byte[message.Length];
        Encoding.UTF8.GetBytes(message).CopyTo(send_buff, 0);
        NetworkDemo network = new NetworkDemo();

        while(true)
        {
            if (DateTime.Now.ToOADate() > last_send_time + send_delay_time)
            {
                last_send_time = DateTime.Now.ToOADate();
                network.Send(send_buff, send_buff.Length);
            }
        }
    }
}
```

***
## 4. python端收发数据
python端监听端口，等待客户端连接，收到消息之后进行回复，实现如下：
```python
# TestNet.py

# -*- coding: utf-8 -*-
import socket
import errno
import struct
import logging

logger = logging.getLogger(__name__)


class ServerBase(object):
    MAX_HOST_CLIENTS_INDEX = 0xfffe
    NET_CONNECTION_NEW = 0  # new connection
    NET_CONNECTION_LEAVE = 1  # lost connection
    NET_CONNECTION_DATA = 2  # data coming
    NET_HEAD_LENGTH_SIZE = 4  # 4 bytes little endian (x86)
    NET_HEAD_LENGTH_FORMAT = '<I'

    def __init__(self):
        super(ServerBase, self).__init__()
        self.socket = socket.socket()
        self.event = list()
        self.conns = dict()
        self.invalid_conns = list()			# 记录已经无效的连接

    def setup(self, ip='localhost', port=2000):
        self.socket.bind((ip, port))		# 监听2000端口
        self.socket.listen(self.MAX_HOST_CLIENTS_INDEX)
        self.socket.setblocking(False)

    def process(self):
        self._handle_conn()
        for conn_id, conn in self.conns.iteritems():
            self._handle_recv(conn)
        self._handle_leave()

    def _handle_recv(self, conn):
        remain_text = ''
        while True:
            data = None
            try:
                data = conn.recv(1024)
                if not data:        # 当收到空数据时，应为socket端开
                    self.invalid_conns.append(conn)
                    return -1
            except socket.error, (code, strerror):
                if code not in (errno.EINPROGRESS, errno.EALREADY, errno.EWOULDBLOCK):
                    self.invalid_conns.append(conn)
                    return -1
            if not data:
                break
            remain_text = self._pack_events(remain_text + data, id(conn))	# 将未处理的数据进行缓存

    def _pack_events(self, data, conn_id):
        # 将数据提取成一个个事件，进行封装
        recv_len = len(data)
        curr_len = 0
        while True:
            if recv_len - curr_len < self.NET_HEAD_LENGTH_SIZE:
                return data[curr_len:]
            data_len = struct.unpack(self.NET_HEAD_LENGTH_FORMAT, data[curr_len: curr_len + self.NET_HEAD_LENGTH_SIZE])[0]
            if recv_len < curr_len + data_len:
                return data[curr_len:]
            curr_len += self.NET_HEAD_LENGTH_SIZE
            data_len -= self.NET_HEAD_LENGTH_SIZE
            self.event.append((self.NET_CONNECTION_DATA, conn_id, data[curr_len:curr_len + data_len]))
            self.send(conn_id, 'REP: ' + data[curr_len:curr_len + data_len])		# 对客户端进行简单回复
            curr_len += data_len

    def _handle_conn(self):
        try:
            conn, addr = self.socket.accept()
            conn.setblocking(False)
            # self.inputs.append(conn)
            print(conn, addr)
            self.conns[id(conn)] = conn
        except Exception as e:
            # print e
            pass

    def _handle_leave(self):
        for conn in self.invalid_conns:
            conn_id = id(conn)
            if conn_id in self.conns:
                conn = self.conns.pop(conn_id)
                try:
                    print ('leave {}'.format(conn.getpeername()))
                    conn.close()
                except Exception as e:
                    print e

    def send(self, conn_id, data):
        conn = self.conns.get(conn_id)
        if conn:
            data = struct.pack(self.NET_HEAD_LENGTH_FORMAT, len(data) + self.NET_HEAD_LENGTH_SIZE) + data
            try:
                conn.send(data)
            except socket.error, (code, strerror):
                logger.info('conn_id: {} sending data failedd'.format(conn_id))
                conn.close()

        else:
            logger.info('conn_id: {} not found'.format(conn_id))

    def close(self):
        for conn_id, conn in self.conns.iteritems():
            conn.close()
        self.socket.close()

    @property
    def has_events(self):
        if self.event:
            return True
        else:
            return False

    def get_next_event(self):
        return self.event.pop(0)

```

```python
# serverTest.py

# -*- coding: utf-8 -*-

from TestNet import ServerBase

if __name__ == "__main__":
    s = ServerBase()
    s.setup()
    while True:
        s.process()
        while s.has_events:
            event = s.get_next_event()		# event 标识(事件，客户端主机号，内容)
            print(event[2])		#收到的消息内容
```

***
## 5. 总结
以上，就可以实现服务端和客户端的通信了，先启动服务端，再启动客户端。
客户端会定时向服务端发送`Hello World!`，服务端会在消息之前加上`REP: `进行回复，两端都会打印各自收到的消息内容。
服务端部分异常情况还需要进一步处理，例如连接断开时的一些异常。
