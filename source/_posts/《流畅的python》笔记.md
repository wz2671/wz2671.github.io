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
