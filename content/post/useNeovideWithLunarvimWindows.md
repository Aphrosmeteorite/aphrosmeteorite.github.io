---
title: "Windows下使用neovide+lunarvim"
author: "laplace"
date: 2024-06-01
lastmod: 2024-06-25T16:26:49
description: "use neovide and lunarvim in Windows" 
tags: 
- tools
categories: 
- tools
---

Windows 下 vscode 已经足够好了，但是还是很喜欢 neovide 的动画，也习惯了 vim 的各种快捷键，所以也把 lunarvim + neovim + neovide 在Windows下使用。

<!-- more -->

## 安装 `scoop`

在安装`scoop`之前需要确保你已经安装了 `PowerShell`(不是`Windows PowerShell`,就叫做`PowerShell`,安装指北[使用Winget安装PowerShell](https://learn.microsoft.com/zh-cn/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.4#install-powershell-using-winget-recommended))。

打开`PowerShell`输入(最好有魔法)

```PowerShell
Set-ExecutionPolicy RemoteSigned -Scope Process -Force; iwr -useb get.scoop.sh | iex
```

## 安装必要组件

`PowerShell`中使用`scoop`安装 neovim, neovide等。

+ 为`scoop`额外增加bucket

```shell
scoop bucket add extras
```
+ 开始安装(如果已经有安装过`gcc`、`make`可以不安装)

```shell
scoop install neovim neovide gcc make unzip tree-sitter
```

## 配置 `lunarvim` 主题

+ 直接 clone 下 `lunarvim`的仓库(在 C:/Users/你的用户名/AppData/Loacl/nvim 里面)

```shell
git clone https://github.com/LunarVim/LunarVim.git $env:LOCALAPPDATA\nvim --depth=1
```

+ 还需要将刚刚clone的文件复制一份到 C:/Users/你的用户名/AppData/Roaming/lunarvim里(lunarvim是新建的)，然后把 lunarvim/nvim 这个 nvim 重命名为 lvim。
+ 接下来请在`PowerShell`中先后尝试`neovide`、`nvim`看看能不能正确打开。

## 为 neovide 配置 Alias

`PowerShell` 要配置的话感觉还挺麻烦的

+ 当前`PowerShell`文件

```shell
echo $PROFILE
```

+ 将上面输出的文件进行更改,添加如下命令,下面的路径请更改为你的`neovide`可执行文件路径，
如果只用`scoop`安装且没有改路径的话，大概率可以在`C:\Users\你的用户名\scoop\apps`下找到。

```PowerShell
Set-Alias vim "path/to/your/neovide.exe"
```

## 在 `WSL` 中使用 `neovide`

目前只使用`PowerShell`的`neovide`打开`WSL`，命令如下

```shell
neovide --wsl
```

`alias`过的话就换成别名，比如我是

```shell
vim --wsl
```

这样的话也需要在 `WSL` 中安装并配置一遍 `neovim`。