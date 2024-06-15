---
title: C++非类型模版参数
description: A brief note about C++ no typelike param
author: Laplace
tags:
  - C++
categories:
  - C++
  - C++ template meta programming
date: 2024-06-15
---
非类型模板参数其实说来也简单，也就是在`template`中将`typename`换成具体的类型。但是还是有诸多限制和使用方式的。👍

<!--more-->

## `Array`的非类型模板参数
我们都知道在`std::array`中需要声明类型和一个编译期可知的常量。我们可以仿照声明一个自己的`Array`。这里的第二个模板参数就是非类型模板参数，要求传进去一个编译期可知的`std::size_t`类型的数作为整个`Array`的最大容量。
```cpp
template <typename T, std::size_t MaxSize>
class Array
{
private:
    std::array<T, MaxSize> m_data;
    std::size_t m_length;
public:
    constexpr Array() = default;
    constexpr std::size_t length() const { return m_length; }
};
```

## 函数的非类型模板参数
我们也可以为函数声明一些非类型模板参数，例如下面这个`addValue`函数。
```cpp
template <int Val, typename T>
T &addValue(T &x)
{
    x += Val;
    return x;
}
```
这个函数可以直接调用`addValue<10>(integer)`(当然你得先定义`integer`)。可是我们稍微细想一下就知道，这里的`T`和`int`类型一样吗？很容易不一样，而且编译器并不会报错，可是运行时就出现问题了。例如下面的代码调用。
```cpp
char const *str = "hello";
lap::addValue<10>(str);
```
这显示不是一个应该被使用的调用，然而编译器并不会报错，甚至运行时不会崩溃。但是这个`str`指针已经变成了奇怪的东西，它指向的地址增加了10字节，因为`str`是指向`char`类型的指针，所以 +10 相当于加了10字节。这就让`str`指向了它不应该指向的位置。当然，如果你声明的是`char const * const str`，那么编译器会正确报错。所以我们的目标是要求这个函数只能对相同类型做加法。

在`C++17`之前，我们会这样声明`addValue`。
```cpp
template <typename T, T Val = T()>
T &addValue(T &x)
{
    x += Val;
    return x;
}
```
在这个声明中，`Val`的默认类型就是`T`，并且默认的值为`T()`，也就是`T`类型的默认构造，比如`int()`一般而言是0。这样我们就保证了该函数每次都能加上一个正确的类型的`Val`，并且当传入类型不同时，编译器会直接报错。
但是我们也发现了，这个函数必须每次都传入两个模版参数(如果你不使用`Val`的默认值的话)，比如说`addValue<int,10>(integer)`，如果这样的话我为何不直接写成一个模版`T`，然后传入的函数参数列表为两个数呢？感觉没啥用。

那么在`C++17`之后，非类型参数也能被声明为 “模版”，当然，这里的 ”模版“非彼模版，而是可以用`auto`占位。例如我们可以写出以下代码。
```cpp
// since C++ 17
template <auto Val, typename T = decltype(Val)>
T &addValueAuto(T &x)
{
    x += Val;
    return x;
}
```
一开始我也有疑惑，用`auto`的区别是什么，直接用一个`typename`不行吗？不过很快我就悟了😎，当然不行，`typename`是一个类型，怎么能直接传入参数而且和`x`进行加和呢。而`auto`则可以，因为它是一个非类型模版参数，现在是不是体会到这个名字的精妙了，**非类型** 的一个 **模版参数**。
而且我们注意到了，这个函数不仅可以保证类型相同，在使用时也更为方便，因为我们只需要传入`Val`的值和`x`即可。`addValueAuto<10>(integer)`。

## 在模版类的非类型模版参数使用`auto` (since C++ 17)
由于`C++17`可以使用`auto`作为占位符，所以我们也可以对模版类的非类型模版参数使用`auto`。例如，
```cpp
template <typename T, auto MaxSize>
class Array
{
public:
    using size_type = decltype(MaxSize);

private:
    std::array<T, MaxSize> m_data;
    size_type m_length;

public:
    constexpr Array() = default;
    constexpr size_type length() const { return m_length; }
};
```
这里我们使用`auto`作为占位符，并在类中增加一个`size_type`作为`MaxSize`的类型别名。我们可以尝试对两个不同的`Array`作类型检查。
```cpp
void testArraySizeType()
{
	using std::println;
    Array<int, 20u> intArray;
    Array<std::string, 40> stringArray;
    // 编译期检查
    if constexpr (!std::is_same_v<decltype(intArray)::size_type,
decltype(stringArray)::size_type>)
    { // size type 一个是 usigned int, 一个是 int
        println("intArray size_type is unsigned int\n"
                "stringArray size_type is int");    
    }
}
```
运行就会直接打印出类型。

## 值得注意的地方
- 使用非类型模板参数是有限制的。通常它们只能是整形常量(包含枚举)，指向`objects/functions/members`的指针，`objects`或者`functions`的左值引用，或者是`std::nullptr_t`。
- 当传递对象的指针或者引用作为模板参数时，对象不能是字符串常量，临时变量或者数据成员以及其它子对象。
	- 在 `C++11` 中，对象必须要有外部链接。
	- 在 `C++14` 中，对象必须是外部链接或者内部链接。
	- 在 `C++17` 中，可以没有链接。
- `< >`中的模版参数如果有运算，并且使用了`<`或`>`等符号，尽量用括号括起来。
在`C++17`之后，我们也可以直接使用静态的局部字符串数组用于非类型模版参数。
```cpp
template <auto T>
// parameter( since C++17)
class Message
{
public:
    static void print() { std::println("Message:{}", T); }
};

void testMessage()
{
    // 可以是静态的常量表达式 since C++17
    static const char theMsg[] = "hello";
    // 不能是浮点数或类类型
    Message<theMsg>::print();
    Message<42>::print();
}
```
顺便一提，使用`MSVC Clang17.03(GNU CLI)`在`C++ templates`第二版中的这个代码似乎并不能通过编译。原书为`int i;`但显然不是编译期可知。
```cpp
template <decltype(auto) N>
class Nclass
{
public:
    using N_type = decltype(N);
};

constexpr int i = 10;
lap::Nclass<(i)>::N_type a = 10;
```
原书认为这里的`N_type`会变为`int &`，然而无法通过编译。如果把`(i)`改为`i`则可以编译，但是`N_type`却是`int`。如果我们使用一个引用类型尝试作为模版参数，则该引用类型并不能被很好地声明。
```cpp
constexpr const int constexprInt = 10;
constexpr const int &i = constexprInt; // example 1
constexpr int &i = constexprInt; // example 2
constexpr const int &i = 10; // example 3
constexpr int &i = 10; // example 4

static int staticInt = 10;
constexpr int &i = staticInt; // example 5
```
以上的 1...4 个 example 都无法通过编译，我们必须声明一个对静态变量的`constexpr &`才能通过编译。此时得到的`N_type`则变成了`int &`类型。

关于为什么`constexprInt`不能被引用的问题，其实我们需要了解到引用是什么。其底层本质是一个指针，只不过这个指针的指向不能发生改变，也就是一个这样的类型。而对于取地址操作，某些情况下不被视为编译时的常量表达式。
```cpp
template <typename T>
using reference_type = T * const;

reference_type<int> ptr = &integer;
ptr = &constexprInt; // 报错，无法修改指向
```
当然，我们这里的变量都是局部变量，如果需要对常量进行引用，该常量应该具有静态存储期。此时应该是全局变量、静态变量。其次也必须指出，我的编译器是`MSVC Clang17.03(GNU CLI)`，但是我也更换了例如`Clang 18.1.6 pc-windows-msvc`，`GCC 13.2.0 x86_64-w64-mingw32`等常用编译器，使用`WSL2`的`g++ 13.2.0`，上面的 1...4 个 example 都是无法编译的。然而 github copilot 、Chatgpt4o都告诉我从`C++ 17`之后，至少 example 1是可以编译的...🤯