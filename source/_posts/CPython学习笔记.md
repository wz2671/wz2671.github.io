---
title: CPython学习笔记
date: 2021-04-07 23:44:47
tags: python笔记
---

[参考资料](https://pg.ucsd.edu/cpython-internals.htm)  
[youtube视频](https://www.youtube.com/playlist?list=PLzV58Zm8FuBL6OAv1Yu6AwXZrnsFbbR0S)  
[百度云(提取码：2twh)](https://pan.baidu.com/s/1SmWNpCrY3kfiKDxAdI8roA)
[python2.7源码链接](https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz)

（但本文中的python代码都是基于python3环境测试的）

![cpython](/images/cpython.jpg)

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
* python 解释器原来主要是一个超大的[`switch...case...`](https://github.com/python/cpython/blob/8d21aa21f2cbc6d50aab3f420bb23be1d081dac4/Python/ceval.c#L1211)，根据各个操作码执行相应的逻辑。
* 例如`LOAD_FAST`和`BINARY_MODULO`cpython实现
    ```cpp
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

***

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
* `/Python/ceval.c`中是python的主循环所在位置，在源码的1069行起[line1069](https://github.com/python/cpython/blob/8d21aa21f2cbc6d50aab3f420bb23be1d081dac4/Python/ceval.c#L1069)，它是一个无限的循环，每次解释一个字节码，就会调度一次循环
    ```c++
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
        ...
        }
    ```
* 可以随意修改cpython源码，进行编译，就能使用自己独家定制的python解释器了


***

# Lecture 2. Opcodes and main interpreter loop

### 1. `compile`内置函数

* 测试文件test.py
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
    1            0 LOAD_CONST               0 (1)        # 这儿LOAD_CONST占一字节(100)，参数一字节，共两字节
                 2 STORE_NAME               0 (x)        # STORE_NAME从第三字节开始(90)

    2            4 LOAD_CONST               1 (2)
                 6 STORE_NAME               1 (y)

    3            8 LOAD_NAME                0 (x)
                10 LOAD_NAME                1 (y)
                12 BINARY_ADD
                14 STORE_NAME               2 (z)

    4           16 LOAD_NAME                3 (print)
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
* 是一个超长的函数[line688-3364](https://github.com/python/cpython/blob/8d21aa21f2cbc6d50aab3f420bb23be1d081dac4/Python/ceval.c#L688-L3364)，它就是执行python源码的主要函数，里面有个指针`stack_pointer`就是存的value stack
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
    co = f->f_code;         // 取出frame的code_object
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

### 3. `dis`模块

* 官方文档的`dis`模块中详细说明了各个字节码的含义，具体内容可参考[链接](https://docs.python.org/3/library/dis.html)

***


# Lecture 3. Frames, functions calls, and scope

### 1. `Frames`

* `PyEval_EvalFrameEx`是之前所说的执行字节码的主入口，他接受一个`PyFrameObject`的指针，这个指针指向的就是一个`frame`对象。

* 每个`frame`都包含一段可以执行的逻辑，也就是`code_object`，还有相关的运行环境如全局变量和局部变量等，它的具体定义如下所示，在文件`Include/frameobject.h`中[line16-50](https://github.com/python/cpython/blob/8d21aa21f2cbc6d50aab3f420bb23be1d081dac4/Include/frameobject.h#L16-L50)
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
* `code_object`定义在了`Include/code.h`之中[line10-30](https://github.com/python/cpython/blob/8d21aa21f2cbc6d50aab3f420bb23be1d081dac4/Include/code.h#L10-L30)，具体成员变量如下所示
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

* `CALL_FUNCTION`字节码的实现只是调用函数[line3005-3019](https://github.com/python/cpython/blob/8d21aa21f2cbc6d50aab3f420bb23be1d081dac4/Python/ceval.c#L3005-L3019)，具体实现在`call_function`函数里的`fast_function`中[line4424-4475](https://github.com/python/cpython/blob/8d21aa21f2cbc6d50aab3f420bb23be1d081dac4/Python/ceval.c#L4424-L4475)。
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

***

# Lecture 4. PyObject The core Python object

### 1. 在python中万物皆对象

* 就算是`int`的变量，也是对象
    ```python
    >>> x = 123
    >>> dir(x)
    ['__abs__', '__add__', '__and__', '__bool__', '__ceil__', '__class__', '__delattr__', '__dir__', '__divmod__', '__doc__', '__eq__', '__float__', '__floor__', '__floordiv__', '__format__', '__ge__', '__getattribute__', '__getnewargs__', '__gt__', '__hash__', '__index__', '__init__', '__init_subclass__', '__int__', '__invert__', '__le__', '__lshift__', '__lt__', '__mod__', '__mul__', '__ne__', '__neg__', '__new__', '__or__', '__pos__', '__pow__', '__radd__', '__rand__', '__rdivmod__', '__reduce__', '__reduce_ex__', '__repr__', '__rfloordiv__', '__rlshift__', '__rmod__', '__rmul__', '__ror__', '__round__', '__rpow__', '__rrshift__', '__rshift__', '__rsub__', '__rtruediv__', '__rxor__', '__setattr__', '__sizeof__', '__str__', '__sub__', '__subclasshook__', '__truediv__', '__trunc__', '__xor__', 'as_integer_ratio', 'bit_length', 'conjugate', 'denominator', 'from_bytes', 'imag', 'numerator', 'real', 'to_bytes']
    >>> x.__add__(1)
    124
    ```
* `int`的加法实际实现在`intobject.c`里的`int_add`中[line468-493](https://github.com/python/cpython/blob/8d21aa21f2cbc6d50aab3f420bb23be1d081dac4/Objects/intobject.c#L468-L493)
    ```c++
    // line[168-179]
    static PyObject *
    int_add(PyIntObject *v, PyIntObject *w)
    {
        register long a, b, x;
        CONVERT_TO_LONG(v, a);
        CONVERT_TO_LONG(w, b);
        /* casts in the line below avoid undefined behaviour on overflow */
        x = (long)((unsigned long)a + b);
        if ((x^a) >= 0 || (x^b) >= 0)
            return PyInt_FromLong(x);
        return PyLong_Type.tp_as_number->nb_add((PyObject *)v, (PyObject *)w);
    }
    ```
* 使用`sys`模块中过的`getrefcount`可以轻易看到引用计数。从视频中的来看，有些令人费解
* 在`object.h`中的注释中说，每个`PyObject`对象都拥有一个`reference count`引用计数，和`type`类型，对于`type`类型，它有一个`type`指向了自己，（也仅仅只有这两个东西）
    ```c++
    #define PyObject_HEAD                   \
        _PyObject_HEAD_EXTRA                \       // 这个宏定义是用于调试的(Py_TRACE_REFS)
        Py_ssize_t ob_refcnt;               \       // 引用计数
        struct _typeobject *ob_type;                // 类型指针
    /* Nothing is actually declared to be a PyObject, but every pointer to
    * a Python object can be cast to a PyObject*.  This is inheritance built
    * by hand.  Similarly every pointer to a variable-size Python object can,
    * in addition, be cast to PyVarObject*.
    */
    typedef struct _object {
        PyObject_HEAD
    } PyObject;
    // 宏定义编辑过后的结果就是
    typedef struct _object {
        Py_ssize_t ob_refcnt;
        struct _typeobject *ob_type;
    }
    ```
* 对于`intobject`，它的定义如下(在`intobject.h`中)，相对于PyObject，多定义了一个long，其他的对象类似。
    ```c++
    typedef struct {
        PyObject_HEAD
        long ob_ival;
    } PyIntObject;
    ```
* PyObject对象的生成与内存分配在`object.c`中的`_PyObject_New`函数中[line240-248](https://github.com/python/cpython/blob/8d21aa21f2cbc6d50aab3f420bb23be1d081dac4/Objects/object.c#L240-L248)。
    ```c++
    // line[240-248] 先创建一个类型
    PyObject *
    _PyObject_New(PyTypeObject *tp)
    {
        PyObject *op;
        op = (PyObject *) PyObject_MALLOC(_PyObject_SIZE(tp));
        if (op == NULL)
            return PyErr_NoMemory();
        return PyObject_INIT(op, tp);
    }
    ```
* python中对象的动态性主要来源于，对每种类型都约束其特定接口，不同类型的PyObject传入后，会执行相同名称不同接口的具体实现[line411-451](https://github.com/python/cpython/blob/8d21aa21f2cbc6d50aab3f420bb23be1d081dac4/Objects/object.c#L411-L451)
    ```c++
    // 例如把某个类型转成字符串，通过`tp_str`接口实现的，有点像多态那味
    PyObject *
    _PyObject_Str(PyObject *v)
    {
        PyObject *res;
        int type_ok;
        if (v == NULL)
            return PyString_FromString("<NULL>");
        if (PyString_CheckExact(v)) {
            Py_INCREF(v);
            return v;
        }
    #ifdef Py_USING_UNICODE
        if (PyUnicode_CheckExact(v)) {
            Py_INCREF(v);
            return v;
        }
    #endif
        if (Py_TYPE(v)->tp_str == NULL)
            return PyObject_Repr(v);

        /* It is possible for a type to have a tp_str representation that loops
        infinitely. */
        if (Py_EnterRecursiveCall(" while getting the str of an object"))
            return NULL;
        res = (*Py_TYPE(v)->tp_str)(v);     // 每个类型都实现了`tp_str`的方法，去执行具体类型转化为字符串的逻辑
        Py_LeaveRecursiveCall();
        if (res == NULL)
            return NULL;
        type_ok = PyString_Check(res);
    #ifdef Py_USING_UNICODE
        type_ok = type_ok || PyUnicode_Check(res);
    #endif
        if (!type_ok) {
            PyErr_Format(PyExc_TypeError,
                        "__str__ returned non-string (type %.200s)",
                        Py_TYPE(res)->tp_name);
            Py_DECREF(res);
            return NULL;
        }
        return res;
    }
    ```

* 除了`PyObject`之外，附近还有一个`PyVarObject`，是用来处理一些可变变量的类型，除了`PyObject_HEAD`之外，它还额外拥有一个`ob_size`属性。因此它有三条属性：引用计数，类型，和体重。
    ```c++
    #define PyObject_VAR_HEAD               \
        PyObject_HEAD                       \
        Py_ssize_t ob_size; /* Number of items in variable part */
    #define Py_INVALID_SIZE (Py_ssize_t)-1

    /* Similarly every pointer to a variable-size Python object can,
    * in addition, be cast to PyVarObject*.
    */
    typedef struct {
        PyObject_VAR_HEAD
    } PyVarObject;
    ```
* 在`object.h`中还定义了`PyTypeObject`[line324-411](https://github.com/python/cpython/blob/8d21aa21f2cbc6d50aab3f420bb23be1d081dac4/Include/object.h#L324-L411)，这个就是每个`PyObject_HEAD`中的那个`ob_type`，超核心的类型指针对应的类型。（搜`_typeobject`比较好找）
    ```c++
    // 这个对象是cpython实现动态类型地关键，通过各个类型实现对应地接口，ceval可以直接拿取指针执行各自类型相应地逻辑，十分相似于多态
    typedef struct _typeobject {
        PyObject_VAR_HEAD
        const char *tp_name; /* For printing, in format "<module>.<name>" */
        Py_ssize_t tp_basicsize, tp_itemsize; /* For allocation */

        /* Methods to implement standard operations */

        destructor tp_dealloc;
        printfunc tp_print;
        getattrfunc tp_getattr;
        setattrfunc tp_setattr;
        cmpfunc tp_compare;
        reprfunc tp_repr;

        /* Method suites for standard classes */

        PyNumberMethods *tp_as_number;
        PySequenceMethods *tp_as_sequence;
        PyMappingMethods *tp_as_mapping;

        /* More standard operations (here for binary compatibility) */

        hashfunc tp_hash;
        ternaryfunc tp_call;                // 可执行函数
        reprfunc tp_str;                    // str(object)函数
        getattrofunc tp_getattro;
        setattrofunc tp_setattro;

        /* Functions to access object as input/output buffer */
        PyBufferProcs *tp_as_buffer;

        /* Flags to define presence of optional/expanded features */
        long tp_flags;

        const char *tp_doc; /* Documentation string */

        /* Assigned meaning in release 2.0 */
        /* call function for all accessible objects */
        traverseproc tp_traverse;

        /* delete references to contained objects */
        inquiry tp_clear;

        /* Assigned meaning in release 2.1 */
        /* rich comparisons */
        richcmpfunc tp_richcompare;         // 比较函数

        /* weak reference enabler */
        Py_ssize_t tp_weaklistoffset;

        /* Added in release 2.2 */
        /* Iterators */
        getiterfunc tp_iter;                // 返回可迭代对象的迭代器
        iternextfunc tp_iternext;           // 返回迭代器的下一个值

        /* Attribute descriptor and subclassing stuff */
        struct PyMethodDef *tp_methods;
        struct PyMemberDef *tp_members;
        struct PyGetSetDef *tp_getset;
        struct _typeobject *tp_base;
        PyObject *tp_dict;
        descrgetfunc tp_descr_get;
        descrsetfunc tp_descr_set;
        Py_ssize_t tp_dictoffset;
        initproc tp_init;
        allocfunc tp_alloc;
        newfunc tp_new;
        freefunc tp_free; /* Low-level free-memory routine */
        inquiry tp_is_gc; /* For PyObject_IS_GC */
        PyObject *tp_bases;
        PyObject *tp_mro; /* method resolution order */
        PyObject *tp_cache;
        PyObject *tp_subclasses;
        PyObject *tp_weaklist;
        destructor tp_del;

        /* Type attribute cache version tag. Added in version 2.6 */
        unsigned int tp_version_tag;

    #ifdef COUNT_ALLOCS
        /* these must be last and never explicitly initialized */
        Py_ssize_t tp_allocs;
        Py_ssize_t tp_frees;
        Py_ssize_t tp_maxalloc;
        struct _typeobject *tp_prev;
        struct _typeobject *tp_next;
    #endif
    } PyTypeObject;
    ```

***

# Lecture 5. Example Python data types

### 1. `stringobject`

* 字符串是不可变类型(immutable)，在python3中，字符串会更复杂一点，因为它要支持各种变长的国际化字符。
* 每个字符串对象，实际真正只会被创建一次，其他的只是持有其引用，类似于java中的池子。([string interning](http://wikipedia.org/wiki/String_interning))，<font color=red> 但是要注意，只有简单的`str`才会有此feature </font>
    ```python
    >>> a = "hello"
    >>> b = "hello"
    >>> a is b
    True
    >>> aa = "ashdfijahsdkl jvoi jweoifj asdoik fuiasdhvck jx"
    >>> bb = "ashdfijahsdkl jvoi jweoifj asdoik fuiasdhvck jx"
    >>> aa is bb
    False
    # 以下这种格式固定的，也会被优化
    >>> aa = 'hellohellohellohellohellohellohellohellohellohellohellohellohellohellohellohellohellohellohellohello'
    >>> bb = 'hellohellohellohellohellohellohellohellohellohellohellohellohellohellohellohellohellohellohellohello'
    >>> aa is bb
    True
    ```

* `stringobject`的定义如下：
    ```c++
    /*
    Type PyStringObject represents a character string.  An extra zero byte is
    reserved at the end to ensure it is zero-terminated, but a size is
    present so strings with null bytes in them can be represented.  This
    is an immutable object type.

    There are functions to create new string objects, to test
    an object for string-ness, and to get the
    string value.  The latter function returns a null pointer
    if the object is not of the proper type.
    There is a variant that takes an explicit size as well as a
    variant that assumes a zero-terminated string.  Note that none of the
    functions should be applied to nil objects.
    */

    /* Caching the hash (ob_shash) saves recalculation of a string's hash value.
    Interning strings (ob_sstate) tries to ensure that only one string
    object with a given value exists, so equality tests can be one pointer
    comparison.  This is generally restricted to strings that "look like"
    Python identifiers, although the intern() builtin can be used to force
    interning of any string.
    Together, these sped the interpreter by up to 20%. */

    typedef struct {
        PyObject_VAR_HEAD
        long ob_shash;          // 用于计算字符串的哈希值，会保存在一个驻留字典中，以节约内存（上面注释有说明）
        int ob_sstate;          // 如果没有驻留在内存中，就为0
        char ob_sval[1];        // 普通的cstring，最后一个字符是0x00

        /* Invariants:
        *     ob_sval contains space for 'ob_size+1' elements.
        *     ob_sval[ob_size] == 0.
        *     ob_shash is the hash of the string or -1 if not computed yet.
        *     ob_sstate != 0 iff the string object is in stringobject.c's
        *       'interned' dictionary; in this case the two references
        *       from 'interned' to this object are *not counted* in ob_refcnt.
        */
    } PyStringObject;
    ```
* 示例代码
    ```python
    # test.py
    a = "hello"
    b = "hello"

    a == b
    a + b
    ```
    ```bash
    PS D:\CODE\Python-2.7.18> python -m dis test.py
    1           0 LOAD_CONST               0 ('hello')
                2 STORE_NAME               0 (a)

    2           4 LOAD_CONST               0 ('hello')
                6 STORE_NAME               1 (b)

    4           8 LOAD_NAME                0 (a)
                10 LOAD_NAME                1 (b)
                12 COMPARE_OP               2 (==)      # 比较两个值
                14 POP_TOP

    6           16 LOAD_NAME                0 (a)
                18 LOAD_NAME                1 (b)
                20 BINARY_ADD                           # 字符串连接，只是个普普通通的加法
                22 POP_TOP
                24 LOAD_CONST               1 (None)
                26 RETURN_VALUE
    ```
* 字符串的比较，被执行的就是以上的`COMPARE_OP`操作码。总体比较的步骤大致如下：
    * `ceval.c`中会对该字节码进行解释执行，从变量栈中取出连个值，由于是字符串，执行到`cmp_outcome`函数
        ```c++
        // line[2566-2601]
        TARGET(COMPARE_OP)
        {
            w = POP();
            v = TOP();
            if (PyInt_CheckExact(w) && PyInt_CheckExact(v)) {       // 整形的比较
                /* INLINE: cmp(int, int) */
                register long a, b;
                register int res;
                a = PyInt_AS_LONG(v);
                b = PyInt_AS_LONG(w);
                switch (oparg) {
                case PyCmp_LT: res = a <  b; break;
                case PyCmp_LE: res = a <= b; break;
                case PyCmp_EQ: res = a == b; break;
                case PyCmp_NE: res = a != b; break;
                case PyCmp_GT: res = a >  b; break;
                case PyCmp_GE: res = a >= b; break;
                case PyCmp_IS: res = v == w; break;
                case PyCmp_IS_NOT: res = v != w; break;
                default: goto slow_compare;
                }
                x = res ? Py_True : Py_False;
                Py_INCREF(x);
            }
            else {
                slow_compare:
                x = cmp_outcome(oparg, v, w);                       // 其他的类型
            }
            Py_DECREF(v);
            Py_DECREF(w);
            SET_TOP(x);
            if (x == NULL) break;
            PREDICT(POP_JUMP_IF_FALSE);
            PREDICT(POP_JUMP_IF_TRUE);
            DISPATCH();
        }
        ```
    * 在`cmp_outcome`会走到`default`中的`PyObject_RichCompare`函数。
        ```c++
        static PyObject *
        cmp_outcome(int op, register PyObject *v, register PyObject *w)
        {
            int res = 0;
            switch (op) {
            case PyCmp_IS:                                  // is的判断 效率会高点
                res = (v == w);
                break;
            case PyCmp_IS_NOT:
                res = (v != w);
                break;
            case PyCmp_IN:
                res = PySequence_Contains(w, v);
                if (res < 0)
                    return NULL;
                break;
            case PyCmp_NOT_IN:
                res = PySequence_Contains(w, v);
                if (res < 0)
                    return NULL;
                res = !res;
                break;
            case PyCmp_EXC_MATCH:
                // 太长，跳过了，也没看懂，似乎是报警用的
                break;
            default:
                return PyObject_RichCompare(v, w, op);          // 走到了这儿
            }
            v = res ? Py_True : Py_False;
            Py_INCREF(v);
            return v;
        }
        ```
    * 在`object.c`中的`PyObject_RichCompare`函数中，走到了取比较函数的指针`frich`并执行的分支，也就是执行了`RICHCOMPARE`宏定义。
        ```c++
        /* Return:
        NULL for exception;
        some object not equal to NotImplemented if it is implemented
            (this latter object may not be a Boolean).
        */
        PyObject *
        PyObject_RichCompare(PyObject *v, PyObject *w, int op)
        {
            PyObject *res;

            assert(Py_LT <= op && op <= Py_GE);
            if (Py_EnterRecursiveCall(" in cmp"))
                return NULL;

            /* If the types are equal, and not old-style instances, try to
            get out cheap (don't bother with coercions etc.). */
            if (v->ob_type == w->ob_type && !PyInstance_Check(v)) {
                cmpfunc fcmp;
                richcmpfunc frich = RICHCOMPARE(v->ob_type);                // 这儿会把stringobject中的比较函数指针拿出来
                /* If the type has richcmp, try it first.  try_rich_compare
                tries it two-sided, which is not needed since we've a
                single type only. */
                if (frich != NULL) {
                    res = (*frich)(v, w, op);                               // 在这儿执行这个指针所指向的函数
                    if (res != Py_NotImplemented)
                        goto Done;
                    Py_DECREF(res);
                }
                /* No richcmp, or this particular richmp not implemented.
                Try 3-way cmp. */
                fcmp = v->ob_type->tp_compare;
                if (fcmp != NULL) {
                    int c = (*fcmp)(v, w);
                    c = adjust_tp_compare(c);
                    if (c == -2) {
                        res = NULL;
                        goto Done;
                    }
                    res = convert_3way_to_object(op, c);
                    goto Done;
                }
            }

            /* Fast path not taken, or couldn't deliver a useful result. */
            res = do_richcmp(v, w, op);
        Done:
            Py_LeaveRecursiveCall();
            return res;
        }
        ```
    * 此处，会在运行时拿到`stringobject.c`里的`tp_richcompare`，也就是`string_richcompare`函数，执行，这儿就是最终两个字符串进行比较的地方。
        ```c++
        static PyObject*
        string_richcompare(PyStringObject *a, PyStringObject *b, int op)
        {
            int c;
            Py_ssize_t len_a, len_b;
            Py_ssize_t min_len;
            PyObject *result;

            /* Make sure both arguments are strings. */
            if (!(PyString_Check(a) && PyString_Check(b))) {            // 检查两个参数是否都是字符串类型
                result = Py_NotImplemented;
                goto out;
            }
            if (a == b) {                                               // 判断是否执行同一个PyStringObject
                switch (op) {
                case Py_EQ:case Py_LE:case Py_GE:
                    result = Py_True;                                   // 此类都为True，否则为False
                    goto out;
                case Py_NE:case Py_LT:case Py_GT:
                    result = Py_False;
                    goto out;
                }
            }
            if (op == Py_EQ) {                                          // 如果是判断是否相等
                /* Supporting Py_NE here as well does not save
                much time, since Py_NE is rarely used.  */
                if (Py_SIZE(a) == Py_SIZE(b)                            // 长度不等的串一定不等
                    && (a->ob_sval[0] == b->ob_sval[0]                  // 首字母检查是否相等
                    && memcmp(a->ob_sval, b->ob_sval, Py_SIZE(a)) == 0)) {          // 调用c提供的内存比较方法memcmp
                    result = Py_True;
                } else {
                    result = Py_False;
                }
                goto out;
            }
            len_a = Py_SIZE(a); len_b = Py_SIZE(b);
            min_len = (len_a < len_b) ? len_a : len_b;
            if (min_len > 0) {
                c = Py_CHARMASK(*a->ob_sval) - Py_CHARMASK(*b->ob_sval);
                if (c==0)
                    c = memcmp(a->ob_sval, b->ob_sval, min_len);
            } else
                c = 0;
            if (c == 0)
                c = (len_a < len_b) ? -1 : (len_a > len_b) ? 1 : 0;
            switch (op) {
            case Py_LT: c = c <  0; break;
            case Py_LE: c = c <= 0; break;
            case Py_EQ: assert(0);  break; /* unreachable */
            case Py_NE: c = c != 0; break;
            case Py_GT: c = c >  0; break;
            case Py_GE: c = c >= 0; break;
            default:
                result = Py_NotImplemented;
                goto out;
            }
            result = c ? Py_True : Py_False;
        out:
            Py_INCREF(result);
            return result;
        }
        ```
* 如何根据`tp_richcompare`找到对应类型的比较方法呢？我看了下代码，大致流程如下：
    * 每种类型都会定义一个`PyTypeObeject`的类型，例如string就是`PyString_Type`，每次在创建`PyStringObject`之后，都会使用该`Type`对`PyObject`进行初始化。
    * 在`object.c`中，先调用`PyObject_MALLOC`给具体的`PyObject`分配内存，然后调用`PyObject_Init`或`PyObject_InitVar`对其类型进行初始化。本质上执行的就是`Py_TYPE`，也就是把这个类型赋值给了其中的`op_type`变量，`#define Py_TYPE(ob)              (((PyObject*)(ob))->ob_type)`
    * 归根结底，`PyObject`中的`ob_type`对应的对象，就已经决定了这个`PyObejct`的执行轨迹。

* **字符串连接**，本质上是解析并执行了`BINARY_ADD`这个字节码。执行起来就比较直接了，直接进行类型判断，调用`string_concatenate`函数
    ```c++
    TARGET_NOARG(BINARY_ADD)
    {
        w = POP();
        v = TOP();
        if (PyInt_CheckExact(v) && PyInt_CheckExact(w)) {
            /* INLINE: int + int */
            register long a, b, i;
            a = PyInt_AS_LONG(v);
            b = PyInt_AS_LONG(w);
            /* cast to avoid undefined behaviour
                on overflow */
            i = (long)((unsigned long)a + b);
            if ((i^a) < 0 && (i^b) < 0)
                goto slow_add;
            x = PyInt_FromLong(i);
        }
        else if (PyString_CheckExact(v) &&                  // 如果两个变量是字符串类型，就调用连接的函数
                    PyString_CheckExact(w)) {
            x = string_concatenate(v, w, f, next_instr);
            /* string_concatenate consumed the ref to v */
            goto skip_decref_vx;
        }
        else {
            slow_add:
            x = PyNumber_Add(v, w);
        }
        Py_DECREF(v);
        skip_decref_vx:
        Py_DECREF(w);
        SET_TOP(x);
        if (x != NULL) DISPATCH();
        break;
    }
    ```
    ```c++
    static PyObject *
    string_concat(register PyStringObject *a, register PyObject *bb)
    {
        register Py_ssize_t size;
        register PyStringObject *op;
        if (!PyString_Check(bb)) {
    #ifdef Py_USING_UNICODE
            if (PyUnicode_Check(bb))
                return PyUnicode_Concat((PyObject *)a, bb);
    #endif
            if (PyByteArray_Check(bb))
                return PyByteArray_Concat((PyObject *)a, bb);
            PyErr_Format(PyExc_TypeError,
                        "cannot concatenate 'str' and '%.200s' objects",
                        Py_TYPE(bb)->tp_name);
            return NULL;
        }
    #define b ((PyStringObject *)bb)
        /* Optimize cases with empty left or right operand */
        if ((Py_SIZE(a) == 0 || Py_SIZE(b) == 0) &&
            PyString_CheckExact(a) && PyString_CheckExact(b)) {
            if (Py_SIZE(a) == 0) {
                Py_INCREF(bb);
                return bb;
            }
            Py_INCREF(a);
            return (PyObject *)a;
        }
        /* Check that string sizes are not negative, to prevent an
        overflow in cases where we are passed incorrectly-created
        strings with negative lengths (due to a bug in other code).
        */
        if (Py_SIZE(a) < 0 || Py_SIZE(b) < 0 ||
            Py_SIZE(a) > PY_SSIZE_T_MAX - Py_SIZE(b)) {
            PyErr_SetString(PyExc_OverflowError,
                            "strings are too large to concat");
            return NULL;
        }
        size = Py_SIZE(a) + Py_SIZE(b);

        /* Inline PyObject_NewVar */
        if (size > PY_SSIZE_T_MAX - PyStringObject_SIZE) {
            PyErr_SetString(PyExc_OverflowError,
                            "strings are too large to concat");
            return NULL;
        }
        op = (PyStringObject *)PyObject_MALLOC(PyStringObject_SIZE + size);
        if (op == NULL)
            return PyErr_NoMemory();
        (void)PyObject_INIT_VAR(op, &PyString_Type, size);
        op->ob_shash = -1;
        op->ob_sstate = SSTATE_NOT_INTERNED;
        Py_MEMCPY(op->ob_sval, a->ob_sval, Py_SIZE(a));                         // 通过memcpy来拷贝字符串，
        Py_MEMCPY(op->ob_sval + Py_SIZE(a), b->ob_sval, Py_SIZE(b));
        op->ob_sval[size] = '\0';
        return (PyObject *) op;                                                 // 返回一个新的字符串
    #undef b
    }
    ```

***


# Lecture 6. Code objects, function objects, and closures

### 1. function object

* 在`import`一个模块的时候，只有当执行到了定义的函数之后，函数名对应的`function object`才被创建，在这之前是无法获取函数名的，讲函数名赋值给另外一个变量，实质上是创建了一个新的引用指向了该`function object`。
* 函数的属性们
    ```python
    >>> def func(x, y):
    ...     z = x + y
    ...     return z
    ...
    >>> bar = func
    >>> dir(bar)
    ['__annotations__', '__call__', '__class__', '__closure__', '__code__', '__defaults__', '__delattr__', '__dict__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__get__', '__getattribute__', '__globals__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__kwdefaults__', '__le__', '__lt__', '__module__', '__name__', '__ne__', '__new__', '__qualname__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__sizeof__', '__str__', '__subclasshook__']
    >>> bar.__globals__
    {'__name__': '__main__', '__doc__': None, '__package__': None, '__loader__': <class '_frozen_importlib.BuiltinImporter'>, '__spec__': None, '__annotations__': {}, '__builtins__': <module 'builtins' (built-in)>, 'func': <function func at 0x000001775B29D0D0>, 'bar': <function func at 0x000001775B29D0D0>}
    ```
* `__globals__`（在python2中是`func_globals`）是函数对象的一个成员变量，为什么有这个变量，因为对于函数而言，它的全局变量是以文件为单位的，不同py文件中的函数，他们的`__globals__`是不一样的。因此对于两段完全相同的代码（`__code__`），可以因为环境的不同，产生完全不同的结果。
* python中的`code object`拥有的属性如下，`co_code`就是经过编译之后的字节码
    ```python
    >>> func.__code__.co_code
    b'|\x00|\x01\x17\x00}\x02|\x02S\x00'
    >>> dir(func.__code__)
    ['__class__', '__delattr__', '__dir__', '__doc__', '__eq__', '__format__', '__ge__', '__getattribute__', '__gt__', '__hash__', '__init__', '__init_subclass__', '__le__', '__lt__', '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__sizeof__', '__str__', '__subclasshook__', 'co_argcount', 'co_cellvars', 'co_code', 'co_consts', 'co_filename', 'co_firstlineno', 'co_flags', 'co_freevars', 'co_kwonlyargcount', 'co_lnotab', 'co_name', 'co_names', 'co_nlocals', 'co_posonlyargcount', 'co_stacksize', 'co_varnames', 'replace']
    ```
* `bytecode object`的cpython源码，在`code.h`中定义的`PyCodeObject`。第三讲里的笔记已经贴了源码了。

### 2. `funcobject`

* cpython源码中的`PyFUnctionObejct`(在`funcobject.h`中的定义)
    ```c++
    typedef struct {
        PyObject_HEAD
        PyObject *func_code;	/* A code object */                             // code object 里面存的编译后的字节码
        PyObject *func_globals;	/* A dictionary (other mappings won't do) */        // 全局变量
        PyObject *func_defaults;	/* NULL or a tuple */
        PyObject *func_closure;	/* NULL or a tuple of cell objects */               // 里面存的是闭包里的变量
        PyObject *func_doc;		/* The __doc__ attribute, can be anything */
        PyObject *func_name;	/* The __name__ attribute, a string object */
        PyObject *func_dict;	/* The __dict__ attribute, a dict or NULL */
        PyObject *func_weakreflist;	/* List of weak references */
        PyObject *func_module;	/* The __module__ attribute, can be anything */

        /* Invariant:           
        // 这儿对闭包的变量解释了以下co_freevars里存的就是函数作用域范围外的变量，co_freevars和closure里的cell应是一一对应的
        *     func_closure contains the bindings for func_code->co_freevars, so
        *     PyTuple_Size(func_closure) == PyCode_GetNumFree(func_code)
        *     (func_closure may be NULL if PyCode_GetNumFree(func_code) == 0).
        */
    } PyFunctionObject;
    ```
* 在`funcobejct.c`中，构造一个`PyfunctionObejct`只需需要传入两个参数，`code object`和`globals`，分别指的是函数的字节码和全局变量的指针。它的函数声明如下，`PyObject * PyFunction_New(PyObject *code, PyObject *globals)`

* `PyMemberDef`和`PyGetSetDef`，里面定义的是从python控制台里可以直接取到的变量。，对于`PyGetSetDef`里，还定义了一些可以修改的变量。
    ```c++
    static PyMemberDef func_memberlist[] = {
        {"func_closure",  T_OBJECT,     OFF(func_closure),
        RESTRICTED|READONLY},
        {"__closure__",  T_OBJECT,      OFF(func_closure),
        RESTRICTED|READONLY},
        {"func_doc",      T_OBJECT,     OFF(func_doc), PY_WRITE_RESTRICTED},
        {"__doc__",       T_OBJECT,     OFF(func_doc), PY_WRITE_RESTRICTED},
        {"func_globals",  T_OBJECT,     OFF(func_globals),
        RESTRICTED|READONLY},
        {"__globals__",  T_OBJECT,      OFF(func_globals),
        RESTRICTED|READONLY},
        {"__module__",    T_OBJECT,     OFF(func_module), PY_WRITE_RESTRICTED},
        {NULL}  /* Sentinel */
    };
    ```
    ```c++
    static PyGetSetDef func_getsetlist[] = {
        {"func_code", (getter)func_get_code, (setter)func_set_code},
        {"__code__", (getter)func_get_code, (setter)func_set_code},
        {"func_defaults", (getter)func_get_defaults,
        (setter)func_set_defaults},
        {"__defaults__", (getter)func_get_defaults,
        (setter)func_set_defaults},
        {"func_dict", (getter)func_get_dict, (setter)func_set_dict},
        {"__dict__", (getter)func_get_dict, (setter)func_set_dict},
        {"func_name", (getter)func_get_name, (setter)func_set_name},
        {"__name__", (getter)func_get_name, (setter)func_set_name},
        {NULL} /* Sentinel */
    };
    ```
* 对于一个`function object`而言，其核心的功能，调用函数功能由函数`function_call`函数完成，它定义在了`PyFunction_Type`中(也就是`PyObject`里函数对象所对应的类型)，通过`tp_call`属性即可引用到它。
* `function_call`实现功能的方式是取出`PyFunction`中的`PyCodeObject`、`globals`等，交由`ceval.c`中的`PyEval_EvalCodeEx`执行，然后构造出一个`PyFrameObejct`，交由`PyEval_EvalFrameEx`完成对字节码的解析并执行的结果。（又回到最初的起点）

### 3. `closures`（闭包）

* 示例代码
    ```python
    x = 1000

    def foo(x):
        def bar(y):
            print(x + y)
        return bar
    
    b1 = foo(10)
    b1(1)
    b2 = foo(20)
    b2(1)
    ```
* 对于以上代码，`b1`是一个`function object`，它是一个闭包，拥有一个指向运行`foo(10)`时创建的`frame object`的指针，同时，该`frame object`由于拥有一个引用，也不会销毁，所以写代码时容易产生循环引用问题。
* 上面说的并不对，python并不会持有整个`frame object`，而是只保留了那唯一的一个变量`10`和`20`，它保存在了函数的`func_closure`中（python3中是`__closure__`属性），里面是一个`cell`类型的元组，其中`cell.cell_contents`里存储的就是上述的变量。
    ```python
    # python3
    >>> import test
    11
    21
    >>> test.b1.__closure__
    (<cell at 0x000001E9BEFD5BB0: int object at 0x00007FFD788D17C0>,)
    >>>
    # 数值
    >>> test.b1.__closure__[0].cell_contents
    10
    # 变量名与__closure__中的cell个数是一一对应的（在上面的注释里有说）
    >>> test.b1.__code__.co_freevars
    ('x',)
    ```
* 闭包执行的字节码如下
    ```python
    >>> dis.dis(test.b1)
    5           0 LOAD_GLOBAL              0 (print)
                2 LOAD_DEREF               0 (x)                # 这儿就是读取闭包中变量的字节码
                4 LOAD_FAST                0 (y)
                6 BINARY_ADD
                8 CALL_FUNCTION            1
                10 POP_TOP
                12 LOAD_CONST               0 (None)
                14 RETURN_VALUE
    ```
    ```c++
    TARGET(LOAD_DEREF)
    {
        x = freevars[oparg];            // 可以看到变量名是存在了freevars里，也就是上面的`test.b1.__code__.co_freevars`
        w = PyCell_Get(x);
        if (w != NULL) {
            PUSH(w);
            DISPATCH();
        }
        err = -1;
        /* Don't stomp existing exception */
        if (PyErr_Occurred())
            break;
        if (oparg < PyTuple_GET_SIZE(co->co_cellvars)) {
            v = PyTuple_GET_ITEM(co->co_cellvars,
                                    oparg);
            format_exc_check_arg(
                    PyExc_UnboundLocalError,
                    UNBOUNDLOCAL_ERROR_MSG,
                    v);
        } else {
            v = PyTuple_GET_ITEM(co->co_freevars, oparg -
                PyTuple_GET_SIZE(co->co_cellvars));
            format_exc_check_arg(PyExc_NameError,
                                    UNBOUNDFREE_ERROR_MSG, v);
        }
        break;
    }
    ```

***

# Lecture 7. Iterators

### 1. 迭代器

* 像`list`之类的是可迭代对象，`__iter__()`方法会返回一个迭代器，通过`next()`函数可以不断取出迭代器中元素，直至抛出`StopIteration`异常，在[流畅的python中十四章](https://wz2671.github.io/2020/12/13/%E6%B5%81%E7%95%85%E7%9A%84python/)有更详细说明。
* 测试代码`test.py`
    ```python
    x = ['a', 'b', 'c']
    for e in x:
        print e
    ```
* python编译之后，这儿是python3编译后的结果，和python2的差别挺大，python2还有个`SETUP_LOOP`的字节码
    ```bash
    PS D:\CODE\Python-2.7.18> python -m dis .\test.py
    1           0 LOAD_CONST               0 ('a')
                2 LOAD_CONST               1 ('b')
                4 LOAD_CONST               2 ('c')
                6 BUILD_LIST               3
                8 STORE_NAME               0 (x)

    2          10 LOAD_NAME                0 (x)
               12 GET_ITER
          >>   14 FOR_ITER                12 (to 28)        # 在14-28之前都是循环里的代码，stop之后，会跳到28
               16 STORE_NAME               1 (e)

    3          18 LOAD_NAME                2 (print)
               20 LOAD_NAME                1 (e)
               22 CALL_FUNCTION            1
               24 POP_TOP
               26 JUMP_ABSOLUTE           14
          >>   28 LOAD_CONST               3 (None)
               30 RETURN_VALUE
    ```
* 因此`for`循环的核心代码，主要是`GET_ITER`和`FOR_ITER`操作码，他们的cpython源码实现如下：
    ```c++
    TARGET_NOARG(GET_ITER)
    {
        /* before: [obj]; after [getiter(obj)] */
        v = TOP();
        x = PyObject_GetIter(v);            // 获取v的迭代器
        Py_DECREF(v);
        if (x != NULL) {
            SET_TOP(x);                     // 迭代器放到了栈顶
            PREDICT(FOR_ITER);              // 预测并直接跳到下一个操作码FOR_ITER
            DISPATCH();
        }
        STACKADJ(-1);
        break;
    }

    PREDICTED_WITH_ARG(FOR_ITER);           // 从这儿执行，只是一重eval循环
    TARGET(FOR_ITER)
    {
        /* before: [iter]; after: [iter, iter()] *or* [] */
        v = TOP();                          // 此时这儿是那个迭代器
        x = (*v->ob_type->tp_iternext)(v);  // 取出了迭代器的next方法，并调用，这儿返回的就是具体的变量
        if (x != NULL) {                    // 根据next函数返回的结果判断是否结束for循环
            PUSH(x);                        // 压入变量栈中
            PREDICT(STORE_FAST);            // 存到了for循环里那个局部变量中
            PREDICT(UNPACK_SEQUENCE);
            DISPATCH();
        }
        if (PyErr_Occurred()) {
            if (!PyErr_ExceptionMatches(
                            PyExc_StopIteration))
                break;
            PyErr_Clear();
        }
        /* iterator ended normally */
        x = v = POP();
        Py_DECREF(v);
        JUMPBY(oparg);
        DISPATCH();
    }
    ```
* 获取迭代器的方法`PyObject_GetIter`定义在了`abstarct.h`中，是一个抽象基础方法。具体实现是尝试获取PyObject的`tp_iter`方法，如果没有找到的话，会尝试构建一个迭代器，实现代码如下：
    ```c++
    PyObject *
    PyObject_GetIter(PyObject *o)
    {
        PyTypeObject *t = o->ob_type;
        getiterfunc f = NULL;
        if (PyType_HasFeature(t, Py_TPFLAGS_HAVE_ITER))     // 会根据类型定义标志的作比较
            f = t->tp_iter;
        if (f == NULL) {
            if (PySequence_Check(o))
                return PySeqIter_New(o);                    // 对于list而言，会走这儿构建一个新的迭代器
            return type_error("'%.200s' object is not iterable", o);
        }
        else {
            PyObject *res = (*f)(o);
            if (res != NULL && !PyIter_Check(res)) {
                PyErr_Format(PyExc_TypeError,
                            "iter() returned non-iterator "
                            "of type '%.100s'",
                            res->ob_type->tp_name);
                Py_DECREF(res);
                res = NULL;
            }
            return res;
        }
    }
    ```

* 构造迭代器的方法`PySeqIter_New`定义在了`iterobejct.c`，第一个接口就是，主要思路就创建一个迭代器对象，把索引和对象的指针设置一下完毕，迭代器的定义如下：
    ```c++
    typedef struct {
        PyObject_HEAD
        long      it_index;
        PyObject *it_seq; /* Set to NULL when iterator is exhausted */
    } seqiterobject;
    ```
* 对于调用`next`方法，也就是`ceval.c`中的`x = (*v->ob_type->tp_iternext)(v)`语句，对于上述例子，会执行`iter_iternext`方法，实现的源码如下：
    ```c++
    static PyObject *
    iter_iternext(PyObject *iterator)
    {
        seqiterobject *it;
        PyObject *seq;
        PyObject *result;

        assert(PySeqIter_Check(iterator));      // 检查是否是一个迭代器
        it = (seqiterobject *)iterator;
        seq = it->it_seq;                       // 取出其中的序列
        if (seq == NULL)
            return NULL;
        if (it->it_index == LONG_MAX) {
            PyErr_SetString(PyExc_OverflowError,
                            "iter index too large");
            return NULL;
        }

        result = PySequence_GetItem(seq, it->it_index);         // 类似于直接按下标取值seq[it->it_index]
        if (result != NULL) {
            it->it_index++;
            return result;
        }
        if (PyErr_ExceptionMatches(PyExc_IndexError) ||             // StopIteration或索引越界都认为结束了
            PyErr_ExceptionMatches(PyExc_StopIteration))
        {
            PyErr_Clear();
            it->it_seq = NULL;                  // 将序列的指针置为null
            Py_DECREF(seq);
        }
        return NULL;                            // 返回，后续会根据null决定是否结束for循环
    }
    ```

# Lecture 8. User-defined classes and objects

### 1. class

* python测试代码(test.py)
    ```python
    class Counter(object):
        def __init__(self, low, high):
            self.current = low
            self.high = high

        def __iter__(self):
            return self

        def __next__(self):         # 在python2中，没有双下划线，就叫`next`
            if self.current > self.high:
                raise StopIteration
            else:
                self.current += 1
                return self.current - 1

    c =  Counter(5, 7)
    ```
    ```bash
    PS D:\CODE\Python-2.7.18> python -m dis .\test.py
    # 这部分就是定义类class Counter和创建Counter对象c的部分，使用python2编译器编译出来的内容只会打印这部分
    1            0 LOAD_BUILD_CLASS        # python2中，是先load多个const，才执行BUILD_CLASS
                 2 LOAD_CONST               0 (<code object Counter at 0x000001C5B0ACAEA0, file ".\test.py", line 1>)
                 4 LOAD_CONST               1 ('Counter')
                 6 MAKE_FUNCTION            0
                 8 LOAD_CONST               1 ('Counter')
                10 LOAD_NAME                0 (object)
                12 CALL_FUNCTION            3
                14 STORE_NAME               1 (Counter)

    16          16 LOAD_NAME                1 (Counter)
                18 LOAD_CONST               2 (5)
                20 LOAD_CONST               3 (7)
                22 CALL_FUNCTION            2
                24 STORE_NAME               2 (c)
                26 LOAD_CONST               4 (None)
                28 RETURN_VALUE
    # 这儿是创建类 本身这个对象的部分，主要就是定义了它的各个函数的code object
    Disassembly of <code object Counter at 0x000001992E279EA0, file ".\test.py", line 1>:
    1            0 LOAD_NAME                0 (__name__)
                 2 STORE_NAME               1 (__module__)
                 4 LOAD_CONST               0 ('Counter')
                 6 STORE_NAME               2 (__qualname__)

    2            8 LOAD_CONST               1 (<code object __init__ at 0x000001992E279C90, file ".\test.py", line 2>)
                10 LOAD_CONST               2 ('Counter.__init__')
                12 MAKE_FUNCTION            0
                14 STORE_NAME               3 (__init__)

    6           16 LOAD_CONST               3 (<code object __iter__ at 0x000001992E279D40, file ".\test.py", line 6>)
                18 LOAD_CONST               4 ('Counter.__iter__')
                20 MAKE_FUNCTION            0
                22 STORE_NAME               4 (__iter__)

    9           24 LOAD_CONST               5 (<code object next at 0x000001992E279DF0, file ".\test.py", line 9>)
                26 LOAD_CONST               6 ('Counter.next')
                28 MAKE_FUNCTION            0
                30 STORE_NAME               5 (next)
                32 LOAD_CONST               7 (None)
                34 RETURN_VALUE
    # 这儿是__init__函数的部分
    Disassembly of <code object __init__ at 0x000001992E279C90, file ".\test.py", line 2>:
    3            0 LOAD_FAST                1 (low)
                 2 LOAD_FAST                0 (self)
                 4 STORE_ATTR               0 (current)

    4            6 LOAD_FAST                2 (high)
                 8 LOAD_FAST                0 (self)
                10 STORE_ATTR               1 (high)
                12 LOAD_CONST               0 (None)
                14 RETURN_VALUE
    # __iter__部分
    Disassembly of <code object __iter__ at 0x000001992E279D40, file ".\test.py", line 6>:
    7           0 LOAD_FAST                0 (self)
                2 RETURN_VALUE
    # next函数
    Disassembly of <code object __next__ at 0x000001992E279DF0, file ".\test.py", line 9>:
    10           0 LOAD_FAST                0 (self)
                 2 LOAD_ATTR                0 (current)
                 4 LOAD_FAST                0 (self)
                 6 LOAD_ATTR                1 (high)
                 8 COMPARE_OP               4 (>)
                10 POP_JUMP_IF_FALSE       18

    11          12 LOAD_GLOBAL              2 (StopIteration)
                14 RAISE_VARARGS            1
                16 JUMP_FORWARD            24 (to 42)

    13     >>   18 LOAD_FAST                0 (self)
                20 DUP_TOP
                22 LOAD_ATTR                0 (current)
                24 LOAD_CONST               1 (1)
                26 INPLACE_ADD
                28 ROT_TWO
                30 STORE_ATTR               0 (current)

    14          32 LOAD_FAST                0 (self)
                34 LOAD_ATTR                0 (current)
                36 LOAD_CONST               1 (1)
                38 BINARY_SUBTRACT
                40 RETURN_VALUE
            >>  42 LOAD_CONST               0 (None)
                44 RETURN_VALUE
    ```
* 由于python版本问题，上面的编译结果和展示的代码并不一致（问题不大
* `BUILD_CLASS`字节码在`ceval.c`中的代码如下：
    ```c++
    TARGET_NOARG(BUILD_CLASS)
    {
        u = TOP();      // 函数的字典
        v = SECOND();   // 基类
        w = THIRD();    // 类名
        STACKADJ(-2);
        x = build_class(u, v, w);
        SET_TOP(x);
        Py_DECREF(u);
        Py_DECREF(v);
        Py_DECREF(w);
        break;
    }

    static PyObject *
    build_class(PyObject *methods, PyObject *bases, PyObject *name)
    {
        PyObject *metaclass = NULL, *result, *base;

        if (PyDict_Check(methods))      // 对函数做检查
            metaclass = PyDict_GetItemString(methods, "__metaclass__");
        if (metaclass != NULL)
            Py_INCREF(metaclass);
        else if (PyTuple_Check(bases) && PyTuple_GET_SIZE(bases) > 0) {
            base = PyTuple_GET_ITEM(bases, 0);
            metaclass = PyObject_GetAttrString(base, "__class__");
            if (metaclass == NULL) {
                PyErr_Clear();
                metaclass = (PyObject *)base->ob_type;
                Py_INCREF(metaclass);
            }
        }
        else {
            PyObject *g = PyEval_GetGlobals();
            if (g != NULL && PyDict_Check(g))
                metaclass = PyDict_GetItemString(g, "__metaclass__");
            if (metaclass == NULL)
                metaclass = (PyObject *) &PyClass_Type;
            Py_INCREF(metaclass);
        }
        result = PyObject_CallFunctionObjArgs(metaclass, name, bases, methods,
                                            NULL);  // 函数内部调用了metaclass->ob_type->tp_call执行了`PyClass_New`
        Py_DECREF(metaclass);
        if (result == NULL && PyErr_ExceptionMatches(PyExc_TypeError)) {
            /* A type error here likely means that the user passed
            in a base that was not a class (such the random module
            instead of the random.random type).  Help them out with
            by augmenting the error message with more information.*/

            PyObject *ptype, *pvalue, *ptraceback;

            PyErr_Fetch(&ptype, &pvalue, &ptraceback);
            if (PyString_Check(pvalue)) {
                PyObject *newmsg;
                newmsg = PyString_FromFormat(
                    "Error when calling the metaclass bases\n"
                    "    %s",
                    PyString_AS_STRING(pvalue));
                if (newmsg != NULL) {
                    Py_DECREF(pvalue);
                    pvalue = newmsg;
                }
            }
            PyErr_Restore(ptype, pvalue, ptraceback);
        }
        return result;
    }   
    ```
* `classobject`里定义的类对象，类实例对象，类方法对象
    ```c++
    typedef struct {
        PyObject_HEAD
        PyObject	*cl_bases;	/* A tuple of class objects */      // 基类
        PyObject	*cl_dict;	/* A dictionary */                  // 方法字典
        PyObject	*cl_name;	/* A string */                      // 类型
        /* The following three are functions or NULL */         // 应该是属性描述符（流畅的python中有介绍）
        PyObject	*cl_getattr;
        PyObject	*cl_setattr;
        PyObject	*cl_delattr;
        PyObject    *cl_weakreflist; /* List of weak references */
    } PyClassObject;

    typedef struct {
        PyObject_HEAD
        PyClassObject *in_class;	/* The class object */          // 所属的类
        PyObject	  *in_dict;	/* A dictionary */                  // 实例对象里的字典也就是__dict__
        PyObject	  *in_weakreflist; /* List of weak references */
    } PyInstanceObject;

    typedef struct {
        PyObject_HEAD
        PyObject *im_func;   /* The callable object implementing the method */      // 原始函数本身
        PyObject *im_self;   /* The instance it is bound to, or NULL */         // 指向实例对象自己的指针（我懂得）
        PyObject *im_class;  /* The class that asked for the method */          // 所属的类
        PyObject *im_weakreflist; /* List of weak references */
    } PyMethodObject;
    ```
* 使用python定义的类实例化对象，通过执行`CALL_FUNCTION`字节码，最终调用了`PyInstance_New`函数(`PyClass_Type->tp_call`指针所指向的方法)
    ```c++
    PyObject *
    PyInstance_New(PyObject *klass, PyObject *arg, PyObject *kw)
    {
        register PyInstanceObject *inst;
        PyObject *init;
        static PyObject *initstr;

        if (initstr == NULL) {
            initstr = PyString_InternFromString("__init__");
            if (initstr == NULL)
                return NULL;
        }
        inst = (PyInstanceObject *) PyInstance_NewRaw(klass, NULL);     // 这儿是创建实例对象的
        if (inst == NULL)
            return NULL;
        init = instance_getattr2(inst, initstr);                        // 获取__init__方法
        if (init == NULL) {
            if (PyErr_Occurred()) {
                Py_DECREF(inst);
                return NULL;
            }
            if ((arg != NULL && (!PyTuple_Check(arg) ||
                                PyTuple_Size(arg) != 0))
                || (kw != NULL && (!PyDict_Check(kw) ||
                                PyDict_Size(kw) != 0))) {
                PyErr_SetString(PyExc_TypeError,
                        "this constructor takes no arguments");
                Py_DECREF(inst);
                inst = NULL;
            }
        }
        else {
            PyObject *res = PyEval_CallObjectWithKeywords(init, arg, kw); // 执行init方法，注意这儿的method方法有instance对象本身(im_self)，因此不需要再额外传入实例化的对象inst
            Py_DECREF(init);
            if (res == NULL) {
                Py_DECREF(inst);
                inst = NULL;
            }
            else {
                if (res != Py_None) {
                    PyErr_SetString(PyExc_TypeError,
                            "__init__() should return None");
                    Py_DECREF(inst);
                    inst = NULL;
                }
                Py_DECREF(res);
            }
        }
        return (PyObject *)inst;
    }
    ```
* 视频最后还讲了关于`bounded method`和`unbound method`的一些内容，简单来说，就是使用类取得的函数是`unbound`的，调用时需要显示传入对象，但对象调用自身方法时，已经绑定了对应的对象，它是一个`bounded`方法，无需再传入自身。尤其在使用一些装饰器时需要多加注意，想获取`bounded method`应当使用`inspece.get_members`之类的。
* <font color=red>对于`metaclass`创建类的过程仍未十分清晰，若有时间，仍需仔细看下</font>


# Lecture 9. Generators

### 1. 生成器

* python测试代码(test.py)
    ```python
    def Counter(low, high):
        current = low
        while current <= high:
            yield current
            current += 1
    
    c =  Counter(5, 7)
    for elt in c:
        print(elt)
    ```
    编译过后:
    ```bash
    PS D:\CODE\Python-2.7.18> python -m dis .\test.py
                 1 ('Counter')
                  4 MAKE_FUNCTION            0
                  6 STORE_NAME               0 (Counter)
    # 创建Counter(5, 7)对象
      7           8 LOAD_NAME                0 (Counter)
                 10 LOAD_CONST               2 (5)
                 12 LOAD_CONST               3 (7)
                 14 CALL_FUNCTION            2
                 16 STORE_NAME               1 (c)
    # for 循环 
      8          18 LOAD_NAME                1 (c)
                 20 GET_ITER
            >>   22 FOR_ITER                12 (to 36)
                 24 STORE_NAME               2 (elt)
    
      9          26 LOAD_NAME                3 (print)
                 28 LOAD_NAME                2 (elt)
                 30 CALL_FUNCTION            1
                 32 POP_TOP
                 34 JUMP_ABSOLUTE           22
            >>   36 LOAD_CONST               4 (None)
                 38 RETURN_VALUE
    # Counter 函数的字节码 
    Disassembly of <code object Counter at 0x000001DC7D029870, file ".\test.py", line 1>:
      2           0 LOAD_FAST                0 (low)
                  2 STORE_FAST               2 (current)
    
      3     >>    4 LOAD_FAST                2 (current)
                  6 LOAD_FAST                1 (high)
                  8 COMPARE_OP               1 (<=)
                 10 POP_JUMP_IF_FALSE       28
    
      4          12 LOAD_FAST                2 (current)
                 14 YIELD_VALUE             # yield对应的字节码，也是唯一区别之处
                 16 POP_TOP
    
      5          18 LOAD_FAST                2 (current)
                 20 LOAD_CONST               1 (1)
                 22 INPLACE_ADD
                 24 STORE_FAST               2 (current)
                 26 JUMP_ABSOLUTE            4
            >>   28 LOAD_CONST               0 (None)
                 30 RETURN_VALUE
    ```

### 2. `YIELD_VALUE`
* 生成器函数的字节码与普通函数的区别主要就是`YIELD_VALUE`，打会打断循环，函数调用等 原本的执行顺序（直接交付返回值）
* 在`ceval.c`中的具体执行的代码如下：
    ```c++
    // switch... case YIELD_VALUE
    TARGET_NOARG(YIELD_VALUE)
    {
        retval = POP();         // 每次执行这个YIELD_VALUE，会退出执行并返回栈顶的结果
        f->f_stacktop = stack_pointer;
        why = WHY_YIELD;
        goto fast_yield;
    }
    // fast_yield部分的代码如下
    fast_yield:
        if (tstate->use_tracing) {      // 应该时调试用的部分
            if (tstate->c_tracefunc) {
                if (why == WHY_RETURN || why == WHY_YIELD) {
                    if (call_trace(tstate->c_tracefunc,
                                tstate->c_traceobj, f,
                                PyTrace_RETURN, retval)) {
                        Py_XDECREF(retval);
                        retval = NULL;
                        why = WHY_EXCEPTION;
                    }
                }
                else if (why == WHY_EXCEPTION) {
                    call_trace_protected(tstate->c_tracefunc,
                                        tstate->c_traceobj, f,
                                        PyTrace_RETURN, NULL);
                }
            }
            if (tstate->c_profilefunc) {
                if (why == WHY_EXCEPTION)
                    call_trace_protected(tstate->c_profilefunc,
                                        tstate->c_profileobj, f,
                                        PyTrace_RETURN, NULL);
                else if (call_trace(tstate->c_profilefunc,
                                    tstate->c_profileobj, f,
                                    PyTrace_RETURN, retval)) {
                    Py_XDECREF(retval);
                    retval = NULL;
                    why = WHY_EXCEPTION;
                }
            }
        }

        if (tstate->frame->f_exc_type != NULL)
            reset_exc_info(tstate);
        else {
            assert(tstate->frame->f_exc_value == NULL);
            assert(tstate->frame->f_exc_traceback == NULL);
        }
    //... 其他几个goto的标志
    return retval;      // 返回结果
    ```


### 3. `genobject`生成器对象

* cpython 的结构体定义
    ```c++
    typedef struct {
        PyObject_HEAD
        /* The gi_ prefix is intended to remind of generator-iterator. */

        /* Note: gi_frame can be NULL if the generator is "finished" */
        struct _frame *gi_frame;            // 函数运行时的frame，只要不为空，就可以一直被运行（not finished）

        /* True if generator is being executed. */
        int gi_running;
        
        /* The code object backing the generator */
        PyObject *gi_code;

        /* List of weak reference. */
        PyObject *gi_weakreflist;
    } PyGenObject;
    ```
* 每当想获取生成器对象`gen`的迭代器时`gen->tp_iter`，生成器对象会把自己返回过去，当调用`gen.next`方法`gen->tp_iternext`的时候，其实执行的是`gen_iternext`方法，因此生成器对象可以非常自然地表现地像是一个迭代器和可迭代对象
    ```c++
    PyTypeObject PyGen_Type = {
        PyVarObject_HEAD_INIT(&PyType_Type, 0)
        "generator",                                /* tp_name */
        sizeof(PyGenObject),                        /* tp_basicsize */
        0,                                          /* tp_itemsize */
        /* methods */
        (destructor)gen_dealloc,                    /* tp_dealloc */
        0,                                          /* tp_print */
        0,                                          /* tp_getattr */
        0,                                          /* tp_setattr */
        0,                                          /* tp_compare */
        (reprfunc)gen_repr,                         /* tp_repr */
        0,                                          /* tp_as_number */
        0,                                          /* tp_as_sequence */
        0,                                          /* tp_as_mapping */
        0,                                          /* tp_hash */
        0,                                          /* tp_call */
        0,                                          /* tp_str */
        PyObject_GenericGetAttr,                    /* tp_getattro */
        0,                                          /* tp_setattro */
        0,                                          /* tp_as_buffer */
        Py_TPFLAGS_DEFAULT | Py_TPFLAGS_HAVE_GC,/* tp_flags */
        0,                                          /* tp_doc */
        (traverseproc)gen_traverse,                 /* tp_traverse */
        0,                                          /* tp_clear */
        0,                                          /* tp_richcompare */
        offsetof(PyGenObject, gi_weakreflist),      /* tp_weaklistoffset */
        PyObject_SelfIter,                          /* tp_iter */       // 生成器的迭代器就是它自己
        (iternextfunc)gen_iternext,                 /* tp_iternext */   // 生成器的next方法执行的是`gen_iternext`函数
        gen_methods,                                /* tp_methods */
        gen_memberlist,                             /* tp_members */
        gen_getsetlist,                             /* tp_getset */
        0,                                          /* tp_base */
        0,                                          /* tp_dict */

        0,                                          /* tp_descr_get */
        0,                                          /* tp_descr_set */
        0,                                          /* tp_dictoffset */
        0,                                          /* tp_init */
        0,                                          /* tp_alloc */
        0,                                          /* tp_new */
        0,                                          /* tp_free */
        0,                                          /* tp_is_gc */
        0,                                          /* tp_bases */
        0,                                          /* tp_mro */
        0,                                          /* tp_cache */
        0,                                          /* tp_subclasses */
        0,                                          /* tp_weaklist */
        gen_del,                                    /* tp_del */
    };
    ```
* 像上述的`gen_iternext`，`gen_send`等函数，在`genobject.c`中，执行的都是`gen_send_ex`函数，这个函数，就是每次驱动生成器推进的主要逻辑所在，具体的代码如下：
    ```c++
    static PyObject *
    gen_send_ex(PyGenObject *gen, PyObject *arg, int exc)
    {
        PyThreadState *tstate = PyThreadState_GET();
        PyFrameObject *f = gen->gi_frame;           // 取出上一次执行过程中的frame
        PyObject *result;

        if (gen->gi_running) {                      // 如果生成器已经在执行过程中了，就会抛异常(大概是在生成器执行过程中，又把自己执行了一遍)
            PyErr_SetString(PyExc_ValueError,
                            "generator already executing");
            return NULL;
        }
        if (f==NULL || f->f_stacktop == NULL) {         // 当生成器的frame为空时，就抛出StopInteration
            /* Only set exception if called from send() */
            if (arg && !exc)
                PyErr_SetNone(PyExc_StopIteration);
            return NULL;
        }

        if (f->f_lasti == -1) {
            if (arg && arg != Py_None) {
                PyErr_SetString(PyExc_TypeError,
                                "can't send non-None value to a "
                                "just-started generator");
                return NULL;
            }
        } else {
            /* Push arg onto the frame's value stack */
            result = arg ? arg : Py_None;       // 如果send方法没有传入参数，就置为None
            Py_INCREF(result);
            *(f->f_stacktop++) = result;        // 把参数压入栈顶
        }

        /* Generators always return to their most recent caller, not
        * necessarily their creator. */
        f->f_tstate = tstate;
        Py_XINCREF(tstate->frame);
        assert(f->f_back == NULL);
        f->f_back = tstate->frame;

        gen->gi_running = 1;            // 讲正在运行的标记置为1
        result = PyEval_EvalFrameEx(f, exc);        // 重新执行生成器中的代码，并取出结果(由上面分析的结果看，他会在`YIELD_VALUE`部分返回结果，不会无止境的执行下去)
        gen->gi_running = 0;            // 重置为0

        /* Don't keep the reference to f_back any longer than necessary.  It
        * may keep a chain of frames alive or it could create a reference
        * cycle. */
        assert(f->f_back == tstate->frame);
        Py_CLEAR(f->f_back);
        /* Clear the borrowed reference to the thread state */
        f->f_tstate = NULL;

        /* If the generator just returned (as opposed to yielding), signal
        * that the generator is exhausted. */
        if (result == Py_None && f->f_stacktop == NULL) {
            Py_DECREF(result);
            result = NULL;
            /* Set exception if not called by gen_iternext() */
            if (arg)
                PyErr_SetNone(PyExc_StopIteration);
        }

        if (!result || f->f_stacktop == NULL) {
            /* generator can't be rerun, so release the frame */
            Py_DECREF(f);
            gen->gi_frame = NULL;       // 生成器是一次性的，本质上就是这个frame在不断地被打断和启动
        }

        return result;
    }
    ```