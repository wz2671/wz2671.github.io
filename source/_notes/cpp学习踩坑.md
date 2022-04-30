
* 在使用VS2019编译时，使用到了`string`，一直无法编译过，报错如下所示：
    ```
    unresolved external symbol __imp___invalid_parameter referenced in function "void * __cdecl std::_Allocate<8,struct std::_Default_allocate_traits,0>
    ```
    解决办法，参考[链接](https://stackoverflow.com/questions/42801276/error-lnk-2019-unresolved-external-symbol-imp-crtdbgreportw-in-visual-studio)

* 像`or`, `and`, `not`之类的也是c++的关键词，它们定义在了`iso646.h`里，在网上文档里也说明了它们确实是[关键词](https://en.cppreference.com/w/cpp/keyword)
    ```c++
    #define and &&
    #define and_eq &=
    #define bitand &
    #define bitor |
    #define compl ~
    #define not !
    #define not_eq !=
    #define or ||
    #define or_eq |=
    #define xor ^
    #define xor_eq ^=
    ```

* `BOOST_UNLIKELY`和`BOOST_LIKELY`这两个宏是为了告诉编译器某个分支执行的概率比较大，方便编译器优化。本质上判断语句一致

* 看到一种能够将成员函数作为参数传入的方法，使得对象动态调用对应的接口函数，以下是可以正常work的。
    ```c++
    struct Cls
    {
    public:
        void func() {std::cout<< "Cls::func" << std::endl;}
    };

    void test_ptr()
    {
        auto t = Cls();
        auto ptr = &t;
        (ptr ->* (&Cls::func))();
        (t.*(&Cls::func))();
    }
    ```


### 智能指针
* `unique_ptr`：不允许赋值，但可以用`std::move`函数转移控制权（右值），转移完的指针不能再使用，否则crash
* `shared_ptr`：可以赋值添加引用计数，在离开作用域后就会自动销毁。
    * 不能用同一个指针初始化多个智能指针
    * 不能用智能指针的指针来搞操作
    * 可能产生循环引用问题
* `weak_ptr`：使用`shared_ptr`对象给其赋值时，不增加`shared_ptr`的引用计数
    * 它不直接包含对象，同时也不直接访问到对象成员
    * 需要使用`lock`函数获取原始的`shared_ptr`，若已被析构，返回的是空的；可使用`use_count`和`expired`判断

