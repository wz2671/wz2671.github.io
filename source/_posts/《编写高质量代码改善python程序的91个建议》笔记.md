---
title: 《编写高质量代码改善python程序的91个建议》笔记
date: 2018-03-29 15:33:31
tags: python笔记
---

最近在阅读《编写高质量代码改善python程序的91个建议》，感觉挺有帮助，做些笔记。  

![不想学习](https://raw.githubusercontent.com/wz2671/wz2671.github.io/master/static/images/blog/cmxxrjxs.jpg)  


<!-- more -->

## 目录

* 利用`str.fromat()`进行字符串格式化  
* 三元操作符`?:`  
* 常量管理  
* 利用lazy evaluation特性  
* 枚举的替代实现  
* 不推荐使用`type()`来进行类型检查  
* `eval()`函数的使用  
* 使用`enumerate()`获取序列迭代的索引和值  
* 使用`with`自动关闭资源  
* `else`子句的使用  
* 优先使用`join`而不是`+`连接字符串  
* 列表解析  
* 参数传递  
* `str()`和`repr()`的区别  
* 字符串的基本用法  
* `sort()`和`sorted()`的用法  
* 浅拷贝与深拷贝  
* `__init__()`不是构造方法  
* 为什么需要`self`参数  
* 掌握循环优化的基本技巧   


***

#### 1. 利用`str.fromat()`进行字符串格式化

```python
	print '{greet} from {language}.'.format(greet = 'Hello world', language = 'Python')

	point = [1, 2, 3]
	s = 'x:{0[0]};y:{0[1]};z:{0[2]}'.format(point)
```  


***


#### 2. 三元操作符`?:`
在传统c/c++/java中支持的三元操作符`?:`可以用`if...else...`形式实现。

C/C++/JAVA形式  

```c
	C?X:Y
```  

python中实现  

```python
	X if C else Y
```  


***


#### 3. 常量管理

* 1. **通过命名风格来表示其含义**
    
	例如常量名所有字母大写，用下划线链接各个单词。  
	`MAX_OVERFLOW`

* 2. **通过自定义类实现常量功能**
	
	要求：“命名全部为大写”和“值一旦绑定便不可再修改”  
	思路为 当命名不符合规范时抛出异常。

```python
class _onst:
	class ConstError(TypeError): pass
	class ConstCaseError(ConstError): pass
	
	def __setattr__(self, name, value)
		if self.__dict__.has_key(name):
			raise self.ConstError, "Can't change const.%s" % name
		if not name.isupper():
			raise self.ConstCaseError, \
				'const name "%s" is not all uppercase' %name
		self.__dict__[name] = value
	
import sys
sys.modules[__name__] = _const()
import const
const.MY_CONSTANT = 1
const.MY_SECOND_CONSTANT = 'a'
```  

当在其他模块中引用这些常量时，按照如下方式进行即可：

```python
from constant import const
print const.MY_CONSTANT
print const.MY_SECOND_CONSTANT*2
```  

***


#### 4. 利用lazy evaluation特性  

**好处**  
  * 1. 避免不必要的计算，带来性能的提升  
  * 2. 节省空间  
  
例：生成器表达式实现斐波那契数列  

```python
	def fib():
		a, b = 0, 1
		while True:
			yield a
			a, b = b, a+b

	from itertools import islice
	print list(islice(fib(), 5))
```  

***  

#### 5. 枚举的替代实现  

* 1. **使用类属性**  

```python
	class Seasons:
		spring = 0
		Summer = 1
		Autumn = 2
		Winter = 3
```  

 也可以写成  
	
```python
	class Seasons:
		spring, summer, autumn, winter = range(4)
```  

* 2. **借助函数**  

```python
	def enum(*posarg, **keysarg):
		return type("Enum", (object,), dict(zip(posarg, range(len(posarg))), **keysarg))

	Seasons = enum("Spring", "Summer", "Autumn", Winter = 1)
	Seasons.Spring  
```  

* 3. **使用`collections.nameduple`**  

```python
	Seasons = nameduple('Seasons','Spring Summer Autumn Winter')._make(range(4))
	
	print Seasons.Spring
```  

**不合理之处**  
* 1. 允许枚举值重复  
* 2. 支持无意义的操作  

***

#### 6. 不推荐使用`type()`来进行类型检查

**原因：**   
* 1. 基于内建类型扩展的用户自定义类型，type函数并不能准确返回结果。  
* 2. 在古典类中，任意类的实例的type()返回结果都是`<type 'instance'>`。  

**如何约束用户的输入类型：**  
* 1. 利用工厂函数对类型做相应的转换:`str(name)`  
* 2. 使用`isinstance()`函数来检测:`isinstance(object, classinfo)`。  

***

#### 7. `eval()`函数的使用  

`eval()`函数将字符串str当成有效的表达式来求值并返回计算结果。  

```python
	eval(expression[, globals[, lacals]])
```  

**存在问题：** 可能会被有不良目的的人恶意利用。  
**解决方法：**如果使用对象不是信任源，避免使用eval，在需要使用的地方用安全性更好的`ast.literal_eval`替代。  

***

#### 8. 使用`enumerate()`获取序列迭代的索引和值  

```python
	li = ['a', 'b', 'c', 'd', 'e']
	for i, e in enumerate(li):
		print "index:", i, "element:", e
```  

使用`enumerate()`可使代码清晰简洁，可读性最好，具有一定的惰性。（获取索引以及对应值）  

`enumerate(sequence, start = 0)`函数的内部实现:  

```python
	def enumerate(sequence, start = 0)
		n = start
		for elem in sequence:
			yield n, elem
			n += 1
```  

对于字典的迭代循环，`enumerate()`函数并不适合（默认转换成了序列进行处理）。  
要获取迭代过程中字典的key和value，应该使用`iteritems()`方法。  
  
```python
	for k, v in personinfo.iteritems():
		print k, ":", v
```  

***  


#### 9. 使用`with`自动关闭资源  

`with`语句的语法：  

```python
	with 表达式 [as 目标]:
		代码块
```  

`with`语句可以在代码块执行完毕后还原进入该代码块时的现场。其执行过程如下：  
1. 计算表达式的值，返回一个上下文管理器对象。
2. 加载上下文管理器对象的`__exit__()`方法以备后用。
3. 调用上下文管理器对象的`__enter__()`方法。
4. 如果`with`语句中设置了目标对象，则将`__enter__()`方法的返回值赋值给目标对象。
5. 执行`with`中的代码块。
6. 如果步骤5中代码正常结束，调用上下文管理器对象的`__exit__()`方法，其返回值直接忽略。
7. 如果步骤5中代码执行过程中发生异常，调用上下文管理器对象的`__exit__()`方法，并将异常类型、值及traceback信息作为参数传递给`__exit__()`方法。如果`__exit__()`返回值为false，则异常会被重新抛出；如果返回值为true,异常值被挂起，程序继续执行。  


利用`with`语句自动关闭文件：  

```python
	with open('test.txt', 'w') as f:
		f.write("test")
```  

**上下文管理器：**  

它定义程序运行时需要建立的上下文，处理程序的进入和退出，实现了上下文管理协议，即在对象中定义`__enter__()`和`__exit__()`方法。  

用户可以定义子集的上下文管理器来控制程序的运行，只需要实现上下文协议便能够和`with`语句一起使用。  

```python
	class MyContextManager(object):
		def __enter__(self):
			print "entering..."
		def __exit__(self, exception_type, exception_value, traceback):
			print "leaving..."
			if exception_type is None:
				print "no exceptions!"
				return Fasle
			elif exception_type is ValueError:
				print "value error!"
				return True
			else：
				print "other error"
				return True
```  

```python
	with MyContextManger():
		print "Testing..."
		raise(ValueError)
```  

***

#### 10. `else`子句的使用

* **循环中的`else`:**  
  当循环“自然”终结时，`else`从句会被执行一次，而当循环是由`break`语句中断时，`else`子句就不会被执行。  
  例：查找素数

```python
	def print_prime2(n):
		for i in range(2, n):
			for j in range(2, i):
				if i % j == 0:
					break
			else:
				print '%d is a prime number'%i
```  

`while`语句中的`else`子句语意一致。

* **异常处理中的`else`:**  
  `try`块没有抛出任何一异常时，执行`else`块。  
  例：写数据入文件 

```python
	def save(db, obj):
		try:
			# save attr1
			db.execute('a aql stmt', obj.attr1)
			# save attr2
			db.execute('another sql stmt', obj.attr2)
		except DBError:
			db.rollback()
		else:
			db.commit()
```  


***

#### 11. 优先使用`join`而不是`+`连接字符串

* 当用操作符`+`连接字符串时，由于字符串时不可变对象，执行一次`+`操作便会在内存中申请一块新的内存空间，并将上一次操作的结果和本次操作的右操作数复制到新申请的内存空间。所以字符串的连接时间复杂度近似为O(n^2)。

* 而当用`join()`方法连接字符串的时候，会首先计算需要申请的总的内存空间，然后一次性申请所需的内存并将序列中的每一个元素复制到内存中去。所以`join()`操作的时间复杂度近似为O(n)。  

```python
	str1, str2, str3 = 'testing ', 'string ', 'concatenation '
	str1 + str2 + str3
```  

```python
	str1, str2, str3 = 'testing ', 'string ', 'concatenation '
	''.join([str1, str2, str3])
```  

***


#### 12. 列表解析

列表解析的语法为： `[expr for iter_item in iterable if cond_expr]`  
它迭代`iterable`中的每一个元素，当条件满足时便根据表达式`expr`计算的内容生成一个元素并放入新的列表中，依次类推，并最终返回整个列表。  
如果没有条件表达式，就直接将`expr`中计算出的元素加入`List`中。  

1. **支持多重嵌套**  
```python
	nested_list = [['Hello', 'World'], ['Goodbye', 'World']]
	nested_list = [[s.upper() for s in xs] for xi in nested_list]
	print(nested_list)
```  
```python
	[['HELLO', 'WORLD'], ['GOODBYE', 'WORLD']]
```  

2. **支持多重迭代**  
```python
	[(a, b) for a in ['a', '1', 1, 2] for b in ['1', 3, 4, 'b'] if a != b]
```  
```python
	[('a', '1'), ('a', 3), ('a', 4), ('a', 'b'), ('1', 3), ('1', 4), ('1', 'b'), \
		(1, '1'), (1, 3), (1, 4), (1, 'b'), (2, '1'), (2, 3), (2, 4), (2, 'b')]
```  

3. **列表解析语法中的表达式可以是简单表达式，复杂表达式，函数**  
```python
	def f(v):
		if v%2 == 0:
			v = v ** 2
		else:
			v = v + 1
	[f(v) for v in [2, 3, 4, -1] if v>0]
```  
```python
	[v**2 if v%2 == 0 else v+1 for v in [2, 3, 4, -1] if v > 0]
```  

4. **列表解析语法中的`iterable`可以是任意可迭代对象**  
```python
	fh = open("test.txt", "r")
	result = [i for i in fh if "abc" in i]
	print(result)
```  

**优势**  
* 使用列表解析更为直观清晰，代码更为简洁  
* 列表解析的效率更高  

除了列表以外，其他几种内置的数据结构也支持，比如：元组，集合，字典等。

***

#### 13. 参数传递

python函数参数传递为**对象**或**对象的引用**。  
可变对象的修改在函数外部以及内部都可见，调用者和被调用者之间共享这个对象。  
不可变对象，由于并不能真正被修改，因此，修改往往是通过生成一个新对象然后赋值来实现的。  

***

#### 14. `str()`和`repr()`的区别

1. **两者之间目标不同：**  
  * `str()`主要面向用户，其目的性是可读性，返回形式为用户友好性和可读性都较强的字符串类型；
  * `repr()`面向的是python解释器，或者说开发人员，其目的是准确性，其返回值表示python解释器内部的含义常作为编程人员debug用途。

2. 在解释器中直接输入a时默认调用`repr()`函数，而`print(a)`则调用`str()`函数。

3. `repr()`的返回值一般可以用`eval()`函数来还原对象，通常来说有如下等式。  
  `obj == eval(repr(obj))`

4. 这两个方法分别调用内建的`__str__()`和`__repr__()`方法，`__str__()`方法可选，当可读性比准确性更为重要的时候应该考虑定义`__str__()`方法。

***


#### 15. 字符串的基本用法  

**判定是否包含字串**  
可以用`find()`方法，推荐使用`in`和`not in`操作符。  

```python
	str = "Test if a string contains some special substrings"
	if str.find("some") != -1: # 使用find方法进行判断
		print("Yes, it contains")
```  

```python
	if "some" in str: # 使用in方法也可以判断
		print(Yes, it contains using in)
```  

**`split()`的使用**  
`split([sep [,maxsplit]])`，参数`maxsplit`是最大分切次数。  

对于字符串`s`，`s.split()`、`s.split('')`的返回值是不同的。  
`s.split()`先去除字符串两端的空白符，然后以任意长度的空白符串作为界定符分切字符串。  
`s.split('')`认为两个连续的`sep`之间存在一个空字符串。  

***

#### 16. `sort()`和`sorted()`的用法  

两者的**函数形式**：  
```python
	sorted(iterable[, cmp[, key[, reverse]]])
	s.sort([cmp[, key[, reverse]]])
```  

**参数**  

* `cmp`为用户定义比较函数  
* `key`是带一个参数的函数，用来为每个元素提取比较直。
* `reverse`表示排序结果是否反转

**`sort()`和`sorted()`的不同之处：**  

1. 相比于`sort()`,`sorted()`使用的范围更为广泛。
  
2. 当排序对象为列表的时候，两者适合的场景不同。  
  `sorted()`函数会返回一个排序后的列表。  
  `sort()`函数会直接修改原有列表。但消耗的内存较少，效率较高。  

3. 无论是`sort()`还是`sorted()`函数，传入参数`key`比传入参数`cmp`效率要高。

4. `sorted()`函数功能非常强大，使用它可以方便地针对不同的数据结构进行排序。
  * 对字典进行排序  
  
    ```python
	    phonebook = {'Li': '77', 'Bo': '93', 'Ca': '58'}
		from operator import itemgetter
		sorted_pd = sorted(phonebook.items(), key=itemgetter(1))
	```  

  * 多维`list`排序  
	
	```python
		from operator improt itemgetter
		gameresult = [['Bob',95.00,'A'],['Alan',86.0,'C'], \
			['Mandy',82.5,'A'],['Rob',86,'E']]
		print(sorted(gamersult, key=itemgetter(2, 1)))
	```  
		
  * 字典中混合`list`排序  

	```python
		dict = {'Li':['M',7],
		'Zhang':['E',2],
		'Wang':['P',3],
		'Du':['C',2],
		'Ma':['C',9],
		'Zhe':['H',7]}
		print(sorted(dict.items(), key=lambda k: k[1][0]))
	```  

  * `List`中混合字典排序
  
	`lue`

***

#### 17. 浅拷贝与深拷贝

**浅拷贝**：构造一个新的符合对象并将从原对象中发现的引用插入该对象中。如工厂函数、切片操作、`copy`操作。  

**深拷贝**：构造一个新的符合对象，但是遇到引用会继续递归拷贝其所指向的具体内容，也就是说它会针对引用所指向的对象继续执行拷贝，因此产生的对象不受其他应用对象操作的影响。  

简单而言：浅拷贝直接拷贝原对象中包含的引用，而深拷贝会继续对引用指向的对象进行拷贝。

***


***
本书中还涉及到许多其他关于设计模式、多线程、网络编程等相关的知识，由于本人暂时~~（看不懂）~~不需要用到，所以没有多深究，详见原书。以后对python有了更深入理解后再详细阅读。

#### 18. `__init__()`不是构造方法 


**真正的构造方法其实是`__new__()`**

`__init__()`方法所做的工作是在类的对象创建好之后进行变量的初始化，`__new__()`方法才会真正的创建实例，是类的构造方法。 
这两个方法都是`object`类中默认的方法，继承自`object`的新式类，如果不覆盖这两个方法会默认调用`object`中对应的方法。

**这两个方法之间不同点：**  

* `__new__()`方法是静态方法，而`__init__()`为实例方法。  
* `__new__()`方法一般需要返回类的对象，当返回类的对象时将会自动调用`__init__()`方法进行初始化，如果没有对象返回，则`__init__()`方法不会被调用。`__init__()`方法需要显示返回，默认为`None`,否则会在运行时抛出`TypeError`。  
* 当需要控制实例创建的时候可使用`__new__()`方法，而控制实例初始化的时候使用`__init__()`方法。  
* 一般情况下不需要覆盖`__new__()`方法，但当子类继承自不可变类型，如`str`、`int`、`unicode`或者`tuple`的时候，往往需要覆盖该方法。  
* 当需要覆盖`__new__()`和`__init__()`方法的时候这两个方法的参数必须保持一致，如果不一致将导致异常。  


**在什么特殊情况下需要覆盖`__new__()`方法**  

* 当类继承自不可变类型且默认的`__new__()`方法不能满足需求的时候。  
* 用来实现工厂模式或者单例模式或者进行元类编程的时候。
* 作为用来初始化的`__init__()`方法在多继承的情况下，子类的`__init()__`方法如果不显式调用父类的`__inti__()`方法，则父类的`__init__()`方法不会被调用。


***

#### 19.为什么需要`self`参数

1. python再当初设计的时候借鉴了其他语言的一些特性，如Moudla-3中方法会显式地再参数列表中传入`self`  

2. python语言本身的动态性决定了使用`self`能狗带来一些便利。  
  例：  
	```python  
		def len(point):
			return math.sqrt(point.X **2 + point.Y **2)
			
		class RTriangle(object):
			def __init__(self, right_angle_sideX, right_angle_sideY):
				self.right_angle_sideX = right_angle_sideX
				self.right_angle_sideY = right_angle_sideY
		
		RTriangle.len = len
		rt = RTriangle(3, 4)
		rt.len()  
	```  
3. 在存在同名的局部变量以及实例变量的情况下，使用`self`使得实例变量更容易被区分。  

***

#### 20. 掌握循环优化的基本技巧  

1. 减少内部循环的计算。  
2. 将显式循环改为隐式循环。  
例：求等差数列1,2,...,n的和
	```python  
		sum = 0
		for i in range(n+1):
			sum = sum+i  
	```  
也可以直接计算：`n*(n+1)/2`  
3. 在循环中尽量引用局部变量。 （因为在命名空间中局部变量优先搜索）  
4. 关注内层嵌套循环。 （尽量将内层循环的计算往上层移）  

***

全剧终~
