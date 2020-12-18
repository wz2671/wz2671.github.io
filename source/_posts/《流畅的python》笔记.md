---
title: 《流畅的python》笔记
tags: python笔记
date: 2020-12-13 17:23:59
---

参考书籍：《流畅的python》(Fluent Python）

**更新中**

<!--more -->


# 一、Python数据模型


### 1. `__getitem__`方法

* 在语句`obj[key]`背后实际调用的就是`obj.__getitem__(key)`方法。
* 一般称之为“双下方法”(dunder method)
* 实现这个方法就可以支持切片(slicing)操作和迭代.
* 配合`__len__`方法，就能和Python自由的序列数据类型一样使用了。


### 2. 对于Python内置的类型（例如：list, str, bytearry），CPython会直接返回`PyVarObject`里的`ob_size`的值。它表示内存中长度可变的内置对象的C语言结构体。


### 3. 字符串表示形式

* `__repr__`和`__str__`，后者是在`str()`函数被使用，或者在用`print`函数时才被调用。
* 如果一个对象没有`__str__`函数而又需要时，解释器会用`__repr__`作为替代。
* [Difference between \__str\__ and \__repr\__ in Python](https://stackoverflow.com/questions/1436703/difference-between-str-and-repr)


### 4. 自定义布尔值

* `bool(x)`背后调用的是`__bool__`方法，如果不存在，那么会尝试调用`x.__len__()`。
* 如果想要`Vector.__bool__`更高效，可以返回`bool(self.x or self.y)`


### 5. 特殊方法

* 在Python语言参考手册[Data Model](https://docs.python.org/3/reference/datamodel.html)中列出了特殊方法。
* 集合模拟: `__len__`, `__getitem__`, `__setitem__`, `__delitem__`, `__contains__`。
* 迭代枚举: `__iter__`, `reversed__`, `__next__`。
* 属性管理: `__getattr__`, `getattribute__`, `__setattr__`, `__delattr__`, `__dir__`。


### 6. 为什么`len`不是普通方法

* `len`之所以不是一个普通方法，是为了让Python自带的数据结构可以走后门，`abs`也是同理。
* 我们也可以把`len`用于自定义数据类型，保证了语言的一致性。


***

# 二、序列构成的数组

### 1. 大佬(Raymond hettinger)实现了一个[排序集合模块](http://code.activestate.com/recipes/577197-sortedcollection)

* `itemgetter`的用法，在`operator`模块中，可以方便实现从字典中取值，`itemgetter('key')`相当于`lambda bdict: bdict['key']`，所以它还是个可调用的东西。
* `property`函数，可以免去装饰器的声明，直接将函数作为参数传入。（应该）只是换了一种写法。
    ```python
    class collection(object):
        def _getkey(self):
            pass
    
        def _setkey(self, key):
            pass
    
        def _delkey(self):
            pass
    
        key = property(_getkey, _setkey, _delkey, 'key function')
    ```

### 2. 内置序列类型

* 容器序列：`list`, `tuple`和`collections.deque`，这些序列能存放不同类型的数据。(存放的是他们包含对象的引用)
* 扁平序列：`str`, `bytes`, `bytearray`, `memoryview`, `array.array`， 这类序列只能容纳一种类型。(实质上是一段连续的内存空间)

* 可变序列：`list`, `bytearray`, `array.array`, `collections.deque`和`memoryview`。
* 不可变序列: `tuple`, `str`, `bytes`。

* 一般序列都包含方法`__contains__`, `__iter__`, `__len__`方法。
* 不可变序列还包含`__getitem__`, `__reversed__`, `index`, `count`等方法。
* 可变序列在不可变序列的基础上，还包含`__setitem__`, `__delitem__`, `insert`, `append`, `reverse`, `extend`, `pop`, `remove`, `__iadd__`等操作方法。

### 3. 列表推导和生成器表达式

* 列表推导(list comprehension)应当只用于**生成新的列表**。
* 在python2.x中会有变量泄露的问题，但python3中不会。
* **生成器表达式** 和列表推导类似，只需要将`[]`换成`()`即可，我测试了一下，返回的确实是一个*生成器*
    ```python
    >>> (int(x) for x in range(10))
    <generator object <genexpr> at 0x0000017A0C9416D0>
    ```
* 元组拆包可以应用到任何可迭代对象上，唯一的硬性要求是，被可迭代对象中的元素数量必须要跟接受这些元素的元组的空挡数一致。(但可以用`*`来表示忽略多余的元素)， 例如`a, b, c, *d = range(10)`
* 还要注意，生成器被迭代过一次就没了，例如：
    ```python
    >>> b = (int(x) for x in range(10))
    >>> e, f, g, *rest = b
    >>> e, f, g, rest
    (0, 1, 2, [3, 4, 5, 6, 7, 8, 9])
    >>> e, f, g, *rest = b
    Traceback (most recent call last):
        File "<stdin>", line 1, in <module>
    ValueError: not enough values to unpack (expected at least 3, got 0)
    >>> list(b)
    []
    ```

### 4. 元组
* 包含<font color="red">位置</font>信息，和<font color="red">不可变</font>两个特性
* 具名元组`collections.namedtuple`是一个工厂函数，可以用来构建一个带字段名的元组，和一个有名字的类。
*    
    ```python
    from collections import namedtuple
    City = namedtuple('City', 'name country population')        # 参数可以以空格分隔的字符串传入
    tokto = City('Tokyo', 'JP', 36)                             # 创建一个对象
    tokto.population                                            # 可以通过字段名取值
    tokto[1]                                                    # 可通过位置索引值
    ```
* 具名元组还有专有属性`_fields`, `_make(iterable)`(类方法), `_asdict()`(实例方法)。
    * `_fields`返回这个类所有字段名称
    * `_make`接受可迭代对象，生成一个实例
    * `_asdict`将具名元组以`collections.OrderedDict`的形式返回
* 和列表相比，没有增减元素等相关方法


### 5. 切片
* 切片和区间会忽略最后一个元素
    1. 当只有最后一个位置信息时，可以快速看出有几个元素，例：`my_list[:3]`
    2. 可以快速计算出切片和区间的长度
    3. 可以用一个下标将序列分成两个不重叠的部分。例如：`my_list[:3]`和`my_list[3:]`
* 可以用`s[a:b:c]`的形式对`s`在`a`和`b`之间以`c`为间隔取值，`c`可以为负。
* `a:b:c`是一个切片，作为**索引**或**下标**用在`[]`中会返回切片对象`slice(a, b, c)`。
* 当执行`seq[start:stop:step]`求值时，本质上会调用`seq.__getitem__(slice(start, stop, step))`。
* 也可以对切片对象取名来提高复用性。
    ```python
    >>> one2five = slice(1, 5)
    >>> 'abcdefg'[one2five]
    'bcde'
    >>> range(10)[one2five]
    range(1, 5)
    ```
* 可以在对象的特殊方法`__getitem__`和`__setitem__`实现里以<font color="red">元组</font>的形式接收`a[i, j]`来实现多维切片。也就是`a[i, j]`本质上是调用的`a.__getitem__((i, j))`方法。
* `...`在python解析器中是一个符号，是`Ellipsis`对象的别名。可以用在函数的参数清单中`f(a, ..., z)`或`a[i: ...]`。如果`x`是四维数组，那么`x[i, ....]`就是`x[i, :, :, :]`
* 还可以给切片赋值，如下，就很强。
    ```python
    >>> l = list(range(10))
    >>> l
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    >>> l[2:5] = [23, 34]
    >>> l
    [0, 1, 23, 34, 5, 6, 7, 8, 9]
    ```

### 6. 序列操作
* 对序列使用`+`和`*`进行操作时，不会修改原有的操作对象，而是会构造一个全新的序列。
* 子序列只会拷贝相应的引用，例如：`my_list = [['_'] * 3] * 3`中三个`['_', '_', '_']`指向同一个列表。如果希望创建三个不同的列表，应当使用列表推导，例如`[['_'] * 3 for i in range(3)]`
* `+=`和`*=`本质上调用了`__iadd__`和`__imul__`，如果一个类没有实现这两个方法，python会退一步调用`__add__`之类的方法，此时`a += b`的效果就和`a = a + b`时一样的了（会产生新的对象）。
* 
