本文以x86_64为例看看Firecracker创建虚拟机的细节。

## 架构

先看官网文档：https://github.com/firecracker-microvm/firecracker/blob/master/docs/design.md

![image-20210402154648948](_images/firecracker-arch.png)

## KVM

KVM在内核中实现了虚拟的CPU、内存管理、中断控制器、时钟设备，这不仅高性能，还大大简化了应用层VMM的开发难度。Firecracker使用开源库[kvm-ioctls](https://github.com/rust-vmm/kvm-ioctls)来操作KVM。

> 避免重复造轮子，CrosVM和Firecracker作者提取通用的部分成立新项目[rust-vmm](https://github.com/rust-vmm)，两个项目都引用它。

## 流程

以x86_64为例，src/vmm/src/builder.rs文件里的`build_microvm_for_boot()`函数是总入口。创建虚拟机流程大致如下：

1. 创建内存
2. 创建vCPU和虚拟中断控制器
3. 创建传统设备(Port I/0)
4. 创建Virtio设备(MMIO)
5. 启动虚拟机，分子线程运行每个vCPU。

```yaml
build_microvm_for_boot
	->create_guest_memory     # 创建Guest内存条
		-> arch::arch_memory_regions()    # 创建x86_64内存条数组
		-> GuestMemoryMmap::from_ranges() # mmap()分配内存空间
	->load_kernel             # 装载vmlinux到内存
	->load_initrd_from_config # 装载initrd到内存(如果有)
	->create_vmm_and_vcpus
		->setup_kvm_vm
			->KvmContext::new()   # 创建kvm实例
			->Vm::new()           # 创建vm实例
			->vm.memory_init()    # 将之前的内存条插入到KVM中
		->setup_interrupt_controller
			->Vm::setup_irqchip()
		    	->x86_64::create_irq_chip # 创建8259A及IOPAIC+LAPIC中断控制器
		    	->x86_64::create_pit2     # 创建虚拟时钟设备(i8254, KVM_CREATE_PIT2)
		->create_vcpus                # 创建vCPU
		->setup_serial_device # 创建一个绑定当前stdin和stdout的串口设备
		->create_pio_dev_manager_with_legacy_devices # 注册串口和键盘设备
	# 下面都是MMIO设备
	->attach_boot_timer_device # 注册BotTimer设备，用来记录启动时间
	->attach_balloon_device    # 注册内存气球后端
	->attach_block_devices     # 注册块设备
	->attach_net_devices       # 注册网卡
	->attach_unixsock_vsock_device # 注册vsock后端
	
	# 启动cpu前的配置
	->configure_system_for_boot
		->kvm_vcpu.configure               # / 对每个CPU的配置
		    ->set_cpuid_entries            # | 绑定CPUID内容
		    ->VcpuFd::set_cpuid2
		    ->x86_64::msr::setup_msrs      # | 绑定MSR内容
		    ->x86_64::regs::setup_regs     # | 设置通用寄存器
		    ->x86_64::regs::setup_fpu      # | 初始化FPU
		    ->x86_64::regs::setup_sregs    # | 设置特殊寄存器
		        ->configure_segments_and_sregs # 初始化x64的保护模式上下文
		        ->setup_page_tables            # 初始化一个临时用的页表机制
		    ->x86_64::interrupts::set_lint # | 设置LAPIC
		->kernel::loader::load_cmdline
		->x86_64::configure_system
		    ->mptable::setup_mptable # 填充MP Table到内存0x9fc00位置(MP Spec v1.4)
		    ->add_e820_entry         # 填充E820到内存
		    -> 填充boot_params到ZERO_PAGE_START
	->vmm.start_vcpus
		->vcpu.set_mmio_bus         # 绑定MMIO总线
		->vcpu.kvm_vcpu.set_pio_bus # 绑定PIO总线
		->vcpu.start_threaded   # 创建vCPU线程，初始状态是[Paused]
	->SeccompFilter::apply    # 给每个vCPU线程设置seccomp限制
	->vmm.resume_vm()         # 激活vCPU,进入[Resume]状态，进入Vcpu::running()
	->event_manager.add_subscriber(vmm) # 主线程订阅VMM的eventfd事件
```
## 创建内存

KVM可以插入多条内存条，每个插槽(Slot)指定一个物理地址和大小。内存区域的定义如下：

```c
struct kvm_userspace_memory_region {
	__u32 slot;
	__u32 flags;
	__u64 guest_phys_addr; /* Guest中看到的物理地址 */
	__u64 memory_size; /* bytes */
	__u64 userspace_addr; /* start of the userspace allocated memory */
};
```

根据虚拟机内存大小最多会创建两个Slot：

```sh
# 客户机物理地址
[0x0,        0xcfffffff]  # Slot 0，lowmem
[0x100000000, 剩余的大小 ] # Slot 1，highmem

# 该物理地址保留作为MMIO地址(3.25GB - 4GB)
[0xd0000000, 0xffffffff] 
```



## 如何启动Linux

Firecracker没有BIOS或UEFI，它只支持ELF格式的vmlinux。它的方法是在开机之前直接把vmlinux给塞到内存并设置入口函数为CPU执行的第一行代码。

### load_kernel

以下是ELF格式的Program Headers：

```sh
➜  hello readelf -lW hello-vmlinux.bin

Entry point 0x1000000
There are 5 program headers, starting at offset 64

Program Headers:
Type  Offset    VirtAddr           PhysAddr           FileSiz  MemSiz   Flg Align
LOAD  0x200000  0xffffffff81000000 0x0000000001000000 0xb6e000 0xb6e000 R E 0x200000
LOAD  0xe00000  0xffffffff81c00000 0x0000000001c00000 0x0aa000 0x0aa000 RW  0x200000
LOAD  0x1000000 0x0000000000000000 0x0000000001caa000 0x01f6d8 0x01f6d8 RW  0x200000
LOAD  0x10ca000 0xffffffff81cca000 0x0000000001cca000 0x125000 0x40c000 RWE 0x200000
NOTE  0xa031d4  0xffffffff818031d4 0x00000000018031d4 0x000024 0x000024     0x4
```

把所有LOAD段加载到Guest内存（PhysAddr和GPA一一对应加载）， `ehdr.e_entry`作为CPU执行的第一行代码。

### 初始化保护模式

在开机之前，还要设置好保护模式（GDT、IDT、页表），方法是硬编码内存布局和寄存器初始值。代码见`kvm_vcpu.configure`函数。

- **CPU上下文**

```sh
# GDT
#                   flags   base  limit
gdt_table[0]  NULL  0       0     0
gdt_table[1]  CODE  0xa09b  0     0xfffff
gdt_table[2]  DATA  0xc093  0     0xfffff
gdt_table[3]  TSS   0x808b  0     0xfffff

# 通用寄存器
rflags = 2
rip = vmlinux::ehdr.e_entry
rsp = rbp = 0x8ff0 # 初始化临时栈桢，BOOT_STACK_POINTER
rsi = 0x7000       # Linux要求的 ZERO_PAGE_START

# 特殊寄存器
sregs.gdt.base = 0x500
sregs.gdt.limit = 31
sregs.idt.base = 0x520
sregs.idt.limit = 7
sregs.cs = code_seg;
sregs.ds = sregs.es = sregs.fs = sregs.gs = sregs.ss = data_seg;
sregs.tr = tss_seg;
sregs.cr0 = X86_CR0_PE | X86_CR0_PG
sregs.cr3 = 0x9000
sregs.cr4 |= X86_CR4_PAE
sregs.efer |= EFER_LME | EFER_LMA; # 虚拟机的LMA必须自己设置
```

- **临时页表**

    Firecracker临时制作了个支持512MB内存的页表，页大小是2MB，

    ```
                 CR3 = 0x9000
    一级：PML4    PML4[0] = 0xa000
    二级：PDP     PDP[0]  = 0xb000
    三级：PDE     PDE[0]
    ```

    

- **内存布局**

```
             +------------------+
0            |                  |
0x500        | GDT[4]           |
0x520        | IDT[...]         |
0x7000       | boot_params      |
0x9000       | PML4 Table       |
0xa000       | PDP Table        |
0xb000       | PDE Table        |
0x20000      | cmdline          |
0x9fc00      | MP Table         |
0x1000000    | vmlinux          |
```

- **e820**

```sh
# e820包含再boot_params中
BIOS-e820: [mem 0x0000000000000000-0x000000000009fbff] usable
# <-- 跳过了MP Table的地址范围
BIOS-e820: [mem 0x0000000000100000-0x00000000cfffffff] usable、
# <-- 跳过了MMIO地址范围
BIOS-e820: [mem 0x0000000100000000-剩余的大小         ] usable
```

- **MP table**

函数：`setup_mptable`

遵循Intel的MP Spec 1.4协议填充即可，把内容放到GPA=0x9fc00位置后linux会自己去调用，内存布局如下：

```
+--------------------------+
| mpf_intel                |
+--------------------------+ 
| mpc_table                |
+--------------------------+
| mpc_cpu * NCPU           | <- 设置LAPIC ID, 把cpu0设为启动CPU
+--------------------------+
| mpc_bus                  |
+--------------------------+
| mpc_ioapic               |
+--------------------------+
| mpc_intsrc * (IRQ_MAX+1) |
+--------------------------+
| mpc_lintsrc * 2          |
+--------------------------+
```