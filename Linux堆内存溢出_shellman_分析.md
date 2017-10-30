# shellman

@elemeta

## 1. shellman分析

实验环境：CentOS 6.6 x64 + glibc-2.25
分析工具：IDA 6.6.141224(64-bit) for Windows

shellman是一个64位的elf可执行文件，文件夹中的libc.so是glibc-2.19版本，我的实验
环境是glibc-2.25，这对问题分析没有影响。

    [elemeta@emcos66x64 1]$ strings ./libc.so.6.x86_64.3f6aaa980b58f7c7590dee12d731e099 | grep glibc
    glibc 2.19
    <https://bugs.launchpad.net/ubuntu/+source/eglibc/+bugs>.
    [elemeta@emcos66x64 1]$ file ./shellman.b400c663a0ca53f1f6c6fcbf60defa8d 
    ./shellman.b400c663a0ca53f1f6c6fcbf60defa8d: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked (uses shared libs), for GNU/Linux 2.6.32, stripped

Shellman程序设置了alarm(60); 程序运行60秒将终止, 如果用gdb调试需要忽略SIGALRM信号

    (gdb) handle SIGALRM print nopass

该程序是个对堆内存进行alloc、copy、free操作的工具，分析的关键是找出struct shellcode结构体：

    struct shellcode {
        long is_exist;
        long data_len;
        void *data_ptr;
    };

    struct shellcode_list[256];
    
程序最多可以分配256个内存块来存放shellcode，每块大小限制在1024字节内。主要操作如下：

- new_shellcode = malloc
- edit_shellcode = copy
- del_shellcode = free
    
我们在edit_shellcode函数中找到一个堆溢出bug，它没有对已存在的堆内存大小进行检查：

    .text:0000000000400C78 loc_400C78:                             ; CODE XREF: edit_shellcode+32j
    .text:0000000000400C78                 mov     edi, offset aLengthOfShellc ; "Length of shellcode: "
    .text:0000000000400C7D                 xor     eax, eax
    .text:0000000000400C7F                 call    _printf
    .text:0000000000400C84                 xor     eax, eax
    .text:0000000000400C86                 call    get_int32
    .text:0000000000400C8B                 mov     ebp, eax
    .text:0000000000400C8D                 lea     eax, [rax-1]
    .text:0000000000400C90                 cmp     eax, 3FFh
    .text:0000000000400C95                 ja      short _invalid_sc_num
    .text:0000000000400C97                 mov     edi, offset aEnterYourShe_0 ; "Enter your shellcode: "
    .text:0000000000400C9C                 xor     eax, eax
    .text:0000000000400C9E                 call    _printf
    .text:0000000000400CA3                 mov     rdi, ds:sc_list.data_ptr[rbx] ; buf
    .text:0000000000400CAA                 mov     esi, ebp        ; len
    .text:0000000000400CAC                 call    read_data       ; 这里有溢出,未判断原来的数据长度
    .text:0000000000400CB1                 add     rsp, 8
    .text:0000000000400CB5                 mov     edi, offset aSuccessfullyUp ; "Successfully updated a shellcode."
    .text:0000000000400CBA                 pop     rbx
    .text:0000000000400CBB                 pop     rbp
    .text:0000000000400CBC                 jmp     _puts

对应的C代码如下：

    printf("Length of shellcode: ");
    _len = get_int32();
    if ((_len - 1) > 0x3FF) {
      puts("Invalid shellcode length!");
    } else {
      printf("Enter your shellcode: ");
      read_data((void *)sc_list[_sc_idx].data_ptr, _len);
      puts("Successfully updated a shellcode.");
    }

*更详细的分析过程请查看附件中的：shellman.i64*

## 2. libc堆内存管理

内存分配器将堆上的内存划分为许多thunk，每个thunk包含用户分配的一个数据块和头部，
在分配和回收内存时对thunk进行分割和回收操作。这里参考了glibc-2.25/malloc/malloc.c
中的代码(以x86_64系统为例子作说明）。以下是一个已经分配的thunk的示意图，它包
含2*SIZE_SZ大小的头部和用户数据部分。mem是用户数据的起点，也就是malloc返回给用
户的指针。

        chunk-> +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
                |   Size of previous chunk, if unallocated (P clear)  |
                +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
                |   Size of chunk, in bytes                     |A|M|P|
        mem->   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
                |   User data starts here...                          .
                .                                                     .
                .   (malloc_usable_size() bytes)                      .
                .                                                     |
    nextchunk-> +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
                |   (size of chunk, but used for application data)    |
                +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
                |   Size of next chunk, in bytes                |A|0|1|
                +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

此时thunk头部可用下面结构体表示：

    struct malloc_chunk {
      INTERNAL_SIZE_T      mchunk_prev_size;  /* Size of previous chunk (if free).  */
      INTERNAL_SIZE_T      mchunk_size;       /* Size in bytes, including overhead. */
    };
      
      
以下是一个已经回收的thunk的示意图，他的头部是4*SIZE_SZ大小(占用了原来2*SIZE_SZ大小
的用户数据部分,存放附近的两个thunk的指针fd和bk组成双向链表),

        chunk-> +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
                |   Size of previous chunk, if unallocated (P clear)  |
                +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        `head:' |   Size of chunk, in bytes                     |A|0|P|
          mem-> +-+--+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
                |   Forward pointer to next chunk in list             |
                +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
                |   Back pointer to previous chunk in list            |
                +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
                |   Unused space (may be 0 bytes long)                .
                .                                                     .
                .                                                     |
    nextchunk-> +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
        `foot:' |   Size of chunk, in bytes                           |
                +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
                |   Size of next chunk, in bytes                |A|0|0|
                +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

此时的thunk头部可用下面结构体表示：
    struct malloc_chunk {
      INTERNAL_SIZE_T      mchunk_prev_size;  /* Size of previous chunk (if free).  */
      INTERNAL_SIZE_T      mchunk_size;       /* Size in bytes, including overhead. */

      struct malloc_chunk* fd;         /* double links -- used only if free. */
      struct malloc_chunk* bk;
    };

另外，thunk是按照8字节对齐的，mchunk_size的低3位始终为0，所以另做其他用途，其中我
们需要关注mchunk_size的最低位P(PREV_INUSE)位表示前面一个thunk是否在使用中。另外，
当我们多次调用malloc的时，分配的thunk的地址也是连续的。

### free()分析

    static void _int_free (mstate av, mchunkptr p, int have_lock)
    {
        size = chunksize (p);
        
        // 是否要放在fastbins里，前面提到DEFAULT_MXFAST = 0x80
        if ((unsigned long)(size) <= (unsigned long)(get_max_fast ())
        {
            ...
        }
        // 我们主要是利用这里的代码逻辑来触发漏洞,所以我们malloc的内存大小要大于0x80
        else if (!chunk_is_mmapped(p))
        {
            ......
            
            /* consolidate backward */
            if (!prev_inuse(p)) {
                prevsize = prev_size (p);
                size += prevsize;
                p = chunk_at_offset(p, -((long) prevsize));
                unlink(av, p, bck, fwd);
            }
            ......
        } 
        else
        {
            // mmap分配的，通过munmap释放
            munmap_chunk(p);
        }
    }

### unlink分析

    /* Take a chunk off a bin list */
    #define unlink(AV, P, BK, FD) {                                            \
        FD = P->fd;                                   \
        BK = P->bk;                                   \
        if (__builtin_expect (FD->bk != P || BK->fd != P, 0))             \
          malloc_printerr (check_action, "corrupted double-linked list", P, AV);  \
        else {                                    \
            FD->bk = BK;                                  \
            BK->fd = FD;                                  \
            ......
          }                                       \
    }
    
unlink的作用就是把P从双向链表中移除，以便和旁边的合并，核心代码是下面四行：
    
    FD = P->fd;
    BK = P->bk;
    FD->bk = BK;
    BK->fd = FD;
    
单看这四行会有一个向内存任意位置写任意数据的机会，该利用方法在《0day安全》这本书
中被称为DWORD SHOOT。只要用自己的数据溢出到下一个thunk的fd即可实现让P->bk->fd = P->fd。
不过unlink宏还有段指针合法性检测代码：

    if (__builtin_expect (FD->bk != P || BK->fd != P, 0))
        malloc_printerr (check_action, "corrupted double-linked list", P, AV);

这样很难实现内存任意位置的写,不过还是可以有限的地址修改的（如：把mem改成&mem-0x18）。

## 3. shellman中漏洞的利用

mem是用户数据指针，我们在mem里伪造一个thunk头部，设置好

    fd_1 = &mem - 0x18;
    bk_1 =  &mem - 0x10;
    
然后溢出到下一个thunk，让prev_size = mem的大小，size的最低位(P)设为0，这样当我们
free(mem2)的时候会发生：

    FD = P->fd = &mem - 0x18;
    BK = P->bk = &mem - 0x10;
    
        thunk-> +--------------------------+
                | prev_size                |
                +--------------------------+
                | size                     |
          mem-> +--------------------------+ <-fake thunk
                | prev_size_1              |
                +--------------------------+
                | size_1                   |
                +--------------------------+
                | fd_1 = &mem - 0x18       |
                +--------------------------+
                | bk_1 = &mem - 0x10       |
                +--------------------------+
                |                          |
                .                          .
    nextchunk-> +--------------------------+
                | prev_size = size of mem  |
                +--------------------------+
                | size                 |P=0|
                +--------------------------+ <-mem2
                |                          |
                .                          .                
            
这样做配置即可满足 (FD->bk == P || BK->fd == P) 的检查,结果呢？
    
    FD->bk = BK; 即 P = &P - 0x10
    BK->fd = FD; 即 P = &P - 0x18
    
结果是把mem向前移动了0x18位置。结合shellman的情况mem = 0x6016b8，通过逆向
得出这里的内存布局情况如下：

     FD = P->fd +--------------------------+ <-0x6016b8
                |                          |
     BK = P->bk +--------------------------+ <-0x6016c0
                | sc_list[0].is_exist      |
                +--------------------------+ <-0x6016c8
                | sc_list[0].data_len      |
         &mem-> +--------------------------+ <-0x6016d0
                | sc_list[0].data_ptr      |
                +--------------------------+
                | sc_list[1].is_exist      |
                +--------------------------+
                | sc_list[1].data_len      |
                +--------------------------+
                | sc_list[1].data_ptr      |
                +--------------------------+
                |                          |
                .                          .
                
- edit_shellcode可以修改sc_list[0].data_ptr指针
- list_shellcode可以读取sc_list[0].data_ptr内容

接下来我们利用它修改GOT表中free项内容改成system函数地址，这样当
del_shellcode的时候就能调用system函数，可以得到一个shell。

### 得到system函数地址

接下去要考虑如何得到system函数地址，shellman中没有引用system函数，所以需要在当前
地址空间定位libc.so的system函数地址。

1. 用edit_shellcode把sc_list[0].data_ptr = GOT表的free项地址。
2. 用list_shellcode来获取free在当前地址空间的地址。
3. system = free - free在libc的虚拟地址 + system在libc的虚拟地址。

    [elemeta@emcos66x64 1]$ readelf -s /lib64/libc.so.6 | grep -e ' free$'
      7180: 0000003521c7b520   237 FUNC    GLOBAL DEFAULT   12 free
    [elemeta@emcos66x64 1]$ readelf -s /lib64/libc.so.6 | grep -e ' system$'
      5534: 0000003521c3e8f0    97 FUNC    WEAK   DEFAULT   12 system
    [elemeta@emcos66x64 1]$ 

4. 用edit_shellcode把GOT表的free项目内容改成system的地址
5. 完成!

*利用代码请看附件中的：shellman-exp.py*

## 4. shellman-exp.py

### 我的实验方法

1.模拟某服务器上的服务端程序提供shellman服务

    [root@emcos66x64 bin]# rm -f /tmp/f; mkfifo /tmp/f
    [root@emcos66x64 bin]# cat /tmp/f | /home/elemeta/1/shellman.b400c663a0ca53f1f6c6fcbf60defa8d -i 2>&1 | nc -l 127.0.0.1 1234 > /tmp/f

2.利用堆溢出漏洞得到该服务器的shell

    [elemeta@emcos66x64 1]$ ./shellman-exp.py

    
## 5. 总结

1.该题目主要考察对libc中unlink时候堆溢出的理解以及对shellman程序的理解。

2.如何修补shellman,在edit_shellcode函数中加上堆数据长度的检查应该就能防止利用了。
    
    if (_len > sc_list[_sc_idx].data_len) {
        free(sc_list[_sc_idx].data_ptr);
        sc_list[_sc_idx].data_ptr = malloc(_len);
        sc_list[_sc_idx].data_len = _len;
    }
 
 3.对libc堆内存管理的思考
 
 - 当前版本的堆内存的管理方式是连续分配的，内存块是紧挨者的，很容易猜测出下一个
   thunk的地址，如果让攻击者猜不出下一个thunk的位置应该能提高一些安全性，我们可
   以加入一些随机性。比如事先定义几个zone，每次随机选择一个zone分配内存；又比如
   引入ASLR让thunk不是紧挨着的；又或者使用索引表的方式管理thunk，等等。
 - unlink中 如果将FD->bk = BK; BK->fd = FD两行代码的位置调换一下，这样只能实
   现P=&P-0x10,在实际运用中可能会好上那么一丢丢。
    
## 6.参考

- http://winesap.logdown.com/posts/258859-0ctf-2015-freenode-write-up
- https://segmentfault.com/a/1190000005655132
- malloc/malloc.c (http://ftp.gnu.org/gnu/glibc/glibc-2.25.tar.xz)
