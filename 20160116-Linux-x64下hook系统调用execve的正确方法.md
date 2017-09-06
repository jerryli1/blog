# Linux x64下hook系统调用execve的正确方法

## 1.概述

Linux下hook内核execve系统调用的方法有很多：

1. 可以使用inline-hook，将`sys_execve`函数头部修改成jmp指令跳转到我们自己hook函数；
2. 可以使用内核本身的kprobes功能，内核需包含`CONFIG_KPROBES`编译选项；
3. 还可以使用hook系统调用表的方法，替换其中`__NR_execve`项为我们的hook函数的地址。

本文介绍一下采用hook系统调用表项的方法该如何实现。

## 2.问题

一般的hook系统调用表项代码要这样写(伪代码)

	asmlinkage long my_execve_hook64(const char __user *filename,
	                                 const char __user *const __user *argv,
	                                 const char __user *const __user *envp)
	{
		long rc;
		
		rc = do_something(filename, argv, envp);
		if (0 != rc)
		    return rc; /* 拦截execve */
		
		return orig_execve(filename, argv, envp); /* 执行原来的execve路径 */
	}
	
	void execve_hook_init(void)
	{
		unsigned long *sct;
		
		sct = get_sys_call_table();
		
		make_kernel_page_readwrite();
		preempt_disable();
		
		orig_execve = (void *)sct[__NR_execve];
		sct[__NR_execve] = (unsigned long)my_execve_hook64;
		
		preempt_enable();
		make_kernel_page_readonly();
	}

在x64系统中，我们按照上面思路写好我们的内核模块并加载，结果却发现任何操作都会导致Segment fault错误！看来这种方式有些不对。

## 3.分析

这里以我的CentOS 7.2(3.10.0-327.3.1.el7.x86_64)为例来分析一下execve的调用路径：

	(Ring3)sysenter -> (Ring0)system_call -> stub_execve -> sys_execve
	
来看看stub_execve函数：

    (gdb) disassembl stub_execve
    Dump of assembler code for function stub_execve:
       0xffffffff81715010 <+0>:     add    $0x8,%rsp       # 相当于把call stub_execve变成了jmp stub_execve
       0xffffffff81715014 <+4>:     sub    $0x30,%rsp      # SAVE_REST
       0xffffffff81715018 <+8>:     mov    %rbx,0x28(%rsp)
       0xffffffff8171501d <+13>:    mov    %rbp,0x20(%rsp)
       0xffffffff81715022 <+18>:    mov    %r12,0x18(%rsp)
       0xffffffff81715027 <+23>:    mov    %r13,0x10(%rsp)
       0xffffffff8171502c <+28>:    mov    %r14,0x8(%rsp)
       0xffffffff81715031 <+33>:    mov    %r15,(%rsp)
       0xffffffff81715035 <+37>:    mov    %gs:0xaf80,%r11 # FIXUP_TOP_OF_STACK
       0xffffffff8171503e <+46>:    mov    %r11,0x98(%rsp)
       0xffffffff81715046 <+54>:    movq   $0x2b,0xa0(%rsp)
       0xffffffff81715052 <+66>:    movq   $0x33,0x88(%rsp)
       0xffffffff8171505e <+78>:    movq   $0xffffffffffffffff,0x58(%rsp)
       0xffffffff81715067 <+87>:    mov    0x30(%rsp),%r11
       0xffffffff8171506c <+92>:    mov    %r11,0x90(%rsp)
       0xffffffff81715074 <+100>:   callq  0xffffffff8123a150 <SyS_execve>   # 调用sys_execve
       0xffffffff81715079 <+105>:   mov    %rax,0x50(%rsp)
       0xffffffff8171507e <+110>:   mov    (%rsp),%r15     # RESTORE_REST
       0xffffffff81715082 <+114>:   mov    0x8(%rsp),%r14
       0xffffffff81715087 <+119>:   mov    0x10(%rsp),%r13
       0xffffffff8171508c <+124>:   mov    0x18(%rsp),%r12
       0xffffffff81715091 <+129>:   mov    0x20(%rsp),%rbp
       0xffffffff81715096 <+134>:   mov    0x28(%rsp),%rbx
       0xffffffff8171509b <+139>:   add    $0x30,%rsp
       0xffffffff8171509f <+143>:   jmpq   0xffffffff81714c70 <int_ret_from_sys_call>
    End of assembler dump.

这不是一个符合gcc调用约定的函数。我们上面的hook方法必定导致栈不平衡，从而导致错误。

## 4.解决

看来我们要自己平衡一下栈了，我们也要写一个`stub_execve`函数来间接调用hook函数，这个函数要用汇编来写：

	/**
	 * @filename my_stub_execve_64.S
	 */
	 
	.text
	.globl  my_stub_execve_hook64
	.type   my_stub_execve_hook64, @function
	
	my_stub_execve_hook64:
	    /**
	     * 保存寄存器状态, 保证之后调用原来的stub_execve的时候CPU执行环境一致
	     * 其中rdi,rsi,rdx,rcx,rax,r8,r9,r10,r11保存sysenter的参数，rbx作为临时变量
	     */
	    pushq   %rbx
	    pushq   %rdi
	    pushq   %rsi
	    pushq   %rdx
	    pushq   %rcx
	    pushq   %rax
	    pushq   %r8
	    pushq   %r9
	    pushq   %r10
	    pushq   %r11
	
		/* 调用自己的hook函数 */
	    call    my_execve_hook64
	    test    %rax, %rax
	    movq    %rax, %rbx
	
	    /* 恢复寄存器状态 */
	    pop     %r11
	    pop     %r10
	    pop     %r9
	    pop     %r8
	    pop     %rax
	    pop     %rcx
	    pop     %rdx
	    pop     %rsi
	    pop     %rdi
	
	    jz      my_stub_execve_hook64_done
	    
	    /* my_execve_hook64返回值为非0时 */
	    movq    %rbx, %rax
	    pop     %rbx
	    ret   /* 这里不一定要jmp int_ret_from_sys_call，反正execve已经被我们拦截了 */
	    
	    /* my_execve_hook64返回值为0时 */
	my_stub_execve_hook64_done:
	    pop     %rbx
	    jmp     *orig_sys_call_table(, %rax, 8) /* 调用orig_execve, 既stub_execve */

然后使用`my_stub_execve_hook64`函数来替换系统调用表中的`__NR_execve`项即可：

	extern long my_stub_execve_hook64(char *, char **, char **);
	......
	orig_execve = (void *)sct[__NR_execve];
	sct[__NR_execve] = (unsigned long) my_stub_execve_hook64;

hook以后的调用路径如下：

	(Ring3)sysenter -> (Ring0)system_call -> my_stub_execve_hook64 
	          -> my_execve_hook64 -> stub_execve -> sys_execve
	
## 5.参考资料

[http://stackoverflow.com/questions/8372912/hooking-sys-execve-on-linux-3-x](http://stackoverflow.com/questions/8372912/hooking-sys-execve-on-linux-3-x)

[http://lxr.free-electrons.com/source/arch/x86/kernel/entry_64.S?v=3.10#L877](http://lxr.free-electrons.com/source/arch/x86/kernel/entry_64.S?v=3.10#L877)