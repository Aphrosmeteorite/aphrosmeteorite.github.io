---
title: "C++制作一个编译期整数序列生成器"
description: "just use C++ to build a compiler time index maker"
author: "Laplace"
tags:
  - C++
categories:
  - C++
  - C++ template meta programming
date: 2024-06-22
lastmod: 2024-06-22
---

在使用`std::get<>()`时产生的好奇，发现标准库有一个`std::index_sequence`，尝试使用`C++`自行实现一个`std::index_sequence`整数序列生成器，只需要编译期传入序列终点👍。

<!--more-->

## 功能是什么？
首先需要让我们看看功能是什么，具体可以怎么做。例如我们有一个元组，我们需要一个函数在编译期帮助我们直接遍历这个元组，并将元组内容打印出来。目的是将`t`传入，然后把`t`的内容全部打印出来。
```cpp
auto t = std::make_tuple(1, 2, 3, "Hello!", 4.5);
lap::print(t);
//1,2, 3, Hello!, 4.5
```

## 如何产生序列？
如果需要通过只传入一个序列终点就产生从0开始的序列，仅仅凭借一个值是不可能产生的，我们也许会说变参模版，这也是接下来的解决方案。我通过继承模版递归，进行序列的生成。

### 继承模版递归
要产生序列，我们需要通过一个终点不断往更小的值递归，然后把更小的值放进这个序列的变参模版中。我制作了下面这个`_make_integer_sequence`类模版。
```cpp
template <typename T, size_t... _Vals>
struct integer_sequence
{
    using type = T;
    static constexpr std::size_t value_size = sizeof...(_Vals);
};

template <typename T, size_t N, T... _Vals>
struct _make_integer_sequence
    : _make_integer_sequence<T, N - 1, N - 1, _Vals...>
{
    /**
     * @brief: 递归生成序列
     * 每次递归都会生成一个新的继承类,直到N为0
     **/
};

template <typename T, T... _Vals>
struct _make_integer_sequence<T, 0, _Vals...>
    : integer_sequence<T, _Vals...>
{
};
```
我们先聚焦于`_make_integer_sequence`这个类本身，第 8-15 行是这个类的定义，它的第一个模版参数是一个类型，第二个则是一个`size_t`类型的非类型模版参数，第三个则是`T... _Vals`代表为`T`类型的变参模版。

然后这个类好像自己继承自己，不断往下递归，然而这就是生成序列的关键😋。我们需要了解到继承了什么。继承的是`_make_integer_sequence<T, N-1, N-1, _Vals>`这样一个模版参数多了一个的类型，其实之前的，这里关注第三个模版参数和第四个`_Vals`，其实不难发现，就是每次把`N-1`放入到原来的`T... _Vals`中，然后再将`size_t N`变为`N-1`，这样就会不断地往下递归，直到我们的终止条件，这也是第 18-22 行的特例化。

在这个特例化版本中，`size_t N`直接为0，而同时继承自`integer_sequence<T, _Vals...>`。对于类`integer_sequence`，其实就是一个模版类，第一个模版参数是`T`类型，第二个则是变参模版，在该类内，提供了类型`T`的别名，以及当前的变参模版参数的个数。此时这个类作为整个递归的出口(结束)。

也就是说，当我们结束递归时，我们产生了一个`integer_sequence<T,0,1,2...,N>`的`integer_sequence`类，所以我们需要的只是为`integer_sequence`取一个特例化的别名。
```cpp
template <std::size_t... IndxVals>
using index_sequence = integer_sequence<std::size_t, IndxVals...>;
```
上述代码即将类型变为`size_t`，且保证了变参模版的整数序列传递。

## 根据当前参数个数生成序列的接口
由于我们传递到`tuple`内的通常是变参模版，而且个数不定。为了直接打印整个`tuple`，必须在编译期获取到`tuple`中模版参数的个数。此时我们也需要一个只是传递类型就能获取到序列应该如何生成的接口。
```cpp
template <typename... _Vals>
using index_sequence_for =
    _make_integer_sequence<std::size_t, sizeof...(_Vals)>;
```
这个接口将`sizeof...(_Vals)`传入到`_make_integer_sequence`中，这里不能使用`integer_sequence`，因为`integer_sequence`只支持第二个模版参数传入非类型变参模版，而不是类型的变参模版。通过这个接口，我们也就生成了一个可以根据类型个数产生序列的别名。

## 完成`print`
注意我们的打印是`1, 2, 3, Hello!, 4.5`而不是普通的插入空格。为了方便条件判断，我使用`std::cout`进行变参模版的解包。
```cpp
template <typename Tuple, size_t... Indx>
constexpr void printImpl(const Tuple &t, index_sequence<Indx...>)
{
    (..., (std::cout << (Indx == 0 ? "" : ", ") << std::get<Indx>(t)));
}

template <typename... Args>
constexpr void print(const std::tuple<Args...> &t)
{
    printImpl(t, index_sequence_for<Args...>{});
}
```
在`print`的实现中，我们只传入类型的变参模版，调用`index_sequence_for`为类型生成一个整数类型的`_make_integer_sequence`，然后将其传入具体的实现`printImpl`中，在这个函数内进行模版参数解包。