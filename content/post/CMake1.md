---
title:  "Windows下CMake链接库"
description: "Windows CMake link library"
author:  "Laplace"

date: 2024-02-11
lastmod: 2024-02-11

tags: 
  - C++
categories:
- C++
---

如何在`VScode`中使用`CMake`链接库，主要是静态库，动态库在`Windows`中直接放在`exe`同目录。

<!--more-->

## 说明

+ ` Cmake`工具包使用`VS Studio Community 2022 - amd64`。
+ 这篇博客会以两个库作为例子，一个是自己写的`add.h及add.cpp`另一个则链接`openCV4.8.0`。
+ 这篇博客不记录`CMake、C++`等工具相关配置。

## 关于add.h

### 编译链接静态库

+ 以下是文件结构，未标识后缀的应视为文件夹，除`.vscode`属一个文件夹（主要是 `C++`相关配置文件）。
+ 此项目名称为`cmake-study`。

```
D:/cmake-study/
├─.vscode
├─build
├─lesson2-1
│  ├─add
│     ├─add.cpp
│     └─CMakelists.txt
│  ├─lib
│     ├─add_static.lib
│     └─add.h
│  ├─CMakelists.txt
│  └─main.cpp
├─CMakeLists.txt
```

`C++`中我们自己写的库可以与`main`一起放在同一目录下，`#include"add.h"`然后进行调试或运行。对于我们自己写的库，为避免过多的代码复写，直接编译成动态库或静态库要更加省力。所以我们的目标是将`add.cpp`编译成静态库，然后通过`CMake`指定需要链接的库，然后直接在`main.cpp`中调用即可。

### 编写lesson2-1/add中的CMakelists

我们的目标是通过该`CMakelists.txt`指定将`add.cpp`编译为一个静态库，Windows系统一般以`.lib`作后缀。所以该`CMakelists.txt`应编写如下。

```cmake
add_library(add_static add.cpp)
```

`add_library`指定我们需要编译一个‘库’，而内部的`add_static`指定编译后库的名字，也即编译后，我们的静态库应该叫`add_static.lib`，而`add.cpp`则是需要编译的文件，需要注意的是，这里使用的是相对路径，也可以写成`./add.cpp`。

### 编写lesson2-1中的CMakelists

该`CMakelists`的目标是将`./add`中的`CMakelists`加入进来，同时指定需要包括的静态库文件的位置、需要链接的静态库文件以及需要编译的文件。在本文件结构下，把所有静态库以及相关头文件全部放在同目录的`lib`文件夹下。则可以编写`CMakelists.txt`如下。

```cmake
add_subdirectory(add)
include_directories(./lib)
add_executable(lesson2-1 main.cpp)
target_link_libraries(lesson2-1 D:/cmake-study/lesson2-1/lib/add_static.lib)
```

`add_subdirectory`将同目录下`add`文件夹加入进来，同时`include_directories`指定包括头文件位置，`add_executable`指定需要一同编译的文件，同时指定生成一个`lesson2-1`的项目文件，该文件可以在`./cmake-study/build`中找到。最后`target_link_libraries`指定需要链接的文件以及被链接的项目文件。***但此处仿佛必须写绝对路径，否则依然会出现 LNK ERROR，故也可以参考下列编写方法。***

```cmake
add_subdirectory(add)
include_directories(./lib)
link_directories(./lib) # 指定链接库的路径
add_executable(lesson2-1 main.cpp)
target_link_libraries(lesson2-1 add_static.lib) # 在指定的 link_directories 中选择链接的库
```

### 编写cmake-study中的CMakelists

该`CMakelists.txt`主要作为所有项目的管理，所以主要是设定一些基本设置。比如我们还有`lesson2-2`文件夹，该文件中还可以有其他`C++项目`，或是即将要讲到的`lesson2-opencv`文件夹。我们指定`C++ 14`以及最低`CMake`版本为 3.15。同时指定整个项目文件名为`cmake-study`。

```cmake
cmake_minimum_required(VERSION 3.15)
project(camke_study)

set(CMAKE_CXX_STANDARD 14)
add_subdirectory(lesson2-1)
add_subdirectory(lesson2-2)
add_subdirectory(lesson2-opencv)
```

## 关于链接openCV

我们首先给出一个示例程序，`main.cpp`，注意`cv::imread`中的图像路径需要自己指定，如果不指定的话也可以看终端是否成功输出"无法读取输入图像"。

```c++
#include <opencv2/opencv.hpp>
#include <iostream>
int main(int argc, char **argv)
{
    cv::Mat inputImage = cv::imread("path/to/image.jpg", cv::IMREAD_COLOR);
    if (inputImage.empty())
    {
        std::cout << "无法读取输入图像" << std::endl;
        return -1;
    }
    cv::Mat outputImage;
    inputImage.copyTo(outputImage);
    cv::imshow("原始图像", inputImage);
    cv::imshow("复制后的图像", outputImage);
    cv::waitKey(0);
    return 0;
}
```

### 链接opencv2/opencv.hpp

注意此处`cmake-study/CMakelists.txt`文件与示例`add.h`一致，主要是用于所有项目的管理。所以重要的是`cmake-study/lesson2-opencv`文件夹下的`CMakelists.txt`。

```
D:/cmake-study/
├─.vscode
├─build
├─lesson2-opencv
│  ├─CMakelists.txt
│  └─main.cpp
├─CMakeLists.txt
```

### 编写lesson2-opencv中的CMakelists

通过第一个例子我们已经知道，要链接`opencv2/opencv.hpp`文件，我们需要该文件的位置，以及相关静态库/动态库的位置。官网下载`openCV4.8.0`并指定路径进行安装后，打开该`opencv`文件，我们主要需要`/opencv/build/include`(该文件夹内包括了opencv2以及各种头文件)和`/opencv/build/x64/vc16`中的`bin`(动态库)以及`lib`(静态库)。***注意以上opencv文件路径省略了前面的部分，需要使用绝对路径***。所以我们可以编写`CMakelists.txt`如下

```cmake
include_directories(D:/opencv/build/include)
add_executable(lesson2-opencv main.cpp)
target_link_libraries(lesson2-opencv D:/opencv/build/x64/vc16/lib/opencv_world480d.lib) # debug版本选择opencv_world480d.lib
```

当然，我们也可以将`opencv/build/include`中的`include`文件夹直接复制到`main.cpp`相同目录中，同时新建一个文件夹`lib`将静态库复制在里面，此时`CMakelists`编写如下。

```cmake
include_directories(include)
link_directories(./lib)
add_executable(lesson2-opencv main.cpp)
target_link_libraries(lesson2-opencv opencv_world480d.lib) # debug版本选择opencv_world480d.lib
```