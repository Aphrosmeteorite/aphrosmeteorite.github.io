---
author:  "Laplace" 
title:  "关于C++中使用using替代typedef"
date: 2023-12-25
description: "cpp with using"
tags:
  - C++
categories:
- C++
- Effective Modern C++
---

很久没有更新博客了🫠，主要是(~~懒~~)学业繁忙，继续写点`C++`相关吧。

<!--more-->

最近在写一些 ds 中的算法时涉及需要同时调试几个函数，操作基本一致，一开始的想法是直接使用函数指针做调用，尽管也顺利完成了，但感觉还是不够`C++`。

# 之前

先浅谈一下之后可能聊到的东西。

+ 假设共4个函数，分别是 <font face="Afacad">fn1、fn2、fn3、fn4</font>。
+ 假令我们的函数指针、`typedef` 、 `using` 定义的均使用`fnPtr`。
+ 函数的参数均为`int`型，返回值为`std::vector<int>`。

# 函数指针数组

函数指针可以说是`C`当中的一个经典写法了，以下定义一个函数指针，怎么读呢？

括号让`[]`与`fnPtr`先结合表明`fnPtr`是一个数组，再与`*`结合表明数组元素是指针，最后与`(int )`结合表明这是一个函数，而前面的`std::vector<int>`则表明返回类型。

```cpp
std::vector<int> (*fnPtr[])(int ) = {fn1 , fn2 , fn3 , fn4}
```

通过这样一个函数指针，我们可以轻松地像数组一样批量调用<font face="Afacad">fn</font>$i$。

```cpp
for(int i=0; i<4 ;i++)
    fnPtr[i](i);
// 也可以更C++一点
for(auto & fn:fnPtr)
    fn(1); // 传参 1 是随便写的
```

# 使用 `typedef`

`typedef`也是很常用了，比如我们不喜欢一直写`long long`，我们可以使用`typedef `，如下：

```cpp
long long a = 1;
typedef long long ll;
ll b = 1; // good 
```

在上述例子中，我们可以感觉到`typedef`好像十分优雅地解决了`long long`难打的问题，但是如果我们再看下式呢？

```cpp
typedef std::vector<int> (*fnPtr)(int );
```

经验丰富的`C++`大师已经知道这是一个函数指针了，但······作为蒻芨的我还是难以理解。`typedef`?蒽，看起来在定义一个类型，蒽？定义成谁了？是`fnPtr`？那为什么`long long`的例子里面是最后的`ll`？

也许我们应该使用`using`

# 使用`using`

`using`也可以说是一种`typedef`的语法糖，但使用`using`可以使代码可读性变强太多。上例子中`long long`的问题，使用`using`的解法如下：

```cpp
using ll = long long;
```

我的世界突然就清澈了起来🥰，这个`=`太符合直觉了，好像就是把`long long`赋值给`ll`，所以`ll`就和`long long`一样。那函数指针数组呢？

```cpp
using fnPtr = std::vector<int> (* [])(int );
fnPtr fnptr = {fn1 , fn2 , fn3 , fn4};
```

看起来是不是比`typedef`清爽多了，我们好像定义了一个类型`fnPtr`是一个返回值为`std::vector<int>` 的函数指针数组，使用这个类型定义一个变量`fnptr`去存下需要调用的函数岂不妙哉。

```cpp
for(auto & fn:fnptr)
    fn(1); // 传参 1 是随便写的
```

