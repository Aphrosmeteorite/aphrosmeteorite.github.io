---
author:  "Laplace" 
title:  "一个设计让你的C++只需要一个赋值运算符！"
date: 2024-02-20
description: "A design to so that your C++ needs only one assignment operator"
tags:
  - C++
categories:
- C++
- Effective Modern C++
---

~~希望没有标题党的意思~~,一个有趣且巧妙的设计,可以让一些类只需要两个构造函数,而我们只需要额外增加的只有`swap`和`copy`

<!--more-->

## 说明

+ 以下将以类`Buffer`作为例子
+ 需要具有一定的左值和右值相关前置知识
+ 同时涉及到异常处理相关内容

`Buffer`类的设计如下

```cpp
class Buffer
{
private:
    char *m_data; // 存放字符串
    std::size_t m_length; // 字符串长度
    std::size_t m_capacity; // 字符串的容量

public:
    explicit Buffer(std::size_t length); // 构造函数
    ~Buffer(); // 析构函数
    Buffer(const Buffer &rhs); // 拷贝构造
    Buffer(Buffer &&rhs) noexcept; // 移动构造
    Buffer &operator=(Buffer rhs) noexcept; // 赋值运算符
    void swap(Buffer &rhs) noexcept; // 类内swap函数
};
```

## 构造函数和拷贝构造函数的设计

这里两个函数的设计很常规,以下直接给出代码做参考（函数定义写在类内）

```cpp
explicit Buffer(std::size_t length)
try : m_data(length > 0 ? new char[length] : nullptr), m_length(0), m_capacity(length)
{ 
}
catch (const std::bad_alloc &e)
{
    std::cerr << "Failed to allocate memory\n";
    std::cerr << e.what() << '\n';
    delete[] m_data;
    throw;
}

Buffer(const Buffer &rhs)
try : m_length(rhs.m_length),m_capacity(rhs.m_capacity),m_data(rhs.m_capacity > 0 ? new char[rhs.m_capacity] : nullptr)
{
    std::copy(rhs.m_data, rhs.m_data + rhs.m_length, m_data);
}
catch (const std::bad_alloc &e)
{
    std::cerr << "Failed to allocate memory\n";
    std::cerr << e.what() << '\n';
    delete[] m_data;
    throw;
}
```

这里可能显示起来比较丑，可以在编辑器中自动格式化代码会好看一些。两个构造函数其实整体差别不大，利用初始化列表进行类内各值的初始化，同时也保证能够捕捉到异常，这里需要判断`m_data`是否应该为空指针。同时由于当构造函数出现异常时，**对象不会被构造**，所以析构函数无法自己调用，这时候我们需要在`catch`语句中写`delete`。

## 析构函数

这个应该没什么好说的。

```cpp
~Buffer()
{
    std::cout << "~Buffer\n";
    delete[] m_data;
}
```

## swap函数和copy函数

由于移动构造和赋值运算符都需要这两个函数，所以先写了。`copy`其实是调用的`std::copy()`，而`swap`则是把所有的交换都封装起来，内部也是调用`std::swap()`

```cpp
void swap(Buffer &rhs) noexcept
{
    std::swap(m_data, rhs.m_data);
    std::swap(m_length, rhs.m_length);
    std::swap(m_capacity, rhs.m_capacity);
}
```

为保证效率，在交换时选择直接交换指针而不是用中间变量去拷贝。

## 进入正题！

### 移动构造函数

这里先给出代码。

```cpp
Buffer(Buffer &&rhs) noexcept
    : Buffer(0)
// 这里将*this构造为一个容量为0的Buffer,然后与rhs交换
{
    swap(rhs);
}
```

在`C++`当中，被传入的`rhs`视为将亡值，构造执行完毕，则传入的`rhs`已不再能直接正常使用。这里在初始化参数列表直接调用构造函数将`this`构造为”空对象“——空指针且容量长度都为0。然后将该对象与`rhs`交换完成移动构造。

### 赋值运算符

还是先给出代码。

```cpp
Buffer &operator=(Buffer rhs) noexcept
{
    // 传值调用,这里rhs会调用拷贝构造函数
    // 临时变量被swap,然后析构
    swap(rhs);
    return *this;
}
```

#### 传入左值的情况

传入左值时，我们知道在`C++`中需要拷贝临时变量，将传入值拷贝给`rhs`，然后在内部与`*this`做交换，可以发现，这里只有一次拷贝构造，并且拷贝构造函数是一个强异常安全函数，也同时保证了在左值赋值时仍然是强安全类型。由于`rhs`是拷贝的临时变量，所以交换不会影响原来的传入值。

还有一个优点，传统写法我们会将`this->m_data`先进行`delete`，然后将`rhs.m_data`进行过拷贝，也就是深拷贝，但是我们忽略了一件事，这里出现了两次拷贝，一次在构造`rhs`这个临时变量，一次在构造`this->m_data`，而这个写法减少了一次拷贝。当然，如果认识到了`rhs`是临时变量，那么我们直接把`rhs.m_data`与`this->m_data`的指针交换，也可以省去一次拷贝，但是写法却远不及`swap`来的简单。

#### 传入右值的情况

传入右值时同样要进行构造，不过这里是调用移动构造函数，`rhs`的构造需要调用移动构造函数，此时会初始化一个`Buffer(0)`这样的空对象（这个对象就是`rhs`）并与传入的右值（也许说将亡值会更好？）进行交换。

`explicit Buffer(std::size_t length)`函数是一个强异常安全函数，一同保证了移动构造函数的安全。得到`rhs`后，传入的右值（也许说将亡值好？）变为空对象，然后继续走`operator=`的函数体。此时直接将`rhs`与当前对象做交换即可，交换后`rhs`离开作用域就自动析构。

在传统写法中，我们会多写一个这样的函数`Buffer &operator=(Buffer &&rhs) noexcept`，这个函数也能完成移动构造，内部也是执行指针的交换。

```cpp
if (this != &rhs)
{
    delete[] m_data;
    m_data = rhs.m_data;
    m_length = rhs.m_length;
    m_capacity = rhs.m_capacity;
    rhs.m_data = nullptr;
    rhs.m_length = 0;
    rhs.m_capacity = 0;
}
return *this;
```

在这个函数中，`delete`会抛出异常，当`delete`抛出异常时，后续操作不再执行，并没有继续更改其他值，但是如果我们把顺序交换一下（如下），当`delete`抛出异常时，`m_length`和`m_capacity`的已经被修改了，此时即使捕获异常，也无法拿回原来的数据了，而且这两个值的错误修改对`Buffer`对象而言是致命的。

```cpp
m_length = rhs.m_length;
m_capacity = rhs.m_capacity;
delete[] m_data;
m_data = rhs.m_data;
```

