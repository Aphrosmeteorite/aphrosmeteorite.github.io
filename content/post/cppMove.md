---
author: "Laplace" 
title: "C++移动语义"
date: 2023-10-28
description: "cpp Move Semantics"
tags:
  - C++
categories:
- C++
---

最近看了一点移动语义，写一点学习内容吧

<!--more-->

## 简介

C++中的移动语义是一种重要的语言特性，它允许高效地管理对象的资源，尤其是动态分配的内存，以提高性能和减少不必要的复制操作。移动语义通过引入右值引用（Rvalue references）和移动构造函数（Move constructors）来实现。

下面是一些关键概念和技术，有助于理解C++中的移动语义：

1. **左值和右值**：
   - 左值（Lvalue）是可标识和具有地址的表达式，通常是变量或对象的名称。它们可以被赋值，但不能被移动。
   - 右值（Rvalue）是临时的、不可标识的表达式，通常是临时对象或字面常量。它们通常是可以被移动的。
2. **右值引用**：
   - 右值引用是一种新的引用类型，使用`&&`符号表示。它绑定到右值，允许对其进行移动操作。
   - 例如，`T&&`表示类型`T`的右值引用。
3. **移动构造函数**：
   - 移动构造函数是特殊的构造函数，它接受一个右值引用作为参数，用于从另一个对象"窃取"资源，而不是进行深度拷贝。
   - 移动构造函数通常被用于容器类，如`std::vector`和`std::string`，以提高性能。
4. **std::move函数**：
   - `std::move`是一个库函数，用于将左值转换为右值引用。这对于标记要移动的对象非常有用。
   - 例如，`std::move(obj)`将对象`obj`转换为右值引用，从而可以在移动构造函数中使用它。
5. **移动赋值运算符**：
   - 类似于移动构造函数，移动赋值运算符用于在对象之间执行资源的移动，通常在赋值操作中使用。
6. **std::move语义的优点**：
   - 移动语义可以显著提高性能，减少内存分配和复制操作。
   - 它适用于动态分配内存的对象，如动态数组或字符串，以减少不必要的内存复制。
   - 在容器的操作中，移动语义可以减少数据的移动成本。

```cpp
#include <iostream>
#include <vector>

int main() {
    std::vector<int> source = {1, 2, 3};
    std::vector<int> destination = std::move(source);

    // 此时source已被移动，不再有效
    std::cout << "Source size: " << source.size() << std::endl;  // 输出0
    std::cout << "Destination size: " << destination.size() << std::endl;  // 输出3

    return 0;
}
```

上述表明了移动语义的作用，它把`source`的内容`移动 `到`destination`中，而原来的`source`则变空，但上例依然不能很好地看出内部发生了什么。

## 一个`MyString`的例子

下面是通过一个`MyString`类来了解移动语义的示例代码，可以看出移动语义在满足`C++`要求使用到右值引用的情况下，其构造函数本质上是把一个对象的可能封装的指针数据直接给到另一个对象，然后再使指针为空。从这个例子容易看出移动语义能够帮助减少大量复制循环带来的性能损失，但也并不是所有情况都很完美，毕竟原来的右值对象会变空，所以有时候仍然不得不使用到拷贝到方法。

```cpp
class MyString {
public:
    MyString() : data(nullptr) {}
    // 移动构造函数
    MyString(MyString&& other) {
        data = other.data;
        other.data = nullptr;  // 防止资源被重复释放
    }
    // 移动赋值运算符
    MyString& operator=(MyString&& other) {
        if (this != &other) {
            delete[] data;  // 释放当前资源
            data = other.data;
            other.data = nullptr;
        }
        return *this;
    }
    // 析构函数
    ~MyString() {
        delete[] data;
    }
private:
    char* data;
};

int main() {
    MyString str1("Hello, World!");
    MyString str2 = std::move(str1);  // 使用移动构造函数
    str1 = MyString("New String");   // 使用移动赋值运算符
    return 0;
}
```

