---
title: "C++中模版的基本使用技巧"
description: "Fundamental template tricks in C++ and you will learn how to judge whether a type is iterable or not"
author: "Laplace"
tags:
  - C++
categories:
  - C++
  - C++ template meta programming
date: 2024-06-26
lastmod: 2024-06-26
---

这章是`C++ Templates`第五章的读书笔记，希望通过这章能帮助你学会模版的基本使用技巧👍。我们将搭建一个方法来判断某类型是否可迭代(是否存在迭代器)。

<!--more-->

## 别名
在`C++ 17`以后，我们可以对变量模版进行别名，当然，我们也会包括类型模版的别名一同介绍。

### 非类型模版别名
首先我定义一个这样的结构体，这个结构体里面只有一些值和类型。相信不难理解。
```cpp
template <typename T = size_t>
struct MyContainer
{
    static constexpr T value = 42;
    using value_type = T;
};
```
对于`MyContainer`这个类来说，如果我们需要使用内部的`value`或`value_type`，那我们就必须要通过`MyContainer::value`或者`typename MyContainer::value_type`获取，之所以后者加上`typename`进行修饰，是为了避免歧义，毕竟编译器并不能完美地分辨出`value_type`是不是一个类型，当然，现在的编译器可能在部分场合也可以达成了，但是还是推荐加上`typename`。为了方便获取到`value`而不用每次都用`::value`，我们为`MyContainer::value`起个别名。
```cpp
template <typename T>
auto myContainer_v = MyContainer<T>::value;
```
这里的模版参数依然是类型参数，使用时，我们可以通过`myContainer_v<int>`获取到值。**需要注意，当value在别名声明之后改变，那么myContainer_v仍然保持原来的值，不会随value动态变化**。下面的例子可能更符合使用场景。
```cpp
template <auto N = int{}>
constexpr decltype(N) dval = N;
```
如果把模版也当成函数(有输入有输出)，那么你不难理解这个`dval`的功能就是得到模版参数的值并返回出来，比如`dval<10>`就返回出来了一个整数10。在标准库中的类型萃取，`std::is_const_v`就是这样定义的。
```cpp
namespace std{
	template <typename T>
	constexpr bool is_const_v = is_const<T>::value;
}
```

### 类型模版别名
相信有了上面的例子，我们应该也完全会了类型模版的别名，无非是使用`using`来定义罢了。当然，下面不用`typename`也是可以的，因为已经使用了`using`。
```cpp
template <typename T>
using myContainer_vt = typename MyContainter<T>::value_type;
```

## 显式指明调用模版函数
如果在类当中定义了一些模版函数并且需要通过显式指定模版参数类型进行调用时，就需要额外加上`template`关键字确保`<`被解析为模版，而不是比较运算符。
```cpp
template <unsigned long N>
void printBitset(const std::bitset<N>& bs)
{
    /**
    @note: 显式地调用成员模版,避免解析为比较运算符
     */
    std::cout << bs.template to_string<char, std::char_traits<char>,
                                       std::allocator<char>>();
}
```

## 泛型lambda
在`C++14`之后，`lambda`表达式也支持泛型操作。这里我们使用实现一个变参模版的`lambda`版本的打印。
```cpp
auto lambdaTemplatePrint = [](auto... args) -> void {
    std::cout << "lambdaTemplatePrint: ";
    ((std::cout << args << " "), ...);
    std::cout << '\n';
};

template <typename... Args>
auto lambdaTemplatePrint = [](Args... args) -> void {
    std::cout << "lambdaTemplatePrint: ";
    ((std::cout << args << " "), ...);
    std::cout << '\n';
};
```
可以看出，这里的泛型直接使用`auto`作为占位，然而我们其实也能直接使用`template`。

## 制作一个判断迭代器是否存在的方法
这个方法借鉴了[c++ 检查变量类型是否可迭代？]([c++ - 检查变量类型是否可迭代？_Stack Overflow中文网](https://stackoverflow.org.cn/questions/13830158)) ，十分巧妙。
```cpp
template <typename T>

struct is_iterable
{
    using type = decltype((
        begin(std::declval<T&>()) !=
            end(std::declval<T&>()), // begin/end and operator !=
        void(),                      // Handle evil operator ,
        ++std::declval<decltype(begin(std::declval<T&>()))&>(), // operator++
        void(*begin(std::declval<T&>())),                       // operator*
        std::true_type{}));
};
```
这里用到了一个括号表达式，从左往右解析尝试判断`T`类型是否存在这些函数，当所有解析都成功的时候，就能返回括号最右边的值，也就是`true_type`。

这段代码是一个模板结构体，用于检测一个类型 `T` 是否是可迭代的。在 `type`的 `decltype` 中使用 `void()` 的原因是为了处理逗号运算符（`,`）的潜在重载问题。

在 C++ 中，逗号运算符（`,`）可以被重载，这意味着在用户定义的类型中，逗号运算符的行为可能与预期不同。在这个上下文中，`void()` 被用作一个无害的表达式，其唯一目的是确保逗号运算符的标准行为——即，计算其左侧的表达式，然后丢弃结果，接着计算右侧的表达式，并返回右侧表达式的结果。

具体来说，在 `decltype` 中：

1. `begin(std::declval<T&>()) != end(std::declval<T&>())`检查 `T`类型是否支持 `begin`和 `end` 函数，并且它们的返回值是否可以进行不等比较。
2. `void()` 是一个无操作表达式，用来确保即使类型 `T`重载了逗号运算符，后续的表达式也能按预期执行。
3. `++std::declval<decltype(begin(std::declval<T&>()))&>()` 检查迭代器是否可以被递增。
4. `void(*begin(std::declval<T&>()))` 检查通过迭代器解引用是否有效。

通过这种方式，`void()` 作为一个分隔符，确保了即使在逗号运算符被重载的情况下，每个表达式都能独立评估，从而正确地检测类型 `T`是否是可迭代的。

当然，我认为这样还不够好用，起个别名就完美了。
```cpp
template <typename _Container>
using is_iterable_t = typename is_iterable<_Container>::type;
```

现在我们可以尝试为各种可迭代的类型写一个打印函数，将其内容打印。我们用到`requires`进行类型限制，只有当`is_iterable_t`与`std::true_type`一致时，才能调用这个函数。当然，对于类似`std::map`的结构并不能直接调用，因为`std::print`这里并没有对`std::pair`的直接打印方法。
```cpp
template <typename Container>
    requires(std::is_same_v<is_iterable_t<Container>, std::true_type>)
void printcoll(const Container& coll)
{
    typename Container::const_iterator pos;
    typename Container::const_iterator end(coll.end());
    for (pos = coll.begin(); pos != end; ++pos)
    {
        std::print("{} ", *pos);
    }
}
```