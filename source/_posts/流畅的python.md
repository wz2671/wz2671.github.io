---
title: 《流畅的python》笔记
tags: python笔记
date: 2020-12-13 17:23:59
---

参考书籍：《流畅的python》(Fluent Python）

![封面](/images/liuchangdepython.jpg)

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
* 元组中若包含可变对象，会赋值成功，但同时也会报错，例如:
    ```python
    >>> t = (1, 2, [30, 40])
    >>> t[2] += [50, 60]
    Traceback (most recent call last):
    File "<stdin>", line 1, in <module>
    TypeError: 'tuple' object does not support item assignment
    >>> t
    (1, 2, [30, 40, 50, 60])
    ```
* <font color="red">查看python字节码</font>可通过`dis.dis`方法查看，例如上述指令`dis.dis('t[2] += [50, 60]')`的字节码如下(虽然并不能看懂)：
    ```python
    >>> dis.dis('t[2] += [50, 60]')
    1           0 LOAD_NAME                0 (t)
                2 LOAD_CONST               0 (2)
                4 DUP_TOP_TWO
                6 BINARY_SUBSCR
                8 LOAD_CONST               1 (50)
                10 LOAD_CONST               2 (60)
                12 BUILD_LIST               2
                14 INPLACE_ADD
                16 ROT_THREE
                18 STORE_SUBSCR
                20 LOAD_CONST               3 (None)
                22 RETURN_VALUE
    ```

### 7. 排序
* `list.sort`方法会就地排序列表，不会重新将列表复制一份，返回值为`None`。
* 内置函数`sorted`会创建一个新列表作为返回值。(如果有返回值就可以串联调用，形成连贯接口(fluent interface))。
* 排序方法有两个关键字参数，`reverse`和`key`。
    * `reverse`默认为`False`，会升序排序，若为`True`则降序排序。
    * `key`接收只有一个参数的函数，会被应用在序列的每一个元素上，例可以使用`str.lower`来实现忽略大小写的排序。
    * 可以采用`operator.itemgetter`函数来轻松实现取出多个字段的值。以下实现是等价的。
        ```python
        >>> b = operator.itemgetter(1, 0)
        >>> c = lambda x: (x[1], x[0])
        >>> b('abcdefg')
        ('b', 'a')
        >>> c('abcdefg')
        ('b', 'a')
        ```
* `bisect`可以管理已排序的序列。
    * `bisect.bisect(haystack, needle)`可在`haystack`(干草垛)里搜索`needle`(针)的位置。若有相同的`needle`，则会找到它之后的位置。
    * `bisect.bisect_left`会返回之前的索引，所以上面的`bisect.bisect`可以理解为`bisect.bisect_right`。
    * 上面这两个函数还具有可选参数`lo`(起始位置)和`hi`(序列的长度)，可以用来缩小范围。
    * `bisect.insort(seq, item)`可把变量`item`插入有序序列`seq`，并能保持`seq`升序顺序。同时也有个变体叫做`bisect.insort_left`。

### 8. 其他序列
* 如果要存放1000万个浮点数的话，`array`数组的效果要高得多。
* 如果频繁对序列做先进先出的操作，`deque`(双端队列)的速度会更快。
* 如果要检查一个元素是否出现在一个集合中，`set`会更合适。
* `memoryview`(<font color="red">内存视图</font>)是个高级的东西，能让用户不在复制内容的情况下操作同一个数组的不同切片。
    * [When should a memoryview be used?](https://stackoverflow.com/questions/4845418/when-should-a-memoryview-be-used/)
    * 
        > 内存视图其实是泛化和去数学化的NumPy数组。它让你在不需要复制内容的前提下，在数据结构之间共享内存。其中数据结构可以是任何形式，比如PIL图片、SQLite数据库和Numpy数组，等。这个功能在处理大型数据集合的时候非常重要。
        -- Travis Oliphant
* `NumPy`和`SciPy`也很优秀。
* `collections.deque`类(双向队列)是一个线程安全、可以快速从两端添加或删除元素的数据类型。也使用于存放"最近用到的几个元素"。
    * 可以指定`maxlen`，从某一端添加元素时，会反向删除多余的元素。
    * 只可以从头尾添加或删除元素：`s.extend(i)`, `s.extendleft(i)`, `s.pop()`, `s.popleft()`
    * 当在调用`deque`的`extendleft(iter)`方法时会把迭代器里的元素逐个添加到双向队列的左边，迭代器里的元素会逆序出现在队列里。
        ```python
        >>> from collections import deque
        >>> dq = deque(range(10), maxlen=10)
        >>> dq
        deque([0, 1, 2, 3, 4, 5, 6, 7, 8, 9], maxlen=10)
        >>> dq.extendleft([10, 20, 30, 40])
        >>> dq
        deque([40, 30, 20, 10, 0, 1, 2, 3, 4, 5], maxlen=10)
        ```
* `Queue`提供了线程安全类`Queue`、`LifoQueue`和`PriorityQueue`。不同的线程可以利用这些数据类型来交换信息。
* 当队列满了，会被锁住知道另外的线程移除了某个元素而腾出了位置，很适合用来控制<font color="red">活跃的线程的数量</font>。
* `heapq`没有队列类，而是提供了`heappush`和`heappop`方法，可以当作堆队列或者优先队列来使用。
* 更多内容可参考[collections-Container datatypes](https://docs.python.org/3/library/collections.html)

***



# 三、字典和集合


### 1. 泛映射类型

* `collections.abc`中有`Maping`和`MutableMapping`两个抽象基类，主要作用是作为形式化的文档。一般直接对`dict`和`collections.User.Dict`进行扩展。
* 可以利用`isinstance({}, abc.Mapping)`用来判断某个数据是否是广义上的映射类型。
* 只有**可散列**的数据类型才可以作为映射里的键。
    * 可散列对象的散列值，在对象的生命周期中，都是不变的。对象需要实现`__hash__()`和`__qe__()`方法。
    * 原子不可变数据类型（`str`、`bytes`和数值类型）都是可散列类型。
    * `frozenset`是可散列的，它只能容纳可散列类型，当`tuple`的所有元素都是可散列类型，那么元组也可以散列。
    * 一般用户自定义的类型的对象都是可散列的，散列值是`id()`函数的返回值。


### 2. 创建字典

```python
a = dict(one=1, two=2, three=3)
b = {'one': 1, 'two': 2, 'three': 3}
c = dict(zip(['one', 'two', 'three'], [1, 2, 3]))
d = dict({'one': 1, 'two': 2, 'three': 3})
e = {_s: _i for _s, _i in [('one', 1), ('two', 2), ('three', 3)]}
```

### 3. 映射类型的方法

* `d.default_factory`在`__missing__`函数中被调用的函数，用来给未找到的元素设置值。
* `d.setdefault`某些情况下可以减少查询次数。
    ```python
    my_dict.setdefault(key, []).append(new_value)
    # 等价于以下
    if key not in my_dict:
        my_dict[key] = []
    my_dictp[key].append(new_value)
    ```
* `d.fromkeys(it, [initial])`将迭代器`it`里的元素设置为键，`initial`为对应的value

### 4. 映射的弹性键查询

* 当某个键不存在时，如果希望它还能提供一个默认值，有两种方法：使用`defaultdict`或实现`__miss__`方法。
* `collections.defaultdict`在创建时需要配置一个创造默认值的方法。**它只会在__getitem__**之中起作用。
    ```python
    >>> import collections
    >>> index = collections.defaultdict(list)
    >>> index[1].append(1)
    >>> index
    defaultdict(<class 'list'>, {1: [1]})
    >>> index.get(2)
    >>> index.get(1)
    [1]
    ```
* `__miss__`所有的映射类型在处理找不到键的时候，都会调用它。同时，它也只会在`__getitem__`中起作用，`__contains__`和`get`方法都不起作用。
    ```python
    class StrKeyDict(dict):

        def __missing__(self, key):
            if isinstance(key, str):
                raise KeyError(key)     # 避免的找不到时会无限递归调用__miss__
            return self[str(key)]

        def get(self, key, default=None):
            try:
                return self[key]
            except KeyError:
                return default      # __miss__失效

        def __contains__(self, key):
            return key in self.keys() or str(key) in self.keys()        # in self.keys()避免了递归调用__contains__
    ```


### 5. 其他映射类型

* `collections.OrderedDict`: 会保持顺序，迭代次序总是一直，`popitem`默认删除最后一个元素，`popitem(last=False)`会删除第一个
* `collections.ChainMap`: 没有很懂
* `collections.Counter`：整数计数器
    ```pyhton
    >>> ct = collections.Counter('abracadabra')
    >>> ct
    Counter({'a': 5, 'b': 2, 'r': 2, 'c': 1, 'd': 1})
    >>> ct.update('aaaaazz')
    >>> ct
    Counter({'a': 10, 'b': 2, 'r': 2, 'z': 2, 'c': 1, 'd': 1})
    >>> ct.most_common(2)
    [('a', 10), ('b', 2)]
    ```
* `collections.UserDict`使用纯`python`实现了遍`dict`，想要创造自定义映射类型，更推荐以`UserDict`为基类。
    * `dict`某些实现会走捷径，使我们不得不重写。
    * `UserDict`最终存放数据是一个叫做`data`的属性，是`dict`的实例，可以在实现`__setitem__`和`__contains__`等之类的方法，避免不必要的递归。
    ```python
    class StrKeyDict(collections.UserDict):

        def __missing__(self, key):
            if isinstance(key, str):
                raise KeyError(key)     # 避免的找不到时会无限递归调用__miss__
            return self[str(key)]

        def __contains__(self, key):
            return str(key) in self.data        # 直接检查

        def __setitem__(self, key, item):
            self.data[str(key)] = item
    ```
* `types`模块中有一个`MappingProxyType`，可以返回一个映射的只读视图，以达到不可变类型效果。
    ```python
    >>> from types import MappingProxyType
    >>> d = {1:'a'}
    >>> d_proxy = MappingProxyType(d)
    >>> d_proxy[1]
    'a'
    >>> d_proxy
    mappingproxy({1: 'a'})
    >>> d[2] = 'b'
    >>> d_proxy
    mappingproxy({1: 'a', 2: 'b'})
    >>> d_proxy[3] = 'c'
    Traceback (most recent call last):
    File "<stdin>", line 1, in <module>
    TypeError: 'mappingproxy' object does not support item assignment
    ```

### 6. 集合

集合中的元素必须是可散列的，`set`类型不可散列，但是`frozenset`是可散列的。

* 空集合采用`set()`创建，其余可用`{1, 2, ...}`创建。后者会采用一种叫做`BUILD_SET`的字节码创建集合，比利用`set`调用构造函数更快。
    ```python
    >>> dis('{1}')
    1           0 LOAD_CONST               0 (1)
                2 BUILD_SET                1
                4 RETURN_VALUE
    >>> dis('set([1])')
    1           0 LOAD_NAME                0 (set)
                2 LOAD_CONST               0 (1)
                4 BUILD_LIST               1
                6 CALL_FUNCTION            1
                8 RETURN_VALUE
    >>> {i for i in 'anbcdsaoi'}    // 集合推导
    {'n', 'c', 'a', 'o', 'i', 's', 'd', 'b'}
    ```
* 支持中缀运算符: `|` (合集),`&` (交集), `-` (差集)，需要两侧被操作对象都为集合类型。但是成员方法只要求所传入的参数是可迭代对象。
* 其余运算符：
    | | | |
    | :----:| :----: | :----: |
    | `s & z` | `s.__and__(z)` | 交集 |
    | `z & s` | `s.__rand__(z)` 或 `s.intersection(it, ...) ` | 交集 |
    | `s &= z` |  `s.intersection_update(it, ...) ` | 交集并更新 |
    | `s \| z` | `s.__or__(z)` | 并集 |
    | `z \| s` | `s.__ror__(z)` 或 `s.union(it, ...) ` | 并集 |
    | `s \|= z` | `s.__ior__(z)` 或 `s.update__(it, ...)` | 并集并更新 |
    | `s - z` | `s.__sub__(z)` | 差集 |
    | `z - s` | `s.__isub__(z)` 或 `s.difference(it, ...)` | 差集 |
    | `s ^ z` | `s.__xor__(z)` | 对称差集(`(s\|z)-(s&z)`) |
    |  | `s.isdisjoint(z)` | 是否不相交 |
    | `e in s` | `s.__contains__(e)` | `e`是否属于`s` |
    | `s <= z` | `s.__le__(z)` 或 `s.issubset(it)` | `s`是否是`z`的子集 |
    | `s >= z` | `s.__ge__(z)` 或 `s.issuperset(it)` | `s`是否是`z`的父级 |
* 还有个比较陌生的接口`s.discard(e)`，如果`s`里有`e`这个元素的话，把它移除。

### 7. 散列表

![从字典中取值的算法流程图](/images/content_hashtable.png)

* **[dictobject.c源码](/resources/dictobject.c)**

使用散列表给`dict`带来的优势和限制
* 键必须是可散列的
    * 支持`hash()`函数，并且通过`__hash__()`方法所得到的散列值是不变的。
    * 支持通过`__eq__()`方法来检测相等性。
    * 若`a == b`为真，则`hash(a) == hash(b)`也为真。
* 内存开销巨大
* 键查询的速度很快（1000->1000万，时间从0.000163->0.00456）
* 键的次序取决于添加顺序
* 往字典里添加新键可能会改变已有键的顺序

