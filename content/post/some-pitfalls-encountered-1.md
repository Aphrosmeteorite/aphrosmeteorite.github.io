---
title:  "最近遇到的一些坑(C++)"
description: "some pitfalls encountered recently in C++ programming"
author:  "Laplace"

date: 2024-02-28
lastmod: 2024-02-28

tags: 
  - C++
categories:
- C++
---

最近写一个多项式类希望尽可能使用`Modern C++`，但是在使用过程中遇到了一些坑，记录如下：

<!--more-->

## constexpr的坑

最近用`constexpr`希望多项式类可以在编译期直接求值计算，但是在使用过程中发现了一些问题

### std::vector的使用

因为`std::vector`是动态分配内存的，而`constexpr`要求在编译期就能确定大小，所以`std::vector`是不被允许使用。可以尝试运行以下例子(为方便直接用结构体`struct`了)

```cpp
#include <vector>

struct Base{
    std::vector<int> _vec;
    constexpr Base(int n):_vec(n){}
    constexpr Base(const std::initializer_list<int>& il):_vec(il){}
};
```

上述代码会直接报错，原因也很清楚，constexpr 构造函数调用非 constexpr 构造函数来初始化子对象。所以如果要实现一个可以动态扩容的多项式类，大概率是无法使用`constexpr`的。为保证需要在编译期可知，使用`std::array`可能更好。因此我继续写了一个可以保证编译期求值的类`polynimaicl_C`

### 多文件

本来是打算把多项式类的声明写在`polynimial.h`中，定义写在`polynomial.cpp`中，然后把`polynomial.cpp`编译成静态库
与`main.cpp`链接，在`main.cpp`调用多项式类的成员函数。但是在使用过程中发现了一些问题，`CMake`编写如下

```cmake
add_library(polynomial-lib STATIC polynomial.cpp)
add_executable(main main.cpp)
target_link_libraries(main polynomial-lib)
```

当时`CMake`一直无法成功编译，一时以为是`CMake`编写有误，但是`main.cpp`中的报错信息却在`constexpr polynimial_C poly1`行上说`constexpr`对象必须为只读或者引用类型，并且在头文件中被用过的函数报出警告，表示该函数已被使用却从未定义，同时在`build`文件夹下也能找到编译好的静态库。所以`CMake`应该没问题，或者是问题出在了 **LNK** 阶段。但是从`main.cpp`看来应该不是。

其实当时想的太过于简单了，一个对象的成员是`constexpr`类型的话，那么编译器在`main.cpp`中应该就能找到该函数的定义，否则只能靠链接阶段，但显然，此时已经离开编译期了。所以我们的`constexpr`函数的定义也要同时写在头文件中，以使得`main.cpp`能找到该函数的定义。我也尝试过在编译时让`polynimial.cpp`和`main.cpp`一起直接编译成一个可执行文件，但是依然无法解决`constexpr`的报错问题，也可能是才疏学浅，没法想到更多原因。`CMake`如下：

```cmake
add_executable(main main.cpp polynomial.cpp)
```

## 内置print函数的坑

这个是我希望能让每个多项式类直接打印出多项式，但是却在`polynimial_C`这个类出现了问题，这个类可以支持编译期求值，内部使用了`stsd::array`，为保证编译期可知项数，使用了模板`template<std::size_t SIZE>`。虽然按照想法来说，`print`函数一定是一个运行时的函数，因为他调用的是`std::cout`，所以没有被声明为`constexpr`类型，同时还把实现写在了`polynimial.cpp`中，但是这个类算一个模板类，所以实现应该写入到头文件中，也就是`print`函数也应该写在头文件。
