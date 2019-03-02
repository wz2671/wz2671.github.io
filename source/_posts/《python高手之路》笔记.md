---
title: 《python高手之路》笔记
date: 2018-07-10 14:16:33
tags: python笔记
---

最近从图书馆借了本《python高手之路》，看着似乎不错，趁着跑实验的空档，拜读一下，顺便做些笔记。  
著：Julien Danjou  
译：王飞龙  
人民邮电出版社出版发行  


![飞得更高](https://raw.githubusercontent.com/wz2671/wz2671.github.io/master/static/images/blog/pythonfly.jpeg)

<!-- more -->

***

#### 1. 编码风格 

**编写Python代码的[PEP8](https://www.python.org/dev/peps/pep-0008/)标准**

* 每个缩进层级使用4个空格。  
* 每行最多79个字符。  
* 顶层的函数或类的定义之间空两行。  
* 采用ASCII或UTF-8编码文件。  
* 在文件顶端，注释和文档说明之下，每行每条`import`语句只导入一个模块，同时要按标准库、第三方库和本地库的导入顺序进行分组。  
* 在小括号、中括号、大括号之间或者都好之前没有额外的空格。  
* 类的命名采用骆驼命名法；异常的定义使用`ERROR`前缀；函数的命名使用下划线分隔的小写字母；用下划线开头定义私有的属性或方法。  

**可以使用工具[pep8](https://pypi.org/project/pep8/)自动检查Python文件是否符合PEP8要求**

 ***

#### 2. Python之禅
```plane
	The Zen of Python, by Tim Peters
	
	Beautiful is better than ugly.
	Explicit is better than implicit.
	Simple is better than complex.
	Complex is better than complicated.
	Flat is better than nested.
	Sparse is better than dense.
	Eeadability counts.
	Special cases aren't special enough to break the rules.
	Although practicality beats purity.
	Unless explicitly silenced.
	In the face of ambiguity, refuse the temptation to guess.
	There should be one-- and preferably one one --obvious way to do it.
	Although that way may bot be obvious at first unless you're Dutch.
	Now is better than never.
	Although never is often better than *right* now.
	If the implementation is hard to explain, it's a bad idea.
	If the implementation is easy to explain, it may be a good idea.
	Namespaces are one honking great idea -- let's do more of those!
```

***

#### 3. 常用标准库

* `atexit` 允许注册在程序退出时调用的函数。  
* `argparse` 提供解析命令行参数的函数。  
* `bisect` 为可排序列表提供二分查找算法。  
* `calendar` 提供一组与日期相关的函数。  
* `codecs` 提供编解码数据的函数。  
* `collections` 提供一组有用的数据结构。  
* `copy` 提供复制数据的函数。  
* `csv` 提供用于读写CSV文件的函数。  
* `datetime` 提供用于处理日期和时间的类。  
* `fnmatch` 提供用于匹配Unix风格文件名模式的函数。  
* `concurrent` 提供异步计算。  
* `glob` 提供用于匹配Unix风格路徑模式的函数。  
* `io` 提供用于处理I/O流的函数。  
* `json` 提供用来读写JSON格式数据的函数。  
* `logging` 提供对Python内置的日志功能的访问。  
* `multiprocessing` 可以在应用程序中运行多个子进程，而且提供API让这些子进程看上去像线程一样。  
* `operator` 提供实现基本的Python运算符功能的函数，可以使用这些函数而不是自己写`lambda`表达式。  
* `os` 提供对基本的操作系统函数的访问。  
* `random` 提供生成伪随机数的函数。  
* `re` 提供正则表达式功能。  
* `sched` 提供一个无需多线程的事件调度器。  
* `select` 提供对函数`select()`和`poll()`的访问，用于创建事件循环。  
* `shutil` 提供对高级文件处理函数的访问。  
* `signal` 提供用于处理POSIX信号的函数。  
* `tempfile` 提供用于创建临时文件和目录的函数。  
* `threading` 提供对处理高级线程功能的访问。  
* `urllib` 提供处理和解析URL的函数。  
* `uuid` 可以生成全局唯一标识符。  

***

#### 4. 文档

Python中文档格式的事实标准是`reStructuredText`，或者简称`reST`。  
项目的文档应包括下列内容：  
* 用一两句话描述这个项目要解决的问题。  
* 项目所基于的分发许可。  
* 一个展示项目如何工作的小例子。  
* 安装指南。  
* 指向社区支持、邮件列表、IRC、论坛等的链接。  
* 指向bug跟踪系统的链接。  
* 指向源代码的链接，以便开发人员可以下载并立刻投入开发。  
* 还应该包括一个`README.rst`文件，解释这个项目是做什么的。  

**可以利用`Sphinx`模块及其扩展实现自动化文档和其他功能**

***

#### 5. 分发

1. 历史  
* `distutils`是标准库的一部分，能处理简单的包的安装。  
* `setuptools`是领先的包安装标准，曾经被废弃但现在又继续开发。  
* `distribute`从0.7版本开始并入了`setuptools`。  
* `distutils2`（也称为`packaging`）已经被废弃。  
* `distlib`将来可能会取代`distutils`。  

2. 使用`pbr`打包  
`pbr`是指`Python Build Reasonableness`。它的处理方式直接受`distutils2`的启发。  
**`pbr`还提供了其他一些功能：**  
* 基于`requitements.txt`做自动依赖安装。  
* 利用`Sphinx`实现文档自动化。  
* 基于_git_ history自动生成AUTHORS和ChangeLog文件。  
* 针对_git_自动创建文件列表。  
* 基于_git_ tags的版本管理。  

3. Wheel格式  
[PEP427](https://www.python.org/dev/peps/pep-0427/)针对Python的分发包定义了新的标准，名为`Wheel`。已有相应工具作为这一格式的参考实现，也命名为[Wheel](https://pypi.org/project/wheel/)。  

4. 发布成果  
	1. 使用`sdist`命令生成一个用来分发的源代码`tarball`。  
	2. 可以使用PyPI[预付费服务器](https://test.pypi.org/)测试发布流程。(在测试服务器上注册项目，在索引中注册项目，上传一个源代码分发`tarball`和`Wheel`归档文件。在服务器上搜索包确认是否上传成功。)  
	3. 上传项目到PyPI主服务器。  

5. 入口点  

* 利用[entry_point_inspector](https://pypi.org/project/entry_point_inspector/)的包可视化一个包中可用的入口点。  
* 使用控制台脚本，利用`setuptools`的功能`console_scripts`，它能够用来帮助`setuptools`安装一个很小的程序到系统目录中，并通过它调用应用程序中某个模块的特定函数。  
* 使用插件和驱动程序，[stevedore](https://pypi.org/project/stevedore/)提供了对动态插件的支持。  

***

#### 6. 虚拟环境

**环境问题**  
* 系统中没有需要的库；  
* 系统中没有需要的库的正确版本；  
* 对两个不同的应用程序可能需要同一个库的两个不同的版本；  

解决方案： **每个应用程序（包含其依赖）都使用独立的库目录，然后使用这个目录加载所需的Python模块**  

工具`virtualenv`可以自动处理这些目录。  

[PEP 405](https://www.python.org/dev/peps/pep-0405/)定义了虚拟环境机制。  
`venv`模块可以操作虚拟环境而无需使用`virtualenv`包或者其他包。  

***

#### 7. 单元测试

**基础知识**  
* 测试应该保存在应用程序或库的tests子模块中。  
* 通常比较简单的方式是采用模块树的层次结构作为测试树的层级结构。例如，覆盖代码`mylib/foobar.py`的测试应该存储在`mylib/tests/test_foobar.py`中。  
* [nose](https://nose.readthedocs.io/en/latest/)提供`nosetests`命令会加载所有以`test_`开头的文件，然后执行其中所有以`test_`开头的函数。  
* [unittest](https://pypi.org/project/unittest/)能在测试失败的时候，给出测试失败的真正信息（写测试用例时**永远**不应该使用`assert`）。  
* 可以使用`fail(msg)`方法有意让某个测试立刻失败。  
* 如果想忽略某个测试，可以抛出`unittest.SkipTest`异常、使用`unittest.TestCase.skipTest()`方法、或使用`unittest.skip`装饰器。  
* 如果需要在运行某个测试前后执行一组通用的操作，`unittest`提供了两个特殊的方法`setUp`和`tearDown`，它们会在类的每个测试方法调用前后执行一次。经常被称为`fixture`，[fixtures](https://pypi.org/project/fixtures/)Python模块提供了一种简单的创建`fixture`类和对象的机制。  

**模拟(mocking)**  
* `mock`对象即模拟对象，用来通过莫中特殊和可控的方式模拟真实应用程序对像的行为。Python标准库中用来创建`mock`对象的库名为[mock](https://pypi.org/project/mock/)。  
* `mock.patch`方法可以修改外部代码的任何部分，使其按照需要的方式对软件进行各种条件下的测试。  

**场景测试**  
* 对某个对象的不同版本运行一组测试，对一组不同的对象运行同一个错误，对不同的驱动执行整个测试套件。可以使用混入类(mixin class)实现这一点。  
* [testscenarios](https://pypi.org/project/testscenarios/)提供了一种简单的方式针对一组实时生成的不同场景运行类测试。  

**测试序列与并行**  
* [subunit](https://pypi.org/project/python-subunit/)是用来为测试结果提供流协议(streaming protocol)的一个Python模块，可以聚合测试结果或者对测试的运行进行记录或归档等。  
* [testrepository](https://pypi.org/project/testrepository/)可以在测试用例的数量很多时，让程序处理测试结果序列。  
* 通过编辑项目的根目录中的`.testr.conf`文件使`testr`自动执行要运行的测试，自己去加载测试结果。  

**测试覆盖**  
* [coverage](https://pypi.org/project/coverage/)模块可以指出程序的哪些部分从来没有被运行过，以及哪些可能是"僵尸代码"。  
* 使用`nosetests --cover-package=xxx --with-coverage tests.test_xxxx.py`即可结合`nose`生成一份不错的代码覆盖报告。  
* `python setup.py testr --coverage`可以在使用`testrepository`时，使用`setuptools`集成运行`coverage`自动运行测试集，并在`cover`目录中生成HTML报告。  

**使用虚拟环境和tox**  
* `tox`的目标是自动化和标准化Python中运行测试的方式。它提供了在一个干净的虚拟环境中运行整个测试集的所有功能，并安装被测试的应用程序以检查其安装是否正常。  


**测试策略**  
* 最低目标是保证每次代码提交都能通过所有测试，最好是能以自助的方式实现。  
* 如果正在使用流行的`GitHub`托管服务，[Travis CI](https://travis-ci.org/)提供了一种在代码的签入(push)、合并(merge)或签出(pull)请求后运行测试的方式。  

***

#### 8. 方法和装饰器

Python中提供了装饰器(decorator)作为修改函数的一种便捷方式[PEP318](http://www.python.org/dev/peps/pep-0318/)。  

**装饰器本质上就是一个函数，这个函数接收其他函数作为参数，并将其以一个新的修改后的函数替换它**  

例：以下函数，它们在被调用时检查"用户名"参数：  
```python
class Store(object):
    def get_food(self, username, food):
        if username != 'admin':
            raise Expection("This user is not allowed to get food")
        return self.storage.get(food)

    def put_food(self, username, food):
        if username != 'admin':
            raise Expection("This user is not allowed to put food")
        return self.storage.put(food)
```

有了装饰器以后：  
```python
def check_is_admin(f):
    def wrapper(*args, **kwargs):
        if kwargs.get('username') != 'admin':
            raise Exception("This user is not allowed to get food")
        return f(*args, **kwargs)
    return wrapper

class Store(object):
    @check_is_admin
    def get_food(self, username, food):
        return self.storage.get(food)

    @check_is_admin
    def put_food(self, username, food):
        self.storage.put(food)

```


**原生方法的主要缺点：**  
新函数缺少很多原函数的属性，如文档字符串和名字。  
可以通过Python内置的`functools`中`update_wrapper`函数或者名为`wraps`的装饰器解决。  
`inspect`模块允许提取函数的签名并对其进行操作。  


**静态方法**  

装饰器`@staticmethod`提供了以下几种功能：  
* Python不必为我们创建的每个Pizza对象实例化一个绑定方法。可以节约创建绑定方法(对象)的开销。  
* 提高代码的可读性。  
* 可以在子类中覆盖静态方法。  

**类方法**  

类方法是直接绑定到类而非它的实例的方法`@classmethod`。  
类方法对于创建工厂方法最有用，即以特定方式实例化对象。  


**抽象方法**  

可以使用Python内置的[abc](https://docs.python.org/3/library/abc.html)模块实现抽象方法。  


**super**  

`super()`函数实际上是一个构造器，每次调用它都会实例化一个`super`对象。它接收一个或两个参数，地一个参数是一个类，第二个参数是一个子类或第一个参数的一个实例。  
构造器返回的对象就像是地一个参数的父类的一个代理。它有自己的`__getattribute__`方法去遍历MRO列表中的类并返回第一个满足条件的属性。  
`super`是在子类中访问父类属性的标准方式，应该尽量使用它。它能确保父类方法的协作调用而不出意外。  

***

#### 9. 函数式编程

函数式编程具有以下实用的特点：  
* 可证明性。  
* 模块化。  
* 简洁。  
* 并发。  
* 可测性。  

**生成器**  

* 生成器是在[PEP 255](https://www.python.org/dev/peps/pep-0255/)中引入的，并提供了一种比较简单的实现迭代器协议([iterator protocol](https://docs.python.org/3/c-api/iter.html))的方式来创建对象。  

* 在Python中，生成器的构建是通过在函数产生某对象时保持一个对栈的引用来实现的，并在需要时恢复这个栈。Python3中可以使用函数`inspect.getgeneratorstate`给出生成器的状态。  

* 摘自[Python yield 使用浅析](https://www.ibm.com/developerworks/cn/opensource/os-cn-python-yield/)
> `yield`的作用就是把一个函数变成一个`generator`，带有`yield`的函数不再是一个普通函数，Python解释器会将其视为一个`generator`，调用`fab(5)`不会执行`fab`函数，而是返回一个 `iterable`对象！在`for`循环执行时，每次循环都会执行`fab`函数内部的代码，执行到`yield b` 时，`fab`函数就返回一个迭代值，下次迭代时，代码从`yield b`的下一条语句继续执行，而函数的本地变量看起来和上次中断执行前是完全一样的，于是函数继续执行，直到再次遇到`yield`。
当函数执行结束时，`generator`自动抛出`StopIteration`异常，表示迭代完成。在`for`循环里，无需处理`StopIteration`异常，循环会正常结束。
一个带有`yield`的函数就是一个`generator`，它和普通函数不同，生成一个`generator`看起来像函数调用，但不会执行任何函数代码，直到对其调用`next()`（在`for`循环中会自动调用`next()`）才开始执行。虽然执行流程仍按函数的流程执行，但每执行到一个`yield`语句就会中断，并返回一个迭代值，下次执行时从`yield`的下一个语句继续执行。看起来就好像一个函数在正常执行的过程中被`yield`中断了数次，每次中断都会通过`yield`返回当前的迭代值。


**函数式函数的函数化**  

Python中包含很多针对函数式编程的工具。  

* `map(function, iterable)`对`iterable`中的每一个元素应用`function`，在Python2中返回一个列表，在Python3中返回可迭代的`map`对象。  

* `reduce(func, seq[, init()])`每一次迭代，都将上一次的迭代结果（注：第一次为`init`元素，如果没有指定`init`则为`seq`的第一个元素）与下一个元素一同传入二元`func`函数中去执行。在`reduce()`函数中，`init`是可选的，如果指定，则作为第一次迭代的第一个元素使用，如果没有指定，就取`seq`中的第一个元素。  

* `filter(function or None, iterable)`对`iterable`中的元素应用`function`对返回结果进行过滤，在Python2中返回一个列表，在Python3中返回可迭代的`filter`对象。  

* `enumerate(iterable[, start])`返回一个可迭代的`enumerate`对象，当需要参考数组的索引编写代码时，就很有用。  

* `sorted(iterable, key=None, reverse=False)`返回`iterable`的一个已排序版本。通过参数`key`可以提供一个返回要排序的值的函数。  

* `any(iterable)`和`all(iterable)`都返回一个依赖于`iterable`返回的值的布尔值。  

* `zip(iter1 [, iter2 [...]])`接收多个序列并将它们组合成元组。它在将一组键和一组值组合成字典时很有用。  

* 使用Python包[first](https://pypi.org/project/first/)，**`functools.partial`**以及**`operator`**模块可以优雅地实现从列表中找出第一个满足条件的元素。  
```python
import operator
from functools import partial
from first import first
first([-1, 0, 1, 2], key=partial(operator.le, 0))
```

Python标准库中`itertools`模块提供的其他有用的函数：  
* `chain(*iterables)`依次迭代多个`iterables`但并不会构造包含所有元素的中间列表。  
* `combinations(iterable, r)`从给定的`iterable`中生成所有长度为r的组合。  
* `compress(data, selectors)`对data应用来自`selectors`的布尔掩码并从data中返回`selectors`中对应为真的元素。  
* `count(start, step)`创建一个无限的值的序列，从`start`开始，步长为`step`。  
* `cycle(iterable)`重复地遍历`iterable`中的值。  
* `dropwhile(predicate, iterable)`过滤`iterable`中的元素，丢弃符合`predicate`描述的那些元素。  
* `groupy(iterable, keyfunc)`根据`keyfunc`函数返回的结果对元素进行分组并返回一个迭代器。  
* `permutations(iterable[,r])`返回`iterable`中r个元素的所有集合。  
* `product(*iterables)`返回`iterables`的笛卡尔积的可迭代对象，但不使用嵌套的`for`循环。  
* `takewhile(predicate, iterable)`返回满足`predicate`条件的`iterable`中的元素。  

* **`itertools`和`operator`能够覆盖通常程序员依赖`lambda`表达式的大部分场景。**  
参考知乎对`lambda`的相关讨论[Lambda 表达式有何用处？如何使用？](https://www.zhihu.com/question/20125256)，如果引入`lambda`表达式不能使代码更简洁更易懂，那么应该避免使用(滥用)。  

***

#### 10. 抽象语法树

这一章看不懂。。。自己暂时还没有这么高的需求，暂时不深究了。。

* 抽象语法树(abstract syntax tree, AST)是任何语言源代码的抽象结构的树状表示。  
* Python中的`ast`模块可以解析一段Python代码并将其存储从而生成抽象语法树。  
* 用抽象语法树检查来扩展`flake8`。  
* 利用[Hy]()编程语言为Python创建一种新的语法，并将其解析并编译成标准的Python抽象语法树。  

***

#### 11. 性能与优化

> "过早优化是万恶之源。"
————donald Knuth, 摘自_Structured Programming with go to Statements_

**数据结构**  
利用Python提供的数据结构和代码，优雅而简单地解决计算机问题。  
有许多高级的数据结构可以极大地减少代码维护负担。例如，`collections.defaultdict`、`OrderedDict`、`Counter`等。  

**性能分析**  

* `cProfile`可以显示每个函数的调用次数，以及执行所花费的时间，可以使用`-s`选项按其他字段进行排序。  
`python -m cProfile myscript.py`  

* [Valgrind](http://valgrind.org/)能够提供对C程序的性能分析数据。  

* [KCacheGrind](http://kcachegrind.sourceforge.net/html/Home.html)能够对生成的数据进行可视化展示。  

```python
# 用KCacheGrind可视化Python性能分析数据
python -m cProfile -o myscript.cprof myscript.py
pyprof2calltree -k -i myscript.cprof
```

* 用`dis`模块可以对Python字节码进行反编译，能够从微观角度对代码进行分析。  
```python
def x():
    return 42

import dis
dis.dis(x)
```

**有序列表和二分查找**  

* 可以利用Python提供的`bisect`模块使用二分查找算法，也可以使用该模块提供的`insort_left`和`insort_right`函数实现立即插入。  

* 更多的数据类型，Python库已经实现了各种版本，**不要开发和调试自己的版本**。  

**namedtuple和slots**  

* Python中的类可以定义一个`__slots__`属性，用来制定仅该类的实例可用的属性。其作用在于可以将所有对象属性存储在一个`list`对象中，从而避免分配整个字典对象来存储所有的对象属性。  

* `collection`模块中`namedtuple`类允许动态创建一个继承自`tuple`的类，它不可变、条目数固定，但可以通过具名属性而不是索引获取元组的元素。  

**memoization**  

* `memoization`是指通过缓存函数返回结果来加速函数调用的一种技术。  

* `functools`模块提供了一个LRU(Least-Recently-Used)缓存装饰器，它在实现了`memoization`功能的同时，还限定了缓存的条目数目，当缓存的条目数目达到最大时移除最近最少使用的条目。  

**PyPy**

* [PyPy](https://www.pypy.org/)是符合标准的Python语言的一个高效实现。  

**通过缓冲区协议实现零复制**

* 可以使用[memory_profiler](https://pypi.org/project/memory_profiler/)衡量内存的使用情况。  

* 在Python中可以使用实现了**缓冲区协议**的对象。[PEP 3118](https://www.python.org/dev/peps/pep-3118/)定义了缓冲区协议。  

* 使用`memoryview`类的构建函数去构造一个新的`memoryview`对象，它会引用原始的对象内存。  

***

#### 其余章节

后续的部分介绍了扩展和架构、数据库处理、对python3的支持以及其他内容，等以后研究深入了，再来拜读！  

**延伸阅读**  

[The Hitchhiker’s Guide to Python!](https://docs.python-guide.org/)  
[Supporting Python 3: An in-depth guide](http://python3porting.com/)  
[Python Packaging User Guide](https://python-packaging-user-guide.readthedocs.io/)  



