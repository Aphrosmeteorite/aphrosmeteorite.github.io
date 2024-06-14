---
title: "C++类模版"
description: "A brief note about C++ class template"
author: "Laplace"
tags:
  - C++
categories:
  - C++
  - C++ template meta programming
date: 2024-06-14
---

继续开新坑了♿，`C++` 模版元编程。作为一个记录笔记吧。如有错误，也请原谅QAQ，代码都是用`msvc clang`编译跑通。

<!--more-->

## 定义一个类模板
相信大家已经会使用`C++`定义类模板了，不就是在定义的时候多加一行`template<typename T>` 吗。是的，这是最基础的泛型。例如下面的一个`Stack`类，就是一个模板类。在接下来的讲解中，请你不要关注`Stack`这个类本身的作用(例如栈)，这里我们仅仅以此为例，并讨论各种可能与模板类相关的语法，请忽略这种想法“这样定义一个构造函数没意义啊”，我们只讨论语法上的规则和可能性。

```cpp
template <typename T>
class Stack
{
private:
    std::vector<T> m_data;
public:
    Stack() = default;
    Stack(Stack const&); // 参数不指定模板特化类型,默认与当前被构造的Stack类型一致
    Stack(Stack<T> &, size_t size);
    Stack(T elem) : m_data({std::move(elem)}) {}
    Stack(const std::initializer_list<T> &initList) : m_data(initList) {}
};
```

## 省略显式指出模板类型(since C++17)
从`C++17`开始，我们可以不用再显式指出一个模版类的模版参数类型(默认值除外)，例如下面这段代码在`C++17`以后可以成功编译。
```cpp
Stack stk_initList{"Hello"};
Stack stk("Hello");
```
此时我们可以看见对于`stk`变量，其模版参数类型被推导为`const char *`(和`char const *`等价，都属于顶层`const`)。也可以看出这个构造函数匹配了`Stack(T elem)`，但是当我们看`stk_initList`时，我们却会发现不同的地方，虽然模版参数都被推导为了`const char *`，但是这里实际上调用了包含`initializer_list`的构造函数。
可是，如果我们需要更方便得去处理字符串，我们会希望虽然是通过`"Hello"`这样的字面量进行构造，但是其模版类型是`std::string`。那么我们可以通过推断指引进行解决。

## 推断指引
推断指引在我的理解上，就是显式地指定某种类型的构造函数应该按照另一个指定的模版参数类型进行。这么说可能并不直观，我们看以下代码。
```cpp
Stack(const char*) -> Stack<std::string>;
```
我们该如何理解呢？我是这么理解的，`Stack(const char*)`代表了一个以`const char *`为参数类型的构造函数，当发生类型推导为`const char *`时，请将这样的类型推导为`std::string`进行实例化。此时我们再看上面的`Stack stk("Hello")`就会发现它的模板参数类型已经是`std::string`了。而`stk_initList`的却依然是`const char *`，这里实际上是由于它匹配的构造函数是`initializer_list`的构造函数，而并没有为该构造函数进行指引 ，通过添加下述语句，就可以保证此时也构造一个`std::string`模版类型的`Stack`了。
```cpp
Stack(std::initializer_list<const char*>) -> Stack<std::string>;
```
需要指出的是，这个指引语句必须出现在和模版类的定义相同的作用域或命名空间内。😎

## 模板部分特例化
我们应该也接触过，比如说`Stack<int>{......};`就是一种对于`int`类型的特例化，但是我们可能并未察觉，其实特例化还可以是模板，而且还可以在底层实现上与原来完全不一样。
```cpp
template <typename T>
class Stack<T *>
{
private:
    std::deque<T *> m_data;
public:
    Stack(T *elem) { m_data.push_back(elem); }
    void print() { std::println("Stack<T*>"); }
}; // 一个专门处理指针的特例,可以连底层实现都完全不
```
这里我们特例化了一个专门处理指针类型的`Stack<T*>`，这个特例的底层不再使用`std::vector`实现，反而直接使用到`std::deque`实现，同时还定义了一个接受指针的构造函数。如果我们传入一个指针，那么会匹配这个特例化的类，当然，也有反例。
```cpp
int *p = new int[7];
Stack stk_ptr(p);
delete [] p;
```
在上面这个例子当中，我们可以发现`stk_ptr`具有方法`.print()`，但是当我们把`int`换成`char`之后，这个`stk_ptr`不再有`.print()`方法，反而被实例化为了`Stack<std::string>`类型，这里发生了推断指引，且被构造为了原来的`Stack<T>`这样的类型。其实也很好理解，毕竟发生推断指引后，模版参数类型就不再是指针了，自然不会匹配特例化的指针类型`Stack`。

## 聚合类的模版
聚合类其实就是一堆元素绑在一个结构体里面，没有显示定义构造函数，也没有继承来的构造函数，不指定`private`等标识，可以参考`C++ primer`，定义可能并不统一。以下就是一个聚合类。
```cpp
template <typename T>
struct ValueWithComment
{
    T value;
    std::string comment;
};
```
这个类有一个模版参数，我们当然也可以为其实例化赋值，然而这里的第二个实例化却无法编译过。
```cpp
ValueWithComment valWizComet{10, "hlo"};

ValueWithComment valWizComet1 = {10, "hlo"};
```
因为聚合类的原因，并没有定义拷贝构造函数，编译器无法推导出其类型，甚至直接使用`{.value=10 , .comment="hlo"}`也不行。此时就需要进行推断指引。
```cpp
ValueWithComment(int, const char*) -> ValueWithComment<int>;
```
当然，也可以把`int`也换成模版，例如
```cpp
template <typename T>
ValueWithComment(T, const char*) -> ValueWithComment<T>;
```
此时即没有失去泛化能力，也能保证直接构造了。

## 为模版类进行函数重载
这里主要以`std::cout`进行重载。当希望能直接用`std::cout`打印出自定义类对象时，就需要重载`operator<<`。此时就需要用到友元。我们也可以直接定义一个`print`函数把`std::ostream`作为参数进行传入，但是还是让我们谈谈友元的方法。
```cpp
template <typename T>
class Stack;

template <typename T>
std::ostream &operator<<(std::ostream &, Stack<T> const &);
```
为保证友元函数声明时正常，需要预先声明类模版`Stack`，然后继续声明一个模版`operator<<`，这时在`Stack<T>`类的定义里面就可以加上友元声明。
```cpp
template <typename T>
class Stack
{
	friend std::ostream &operator<< <>(std::ostream &, Stack<T> const &);
	// or
	//friend std::ostream &operator<< <T>(std::ostream &, Stack<T> const &);
};
```
然而我一开始对这里`operator<<`之后出现的`<>`感到困惑，为什么要加这个？就像我之前提到的，我们重载的函数被声明为了模版，而友元的声明则是对该模版进行实例化，我又疑惑了，为什么要实例化？其实对于`Stack`这样一个类模版，当我们使用它时，例如`Stack<int> stk`，都有实例化一份代码，而不同的`operator<<`实际上针对的就是这些实例化的`Stack`进行，比如说`Stack<int>`，我们要打印这样的类型，那么自然`operator<<`也是`Stack<int>`类型的友元，那么显然是已经实例化的`operator<< <int>`。所以这里需要实例化。
那我又疑惑了，不是在参数列表里面已经有了`Stack<T>`吗，为什么还要在函数加一个？其实是要求调用模版函数，因为一开始的声明本身就是模版函数，此时自然是调用该模版函数的实例化版本。这点其实可以在`operator<< <T>`的友元声明中看出。

## 总结
这章内容其实不多，还未真正触及到模版元编程的 Core，但是也有很多新概念需要注意。同时我学下来感觉，嗯 · · · · · · 这个不显式指定模版类型而让编译器去推导有时候真的很麻烦，例如聚合类，总有种重复造轮子的感受。而且当我们需要针对不同的类型进行特化处理时，也要格外小心模版被推导为了其他的特化类型，而不是我们想要的那个，这也挺难留意的。
所以总结就是，尽量少让编译器自己推导，特别是你不确定编译器会推导成什么的时候😇 。