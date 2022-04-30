

## wy c++进阶

### 1. Objective view
* 默认构造函数调用顺序
    1. 先调用父类构造函数
    2. 初始化虚表和虚指针
    3. 调用成员变量的构造函数
    ```c++
    // Pseu code in c
    struct BaseInC {};
    struct AtomInC: public BaseInC 
    {     
        struct Cell { int m_data; };     
        Cell m_c1;     
        Cell m_c2;     
        int m_i; 
    };  
    // Pseu code in c 
    void AtomInC__Construct(AtomInC* this_) 
    {     
        // 调用基类的构造函数
        BaseInC__Construct(this_);     
        // setting vtable ptr if need.设置虚表和虚指针
        // call member constructor by defined order 调用成员变量的构造函数  
        CellInC__Construct(&this_->m_c1);     
        CellInC__Construct(&this_->m_c2);     
        // m_i is trivial type, leave it uninitialized  不初始化m_i
    } 
    ```

* 拷贝构造函数
    1. `bitwise`默认构造函数，是一个逐字节拷贝的方法
    2. `memberwise`拷贝，是逐成员变量拷贝，如果我们不实现具体的功能(直接空函数体{})，它就是默认的操作
    ```c++
    // bitwise copy constructor 
    void AtomInC__Copy(AtomInC* this_, AtomInC* src) 
    {     
        memcpy(this_, src, sizeof(*this_));
    } 
    // memberwise copy constructor 
    void AtomInC__Copy(AtomInC* this_, AtomInC* src) 
    {     
        // call base class copy contructor.     
        BaseInC__Copy((BaseInC*)this_, (BaseInC*)src);     
        // setting vtable ptr if need.     
        // call member functions by defined order.     
        CellInC__Copy(&this_->m_c1, &src->m_c1);     
        CellInC__Copy(&this_->m_c2, &src->m_c2);     
        // rough annotation     
        this_->m_i = src->m_i; 
    } 
    ```

* TrivialType 平凡类型？
    当构造函数，拷贝构造函数，析构函数都是Trivail时，那么这个类就是Trivial类
    `POD`：[标准布局](https://en.cppreference.com/w/cpp/named_req/StandardLayoutType)（布局和C的布局时是兼容的），TrivialCopyable（平凡类）
    当函数是`TrivialCopyable`时，就可以采用`bitwise`的方式进行拷贝构造，速度会更快

* Copy Elision 拷贝消除(c++17)
    返回值优化，具名对象返回优化（局部变量也会优化）。
    如果关闭拷贝消除，总共会调用一次构造函数，两次move构造函数，三次析构
    开启拷贝消除，只会调用一次构造函数和析构函数
    ```c++
    Foo test_rvo() { return Foo(); }
    Foo t = test_rvo();
    Foo test_nrvo() { Foo tmp; return tmp; }
    Foo t = test_nrvo();        // 同样有效
    ```
    同时，对象分配的栈也会提前优化，分配在调用函数栈(CallFrameData)之外。


* 类成员变量初始化，
    1. 可以使用初始化列表，（但是要小心，不能用其他成员变量来初始化，它的初始化本身是无序的）
    2. 可以直接用=在定义之后赋值，设置默认成员初始值（default member initializer）
    3. 使用初始化列表`initializer_list`

* 类型转换
    1. 定义构造函数，接收指定类型参数，
    2. 可以实现`operator int()`成员函数，提供转换成`int`类型的方式
    如果不希望隐式转换的话，需要加上`explicit`声明

* 析构函数：
    1. `public and virtual`当需要使用基类指针管理子类对象时，应当声明为虚函数，否则在`delete`时会调用到父类析构函数导致资源泄漏。
    2. `protected and non-virtual`保护型非虚函数，1. 共享数据和方法，2. 不需要多态的，3.防止其他模块使用基类指针去析构子类对象。



* 对象的声明周期类型
    * auto：有声明周期
    * static：静态变量，拥有整个程序声明周期的变量（例如全局变量）
    * thread：线程级变量，和线程声明周期一致
    * dynamic：使用new动态分配的内存

* 静态存储区对象的构造顺序
    静态存储区变量，如果在同一编译单元是按照定义的顺序，若不在同一编译单元是未定义的行为。
    在这种情况下，可能导致使用未定义的一个对象。下面是可能的解决方法：
    ```c++
    // fileRender.cpp
    g_render_sys::ctor()
    // fileSys.cpp
    g_patch_sys::ctor() // 调用了g_render_sys的方法
    ```
    1. 组织好链接顺序，调整文件顺序，（但是无法解决循环调用的问题）
        `gcc fileSys.o fileRender.o -lstdc++ -o game.exe`
    2. 使用单例
        ```c++
        // 视频里说创建对象时会加锁，导致卡死，我自己试了下直接crash并且不会调用析构函数：terminate called after throwing an instance of '__gnu_cxx::recursive_init_error' what():  std::exception
        struct FileSys {
            static FileSys& getInstance() {
                static Render f;
                return f;
            }
        }
        // 使用指针没有合适的销毁时机，导致竞态死锁
        struct FileSys {
            static FileSys& getInstance() {
                if (!p_fs) 
                {   
                    static std::mutex mtx;   
                    std::lock_guard<std::mutex> lck(mtx);   
                    p_fs = new FileSys(); 
                }
                return *p_fs;
            }
        }
        ```
    3. 按顺序初始化，在析构的时候，会导致原来的问题
    视频最终总结，尽量让类自己管理资源，低耦合高内聚

* 成员变量修饰符
    * `mutable`，成员声明了的话，即使是常量对象，它也可以修改该成员变量
    * `static`，归属于类的静态对象；`inline static int m_si = 2;`是支持的，有利于模板元编程

* Bitfield
    ```c++
    struct BitField {
        int i0  : 12;
        int     : 8;
        int i1  : 4;
        unsigned short s0   : 8;
        char c0 : 100;      // 会报错
    }
    // 上面的结构体总共占8字节
    ```

* 类的布局和子对象
    如果父类包含虚函数，那么子类继承时，会优先把虚表放在顶部（对象的开头）
    空类大小为1（方便数组的操作），如果被继承了，子类会优化掉这一个字节

* 成员函数cv描述符(cv-qualified)
    * `const`：是成员变量都是const，可以用常引用/变量使用，添加保护防止修改
    * `volatile`：非线程安全，保证编译器不优化访问，每次都从内存去读取数据，对c中信号友好
    声明不相同的是无法调用不兼容修饰的成员函数

* Name Hidding
    * 继承里会有名字隐藏，当子类实现了父类的同名函数，可以使用`using Base::print`的方法引用基类中的方法
    * 但是如果不同名的函数，子类对象是可以正常调用父类的函数的。

* 虚函数控制：`virtual`，`override`，`final`
* 假如有默认参数，在继承状态中，编译器会默认将指针类型所对应的类的默认值传入 虚函数执行的方法

* 名字查找（Name Lookup）
    * 当解析函数调用时：首先进行**名字查找(Name Lookup)**，再进行**重载解析(Overload Resolution)**，若有多个匹配会报**模糊调用(ambiguous)**错误。  
        * `NameLookup`类型：namespace/function/class/typdef/var
        * Unqualified（未添加描述符）：`cout << "xxx";`
        * Qualified（添加了描述符的）：`::std::cout << "xxx";`
    * 未指定命名空间的查找(Unqualified Name Lookup)
        * 代码段`Block Scope`->类作用域`Class Scope`->基类作用域`Base Class Scope (recursive)`->命名空间`Enclosing NameSpace (recursive)`->全局作用域`Until Global Scope`
        ```c++
        class B 
        {      
            int i; // found 3rd 
        }; 
        namespace M 
        {     
            int i; // found 5th     
            namespace N 
            {         
                class X : public B 
                {             
                    int i; // found 2nd             
                    void f(); 
                };         
                int i; // found 4th 
            } 
        } 
        int i; // found 6th 
        void M::N::X::f()
        {     
            int i;  // found 1st     
            i = 16; // start of unqualified look visit 
        }
        ```
        * 如果使用`using namespace scope`，其实是将`scope`引入嵌套当前的命名空间中，会优先查找本地命名空间，然后才是引入的这个。
        * 如果使用`using scope::func`，会将`func`引入到当前命名空间中，若签名一致会引起模糊调用
        * 对于函数调用，会触发参数依赖查找`Argument Dependent Lookup(ADL)`，也就是会查找每个参数所在命名空间的名称。例如：一个典型的应用就是运算符重载`+`，自定义的对象实现了加运算，会在参数的命名空间中找到`operation +`操作。
        ```c++
        namespace myproj 
        {     
            struct Foo {};     
            void dump(Foo&) {} 
        }  
        void test_adl() 
        {     
            myproj::Foo f;     
            dump(f);    // 使用ADL查找规则，正确找到了myproj::dump方法
        }
        ```
        * 对于`lambda`表达式，不会进行ADL查找，因为它不是一个函数调用。而是类对象的运算符重载。
        * **大致为**：一个函数调用会 **同时** 在当前局部作用域内查找 和 在参数所在命名空间中查找 当前的函数名。如果有多个复合条件就是模糊调用。
        * 它也可以用在特化通用函数(如`swap`)，提供高效的实现。
        * 对于类静态变量定义，或者定义类函数时，本质上还是在类的命名空间，是一种语法糖。
    * Qualified Name Lookup
        使用`::`指定了命名空间的方式，对于`std::cout`，其实是先执行了一次不具名的查找`std`，才进行qualified查找`cout`
    * 名字查找和重载解析，是不同概念，重载解析是在查找结果之后，匹配对应的参数，若有多组可选项，会报模糊调用的错误。