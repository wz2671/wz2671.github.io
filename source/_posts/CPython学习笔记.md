---
title: CPython学习笔记
date: 2021-04-07 23:44:47
tags: python笔记
---

[参考资料](https://pg.ucsd.edu/cpython-internals.htm)
[youtube视频](https://www.youtube.com/playlist?list=PLzV58Zm8FuBL6OAv1Yu6AwXZrnsFbbR0S)


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