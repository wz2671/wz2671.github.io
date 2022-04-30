
# 侯捷c++视频

## 操作符重载
* 在视频中(5.操作符重载)，有小段代码如下：
    ```c++
    inline complex operator + (const complex& x)
    {
        return x;
    }
    ```
    本意是支持`complex d = +c;`这样的运算，此时侯捷老师发问，为何不将返回值改为返回引用，并给出解答，应该是可以的
    我以为的是，返回引用外部可能会在不知情的情况下，改变形参传入的对象值。
    我试了一下，不能编译通过`'return': cannot convert from 'const complex' to 'complex &'`。
    把`const`关键字去掉之后，返回的结果和传入的参数引用，并不是同一个
    ```c++
    inline complex& operator + (complex& x)
    {
        return x;
    }

    complex d = +c;
    // 这样子d和c是不同的对象，并不会引用到同一个地方（我推测，应该是在 = 赋值操作，调用了赋值构造函数）
    complex &d = +c;
    // 这样子会导致c修改，d也会修改
    ```
* 如果要重载`<<`操作符，不能定义为成员函数，只能定义为全局的函数
    ```c++
    ostream& operator << (ostream& os, const complex& x) { return os }
    ```
* 像 `+=` 这种运算符，如果用链式调用的话，是优先从左往右算的。
    ```c++
    inline complex& operator += (complex& v)
    { 
        this->x += v.x;
        this->y += v.y;
        return *this;
    }
    // 以下结果, c为(7, 9)，d为(5, 6)，可以用括号来改变优先级
    complex c(2, 3);
    complex d(4, 5);
    complex e(1, 1);
    c += d += e;
    ```

## 带有指针的类
* 必须自己实现，**拷贝构造函数**(copy ctor)和**拷贝赋值函数**(copy op=)和**析构函数**
    因为 编译器提供的默认函数，都是浅拷贝，会将指针的内容按位拷贝
    容易造成内存泄漏和指向同一个对象
* 拷贝赋值函数 需要注意 要先判断是否为自己，在执行释放内存，分配并赋值
* 对于数组，如果分配的时候用了array new(`p = new string[3]`)，但是并没有用array delete(`delete [] p`)
    此刻会造成内存泄漏，因为`delete p`只会导致数组的第一个元素的析构函数被正确调用，其他元素未被析构，会导致分配的内存无法得到释放
    但是如果数组元素不包含指针，那么所有的内存是可以被正确释放的。但显然，还是用`delete []`正常点。


## 两个类之间的关系
* `Composition`组合，表示一个类持有另一个类的对象
    先调用成员对象构造函数，再调用自身构造函数。析构反之
* `Delegation`委托，又称为Composition by reference，表示一个类持有另一个的引用（一般为指针）
    point to implemet(pImpl)；Handle/Body
    copy on write: 当有某个小弟想改变内容时，就拷贝单独一份让他去改，不能影响其他也引用此对象的用户
* `Inheritance`继承
    先调用父类构造，再调用子类构造函数。先调用子类析构函数，再调用父类析构函数


## 继承(Inheritance)与虚函数(virtual functions)
* 虚函数
* 纯虚函数(`virtual fun() = 0`)，子类继承后必须要实现改方法
* 普通函数
* 使用一个`prototype`的示例，介绍了一种工厂模式的实现方法
    大致的思路是：子类创建一个静态对象，并在构造函数里添加到父类的一个prototype容器里，
    父类想创建子类对象时，从prototype容器里取出对象原型，调用子类的`clone`函数，动态创建一个对象。

* 多态的实现，主要是通过虚指针+虚表实现（动态绑定），大致来说，如下所示：
    1. 当基类里定义了虚函数之后，那么基类及其子类都会包含，一个成员变量虚指针(`vptr`)，它指向虚函数表(`vtbl`)。
    2. 虚表中存的就是每个类中，所有虚函数的地址列表。当调用虚函数时，会被编译成，用成员变量的虚指针，从虚函数表中找到对应的虚函数地址并执行。
    3. 如`*(p-vptr)[n])(p);`所示，`p`表示指向对象的指针，`n`表示虚函数在虚表中的下表索引，取出该函数，并将自己的`this`指针传入。
    4. 显然，每个类中虚表的大小是一致的，等于虚函数的个数；在子类中，弱子类没有覆写对应的虚函数，那么虚表中存的就是父类的地址，如果覆写了，那么就是子类的实现；根据指针的类型，就可以动态的决定调用的函数了。

## `new`和`delete`
* 他们被称为表达式，对应的具体操作是固定的，无法被更改。
    * `new`： 1. 调用`operator new`分配内存。2. 将内存区域进行类型转换`static_cast`。3. 调用对象构造函数
    * `delete`： 1. 调用对象析构函数。2. 释放内存。
* `new`之类的行为不能更改，但是`operator new`之类的操作符是可以被重载的，可以用来做内存池之类的机制。
* `new[]`和`delete[]`的运算符，他们的参数`size_t`会额外包含4字节的大小，里面存的是元素个数
* 使用`Foo* p = ::new Foo(7);`这样的操作，可以绕过重载的`new`方法，直接调用全局的`new`方法。
* 还有一种叫做placement new，可以给`operator new`添加额外的参数，并用`new(extra)`的形式创建对象，就可以使用自定的函数，并且达到无声无息多分配一些内存的效果了，例如标准库中字符串的引用计数之类功能的实现。


## 泛型编程

* 在模板尖括号中，typename和class关键字可以互通
* member template 成员模板
    可以给成员函数再特殊指定模板，使函数可以接受其他类型的模板
    可以用于接受多态类型的参数
* 全特化
    将所有的模板类型，全部都指定，并且提供对应的实现。
* partial specialization 模板偏特化
    假设有多个模板参数，但是只绑定部分的参数类型，就称之为模板偏特化
    可以缩小范围（从任意类型缩小到指针）
    可以指定类型
* template template parameter 模板模板参数
    在模板参数 声明里的 参数类型，它还可以是模板类型
    ```c++
    template<typename T, template <typename T> class container>
    class XCls{
        private: 
        Container<T> c;
    }
    template<typename T>
    using Lst = list<T, allocator<T>>    // 必须要声明该类型，以下对象定义才能成功编译。

    XCls<string, Lst> mylist;
    ```
    以上实现，如果不用模板模板参数实现，就如下所示：
    ```c++
    template<typename T, typename container>
    class XCls{
        private: 
        Container c;
    }
    XCls<string, Lst<string>> mylist;   // 也可以达到同样的效果，个人感觉就稳了很多
    ```

***
## c++ 11

* variadic templates 数量不定的模板参数
    有点像python中的*args
    ```c++
    void print() {}     // 这个是出口
    template<typename T, typename... Types>
    void print(const T& firstArg, const Types&... args)
    {
        cout<< fristArg << endl;
        print(args...); // 递归调用自己或出口
    }
    ```
* auto 如果在声明变量时就赋初值，就可以不指定类型，自动推断出变量的类型（如迭代器）

* bigThree：指的是析构函数，拷贝构造函数，拷贝赋值函数（在c11里还会包含右值引用的两个方法）  
    一个空的类，编译会默认提供以上三个方法，主要是为了方便编译器添加调用父类函数的代码
    可以在函数声明后面添加`=delete`或者`=default`，分别表示不支持操作，或者是使用编译器默认提供的方式。
    例如把拷贝构造函数后面添加`=delete`可以表示对象不支持拷贝，但是删除析构函数的作用不清楚有什么意义。

* alias template 化名(template typedef)
    ```c++
    template <typename T>
    using Vec = std::vector<T, MyAlloc<T>>;
    ```
    在c++11/14课程，第10-11讲里介绍了使用化名来让函数模板可以接受模板模板参数来作为参数，例如，**使一个函数接受两个数据类型（1，数据类型如int；2，容器类型如vector），函数中可以创建容器并动态添加元素**。

* `using`
    1. 用作`typedef`，例如`using func = void(*)(int, int)`
    2. 开放命名空间`using namespace std; using std::count;`
    3. 在类成员里使用类型声明`using _Base::_M_xxx`，这样子就可以直接使用`_M_xxx`作为类型了。

* `noexcept`
    在函数声明后面添加，意思是该函数一定不会抛出异常。
    它可以添加一个参数`void foo() noexcept; void foo() noexcept(true);`
    如果用在`move_constructor`上，需要加上该关键词，不然标准库不敢用你写的。

* `override` 覆写，改写
    主要用在虚函数上。`virtual void func(int) override;`
    编译会帮助检查父类是否定义了该函数，如果没有定义会报错（本质上就是个检查）

* `final`
    如果在父类上后面加了`final`，那么这个类不能再被继承，无法编译通过；`struct Base1 final {};`
    也可以加载虚函数后面，那么这个函数不允许被子类覆写；`virtual void f() final;`，也是帮忙检查的。

* `decltype` （算是关键词
    类似于`typeof`，如`map<string, float> coll; declytype(coll)::value_type elem;`，可以通过对象获取类型。它主要有三个用途：  
    1. 声明返回类型
        ```c++
        template <typename T1, typename T2>
        auto add(T1 x, T2 y) -> decltype(x + y);
        // lambda表达式也是这样子声明返回类型的
        // [...] (...) mutable_opt throwSpec_opt -> retType_opt {...}
        ```
    2. 元编程，在模板里各种应用
        ```c++
        // 假设T是一个容器
        template<typename T>
        void test(T obj)
        {
            typedef typename decltype(obj)::iterator iType; // 当使用了::后，就需要typename
            // iType 就可以直接用了来创建对象了
        }
        ```
    3. 传递lambda表达式类型
        ```c++
        auto cmp = [](const Person& p1, const Person& p2) { return true; }
        std::set<Person, decltype(cmp)> coll(cmp);
        ```
* `Lambdas` 形式如:
    `[...] (...) mutable throwSpec -> retType {...}`
    中括号里，可以把一些上下文的变量传入进去，供`lambda`函数体里使用。使用=号通过值传递，&号通过引用传递，最好全都显式指定
    小括号里，可以传参数，就是一般函数定义以及调用的方式
    大括号里，实现具体函数内容
    `mutable`关键词，可以使函数修改传入的值，但是要真的修改的话，需要通过引用传入
    `retType`定义返回类型

* `variadic templates`

* 右值引用
    1. 一般右值指的是**临时变量**，例如函数返回值，构造的临时对象，常数，等等
    2. 由于是临时变量，它基本上不会被使用，反复调用拷贝构造函数，对于有指针成员变量的，会有很多额外分配内存等操作，使用右值引用定制相关接口(&&)，可以将临时对象分配的内存拿来使用，并将临时对象简单处理一下即可。
        ```c++
        // 直接把右值对象str，的指针_data赋给当前对象，并将str的直接置为NULL，可以避免重新分配内存
        MyString(MyString&& str) noexcept: _data(str._data), _len(str._len)
        {
            str._len = 0;
            str._data = NULL;   // 关键
        }
        ```
    3. 如果希望能将普通函数传入到接收右值的接口中，需要使用`std::move`的方法，但是需要注意，被`move`过后的对象就不能再继续使用了。
    4. 在接受右值引用的接口中，将那个具有名字的对象调用其他函数时，那个对象会无法调用到另外的接受右值接口，此被称为不完美的转交(unperfect forwarding)。此时，应当采用`std::forward<Type>`方法来解决。
        ```c++
        void process(int && i) {}
        void forward(int && i) {
            process(std::forward<int>(i));  // 这样子，就能调用到上面定义的右值接口
        }
        ```

* 智能指针
    1. 智能指针的基类里，包含两个成员，对象的指针和引用计数，其中引用计数分别包含**弱引用计数**和**引用计数**
    2. `shared_ptr`之间的赋值操作会引起引用计数的变化，但是赋值给`weak_ptr`不会改变使用次数`use_count()`。
    3. 


# 浙大翁恺
[视频链接](http://study.163.com/course/courseMain.htm?courseId=271005)

## inline
* 本质上是把函数body展开在调用的地方
* 如果声明了inline函数，那么是不会被编译的  
    如果函数声明和实现在不同地方，并且在调用方的地方，只声明了函数，没有实现的body，那么无法通过编译
* 直接在类(.h)里的函数，如果直接实现了，那么它就是inline的，也可以写在class定义的后面，加上inline关键词

## const
* 在函数声明和函数实现体之间加的const，可以理解为是给this指针加了const约束，也可以解释为什么加个const也能重载
    ```c++
    void f() {}         // void f(A* this)
    void f() const {}   // void f(const A* this)
    ```
* 如果直接在当前cpp文件里定义了`const int`变量并给了初始值，那么它可以在本地用来作为数组的大小，定义数组。
    但是如果这个变量只是声明了另一个文件中的常量，或者接受的是运行时才能获取的数据，那么该常量不能用于初始化数组。
    ```c++
    const int v = 10;
    int arr[v];     // 可
    cin >> v;
    const int v2 = v;
    int arr[v];     // 不可
    ```
* 需要关注常量指针和指针常量，是完全不同的内容，如以下例子所示，在`*`号左边就是指向的内容不能修改，在`*`号右边就是所指向的位置不能修改，甚至可以两者都加(如`p3`)，那么两个都不能修改。
    ```c++
    void test_consts()
    {
        int val = 222, val2 = 111;
        int * const p0 = &val;
        int const * p1 = &val;
        const int * p2 = &val;
        const int * const p3 = &val;
        *p0 = 333;
        // *p1 = 333;      // ERROR
        // *p2 = 333;      // ERROR
        // *p3 = 333;      // ERROR
        // p0 = &val2;     // ERROR
        p1 = &val2;
        p2 = &val2;
        // p3 = &val2;      // ERROR
        std::cout << *p0 << " " << *p1 << " " << *p2 << std::endl;  // 333 111 111
    }
    ```

## 声明与定义
* 两者的区别其实很大，像类里面的一般都是声明，并没有实际定义变量（所以静态变量一定要在.cpp里定义以下）



# 继承与多态
* 如果一个对象里的成员变量很简单，例如只有一个`int`，那么可以通过将该对象地址强制转换成`int`指针，进行赋值操作，就能改变它的`private`类型的数据内容，挺鬼畜的。
* 如果一个类包含虚函数，它的对象会包含一个虚指针，那么可以通过将该对象地址强制转换成`int`指针，该指针中的值就是虚指针所指向的虚表，如果把它的值改成子类的虚指针值，那么它调用`virtual`函数时就会调用到子类的。
    ```c++
    A a; B b;   // 假设B继承自A, 且包含virtual function f()
    A* p = &a;
    int* r = (int*)&a;
    int* t = (int*)&b;

    *r = *t;
    p->f(); // 会调用到B类的f()
    ```
* 只有指针和引用可以表现出多态（父类指针/引用会根据指向的对象，动态调用函数），对象直接用`.`不行。
* 显然，析构函数要定义成`virtual`。
* 子类中调用父类函数的形式为：`Base::func();`
* 如果函数不是虚函数，那么父类子类中的同名函数，毫无关联。
* 如果在父类中有多个同名的`virtual`重载函数，那么在子类中，也必须要重载所有的同名函数。

