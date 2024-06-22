---
title: "C++变参模版"
description: "A brief note about C++ variadic template"
author: "Laplace"
tags:
  - C++
categories:
  - C++
  - C++ template meta programming
date: 2024-06-16
---
这章属于是重点了，而且感觉还挺难掌握各种用法的，不过也是让我感觉魔法的开始✨。

<!--more-->

## 什么是变参模版
变参模版表示的是传入参数可以有无数多个，同时传入参数的类型也可以完全不同。
### `C` 中的可变参数函数
在 `C` 语言中，可以用下面这种方式进行一堆`int`类型打印。第一个参数是需要传入的参数的个数，第二个则是实际参数。
```c
#include <stdio.h>
#include <stdarg.h>

void prints(int argsNumber, ...)
{
    va_list valist;
    va_start(valist, argsNumber);
    for (int i = 0; i < argsNumber; i++)
    {
        printf("%d ", va_arg(valist, int));
    }
    va_end(valist);
}
```
### `C++`中的变参模版
`C++`中变参模版在`C`的基础上变得更加好用，我们不需要传入参数个数，也可以使用模版使得传入的每个参数的类型都不一样。例如我们可以实现这样一个打印不定个参数的函数。请注意这里不要使用`using std::print`或者`using namespace std`，如果需要使用的话，请将下面的代码放在一个命名空间内，防止造成命名空间污染。
```cpp
using std::println;
template <typename T>
void print(T arg)
{
    println("{}", arg);
}

template <typename T, typename... Args>
void print(T firstArg, Args... args)
{
    println("{}", firstArg);
    print(args...); // 每次把第二个参数及以后传入,直到最后一个参数
}
```
在上面的函数中，我们没见过的就是`typename... Args`，这里就是变参模版的写法，代表一堆类型不定的参数。在函数的参数列表里，`Args... `我们应该视作一种类型，而`args`则是所有参数。这里，我们把`args`称作参数包。上面的打印方法通过递归的方式，每次把第一个参数以后的参数传入递归，一直到最后只剩一个参数时，调用第一个`print(T arg)`函数，递归结束，完成打印。

## 获取变参模版中参数个数
为了直接获取变参模版中参数的个数，`C++`提供了运算符`sizeof...`，类似`sizeof`的用法，只不过这个会返回参数包中的参数个数。
```cpp
template <typename... Args>
void getArgsSize(Args... args)
{
    // sizeof...()返回参数包中的参数个数
    println("Args has {} elements", sizeof...(Args));
    println("args has {} elements", sizeof...(args));
}
```
在使用时，我们可以发现，不仅仅可以使用`sizeof...(args)`传入函数参数包，还可以使用`sizeof...(Args)`传入模版参数包。借助这个运算符，我们可以将上面的`print`函数用更好的方式实现。当然，还必须使用到从`C++17`开始支持的`if Constexpr`。
```cpp
template <typename T, typename... Args>
void betterPrint(T firstArg, Args... args)
{
    println("{}", firstArg);
    if constexpr (sizeof...(Args) > 0) // since C++ 17
    {
        betterPrint(args...);
    }
}
```
在这个函数里，我们直接使用 `if` 作条件判断，实际上也就是当参数个数大于1的时候继续递归。但是我们也注意到了这里使用了`if constexpr`，这是因为当`betterPrint`只传入一个参数时，编译器会实现`if`的两个分支，而不存在`betterPrint`传入0个参数时的函数，所以就会报错 "no matching function"。而当我们使用了`if constexpr`时，编译期就能确定好参数个数，也就是不需要把每个分支都进行实例化，此时当`args`为0个参数时，编译器会直接跳过0个参数的`betterPrint`分支的实现要求。
## 折叠表达式 (since C++ 17)
### 定义一个`foldPrint`
折叠表达式就是真正魔法的开始了，他将原来复杂的递归过程变为了一个简单的表达式。例如在`C++17`以后，我们的`print`不需要使用递归进行实现了。
```cpp
template <typename... Args>
void foldPrint(Args... args)
{
    println("[foldPrint]"); // 展开参数包
    (println("{}", args), ...);
    // 等价于 (... , println("{}", args))
}
```
第五行就是折叠表达式。这个折叠表达式巧妙使用到了括号表达式的特点，每次从左边开始求值，然后返回最右边的值。如果我们把`args`作为参数包的第一个开始元素，那么这个括号表达式是从参数包的左边开始，然后一路往右边的参数做同样的操作。但是需要注意，**并不是所有折叠表达式都是这样的运算顺序**。
```cpp
println("{}",args_1)
println("{}",args_2)
println("{}",args_3)
println("{}",args_4)
.......
println("{}",args_n)
```
### 定义一个`foldSum`
我们可以通过折叠表达式进行求和，但在求和之前，请让我们先考虑一下折叠表达式的运算顺序。主要是分为两类，以` ... `和参数包`pack`的位置分，` ... `在左边为左折叠，右边为右折叠。左折叠就是先从最左边的元素开始算，一直到最右边。右折叠则相反。

| Fold Expression       | Evaluation                                     |
| --------------------- | ---------------------------------------------- |
| (... op pack)         | (((pack_1 op pack_2) op pack_3) ··· op pack_N) |
| (pack op ...)         | (pack_1 op ( ··· (pack_N-1 op pack_N )))       |
| (init op ... op pack) | (((init op pack_1) op pack_2) ··· op pack_N)   |
| (pack op ... op init) | (pack_1 op ( ··· (pack_N op init )))           |

那么让我们从右边往左求加和。这个是折叠表达式属于右折叠，并且还有一个`firstArg`在最右边，所以加和情况是上面表格中第四行。
```cpp
template <typename T, typename... Args>
auto foldSum(T firstArg, Args... args)
{
    if constexpr ((std::is_same_v<T, Args> && ...))
    {
	    auto res = (args + ... + firstArg);
        println("[foldSum]:{}", res); // 展开参数包
        return res;
    }
    else
    {
        throw std::runtime_error(
            "please input the same type of arguments to sum");
    }
}

foldSum(std::string("hello"), std::string("world"), std::string("CPP"));
```
这个调用结果是 `worldCPPhello`。由 `pack_N` 也就是`CPP` + `hello`，得到`CPPhello`，然后再 `world` + `CPPhello`，得到`worldCPPhello`。
当然你可以使用`firstArg + ... + args`，得到从左往右解析的结果，即`helloworldCPP`。
在这里，我们还使用到了另一个折叠表达式用于保证参与加和的所有的参数类型是一致的，否则会抛出一个异常。在这里使用到 `std::is_same_v<T, Args> && ...`的右折叠表达式，这个表达式的展开结果如下。
```cpp
std::is_same_v<T, ArgsType_1> && std::is_same_v<T, ArgsType_2> && ... && std::is_same_v<T, ArgsType_N>
```
当然，我们也可以额外拉一个函数实现参数类型是否全部相同的判断。
```cpp
template <typename T, typename... Args>
constexpr bool isSameType(T&&, Args&&...)
{
    return (std::is_same_v<Args, T> && ...);
}
```
### 变参下标
我们可以通过传入一组变参下标来访问一个容器中的元素，并把他们打印出来。
```cpp
template <std::size_t... Indexs, typename Container>
void printValuesTemplate(const Container& container)
{
    // lambda表达式,检查下标是否合法
    auto isIndexValid = [](auto size, auto... index) {
        return ((index < size) && ...);
    };

    if (!isIndexValid(container.size(), Indexs...))
    {
        throw std::out_of_range("index out of range");
    }
    // 展开参数包,并打印对应的值
    println("[printValuesTemplate]");
    (println("{}", container[Indexs]), ...);
}
```
我们将变参模版移到容器类型之前，然后定义了一个`lambda`表达式用于判断传入的下标是否越界，由于这里传入的容器通常是运行时才能确定的，例如`std::vector`等动态容器，所以使用`if constexpr`的空间受限。当然，我们也可以直接使用`std::get`。
```cpp
template <std::size_t... Idx, typename T>
void printByIdx(T t)
{
    println("[printByIdx]");
    (println("{}", std::get<Idx>(t)), ...);
}
```
`std::get`在越界时会编译失败，而我们上面写的`printValuesTemplate`即使越界，编译也是成功的，因为`if`并不是编译期判断。当然，这个`printByIdx`只能处理`std::tuple`、`std::array`、`std::pair`等固定大小的容器中提取元素。
## 变参类模版初体验
例如`std::tuple`就是一个典型的变参类模版，可以这样声明一个变参类模版。具体细节还需后续章节。
```cpp
template <typename ...ElemTypes>
class Tuple
```
