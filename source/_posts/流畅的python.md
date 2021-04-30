---
title: 《流畅的python》笔记
tags: python笔记
date: 2020-12-13 17:23:59
---

参考书籍：[《流畅的python》(Fluent Python）](/doc/流畅的python.pdf)

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


***


# 六、使用一等函数实现设计模式


### 1. 策略模式
* 例如：对于不同的用户，购买物品时有不同的折扣，具体折扣策略，可以使用策略模式
    * 第一种方式，定义一个抽象基类作为策略父类`Promotion`，子类继承自父类实现各自的折扣方法`discount`
        ```python
        class Promotion(ABC):
            @abstractmethod
            def discount(self, order):
                """ 返回折扣金额 """
        ```
    * 第二种方式，定义不同折扣函数，作为参数传入订购对象中，在结算时调用传入的折扣函数
    * 第二种方式更好，策略函数在Python编辑模块时只会创建一次，可以同时在多个上下文中使用，无状态和额外消耗。

* 计算最佳策略
    * 将策略函数，添加到一个列表中，遍历执行返回最优结果
    * 规定模块中全是折扣函数，使用`inspect.getmembers`获取模块中的所有函数，遍历执行

### 2. 命令模式
* "命令"模式的目的是**解耦调用操作的对象(例如图形应用中的菜单项)和提供实现的对象(例如被编辑的文档)**
    * 原始实现，定义个`Command`基类，定义`execute`接口，调用者拿到`Command`的实例，执行`command.execute()`
    * 替代方案，传入可执行函数，或者可调用对象实现`__call__`方法，直接执行`command()`，也可用闭包存储函数的内部状态。

### 3. 总结
* 很多设计模式无需定义类，实例化对象，就能实现花里胡哨的功能了


### 4.python设计模式相关参考资料
* "Learning Python Design Patterns"
* 《Python Cookbook (第3版)中文版》 第8.21章节
* 《Python高级编程》 第14章
* [EuroPython2011演讲](https://pyvideo.org/europython-2011/python-design-patterns.html)
* [Design Patterns in Dynamic Languages](/doc/design-patterns.pdf)

***


# 八、对象引用、可变性和垃圾回收


### 1. 变量
* 变量经常是引用，对引用赋值，索引的是同一块内存
* 创建一个变量只有在赋值语句执行完毕，才有，使用`dir()`可以查看当前的命名空间中的模块
* > 每个变量都有标识、类型和值。对象一旦创建，它的标识绝不会变；你可以把标识理解为对象在内存中的地址。`is`运算符比较两个对象的标识；`id()`函数返回对象标识的整数表示。               -- [Python语言参考手册](https://docs.python.org/3/reference/datamodel.html#objects-values-and-types)
* 在CPython中，`id()`返回对象的内存地址，在其他Python解释器中可能是别的值，但ID一定唯一且对象生命周期中绝对不变
* `==`比较的是两个对象的值，`is`比较对象的标识。
* `is`运算符比`==`快，它不能重载，无需查找调用特殊方法，`==`等同于`__eq__()`，大多数内置类型会考虑对象属性的值。
* 对于元组，元素的标识不能变，但是标识对应的内容可变。
* 复制列表，默认只会做浅拷贝，如果列表中具有可变元素，可能会有bug
* 可变对象的`+=`，`*=`运算符会就地修改，不可变对象会创建新的对象再赋值。
    ```python
    l1 = [3, [66, 55, 44], (7, 8, 9)]
    l2 = list(l1)
    l1.append(100)
    l1[1].remove(55)
    print('l1:', l1)    # l1: [3, [66, 44], (7, 8, 9), 100]
    print('l2:', l2)    # l2: [3, [66, 44], (7, 8, 9)]
    l2[1] += [33, 22]   # 列表会就地相加
    l2[2] += (10, 11)   # 元组相加，会创建新的元组，赋值给l2
    print('l1:', l1)    # l1: [3, [66, 44, 33, 22], (7, 8, 9), 100]
    print('l2:', l2)    # l2: [3, [66, 44, 33, 22], (7, 8, 9, 10, 11)]
    ```
* `deepcopy`函数会记住已经赋值的对象，因此能够优雅地处理循环引用(牛B!)
    ```python
    >>> a = [10, 20]
    >>> b = [a, 30]
    >>> b
    [[10, 20], 30]
    >>> a.append(b)
    >>> a
    [10, 20, [[...], 30]]
    >>> from copy import deepcopy
    >>> c = deepcopy(a)
    >>> c
    [10, 20, [[...], 30]]
    >>>
    ```
* 可以实现特殊方法`__copy__()`和`__deepcopy__()`以控制`copy`和`deepcopy`的行为。


### 2. 函数的参数

* `Python`唯一支持的参数传递模式是共享传参(call by sharing)。也就是**函数内部的形参是实参的别名**。带来的结果是，可变类型的值可以被修改。
* <font color=red>函数的默认值在定义函数时就会计算，如果默认值是可变对象，那么所有的使用该默认值的调用，都会受其影响</font>。
    ```python
    >>> def fun(val=[]):
    ...     val.append(1)
    ...     print(val)
    ...
    >>> fun([2])
    [2, 1]
    >>> fun()
    [1]
    >>> fun()
    [1, 1]
    >>> fun()
    [1, 1, 1]
    ```
* **默认值**其实就在函数的`__defaults__`属性之中。所有操作的默认值，都是它，~~也许可以用来写些鬼畜的代码~~。
    ```python
    >>> fun.__defaults__
    ([1, 1, 1],)
    ```
* > 除非这个方法确实想修改通过参数传入的对象，否则在类中直接把参数赋值给实例变量之前一定要三思，因为这样会为参数对象创建别名。如果不确定，那就创建副本。这样客户会少些麻烦。 


### 3. `del`和垃圾回收

* `del`语句删除的是引用，当删除的变量保存的是对象的最后一个引用，或者这无法得到对象(循环引用)对象时，对象才会被垃圾回收。
* 有个内置方法[`__del__()`](https://docs.python.org/zh-cn/3/reference/datamodel.html#object.__del__)使用这个方法需要小心
    > 警告 由于调用 `__del__()` 方法时周边状况已不确定，在其执行期间发生的异常将被忽略，改为打印一个警告到`sys.stderr`。特别地：
    > * `__del__()` 可在任意代码被执行时启用，包括来自任意线程的代码。如果`__del__()`需要接受锁或启用其他阻塞资源，可能会发生死锁，例如该资源已被为执行`__del__()`而中断的代码所获取。
    > * `__del__()`可以在解释器关闭阶段被执行。因此，它需要访问的全局变量（包含其他模块）可能已被删除或设为`None`。Python会保证先删除模块中名称以单个下划线打头的全局变量再删除其他全局变量；如果已不存在其他对此类全局变量的引用，这有助于确保导入的模块在`__del__()`方法被调用时仍然可用。
* 正确使用`__del__`的一个[指引](https://emptysqua.re/blog/pypy-garbage-collection-and-a-deadlock/)

### 4. 弱引用

* 弱引用不会增加对象的引用数量，不会妨碍所指对象被当作辣鸡回收。
* `weakref`[模块](https://docs.python.org/zh-cn/3/library/weakref.html)是底层接口，共高级用途使用，它可以通过弱引用获取对象
    ```python
    >>> import weakref
    >>> a_set = {0, 1}
    >>> wref = weakref.ref(a_set)
    >>> wref
    <weakref at 0x000002928646E630; to 'set' at 0x0000029286497200>
    >>> wref()
    {0, 1}
    >>> a_set = {0, 1, 3}
    >>> wref
    <weakref at 0x000002928646E630; dead>
    >>> wref()
    ```
* 实际使用的时候，最好应当使用`weakref`集合和`finalize`，如：`WeakKeyDictionary`, `WeakValueDictionary`, `WeakSet`, 不要自己动手创建并处理`weakref.ref`实例。
    * `WeakValueDictionary`是一种映射类型，里面的值是对象的弱引用，若引用的对象没了，那么键会自动从里面删除。**需要注意：如果是全局变量，不手动删除的话，该对象一直都在。**
    * `WeakKeyDictionary`是键为弱引用的字典。它可以在，**不为对象添加引用的情况下，为对象附加额外数据**。
    * `WeakSet`保存元素弱引用的集合类，元素没有强引用时，集合会把它删除。
* 弱引用的局限：基本的`list`和`dict`实例不能作为弱引用的所指对象，但可以使用他们的子类。`int`和`tuple`实例不能作为弱引用的所指对象，甚至他们的子类也不行。这些局限是`CPython`内部优化所导致的结果，在其他Python解释器中可能不一致。
* 对于不可变类型，并不能创建新的对象，例如使用`tuple(t1)`返回的是与`t1`同一个对象，许多字符串常量，小整数会共享同一个对象。这是一种名为驻留(interning)的优化措施。
* Python对象的类型也可以变，只需要将`__class__`属性指定为其他类。

### 5. 其他参考

* 关于垃圾回收，分代回收可参考[python文档](https://docs.python.org/zh-cn/3/library/gc.html)
* 关于更多弱引用相关资料，也可参考[python文档](https://docs.python.org/zh-cn/3/library/weakref.html)，[相关论文](/doc/python_gc_final_2012-01-22.pdf) 

***


# 九、符合Python风格的对象

### 1. 一些特殊方法
* `__bytes__`函数调用它获取对象的字节序列表示形式。再python中，应当返回`bytes`类型。
* `x, y = my_vector`可以采用方法`(i for i in (self.x, self.y))`或`yield self.x; yield self.y`实现。
* 实现`Vector2d`的一个demo:

```python
from array import array
import math

class Vector2d:
    typecode = 'd'

    def __init__(self, x, y):
        self.x = float(x)
        self.y = float(y)

    def __iter__(self):
        return (i for i in (self.x, self.y))

    def __repr__(self):
        class_name = type(self).__name__
        return '{}({!r}, {!r})'.format(class_name, *self)

    def __str__(self):
        return str(tuple(self))

    def __bytes__(self):
        # 前类型码(一字节)转成字节序列，后面是迭代自己(x, y)再转成的数组，再转成字节序列
        return (bytes([ord(self.typecode)])) + bytes(array(self.typecode, self))

    @classmethod
    def frombytes(cls, octets):
        typecode = chr(octets[0])       # 取出字节码
        memv = memotyview(octets[1:]).cast(typecode)   # 将字节序列创建内存视图
        return cls(*memv)       # 用类创建并返回对象

```

### 2. `classmethod`与`staticmethod`
* `classmethod`第一个参数是类本身，而不是实例。<font color=red>常用于定义备选构造方法。</font>
* `staticmethod`就是个静态方法，类似于普通函数。
* 关于python方法描述更详尽的一篇文章[The Definitive Guide on How to Use Static, Class or Abstarct Methods in Python](https://julien.danjou.info/guide-python-static-class-abstract-methods/)


### 3. Python的私有属性
* 如果以两个签到下划线命名的实例属性，Python会把属性名存入实例的`__dict__`属性中，而且会在前面加上一个下划线和类型。我试了一下，确实，如果只有一个下划线，就不会改名。
    ```python
    >>> class Test:
    ...     def __init__(self, x, y):
    ...          self.__y = y
    ...          self.__x = x
    ...
    >>> v = Test(1, 2)
    >>> v.__dict__
    {'_Test__y': 2, '_Test__x': 1}
    ```
* 在模块中，顶层名称使用一个前导下划线时，`from xxx import *`不会导入这些模块，但是可以`from xxx improt _xxx`来导入。

### 4. `__slots__`类属性
* 在类中定义`__slots__`属性，可以节省内存，它的值为一个字符串构成的可迭代对象，其中各个元素表示各个实例属性。`__slots__ = ('__x', '__y')` 
* 此时Python会避免使用消耗内存的`__dict__`属性来存储属性。当有数百万个实例同时活动可以节省大量内存。
* 需要注意以下问题：
    * 不要使用`__slots__`属性禁止类的用户新增属性，它是用于优化而不是约束程序员的。
    * 每个子类都要定义`__slots__`属性。解释器会忽略继承的`__slots__`属性。
    * 实例只能拥有`__slots__`中列出的属性，除非把`__dict__`加入，但就会失去节省内存的功效。
    * 如果不把`__weakref__`加入`__slots__`，实例就不能作为弱引用的目标。

### 5. 覆盖类属性
* 如果类和实例对象都拥有一个属性，那么`self`会优先使用实例对象的属性值。
* 可以通过继承来覆盖父类的属性的默认值，更为Pythonic。

### 6. 切片支持
* `slice`的`indices(x)`方法下可以看到，在长度为`x`的情况下，乱七八糟的索引`(start, stop. stride)`会被整顿为非负数，且都落在指定长度序列的边界内。

### 7 . 动态存取属性

* 属性查找，简单来说，
    * 对 my_obj.x 表达式，Python 会检查 my_obj 实例有没有名为 x 的属性；
    * 如果没有，到类（my_obj.__class__）中查找；
    * 如果还没有，顺着继 承树继续查找。
    * 如果依旧找不到，调用 my_obj 所属类中定义的 __getattr__ 方法，传入 self 和属性名称的字符串形式（如 'x'）
* `operator`模块以函数的形式提供了全部中缀运算符，从而减少使用`lambda`表达式。例如`^`等价于`operator.xor`
* `reduce`函数也叫合拢，累计，聚合，压缩和注入REF. [Fold](https://en.wikipedia.org/wiki/Fold_(higher-order_function))

### Python风格的求和方式
* 问题描述已知`my_list = [[1, 2, 3], [40, 50, 60], [9, 8, 7]]`，求`my_list[0][1] + my_list[1][1] + my_list[2][1]`
* 使用列表推导+`lambda`表达式: `functools.reduce(lambda a, b: a+b, [sub[1] for sub in my_list])`
* 仅使用`lambda`表达式: `functools.reduce(lambda a, b: a + b[1], my_list, 0)`
* 使用`numpy`: `my_array = numpy.array(my_list)` & `numpy.sum(my_array[:, 1])`
* 不适用`lambda`表达式: `functools.reduce(operator.add, [sub[1] for sub in my_list], 0)`
* 使用`sum`: `sum([sub[1] for sub in my_list])`
* 使用`sum` + 生成器表达式: `sum(sub[1] for sub in my_list)`

***


# 十一、接口：从协议到抽象基类

### 1. 接口与协议
* 协议是由文档和约定定义的接口，大致意思是，通过实现某些接口，可以让对象在系统中扮演特定的角色。
* 协议不是强制的，可以只实现部分接口。
* 例如实现`__getitem__`方法，实现序列协议的移部分，就足够访问元素、迭代和使用`in`运算符。
* 可以在运行时对对象打补丁(然而我早已知道)
* > 抽象基类是用于封装框架引入的一般性概念和抽象的，例如“一个序列”和“一个确切的数”。（读者）基本上不需要自己编写新的抽象基类，只要正确使用现有的抽象基类，就能获得99.9%的好处，而不用冒着设计不当导致的巨大风险。

### 2. 标准库中的抽象基类
* 大多数抽象基类在`collections.abc`模块中定义，其他地方例如：`numbers`和`io`包中包有一些基类。[PEP 3119]
* `_collections_abc.py`模块中定义了16个抽象基类。![UML类图](/images/collections_abc.png)
* 大致内容如下：
    * `Iterable`支持迭代(`__iter__`)、`Container`支持`in`运算符(`__contains__`)、`Sized`支持`len`函数(`__len__`)。集合应当继承这三个抽象基类。
    * `Sequence`, `Mapping`, `Set`不可变集合，`MutableSequence`, `MutableMapping`, `MutableSet`可变的集合子类。
    * `MappingView`, `ItemsView`, `KeysView`, `ValuesView`，是`.items()`,`.keys()`, `.values()`返回的实例。
    * `Callable`和`Hashable`主要作用是为内置函数`isinstance`提供支持，以一种安全的方式判断对象能不能调用或散列。
    * `Iterator` 见14章
* `numbers`包中，有以下类: `Number`, `Complex`, `Real`(浮点数), `Rational`, `Integral`(整数)
* 然而现在的Python里有一大堆虚基类了(2021/4/23)
    ```python
    __all__ = ["Awaitable", "Coroutine",
           "AsyncIterable", "AsyncIterator", "AsyncGenerator",
           "Hashable", "Iterable", "Iterator", "Generator", "Reversible",
           "Sized", "Container", "Callable", "Collection",
           "Set", "MutableSet",
           "Mapping", "MutableMapping",
           "MappingView", "KeysView", "ItemsView", "ValuesView",
           "Sequence", "MutableSequence",
           "ByteString",
           ]
    ```

### 3. 自定义抽象基类
* Python3.4及以上可以通过`abc`模块中的相关方法实现，继承自`abc.ABC`使用`abstractmethod`装饰器。子类不实现抽象方法将无法实例化对象。
    ```python
    import abc
    class Tombola(abc.ABC):

        @abc.abstractmethod
        def load(self, iterable):
            """ docstr """
    ```
* 旧版的Python3可使用`metaclass=abc.ABCMeta`作为关键字参数。
    ```python
    class Tombola(metaclass=abc.ABCMeta):
        pass
    ```
* 如果是Python2（会有什么sb公司现在还用python2呢）必须使用`__metaclass__`属性。
    ```python
    class Tobola(object):
        __metaclass__ = abc.ABCMeta
        pass
    ```
* 在函数上堆叠装饰器时，`@abstractmethod`应当放在最里层[abc模块文档](https://docs.python.org/zh-cn/dev/library/abc.html#abc.abstractmethod)

### 4. 虚拟子类

* 注册虚拟子类的方式是在抽象基类上调用`register`方法。这么做之后，注册的类会变成抽象基类的虚拟子类，而且`issubclass`和`isinstance`等函数都能识别。但是注册的类不会从抽象基类中继承任何方法和属性。（个人感觉没啥用）
    ```python
    from tombola import Tombola
    ### python3.3之后
    @Tombola.register
    class TomboList(list):
        pass
    ### python3.3及之前
    Tombola.register(TomboList)
    ```
* `__mro__`这个特殊的类属性中指定了类的继承关系，作用为：按顺序列出类及其超类。并且它只会列出“真实的”超类，注册的并不。
* 有个`__subclasshook__(cls, c)`的方法，会用来检查自定义类是否实现了特定方法，如果实现了就认为是抽象基类的子类。例如`Container`实现如下：
    ```python
    def _check_methods(C, *methods):
        mro = C.__mro__
        for method in methods:
            for B in mro:
                if method in B.__dict__:
                    if B.__dict__[method] is None:
                        return NotImplemented
                    break
            else:
                return NotImplemented
        return True

    class Container(metaclass=ABCMeta):

        __slots__ = ()

        @abstractmethod
        def __contains__(self, x):
            return False

        @classmethod
        def __subclasshook__(cls, C):
            if cls is Container:
                return _check_methods(C, "__contains__")
            return NotImplemented

        __class_getitem__ = classmethod(GenericAlias)
    ```
* 在`class ABCMeta(type)`还有相关的更上层的接口，用来检查是否是父类，其中`_abc_subclasscheck(cls, subclass)`用C语言进行了实现[源码](https://github.com/python/cpython/blob/master/Modules/_abc.c)。

* > 尽管抽象基类使得类型检查变得更容易了，但不应该在程序中过度使用它。Python的核心在于它是一门动态语言，它带来了极大的灵活性。如果处处都强制实行类型约束，那么会使代码变得更加复杂，而本不应该如此。我们应该拥抱Python的灵活性。
—— David Beazley 和 Brian Jones 《Python Cookbook（第 3 版）中文版》


***

# 十二、继承的优缺点

### 1. 子类化内置类型

* 内置类型（使用C语言编写）(的其他方法)不会调用用户定义的类覆盖的特殊方法。如`__getitem__`之类的，但是据说`__missing__`方法却行。
    ```python
    >>> class TestDict(dict):
    ...     def __setitem__(self, key, value):
    ...         super().__setitem__(key, [value] * 2)
    ...
    >>> dd = TestDict(one=1)
    >>> dd
    {'one': 1}
    >>> dd.update(three=3)
    >>> dd
    {'one': 1, 'three': 3}
    >>> dd['two'] = 2       # 显式调用覆盖的特殊方法会有效
    >>> dd
    {'one': 1, 'three': 3, 'two': [2, 2]}
    ```
* <font color=red>直接子类化内置类型（如dict, list, str）容易出错，因为内置类型的方法通常会忽略用户覆盖的方法，不要子类化内置类型，用户自己定义的类应该继承`collections`模块中的类</font>，例如`UserDict`, `UserList`, `UserString`，这些类做了特殊设计，易于扩展。
* 以上问题至发生在C语言实现的内置类型内部的方法委托上，而且之影响直接继承内置类型的用户自定义类。
* PyPy的行为会有微笑差异[Differences between PyPy and CPython](https://doc.pypy.org/en/latest/cpython_differences.html#subclasses-of-built-in-types)

### 2. 多重继承和方法解析顺序

* Python会按照特定的顺序遍历继承图。这个顺序叫做方法解析顺序（Method Resolution Oeder, MRO）。
* 类都有一个名为`__mro__`的属性，它的值是一个元组，按照方法解析顺序列出各个超类，从当前类一直向上，直到object类。
    ```python
    >>> class A:
    ...     pass
    ...
    >>> class B(A):
    ...     pass
    ...
    >>> class C(A):
    ...     pass
    ...
    >>> class D(B, C):
    ...     pass
    ...
    >>> D.__mro__
    (<class '__main__.D'>, <class '__main__.B'>, <class '__main__.C'>, <class '__main__.A'>, <class 'object'>)
    ```
* 可以直接在类上调用实例方法，需要显式传入`self`参数，例如`A.ping(self)`
* 可以使用内置的`super()`函数，使用`super()`调用方法时，会遵守方法解析顺序。
* python的方法解析顺序（MRO）采用了[C3算法](https://www.python.org/download/releases/2.3/mro/)

### 3. 处理多重继承的一些建议

* 把*接口继承*和*实现继承*区分开，接口继承是框架的的支柱，实现继承通常可以换用组合和委托模式。
* 使用抽象基类显式表示接口。
* 通过混入（mixin class）重用代码
* 在名称中明确指明混入，定义类是直接采用`TestMixin`这样子的命名。
* 抽象基类可以作为混入，反过来则不成立（**这部分具体含义没有懂**）
* 不要子类化多个具体类，具体类的超类中，除了这一个具体的超类之外，其余的都是抽象基类或混入。
* 为用户提供聚合类（aggregate class），也就是继承多个Mixin，提供一个类。
* 优先使用对象组合，而不是类继承。

### 4. 作者认为Tkinter的不好之处

* 几何管理器应该用组合模式集成到`Widget`中，而不是继承。
* `Widget`定义的接口含义不清晰明确
* `Misc`提供了许许多多的功能如（剪切板，文本选择之类），而所有的小组件都继承了它，应当拆分成多个`Mixin`分别混入不同小组件。
* 使用`dir(tkinter.Button)`之类，方法众多，无法确定自己所需的方法。

***


# 十三、正确重载运算符

### 各种运算符

* `- x` (`__neg__`) 一元取负算数运算符。
* `+ x` (`__pos__`) 一元取正算数运算符。
* `~ x` (`__invert__`) 对整数按位取反。
* `a + b` (`__add__`, `_radd__`) 加法(反向加法)运算符，如果`a`有`__add__`方法，会调用`a.__add__(b)`方法，否则会尝试调用`b.__radd__(a)`。
* `a * b` (`__mul__`, `__rmul__`) 乘法运算符。

* 还有许许多多新加的运算符，见[文档](https://docs.python.org/zh-cn/3/library/operator.html)


***

# 十四、可迭代对象，迭代器和生成器

### 0. 迭代器模式 (Iterator Pattern)

* 扫描内存中存放不下的数据集时，我们要找到一种惰性获取数据项的方式，即按需一次获取一个数据项。
* 在Python中，所有集合都可以迭代。迭代器主要用于支持：
    * `for`循环
    * 构建和扩展集合类型
    * 逐行遍历文本文件
    * 列表推导、字典推导和集合推导。
    * 元组拆包
    * 使用`*`拆包实参

### 1. 序列可以迭代的原因 (`iter`函数)
* 解释器需要迭代对象时：
    * 检查对象是否实现了`__iter__`方法，如果实现了就调用它，获取一个迭代器。
    * 如果没有实现`__iter__`方法，但是实现了`__getitem__`方法。Python会创建一个迭代器，尝试按顺序（从索引0开始）获取元素。
    * 如果尝试失败，Python抛出`TypeError`异常，通常会提`Class object is not iterable`
* 如果没有`for`语句，就需要用`while`循环包着`try except StopIteration`。
* 标准迭代器接口有两个方法`__next__`（如果没有元素会抛`StopIteration`异常）和`__iter__`（返回`self`）。
* 迭代器`abc.Iterator`的大致实现：
    ```python
    class Iterator(Iterable):
        __slots__ = ()

        @abstractmethod
        def __next__(self):
            'Return the next item from the iterator. When exhausted, raise StopIteration'
            raise StopIteration

        def __iter__(self):
            return self

        @classmethod
        def __subclasshook__(cls, C):
            if cls is Iterator:
                if (any("__next__" in B.__dict__ for B in C.__mro__) and
                    any("__iter__" in B.__dict__ for B in C.__mro__)):
                    return True
                return NotImplemented
    ```

### 2. 迭代器和可迭代对象
* 可迭代对象指的就是可以被迭代的对象，一般需要实现`__iter__`(返回自身的迭代器)方法。
* 迭代器，应该一直可以迭代，他能维护自身的内部状态，一般需要实现`__iter__`(返回自身)和`__next__`(返回单个元素)方法。
* 迭代器模式的优势：
    * 访问聚合对象内容而无需知道内部表示
    * 提供多种遍历方式
    * 提供统一接口
* 模范写法：
    ```python
    class Sentence:

        def __iter__(self):
            return SentenceIterator(self.words)

    class SentenceIterator:

        def __iter__(self):
            return self

        def __next__(self):
            """ 返回单个单词或抛出异常 """
            raise StopIteration()
    ```
* 可以使用`yield`生成逐个单词，也可以迭代。
* 调用生成器函数返回生成器，生成器产出或生成之。
* 也可以使用生成器表达式`(i for i in range(10))`
* 如果函数或构造方法只有一个参数，传入生成器表达式时，不用写两对括号，但有多个，就要用括号围住。

### 3. 标准库中的生成器函数

* `itertools.takewhile`生成一个使用另一个生成器的生成器，直至给定条件为`False`，例如`itertools.takewhile(lambda n: n < 3, itertools.count(1, 0.5))`生成`[1, 1.5, 2.0, 2.5]`，还有个反的名为`itertools.dropwhile`
* `itertools.compress`可以处理两个可迭代对象，会筛选出后者为真的数据，例如`itertools.compress('abcdef', (1,0,1,1,0,1))`生成`[a,c,d,f]`
* `itertools.islice`产生切片，类似于`s[start:stop:step]`

* `itertools.accumulate`产出累计的总和(类似于cursum)，还可以传入`func`，将前两个的计算结果和下一个元素传给`func`，例如`itertools.accumulate([1,2,3,4,5], operator.mul)`生成`[1,2,6,24,120]`
* `map`可以接收多个可迭代对象，例如`map(lambda a, b: (a, b)), range(11), [2, 4, 8]))`生成`[(0, 2), (1, 4), (2, 8)]`，还有个类似的`itertools.starmap`
* `itertools.zip_longest`会一直产出知道最长的可迭代对象到头后才停止，可以提供`fillvalue`

* `itertools.count`生成从零开始的整数数列，可以无限生成。
