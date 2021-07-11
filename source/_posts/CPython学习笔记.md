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
* `int`的加法实际实现在`intobject.c`里的`int_add`中
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
* PyObject对象的生成与内存分配在`object.c`中的`_PyObject_New`函数中。
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
* python中对象的动态性主要来源于，对每种类型都约束其特定接口，不同类型的PyObject传入后，会执行相同名称不同接口的具体实现
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
* 在`object.h`中还定义了`PyTypeObject`，这个就是每个`PyObject_HEAD`中的那个`ob_type`，超核心的类型指针对应的类型。（搜`_typeobject`比较好找）

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

* 字符串连接，本质上是解析并执行了`BINARY_ADD`这个字节码。执行起来就比较直接了，直接进行类型判断，调用`string_concatenate`函数
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
        // 这儿对闭包的变量解释了以下co_freevars里存的就是函数作用域范围外的变量，co_freevars和closure
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