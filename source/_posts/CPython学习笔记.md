---
title: CPython学习笔记
date: 2021-04-07 23:44:47
tags: python笔记
---

[参考资料](https://pg.ucsd.edu/cpython-internals.htm)  
[youtube视频](https://www.youtube.com/playlist?list=PLzV58Zm8FuBL6OAv1Yu6AwXZrnsFbbR0S)  
[百度云(提取码：2twh)](https://pan.baidu.com/s/1SmWNpCrY3kfiKDxAdI8roA)
[python2.7源码链接](https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz)

<!--more -->

# 一、Bytes in the Machine Inside the CPython interpreter

### 1. python interpreter (python解释器)

* python 执行代码时会分为四个阶段
    1. Lexing (词法分析)
    2. Parsing (句法分析) 包括上一步，所做的事情是将Python源码分析成抽象语法树(AST)
    3. Compiling 将抽象语法树转换成字节码，只做的一小部分事情
    4. Interpreting 解释器会执行字节码的逻辑
* python 虚拟机是堆栈机(stack machine)，并不会读写各种内存，而是基于堆栈执行
* `BYTECODE`字节码通常被称为python代码的中间表示形式
* 一个求余的示例
    ```python
    >>> def mod(a, b):
    ...     ans = a % b
    ...     return ans
    ...
    >>> dis.dis(mod)
    2           0 LOAD_FAST                0 (a)
                2 LOAD_FAST                1 (b)
                4 BINARY_MODULO
                6 STORE_FAST               2 (ans)

    3           8 LOAD_FAST                2 (ans)
                10 RETURN_VALUE
    >>>
    ```
* 以上字节码中，最左边的数字（2, 3）表示在源码中的行数，第二列表示字节码中第几位，第三列表示的是字节码的通俗名字，第四列是表示参数的序号，第五列表示参数名。
* `LOAD_FAST`会将后面的变量压入栈中，**注意**，求余运算`BINARY_MODULO`本身是不需要参数的，因为参数全都在栈里了。
* 这儿的栈与调用栈并不是同一概念，每个调用栈被成为`frame`，数据栈存在了调用栈中，`RETURE_VALUE`语句，就是将数据从一个`frame: mod`中传入`frame: main`中。
* python 虚拟机
    * A collection of frames
    * Data stacks on frames
    * A way to run frames
* python 解释器原来主要是一个超大的`switch...case...`，[源码链接](https://hg.python.org/cpython/file/tip/Python/ceval.c#l1838)，根据各个操作码执行相应的逻辑。
* 例如`LOAD_FAST`和`BINARY_MODULO`python3.9实现
    ```cpp
    // [1849:1859]
    case TARGET(LOAD_FAST): {
        PyObject *value = GETLOCAL(oparg);
        if (value == NULL) {
            format_exc_check_arg(tstate, PyExc_UnboundLocalError,
                                    UNBOUNDLOCAL_ERROR_MSG,
                                    PyTuple_GetItem(co->co_varnames, oparg));
            goto error;
        }
        Py_INCREF(value);
        PUSH(value);        // 会将数据压至数据栈中
        DISPATCH();
    }

    // [2038:2056]
    case TARGET(BINARY_MODULO): {
        PyObject *divisor = POP();
        PyObject *dividend = TOP();
        PyObject *res;
        // 这儿本质类似于类型检查
        if (PyUnicode_CheckExact(dividend) && (
                !PyUnicode_Check(divisor) || PyUnicode_CheckExact(divisor))) {
            // fast path; string formatting, but not if the RHS is a str subclass
            // (see issue28598)
            res = PyUnicode_Format(dividend, divisor);
        } else {
            res = PyNumber_Remainder(dividend, divisor);
        }
        Py_DECREF(divisor);
        Py_DECREF(dividend);
        SET_TOP(res);
        if (res == NULL)
            goto error;
        DISPATCH();
    }
    ```
* 如果python只有一个数据栈，那么生成器的特性就无法实现
* 由于`python`的动态类型特性，想要进一步地优化性能是一件很困难的事情，在python2中大多数是个大大的`switch...case...`，在python3中会有部分优化，源码中的部分说明如下：大致意思是，会根据cpu流水线的feature，进行优化。
```cpp
/* Computed GOTOs, or
       the-optimization-commonly-but-improperly-known-as-"threaded code"
   using gcc's labels-as-values extension
   (http://gcc.gnu.org/onlinedocs/gcc/Labels-as-Values.html).

   The traditional bytecode evaluation loop uses a "switch" statement, which
   decent compilers will optimize as a single indirect branch instruction
   combined with a lookup table of jump addresses. However, since the
   indirect jump instruction is shared by all opcodes, the CPU will have a
   hard time making the right prediction for where to jump next (actually,
   it will be always wrong except in the uncommon case of a sequence of
   several identical opcodes).

   "Threaded code" in contrast, uses an explicit jump table and an explicit
   indirect jump instruction at the end of each opcode. Since the jump
   instruction is at a different address for each opcode, the CPU will make a
   separate prediction for each of these instructions, which is equivalent to
   predicting the second opcode of each opcode pair. These predictions have
   a much better chance to turn out valid, especially in small bytecode loops.

   A mispredicted branch on a modern CPU flushes the whole pipeline and
   can cost several CPU cycles (depending on the pipeline depth),
   and potentially many more instructions (depending on the pipeline width).
   A correctly predicted branch, however, is nearly free.

   At the time of this writing, the "threaded code" version is up to 15-20%
   faster than the normal "switch" version, depending on the compiler and the
   CPU architecture.

   We disable the optimization if DYNAMIC_EXECUTION_PROFILE is defined,
   because it would render the measurements invalid.


   NOTE: care must be taken that the compiler doesn't try to "optimize" the
   indirect jumps by sharing them between all opcodes. Such optimizations
   can be disabled on gcc by using the -fno-gcse flag (or possibly
   -fno-crossjumping).
*/
```


# Lecture 1. Interpreter and source code overview

### 1. python解释器说明
* CPython是标准的python解释器，采用c语言实现。PyPy是用python实现的；Jython是用java写的；Skulpt是用javascript写的，因此可以再网页浏览器里使用。
* 讲述了一些基本概念，xxx.py是python的源码，python解释器可以执行它并作出对应输出。而python解释器是cpython经过g++等编辑器编译出来的可执行程序，我们要研究的就是cpython的实现思路之类。
* 解释器执行的是字节码，并不是python的源码，编译成字节码的过程是个比较标准的过程，视频说不会太过关注，解释器部分才是真正python的动态之处

### 2. 源码概览
* [源码链接](https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz)
* `/Include`目录下是所有的头文件，里面定义了所有的接口
* `/Objects`目录下所有的`.c`文件都对应了python中的一种对象类型，例如`listobject.c`就是对应的`list`
* `/Python`目录下是运行时主要用的一些模块
* `/Modules`目录下是一些内置模块的实现如`import operator`，里面是用c语言实现的
* `/Lib`目录下是用python实现的一些内置模块

* `/Include/opcode.h`文件下定义了python中所有的操作码（字节码）例如`LOAD_FAST`之类
* `/Python/ceval.c`中是python的主循环所在位置，在源码的1069行起，它是一个无限的循环，每次解释一个字节码，就会调度一次循环
```c++
// line[1069-1086]
    for (;;) {
#ifdef WITH_TSC
        if (inst1 == 0) {
            /* Almost surely, the opcode executed a break
               or a continue, preventing inst1 from being set
               on the way out of the loop.
            */
            READ_TIMESTAMP(inst1);
            loop1 = inst1;
        }
        dump_tsc(opcode, ticked, inst0, inst1, loop0, loop1,
                 intr0, intr1);
        ticked = 0;
        inst1 = 0;
        intr0 = 0;
        intr1 = 0;
        READ_TIMESTAMP(loop0);
#endif
```
* 可以随意修改cpython源码，进行编译，就能使用自己独家定制的python解释器了


***

# Lecture 2. Opcodes and main interpreter loop

### 1. `compile`内置函数
* 由于切python2环境过于麻烦，此处用的都是python3
* test.py
    ```python
    x = 1
    y = 2
    z = x + y
    print(z)
    ```
* 使用`compile('test.py', 'test.py', 'exec')`编译该模块，返回一个`code object`
    ```python
    >>>> c.co_code
    b'e\x00j\x01\x01\x00d\x00S\x00'
    >>> [byte for byte in c.co_code]       # python
    [101, 0, 106, 1, 1, 0, 100, 0, 83, 0]
    ```
    ```bash
    PS D:\CODE\Python-2.7.18> python -m dis test.py
    1           0 LOAD_CONST               0 (1)
                2 STORE_NAME               0 (x)

    2           4 LOAD_CONST               1 (2)
                6 STORE_NAME               1 (y)

    3           8 LOAD_NAME                0 (x)
                10 LOAD_NAME                1 (y)
                12 BINARY_ADD
                14 STORE_NAME               2 (z)

    4          16 LOAD_NAME                3 (print)
                18 LOAD_NAME                2 (z)
                20 CALL_FUNCTION            1
                22 POP_TOP
                24 LOAD_CONST               2 (None)
                26 RETURN_VALUE
    ```
* 在`opcode.h`中，从94行`HAVE_ARGUMENT`起，下面的字节码是需要接受参数的了