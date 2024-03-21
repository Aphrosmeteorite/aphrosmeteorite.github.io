---
author: "Laplace" 
title: "关于C++中如何检测中文字符串"
date: 2023-10-06
description: "cpp with Chinese characters"
tags:
  - C++
categories:
- C++
---

最近遇见需要处理中文字符串的问题，记录一下处理方法。

<!--more-->

## 中文字符的 ASCII 码

&emsp;我们都知道，对于一个英文字符，或者说半角字符而言，其 ASCII 码为`0~127` 对应的二进制数为`0000 0000~0111 1111` ，不难看出一个半角字符占一个字节。   

&emsp;中文字符则稍显复杂，中文字符的 ASCII 码最高位为 1 ，并且需要两个这样的编码才能得到一个中文字符，也就是说，一个中文字符占两个字节。且一个这样的编码范围应是`1000 0000~1111 1111`，对应`-128~ -1` 。

## 如何在 CPP 中识别中文字符

&emsp;在 CPP 中，字符的比较实际是通过 ASCII 码进行的。经过上述认识我们可以知道，中文字符对应了两个字节，每个字节存储一个8位且数值上大于`1000 0000`的二进制码，为了便于比较，使用`unsigned char` 对中文字符进行比较会更为方便，这样最高位的`1`也表示大小，而不受$\pm$影响。此时，一个中文字符对应的两个编码均为大于`1000 0000`的二进制数，也即大于`0x80`的十六进制数，以此，我们可以遍历一个中文字符，判断其编码是否均大于`0x80`。

```c++
//判断是否是中文字符的函数
inline bool CheckChinese(unsigned char){
    return char >= 0x80;
}
```

该函数能很好的帮助我们判断一个字符是否是中文，是则返回`true`，不是则反之。

```c++
//判断有几个中文字符
unsigned int ChineseNum(unsigned char* str){
    unsigned int count{0}; //定义一个计数器
    for(int i=0; str[i]; ++i){
        if(CheckChinese(str[i]))
            ++count;
    }
    return count/2;
}
```

对于一个中文字符而言，每次比较其 ASCII 码时需要比较两次，故最终`return`后需要对`count/2`处理。

