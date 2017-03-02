#bionic linker解读

## 0x00 概述

bionic linker是Android的动态链接库连接器，路径是/system/bin/linker或者/system/bin/linker64，作用等同于Linux上的ld-linux.so .
当我们运行一个包含动态链接的程序时，他负责加载程序所依赖的所有的动态链接库的加载和符号引用的解析，该ELF文件中的 'DT_INTERP'项告诉我们使用的链接器的路径。

我们下Android的源代码后，在bionic/linker文件夹下就是我们要解读的源代码位置。

## 0x01 执行一个程序

要执行一个程序要从execve系统调用开始，正真开始加载程序是从load_elf_binary函数开始的：
