

# wy c++进阶

### 1. Objective view

#### 默认构造函数调用顺序

1. 先调用父类构造函数
2. 初始化虚表和虚指针
3. 调用成员变量的构造函数
```c++
// Pseu code in c
struct BaseInC {};
struct AtomInC: public BaseInC 
    struct AtomInC: public BaseInC 
struct AtomInC: public BaseInC 
{     
    {     
{     
    struct Cell { int m_data; };     
        struct Cell { int m_data; };     
    struct Cell { int m_data; };     
    Cell m_c1;     
        Cell m_c1;     
    Cell m_c1;     
    Cell m_c2;     
        Cell m_c2;     
    Cell m_c2;     
    int m_i; 
        int m_i; 
    int m_i; 
};  
// Pseu code in c 
    // Pseu code in c 
// Pseu code in c 
void AtomInC__Construct(AtomInC* this_) 
    void AtomInC__Construct(AtomInC* this_) 
void AtomInC__Construct(AtomInC* this_) 
{     
    {     
{     
    // 调用基类的构造函数
    BaseInC__Construct(this_);     
        BaseInC__Construct(this_);     
    BaseInC__Construct(this_);     
    // setting vtable ptr if need.设置虚表和虚指针
    // call member constructor by defined order 调用成员变量的构造函数  
        // call member constructor by defined order 调用成员变量的构造函数  
    // call member constructor by defined order 调用成员变量的构造函数  
    CellInC__Construct(&this_->m_c1);     
        CellInC__Construct(&this_->m_c1);     
    CellInC__Construct(&this_->m_c1);     
    CellInC__Construct(&this_->m_c2);     
        CellInC__Construct(&this_->m_c2);     
    CellInC__Construct(&this_->m_c2);     
    // m_i is trivial type, leave it uninitialized  不初始化m_i
} 
```

#### 拷贝构造函数
1. `bitwise`默认构造函数，是一个逐字节拷贝的方法
2. `memberwise`拷贝，是逐成员变量拷贝，如果我们不实现具体的功能(直接空函数体{})，它就是默认的操作
```c++
// bitwise copy constructor 
    // bitwise copy constructor 
// bitwise copy constructor 
void AtomInC__Copy(AtomInC* this_, AtomInC* src) 
    void AtomInC__Copy(AtomInC* this_, AtomInC* src) 
void AtomInC__Copy(AtomInC* this_, AtomInC* src) 
{     
    {     
{     
    memcpy(this_, src, sizeof(*this_));
} 
// memberwise copy constructor 
    // memberwise copy constructor 
// memberwise copy constructor 
void AtomInC__Copy(AtomInC* this_, AtomInC* src) 
    void AtomInC__Copy(AtomInC* this_, AtomInC* src) 
void AtomInC__Copy(AtomInC* this_, AtomInC* src) 
{     
    {     
{     
    // call base class copy contructor.     
        // call base class copy contructor.     
    // call base class copy contructor.     
    BaseInC__Copy((BaseInC*)this_, (BaseInC*)src);     
        BaseInC__Copy((BaseInC*)this_, (BaseInC*)src);     
    BaseInC__Copy((BaseInC*)this_, (BaseInC*)src);     
    // setting vtable ptr if need.     
        // setting vtable ptr if need.     
    // setting vtable ptr if need.     
    // call member functions by defined order.     
        // call member functions by defined order.     
    // call member functions by defined order.     
    CellInC__Copy(&this_->m_c1, &src->m_c1);     
        CellInC__Copy(&this_->m_c1, &src->m_c1);     
    CellInC__Copy(&this_->m_c1, &src->m_c1);     
    CellInC__Copy(&this_->m_c2, &src->m_c2);     
        CellInC__Copy(&this_->m_c2, &src->m_c2);     
    CellInC__Copy(&this_->m_c2, &src->m_c2);     
    // rough annotation     
        // rough annotation     
    // rough annotation     
    this_->m_i = src->m_i; 
        this_->m_i = src->m_i; 
    this_->m_i = src->m_i; 
} 
```

#### TrivialType 平凡类型？
当构造函数，拷贝构造函数，析构函数都是Trivail时，那么这个类就是Trivial类
`POD`：[标准布局](https://en.cppreference.com/w/cpp/named_req/StandardLayoutType)（布局和C的布局时是兼容的），TrivialCopyable（平凡类）
当函数是`TrivialCopyable`时，就可以采用`bitwise`的方式进行拷贝构造，速度会更快

#### Copy Elision 拷贝消除(c++17)
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


#### 类成员变量初始化，
1. 可以使用初始化列表，（但是要小心，不能用其他成员变量来初始化，它的初始化本身是无序的）
2. 可以直接用=在定义之后赋值，设置默认成员初始值（default member initializer）
3. 使用初始化列表`initializer_list`

#### 类型转换
1. 定义构造函数，接收指定类型参数，
2. 可以实现`operator int()`成员函数，提供转换成`int`类型的方式
如果不希望隐式转换的话，需要加上`explicit`声明

#### 析构函数：
1. `public and virtual`当需要使用基类指针管理子类对象时，应当声明为虚函数，否则在`delete`时会调用到父类析构函数导致资源泄漏。
2. `protected and non-virtual`保护型非虚函数，1. 共享数据和方法，2. 不需要多态的，3.防止其他模块使用基类指针去析构子类对象。



#### 对象的声明周期[类型](https://en.cppreference.com/w/cpp/language/storage_duration)
* auto：有声明周期
* static：静态变量，拥有整个程序声明周期的变量（例如全局变量）
* thread：线程级变量，和线程声明周期一致
* dynamic：使用new动态分配的内存

#### 静态存储区对象的构造顺序
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
                if (!p_fs) 
            if (!p_fs) 
            {   
                static std::mutex mtx;   
                    static std::mutex mtx;   
                static std::mutex mtx;   
                std::lock_guard<std::mutex> lck(mtx);   
                    std::lock_guard<std::mutex> lck(mtx);   
                std::lock_guard<std::mutex> lck(mtx);   
                p_fs = new FileSys(); 
                    p_fs = new FileSys(); 
                p_fs = new FileSys(); 
            }
            return *p_fs;
        }
    }
    ```
3. 按顺序初始化，在析构的时候，会导致原来的问题
视频最终总结，尽量让类自己管理资源，低耦合高内聚

#### 成员变量修饰符
* `mutable`，成员声明了的话，即使是常量对象，它也可以修改该成员变量
* `static`，归属于类的静态对象；`inline static int m_si = 2;`是支持的，有利于模板元编程

#### Bitfield
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

#### 类的布局和子对象
如果父类包含虚函数，那么子类继承时，会优先把虚表放在顶部（对象的开头）
空类大小为1（方便数组的操作），如果被继承了，子类会优化掉这一个字节

#### 成员函数cv描述符(cv-qualified)
* `const`：是成员变量都是const，可以用常引用/变量使用，添加保护防止修改
* `volatile`：非线程安全，保证编译器不优化访问，每次都从内存去读取数据，对c中信号友好
声明不相同的是无法调用不兼容修饰的成员函数

#### Name Hidding
* 继承里会有名字隐藏，当子类实现了父类的同名函数，可以使用`using Base::print`的方法引用基类中的方法
* 但是如果不同名的函数，子类对象是可以正常调用父类的函数的。

#### 虚函数控制：`virtual`，`override`，`final`

#### 假如有默认参数，在继承状态中，编译器会默认将指针类型所对应的类的默认值传入 虚函数执行的方法

### 名字查找（Name Lookup）
* [参考链接](https://en.cppreference.com/w/cpp/language/lookup)
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



### 2. Polymorphism & Exception （类的多态和异常）

#### Pointer to class member（指向类成员的指针）

1. 数据成员的指针
    可以把类中定义的数据类型，用来当作指针和参数使用。对于有继承关系的也ok。
    ```c++
    struct vector3
    {
        float x = 0, y = 0, z = 0;

        void move_dir(float delta, float Vector3::* dir)
        {
            // 这条语句，从汇编角度来说等价于 *(this + dir) += delta
            this->*dir += delta;
        }
    }

    void test_data_ptr()
    {
        vector3 v;
        auto ptr = &vector3::x;     // ptr是一个指向类成员变量的指针
        v.*ptr = 3.0;               // 可以给对象的成员变量赋值
        v.move(1.0, ptr);           // 可以将ptr作为参数传入函数
    }
    ```
    伪代码如下所示：
    ```c++
    template<typename InstType, typename BaseType, typename ValType>
    ValType pick_member(InstType *ins, ValType BaseType::* ptr)
    {     
        int offset = *((int*)(&ptr));           // 类成员指针转成偏移
        BaseType* p_base = (BaseType*)ins;      // 获取基址
        ValType*  ptr_to_ins_member = (ValType*)((char*)p_base + offset);  // 定位到对象成员变量指针
        return *ptr_to_ins_member;              // 取出结果
    }
    ```
    它的作用如下：
    * 兼容继承
    * 检查冗余代码
    * 本质上是内存操作，相对于函数执行，开销很低
    * 对于模板元编程很有用，（它提供了一种，在没有实例对象的情况下，也能访问类成员变量的一种方法）

2. 函数成员的指针
    和数据成员指针类似，用指针指向**类的函数成员**来使用。
    ```c++
    struct Calc 
    {   
        int add(int l, int r) { return l + r; }   
        int sub(int l, int r) { return l - r; }   
        int mod(int l, int r) { return l % r; } 
    };  

    void test_func_ptr() 
    {   
        Calc ins;   
        int (Calc::*ptr_to_func)(int, int);   
        ptr_to_func = &Calc::sub;       // 将类的函数指针 赋值给 指针变量
        // 以下两种调用方式都是可行的
        (ins.*ptr_to_func)(50, 15);
        (ins.*(ptr_to_func))(50, 15);
        // 以下写法可是代码更易读
        // 使用typedef
        typedef int (Calc::* ptrType)(int, int);
        ptrType ptr_to_func = &Calc::sub;
        // 使用宏
        #define CALL_FUNC(object, ptr_to_func) ((object).*(ptr_to_func));
        CALL_FUNC(ins, ptr_to_func)(50, 15);
        // 使用std::invoke
        std::invoke(ptr_to_func, ins, 50, 15);      // 有点类似于python的partical
    }
    ```
    如果函数指针指向了**类的虚函数**，那么该函数指针调用时，也会包含多态性。

3. Functionoid(类函数体)
    使用类函数体可以解决函数指针的一些限制：1. 参数固定，2. 类的种类要一致，3. 必须使用对象实例调用
    Functionoid可以使用`std::bind`,`std::function`,`lambda`等来实现
    ```c++
    void test_func(int val)
    {

    }
    // 可以使用以下方法取代直接使用函数指针
    std::function<void()> func = std::bind(&test_func, 666);
    std::function<void()> func = []() {test_func(666);};

    func();     // 可以避免调用时填写参数
    ```

#### RTTI & Polymorphism （运行时类型识别和多态）
1. `typeid`方法，可以将获取指针或者对象等 的动态类型信息`std::type_info`（它被定义在了`vcruntime_typeinfo.h`文件中）
    ```c++
    struct rEmptyBase {};
    struct rBase { virtual void foo() {} };
    struct rDerivedA : public rBase { }; 
    void test_rtti() 
    {
        rBase* p_ba  = new rDerivedA;      
        // typeid可以动态的根据参数的类型，返回具体类型信息
        // 从汇编的角度，如果是 指针 或者 不是多态对象，会直接返回参数的type_info(RTTI Type Descriptor)
        std::cout << typeid(p_ba).name();       // rBase *
        // 如果是多态对象，如`*p_ba`是一个多态对象，会触发调用函数`__RTtypeid`函数查找运行时真正的信息
        std::cout << typeid(*p_ba).name();      // rDerivedA
    }
    ```
2. `CompleteObjectLocator`定义如下，它处在虚表的开头，其中存储着类的信息和体系结构
    ```c++
    typedef const struct	_s_RTTICompleteObjectLocator	{
        unsigned long							signature;
        unsigned long							offset;
        unsigned long							cdOffset;
        int										pTypeDescriptor;	// Image relative offset of TypeDescriptor
        int										pClassDescriptor;	// Image relative offset of _RTTIClassHierarchyDescriptor
        int										pSelf;				// Image relative offset of this object
        } _RTTICompleteObjectLocator;
    ```
    `typeid`会通过`pTypeDescriptor`来取得具体的`type_info`。
3. `dynamic_cast`（动态类型转换）开销比`static_cast`高，继承体系不满足会失败
    ```c++
    struct rBase { virtual void foo() {} int m_bi = 0; }; 
    struct rBase2 { virtual void moo() {} int m_bi2 = 1; };  
    struct rDerivedA : public rBase { int m_dai = 2; };
    // 由于是protected继承，子类对象往rBase2转型会失败
    struct rDerivedB : protected rBase2 { int m_dbi = 3; };     
    struct rFinal : public rDerivedA, public rDerivedB { int m_fi = 4; };

    rDerivedA* ptr = new rFinal();
    auto ret_upcast = dynamic_cast<rBase*>(ptr);        // 向上转型
    auto ret_downcast = dynamic_cast<rFinal*>(ptr);     // 向下转型
    auto ret_crosscast = dynamic_cast<rBase2*>(ptr);    // 交叉转型，由于是受保护继承，转型失败会返回空指针
    ```
    * 向上转换`up-cast`: 直接返回值，开销和`static_cast`一致。但`protected`之类的继承无法通过编译
    * 向下转换`down-cast`: 会执行`__RTDynamicCast`函数，类型检查开销较大时
    * 交叉转换`cross-cast`: 转到其他的继承链上
    * 转型失败，如果类型为指针会返回空指针，如果是引用会抛出`bad_cast`
    * 基于虚表来做，向上转型在编译时检查，非共有继承转型会失败
4. 花了较大篇幅介绍`dynamic_cast`，由于过于庞杂而且吹牛感觉用处不大，就简略记下
    * 在VC的实现里，上述`CompleteObjectLocator`里的`pClassDescriptor`中包含一个`ClassDescriptorArray`，里面记录了当前所有类的继承体系以及地址偏移，类型转换的操作大致如下: 1. 获取对象的虚表，2. 从虚表-1的位置取出定位符COL，3. 遍历定位符里的继承表，寻找类型描述`pTypeDescriptor`和目标一致的类型。4. 移动指针并返回或者抛出异常。
    * 对于虚继承结构：基类都是平铺开来的。如果基类没有虚函数，派生类没有COL，不能进行交叉转型
    * 虚继承小结：1. 类似于数据层面的多态，根据运行时取到对应的位置，2. 访问虚基类的成员需要重定向子类，有一定开销，3. 没有rtti信息，只做了数据兼容

#### Exception（异常）
1. 函数后有两个描述符:
    * `throw`已经废弃，它需要指定要处理的异常类型，如果抛出了为指定的异常，会导致程序终止
    * `noexcept(true/false)`它可以选择声明是否抛出异常，如果什么不抛的却抛了，也会`terminate`。
2. 工作流程：`Throw exception` -> `Match handler` -> `Catch exception`
3. 异常不会进行隐式类型转换，如果抛出一个浮点数，`catch`一个`double`是不行的
4. 异常抛出及捕获的大致流程：1. 当发生异常时，会将本地的异常对象赋值给全局的异常处理器`g_excep_mgr`，2. 清理本地调用栈的信息，3. 执行流程跳转到异常处理的位置，4. 匹配异常的类型，5. 取出异常对象交付处理，6.清理异常信息
5. 异常捕获时，如果什么为引用，只有一次的构造和析构，如果声明为值传递，会构造和析构多次
6. 创建对象时抛出异常，并不会造成内存泄漏，因为c++会优雅的进行处理`Resource Acquisition Is Initialization(RAII)`**资源获取即初始化**
    ```c++
    template<typename T> T* new_ins(...)
    {
        T * ptr = T::opertor new(sizeof T);     
        try {
            ptr->T::T(...);                     // 如果调用构造函数抛出异常了
        } catch (...) {
            T::operator delete(ptr, sizeof(T));   // 会在catch里释放掉申请的内存 
            throw;     
        }
        return ptr;
    }
    ```
7. 析构函数（可能在stack unwinding时调用），释放资源，交换数据等应当保证不抛出异常；可能会导致资源未被释放；[参考](https://isocpp.org/wiki/faq/exceptions#dtors-shouldnt-throw)
8. Strong guarantee（强保证），在抛异常前会完全回滚。
9. 异常的不足：1. 会造成两倍的开销（不要在热点代码用，用inline） 2. 会导致程序终止，3. 会导致内存泄漏（应当使用RAII的方式处理）4. 需要一堆异常类型
10. 作者推荐使用异常


### 3. c++ 11/14/17

#### Type Deduction (类型推导)
1. `auto`可用来声明类型，编译器会自动推导，它不会保留引用，cv修饰符等信息，除非使用`auto&`声明
    ```c++
    int x = 1;
    const int& rx = x;
    auto y = rx;        // int; auto会忽略cv描述符及引用
    auto& ry = rx;      // const int&; 使用auto&会保持原变量的cv描述符

    int a[3] = {1, 2, 3};
    auto c = a;         // int *; 这样子会是一个指针
    auto& b = a;        // int[3]; 添加引用会编程数组类型
    ```

    也可以用来修饰返回类型。
    ```c++
    template<class T, class U>
    auto add(T t, U u) { return t + u; }
    ```
    
    也可以来提取对象的`typeid`: `auto p = new auto('c')`，此时`p`的类型为`char*`

2. `decltype`，类似于python中的`type`函数，它可以根据实例对象反推出类型，并将它拿来使用
    ```c++
    template<class MapType>
    auto RevertMap(MapType someMap)
    {
        // 可以将任意MapType的key和value类型反转，创建一个对象
        return std::map<
            typename decltype(someMap)::mapped_type, 
            typename decltype(someMap)::key_type
        >();
    }
    ```
    使用`decltype((x))`可以返回x的引用类型
    ```c++
    #include <type_traits>
    int x = 1;
    auto v1 = std::is_same<decltype((x)), int&>::value;
    auto v2 = std::is_same<decltype(++x), int&>::value;     // ++x操作一般返回自身引用
    auto v3 = std::is_same<decltype(x++), int>::value;
    cout << v1 << " " << v2 << " " << v3 << endl;   // 1 1 1
    ```
    使用`decltype(auto)`可以在作为函数声明时，保留原来的引用等声明
    ```c++
    decltype(auto) f() { return g(); }  // 返回的类型是`decltype(g())`

    int x = 1;
    int& rx = x;
    decltype(auto) dx = rx;     // 这样子dx依旧是一个int&类型
    ```

#### Move Semantic
1. `&&`使用它表示，用来处理减少对象的拷贝问题，充分利用临时对象的分配的资源等。
2. Move Constructor，不能是模板构造函数，第一个参数应为`T&&`，可以包含cv描述符，其他参数必须有默认值
3. 值的类型
    * Lvalue：左值；变量，数据成员，函数返回的引用等
    * Rvalue：右值；不能赋值对象的引用或指针给普通的左值（常指针之类的可以）；包含以下两种
        * Prvalue：纯右值；常数，临时对象，函数返回的非引用对象
        * Xvalue：直接返回右值的一些方法；`static_cast<char&&>(x)`
    ```c++
    T a(static_cast<T&&>(b));   // 调用T的move构造函数
    f(static_cast<T&&>(a));     // 调用move版的f函数
    ```
4. Forwarding Reference
    当接收右值作为参数的时候，如果将参数传递给其他函数，那么其他函数无法还原参数的右值性质
    ```c++
    void warpper(U&& t)
    {
        g(t);   // 会调用到g(U& t)的版本
        // 使用以下方式可以调用到右值版本
        g(std::forward<U>(t));
        g(std::move(t));
    }
    ```
    同时，为了不需要每次写函数都定义`U&&`和`U&`版本，可以使用`Forwarding Reference`技巧，也就是用模板实现
    ```c++
    #define IS_SAME(T1, T2) std::is_same<T1, T2>::value

    struct U
    {
        int i = 0;
        operator char()
        {
            return char(i + '0');
        }
    };

    template<class T>
    void f(T&& x)   // 可以同时接收左值和右值的参数
    {
        // 此处的x就是forwarding reference，当传入的是左值，x的类型是T&，如果传入的是右值，x的类型是T&&
        cout << "f: " << x << endl;
        // 此处的x已经变成了左值了，如果需要传递给其他函数，应当使用std::forward<T>(x)的方式；
        g(std::forward<T>(x));  // 可以同时传递左值和右值的类型
        cout << IS_SAME(T, U&&) << " " << IS_SAME(T, U&) << " " << IS_SAME(T, U) << endl;
    }


    U u;
    // 以下两种方式都可以被正确调用
    f(u);   // 0 1 0
    f(U()); // 0 0 1
    // 如何理解：Reference collapsing
    // 当传入左值时，T的类型为U&，声明的类型 U& && 被折叠成 U&
    // 当传入右值时，T的类型为U，声明的类型为 U&& 
    ```

#### Uniform Initialization
1. 初始化的方式：
    * Value initialization, e.g. std::string s(); 
    * Direct initialization, e.g. std::string s("hello");
    * Copy initialization, e.g. std::string s = "hello";
    * List initialization, e.g. std::string s{'a', 'b', 'c'};
    * Aggregate initialization, e.g. char a[3] = {'a', 'b'};
    * Reference initialization, e.g. char& c = a[0];
    * Default initialization, e.g. std::string s;
2. 现在，各种支持用大括号{}，但是它本身是无类型的，会被转成`std::initializer_list`的类型

#### constexpr
1. 视频里扯了一大堆，其实就是，当参数为数字时，编译器会直接将结果推导出来，无需运行时进行计算
    ```c++
    constexpr int func(int x, int y)
    {
        return x + y;
    }

    func(1, 2);         // 在编译时就算好了
    func(x, y);         // x,y是变量，在运行时才计算
    ```
2. 要使用这个特性，限制时返回类型，参数类型都必须是`LiteralType`，它的要求如下：
    1. 字面常量，如`12`,`c`, `void`, 数字，引用，数组
    2. 类，有trivial的析构函数，有至少一个`constexpr`构造函数（不能是copy和move），所有非静态成员变量和基类是`non-volatile`的确切类型(LiteralType)
        ```c++
        // 以下是满足LiteralType的一个类
        struct conststr 
        {     
            const char* p;     
            std::size_t sz;      
            template<std::size_t N>     
            constexpr conststr(const char(&a)[N]) : p(a), sz(N - 1) {}   
        }; 
        // 
        conststr cstr{"Hello World"};   // 可以在编译时构造出来
        ```
3. `if constexpr`的特性，可以在编译期间，就完成分支的选择，实际执行时，直接执行选择后的分支(c++17)
    ```c++
    template<typename T>
    std::string str(T t)
    {
        if constexpr(std::is_same<T, std::string>::value == true)
        {
            return t;
        }
        else        // 没写else，在str(string("1000"))无法通过编译
        {
            return std::to_string(t);
        }
    }

    int main()
    {
        auto t = str(100);  // 会直接执行下一条分支
        cout << t << endl;
        auto e = str(std::string("1000"));      // 会直接执行上一条分支
        cout << e << endl;
        return 0;
    }
    ```

#### lambda表达式
1. 形式
    [](float a, float b) mutable -> return_type { return a < b;}
    [capture_list](parameters) specifier ->  return_type {function body}
2. parameters，可以声明为`auto`，没有参数可以不写小括号
3. return_type，不写默认为`auto`
4. capture_list捕获列表，`[&]`使用引用传数据，`[=]`使用值传递，`[=, &x, y=r+1, this, *this,...]`自由定制
    `[this]`是按引用传递，`[*this]`是按值传递
5. specifier修饰符，`mutable`使用的情况下，就可以修改外部的局部变量，如果是`=`传入，不会影响外部的变量的值
6. 实现时，使用了一个`Closure`的类，实现了`operation()`运算，提供了类似仿函数的效果（视频里讲的太简单，有空应该去看看源码）
7. `std::function`可以用来声明`lambda`表达式对象，它用来声明任何可执行的对象，函数之类的类型。
    `std::function<int(int, int)> func = [](int x, int y) {return x + y;};`，之后就可以使用`func(11, 22);`来进行运算
8. 视频里说的大致实现`std::function`:
    ```c++
    template<typename RetType, typename ArgType> 
    struct Function<RetType(ArgType)>
    {     
        struct CallableBase 
        {         
            virtual RetType operator()(ArgType arg) = 0;         
            virtual ~CallableBase() {}     
        };      
        template<typename T>       
        struct CallableDerive : public CallableBase 
        {             
            T callable;             
            CallableDerive(T c) : callable(c) {}             
            RetType operator()(ArgType arg) override 
            {                 
                return callable(arg);             
            }         
        };    

        CallableBase * base = nullptr;

        template<typename T>
        Function(T callable): base(new CallableDerive<T>(callable)) {}
        ~Function() { delete base; }
        RetType operation()(ArgType arg)
        {
            // 取出具体的可调用对象，执行调用操作
            retrun (*base)(arg);
        }
    };          
    ```

#### Structured Binding（结构化绑定）
1. 形式如下，其中`expr`可以是数组或者是不带union的类对象，类似于python中的拆包
    * cv-auto(& or &&) [id1, id2, ...] = expr; 
    * cv-auto(& or &&) [id1, id2, ...]{expr}; 
    * cv-auto(& or &&) [id1, id2, ...](expr);
2. 它可以对数组或类对象进行绑定，但是绑定的变量的cv属性，其实只遵从原始变量的cv属性，也就是`cv-auto`之前的cv描述符好像没什么
    ```c++
    struct point
    {
        int x;
        int& y;
    };

    int main()
    {
        int i = 22;
        point p = {1, i};
        cout << p.x << " " << p.y << endl;
        const auto& [x, y] = p;           // x, y绑定了p.x和p.y的引用
        y = 222;        // 虽然上面声明了const，但是该变量是可以修改的，也就是 const 没用
        cout << x << " " << y << " "  << i << endl;
        cout << p.x << " " << p.y << endl;
        return 0;
    }
    ```

#### range based for
1. 形式
    ```c++
    for(const auto& [first, second] : someMap) // 配合结构化绑定，可以轻松拆字典
    {     
        std::cout << first << " " << second;    // 此时的first和second是直接是元素的引用，不是迭代器
    }
    ```
2. 自定义类中提供`begin()`和`end()`接口，就可以使用上述语法，自由控制对象是否可遍历。

#### UnScoped Enum
1. 老的枚举有缺陷：1. 名字容易冲突，2. 会隐式转换
2. 添加关键字`class`就可以将枚举值限制在特定命名空间
    ```c++
    enum class Color { red, green, blue };  
    Color r = Color::red; 
    switch(r) 
    {     
        case Color::red  : std::cout << "red\n";   break;     
        case Color::green: std::cout << "green\n"; break;     
        case Color::blue : std::cout << "blue\n";  break; 
    }  
    int n = r;                   // error, no implicit conversion 
    int n = static_cast<int>(r); // ok, explicit conversion
    ```

#### Initializer if
1. 可以在`if`的条件中同时做初始化
    ```c++
    std::set<std::string> set; 
    if (auto [iter, isSucc] = set.insert("hello"); isSucc) 
    {     
        /* ... */ 
    } 
    // iter, isSucc out of scope 
    ```
2. 可以配合RAII使用，使得if语句执行完，自动释放资源

#### nullptr
1. 用于区别NULL（它无法和数字0区分开来，会丧失语义）
2. `nullptr`它可以传递给任意的指针，它的类型是`std::nullptr_t`
    ```c++
    void f(std::nullptr_t) { }
    f(nullptr);
    ```

