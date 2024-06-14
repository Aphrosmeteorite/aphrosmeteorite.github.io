---
title:  "你的 Ubuntu bash输入延迟、卡顿？"
description: "Ubuntu bash laggy"
author:  "Laplace"

date: 2024-04-06
lastmod: 2024-04-06

tags: 
  - Linux
categories:
- Linux
---

这是在我的`Ubuntu 23.10`下大概持续了一个多星期的问题，无论是 `bash` `zsh`都出现了令人难以忍受的延迟输入问题，`vim` `nvim`等编辑器更是完全无法使用。直到最近找到这个问题的解决方法，在此记录。

<!--more-->

## 关于为何卡顿
本博客参考了这篇 `issue` [input delay on Terminal Ubuntu 22.04](https://askubuntu.com/questions/1509058/input-delay-on-terminal-ubuntu-22-04-4/1509288)发现这可能是最近`Ubuntu` 更新 `mutter` 导致的问题，可以看看里面的解答。这里记录一下自己解决的情况。
## 我的解决情况
### 尝试
怀疑是`zsh`导致的问题，尝试重装，无果，使用各种`top`、`time`等分析性能发现基本正常，`iostat`也并没有感觉到磁盘有问题。也找到一些博客说`zsh`冷启动相关问题，但我的`zsh`启动速度十分快，几乎没有什么延迟，延迟出现在输入阶段。
总结，大部分先前找到的方法对我无效，只能继续找相关问题。

### 解决
其实之前也在`ask Ubuntu`上查找终端卡顿、`bash`慢的问题，但是之前一直用`zsh slow`、`bash slow`等等关键词搜索，愣是没有可以解决的回答，最后用`Ubuntn bash laggy`找到了🥹，还是学好英语吧。

#### 参考方法
参考了大佬 mikabytes 的方法，记录一下。这个并没有导致 `apt`损坏，并且对我`Ubuntu 23.10`有效，但是该`PPA`仅仅用于测试，可能会导致其他的问题。关于其他解决方案，可以参考之前提到的`issue`，但其他方案要么可能导致`apt`损坏，还有可能导致图形界面无法启动，所以这里我只选择了这个方案。

```bash
sudo add-apt-repository ppa:vanvugt/mutter
sudo apt update
sudo apt upgrade
```

当官方提供了稳定的解决方案后，会发布新的改进版本，此时只需要移除上述添加的`PPA`然后再更新即可。

```bash
sudo add-apt-repository --remove ppa:vanvugt/mutter
sudo apt update
sudo apt upgrade
```
