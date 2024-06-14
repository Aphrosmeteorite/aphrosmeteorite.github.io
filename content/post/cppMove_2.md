---
author:  "Laplace" 
title:  "C++移动语义(补充)"
date: 2023-12-31
description: "cpp Move Semantics"
tags:
  - C++
categories:
- C++
- Effective Modern C++
---

对之前移动语义的部分补充，主要是关于`std::move`的实现

<!--more-->

# `std::move`本质

`std::move`本质上是把一个量(或一个值)强制转换成一个右值引用，然后再将该右值引用返回。但是在`C++`中存在**引用折叠**现象，具体是什么我们看下列例子。

## 引用折叠

```cpp
template <typename T>
T&& move(T &&param)
{
    return static_cast<T &&>(param);
}

int main()
{
    std::vector<int> v1{1, 2, 3};
    auto v2 = move(v1);
    std::cout << v1.size() << '\n';
}
```

在该`move`函数中，我们通过一个右值引用接受一个参数，再强制转换成`T&&`类型并返回，好像符合我们的想法，但实际上，`move`函数被推导为以下类型

```cpp
std::vector<int> &move<std::vector<int> &>(std::vector<int> &param)
```

我们发现，返回值是一个引用，同时参数也是一个引用，即`T`被推导为`std::vector<int> &`类型，这不符合我们的预期。实际上这里就发生了**引用折叠**。

我们传入的`v1`本身是一个左值，所以传入时应该为左值引用，由于三个`&`出现折叠，最终`T&&`整体为单个`&`类型，即左值引用。所以我们需要的应该是保留传入参数的基本类型(或者说没有任何引用的类型)，防止出现引用折叠，并保证`T`只可能推导成为该基本类型。这里，在`C++14`以上的版本提供了`std::remove_reference_t< >`来实现。

```cpp
template <typename T>
decltype(auto) move2(T &&param)
{
    using ReturnType = typename std::remove_reference_t<T> &&;
    // 如果T是 int && ，则返回 int ,得到 ReturnType = int &&
	return static_cast<ReturnType>(param);
}
```

`typename`强调`std::remove_reference_t<T>`是一个类型，比如说`int`，`std::string`等，通过`using`定义新类型`ReturnType`为去掉所以引用后的`T`再加上`&&`组成的右值引用类型。假设`T`是`int &&`，那么`std::remove_reference_t<T>`就会得到`int`，再结合`&&`得到`int &&`，此时无论`param`是什么类型，都能被强制转换成一个右值引用。此处返回值类型使用`decltype(auto)`，由于直接使用`auto`本质上和直接使用`T`做返回值一样，此时使用`decltype`进一步修饰可以保证保留原来的类型，之所以返回值不写`ReturnType`是因为它在函数内被声明定义，函数定义时还没有该类型，我们也可以像以下这样，可能看起来更明白做了什么。

```cpp
template <typename T>
typename std::remove_reference_t<T> && move2(T &&param)
{
    using ReturnType = typename std::remove_reference_t<T> &&;
    // 如果T是 int && ，则返回 int ,得到 ReturnType = int &&
	return static_cast<ReturnType>(param);
}
```

