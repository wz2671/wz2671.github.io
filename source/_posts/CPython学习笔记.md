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
* 使用`compile(open('test.py').read(), 'test.py', 'exec')`编译该模块，返回一个`code object`。  
    以下两部分是对应的，每个字节对应的就是一条操作码或者参数，`test.py`中的内容编译过后就是总长为28的字节数组(`co_code`)
    ```python
    >>> compile(open("test.py").read(), "test.py", 'exec')
    <code object <module> at 0x000001A131B76190, file "test.py", line 1>
    >>> _.co_code
    b'd\x00Z\x00d\x01Z\x01e\x00e\x01\x17\x00Z\x02e\x03e\x02\x83\x01\x01\x00d\x02S\x00'
    >>> [byte for byte in _]
    [100, 0, 90, 0, 100, 1, 90, 1, 101, 0, 101, 1, 23, 0, 90, 2, 101, 3, 101, 2, 131, 1, 1, 0, 100, 2, 83, 0]
    ```
    ```bash
    PS D:\CODE\Python-2.7.18> python -m dis test.py
    1           0 LOAD_CONST               0 (1)        # 这儿LOAD_CONST占一字节(100)，参数一字节，共两字节
                2 STORE_NAME               0 (x)        # STORE_NAME从第三字节开始(90)

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
* **在教程中，上面说的有点问题**，一开始使用`compile('test.py', 'test.py', 'exec')`实际编译的是`test.py`这条语句。(后来纠正了)
* 在`opcode.h`中，从94行`HAVE_ARGUMENT`起，下面的字节码是需要接受参数的了
* 视频里说第三列的数字表示在变量栈(value stack)里的顺序

### 2. `PyEval_EvalFrameEx`
* 是一个超长的函数`line[689-3364]`，它就是执行python源码的主要函数，里面有个指针`stack_pointer`就是存的value stack
* 先定义了一些操作的宏定义，例如压栈出栈等
    ```c++
    // line[883-975]
    #define PUSH(v)         { (void)(BASIC_PUSH(v), \
                            lltrace && prtrace(TOP(), "push")); \
                            assert(STACK_LEVEL() <= co->co_stacksize); }
    #define POP()           ((void)(lltrace && prtrace(TOP(), "pop")), \
                            BASIC_POP())
    ```
* 它的参数是`PyFrameObject`，指的是第一节中的`frame`，其中存储了各个字节码，参数等
    ```c++
    // line[1024-1029]
    co = f->f_code;
    names = co->co_names;
    consts = co->co_consts;
    fastlocals = f->f_localsplus;
    freevars = f->f_localsplus + co->co_nlocals;
    first_instr = (unsigned char*) PyString_AS_STRING(co->co_code);
    ```
* 大大的循环从`line[1069]`开始`for (;;)`，其中`WITH_TSC`指的是`Timestamp counter`，用来评估程序跑的有多快。
* 从`line[1211]`行起，就是大大的`switch...case...`，分别遍历每个操作符，并执行对应的操作，循环结束的部分如下所示，会跳到`fast_block_end`部分
    ```c++
    // line[2100-2105]
    TARGET_NOARG(RETURN_VALUE)
    {
        retval = POP();
        why = WHY_RETURN;
        goto fast_block_end;
    }
    // line[2852-2856]
    TARGET_NOARG(BREAK_LOOP)
    {
        why = WHY_BREAK;
        goto fast_block_end;
    }

    // line[2858-2867]
    TARGET(CONTINUE_LOOP)
    {
        retval = PyInt_FromLong(oparg);
        if (!retval) {
            x = NULL;
            break;
        }
        why = WHY_CONTINUE;
        goto fast_block_end;
    }
    ```
* 之后会做一些清理的工作，直到`line[3363]`行`return retval`返回结果

***


# Lecture 3. Frames, functions calls, and scope

### 1. `Frames`

* `PyEval_EvalFrameEx`是之前所说的执行字节码的主入口，他接受一个`PyFrameObject`的指针，这个指针指向的就是一个`frame`对象。

* 每个`frame`都包含一段可以执行的逻辑，也就是`code_object`，还有相关的运行环境如全局变量和局部变量等，它的具体定义如下所示，在文件`Include/frameobject.h`中
    ```c++
    typedef struct _frame {
        PyObject_VAR_HEAD
        struct _frame *f_back;	/* previous frame, or NULL */       // 存储了调用它的上一个frame
        PyCodeObject *f_code;	/* code segment */                  // 字节对象
        PyObject *f_builtins;	/* builtin symbol table (PyDictObject) */
        PyObject *f_globals;	/* global symbol table (PyDictObject) */
        PyObject *f_locals;		/* local symbol table (any mapping) */
        PyObject **f_valuestack;	/* points after the last local */       // 拥有一个独立的数据栈
        /* Next free slot in f_valuestack.  Frame creation sets to f_valuestack.
        Frame evaluation usually NULLs it, but a frame that yields sets it
        to the current stack top. */
        PyObject **f_stacktop;
        PyObject *f_trace;		/* Trace function */

        /* If an exception is raised in this frame, the next three are used to
        * record the exception info (if any) originally in the thread state.  See
        * comments before set_exc_info() -- it's not obvious.
        * Invariant:  if _type is NULL, then so are _value and _traceback.
        * Desired invariant:  all three are NULL, or all three are non-NULL.  That
        * one isn't currently true, but "should be".
        */
        PyObject *f_exc_type, *f_exc_value, *f_exc_traceback;

        PyThreadState *f_tstate;
        int f_lasti;		/* Last instruction if called */
        /* Call PyFrame_GetLineNumber() instead of reading this field
        directly.  As of 2.3 f_lineno is only valid when tracing is
        active (i.e. when f_trace is set).  At other times we use
        PyCode_Addr2Line to calculate the line from the current
        bytecode index. */
        int f_lineno;		/* Current line number */
        int f_iblock;		/* index in f_blockstack */
        PyTryBlock f_blockstack[CO_MAXBLOCKS]; /* for try and loop blocks */
        PyObject *f_localsplus[1];	/* locals+stack, dynamically sized */       // 动态创建的一个数据栈
    } PyFrameObject;
    ```

* 每个函数都会对应一个`code_object`，通过编译以下代码，可以看到`code object`被存到了名为`func`的变量里了，它也包含字节码，是一段独立的可执行的逻辑
    ```python
    def fun(x):
        a = x
        print(2 * a)
    ```
    ```bash
    PS D:\CODE\Python-2.7.18> python -m dis .\test.py
    2           0 LOAD_CONST               0 (<code object fun at 0x000001872E049920, file ".\test.py", line 2>)
                2 LOAD_CONST               1 ('fun')
                4 MAKE_FUNCTION            0
                6 STORE_NAME               0 (fun)
                8 LOAD_CONST               2 (None)
                10 RETURN_VALUE

    Disassembly of <code object fun at 0x000001872E049920, file ".\test.py", line 2>:
    3           0 LOAD_FAST                0 (x)
                2 STORE_FAST               1 (a)

    4           4 LOAD_GLOBAL              0 (print)
                6 LOAD_CONST               1 (2)
                8 LOAD_FAST                1 (a)
                10 BINARY_MULTIPLY
                12 CALL_FUNCTION            1
                14 POP_TOP
                16 LOAD_CONST               0 (None)
                18 RETURN_VALUE
    PS D:\CODE\Python-2.7.18>ash
    ```
* `code_object`定义在了`Include/code.h`之中，具体成员变量如下所示
    ```c++
    /* Bytecode object */
    typedef struct {
        PyObject_HEAD
        int co_argcount;		/* #arguments, except *args */
        int co_nlocals;		/* #local variables */
        int co_stacksize;		/* #entries needed for evaluation stack */
        int co_flags;		/* CO_..., see below */
        PyObject *co_code;		/* instruction opcodes */       // 原始的操作码
        PyObject *co_consts;	/* list (constants used) */
        PyObject *co_names;		/* list of strings (names used) */
        PyObject *co_varnames;	/* tuple of strings (local variable names) */   //变量名之类
        PyObject *co_freevars;	/* tuple of strings (free variable names) */    // 自由变量
        PyObject *co_cellvars;      /* tuple of strings (cell variable names) */
        /* The rest doesn't count for hash/cmp */
        PyObject *co_filename;	/* string (where it was loaded from) */
        PyObject *co_name;		/* string (name, for reference) */
        int co_firstlineno;		/* first source line number */
        PyObject *co_lnotab;	/* string (encoding addr<->lineno mapping) See
                    Objects/lnotab_notes.txt for details. */
        void *co_zombieframe;     /* for optimization only (see frameobject.c) */
        PyObject *co_weakreflist;   /* to support weakrefs to code objects */
    } PyCodeObject;
    ```

* 一些概念区分:
    * `code_object`，它存储的了原始的字节码，和一些变量名之类。
    * `function`持有一个`code_object`，同时拥有执行该`code_object`的环境`environment`，它时静态的数据。
    * `frame`是`function`在运行时的对象，它是动态的。如下图所示，`fact`只拥有一个`function`，但是在运行时可以拥有多个`frame`，每个`frame`拥有数据自己的数据栈。![frame_and_function](/images/cpython/frame_and_function.png)

* `CALL_FUNCTION`字节码的实现只是调用函数，具体实现在`call_function`函数里的`fast_function`中。
    ```c++
    // line[3005-3019]
    TARGET(CALL_FUNCTION)
    {
        PyObject **sp;
        PCALL(PCALL_ALL);
        sp = stack_pointer;             
    #ifdef WITH_TSC
        x = call_function(&sp, oparg, &intr0, &intr1);
    #else
        x = call_function(&sp, oparg);  //  执行函数，获取返回值
    #endif
        stack_pointer = sp;             //
        PUSH(x);                        // 返回结果压栈
        if (x != NULL) DISPATCH();
        break;
    }

    // line[4334-4401]
    static PyObject *
    call_function(PyObject ***pp_stack, int oparg
    #ifdef WITH_TSC
                    , uint64* pintr0, uint64* pintr1
    #endif
                    )
    {
    // ...略
        if (PyFunction_Check(func))
            x = fast_function(func, pp_stack, n, na, nk);
        else
            x = do_call(func, pp_stack, na, nk);
    // ...略
    }

    // line[4424]
    static PyObject *
    fast_function(PyObject *func, PyObject ***pp_stack, int n, int na, int nk)
    {
    // 略
            assert(tstate != NULL);
            f = PyFrame_New(tstate, co, globals, NULL);     // 这儿创建的对应frame
            if (f == NULL)
                return NULL;
            // 以下将函数的value_stack拷贝了出来，本质上是将参数传递了过来
            fastlocals = f->f_localsplus;
            stack = (*pp_stack) - n;

            for (i = 0; i < n; i++) {
                Py_INCREF(*stack);
                fastlocals[i] = *stack++;
            }
            retval = PyEval_EvalFrameEx(f,0);       // 此时重新调用主循环，执行刚刚创建的frame
            ++tstate->recursion_depth;
            Py_DECREF(f);
            --tstate->recursion_depth;
            return retval;
        }
    // 略
    }
    ```
* 因此调用一个函数的流程时执行`CALL_FUNCTION`操作码，实质是创建了一个`FrameObject`交给`PyEval_EvalFrameEx`去执行。
