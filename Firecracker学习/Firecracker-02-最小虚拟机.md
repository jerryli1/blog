在深入Firecarcker内部之前，先来编写一个最简单的虚拟机，它只有CPU和内存。大致步骤如下：

1. 创建KVM实例
2. 创建VM实例
3. 插上内存条
4. 把要执行的代码放到Guest内存里。
5. 创建CPU并初始化寄存器
6. 启动CPU

## Cargo.toml

```toml
[package]
name = "minivm"
version = "0.1.0"
authors = ["xrw"]
edition = "2018"

# See more keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html

[dependencies]
kvm-ioctls = "*"
kvm-bindings = "*"
libc = "*"
```

## main.rs

```rust
extern crate kvm_bindings;
extern crate kvm_ioctls;

use std::io::Write;
use std::ptr::null_mut;
use std::slice;

use libc;

use kvm_ioctls::Kvm;
use kvm_ioctls::VcpuExit;

use kvm_bindings::kvm_userspace_memory_region;

fn main() {
    // Guest的物理内存范围是0x1000 - 0x5000,这个范围外的作为MMIO地址
    let guest_addr = 0x1000;
    let mem_size = 0x4000;

    // 开机要执行的代码（实模式）
    let asm_code = [
        0xba, 0xf8, 0x03, /* mov $0x3f8, %dx */
        0x00, 0xd8, /* add %bl, %al */
        0x04, b'0', /* add $'0', %al */
        0xee, /* out %al, %dx, 输出al + bl */
        0xec, /* in %dx, %al */
        0xc6, 0x06, 0x00, 0x80, 0x00, /* movl $0, (0x8000); 执行MMIO Write.*/
        0x8a, 0x16, 0x00, 0x80, /* movl (0x8000), %dl; 执行MMIO Read.*/
        0xf4, /* hlt */
    ];

    // 1. 创建KVM实例
    let kvm = Kvm::new().unwrap();

    // 2. 创建一个VM
    let vm = kvm.create_vm().unwrap();

    // 3. 创建内存条

    // 先Host上映射一块内存
    let load_addr: *mut u8 = unsafe {
        libc::mmap(
            null_mut(),
            mem_size,
            libc::PROT_READ | libc::PROT_WRITE,
            libc::MAP_ANONYMOUS | libc::MAP_SHARED | libc::MAP_NORESERVE,
            -1,
            0,
        ) as *mut u8
    };

    // 把内存插到VM中
    let mem_region = kvm_userspace_memory_region {
        slot: 0, // Slot 0
        guest_phys_addr: guest_addr,
        memory_size: mem_size as u64,
        userspace_addr: load_addr as u64,
        flags: 0,
    };
    unsafe { vm.set_user_memory_region(mem_region).unwrap() }

    // 把Guest运行的代码放到内存中
    unsafe {
        let mut slice = slice::from_raw_parts_mut(load_addr, mem_size);
        slice.write(&asm_code).unwrap();
    }

    // 创建vCPU
    let vcpu_fd = vm.create_vcpu(0).unwrap();

    // 初始化特殊寄存器(sregs, special registers)
    let mut vcpu_sregs = vcpu_fd.get_sregs().unwrap();
    vcpu_sregs.cs.base = 0;
    vcpu_sregs.cs.selector = 0;
    vcpu_fd.set_sregs(&vcpu_sregs).unwrap();

    // 初始化通用寄存器
    let mut vcpu_regs = vcpu_fd.get_regs().unwrap();
    vcpu_regs.rip = guest_addr; // 设置开机执行的第一行代码。
    vcpu_regs.rax = 2;
    vcpu_regs.rbx = 3;
    vcpu_regs.rflags = 0x2;
    vcpu_fd.set_regs(&vcpu_regs).unwrap();

    // 开机，执行vCPU
    loop {
        match vcpu_fd.run().expect("run failed") {
            // IO读事件
            VcpuExit::IoIn(addr, data) => {
                println!(
                    "Received an I/O in exit. Address: {:#x}. Data: {:#x}",
                    addr, data[0]
                );
            }
            // IO写事件
            VcpuExit::IoOut(addr, data) => {
                println!(
                    "Received an I/O out exit. Address: {:#x}. Data: {:#x}",
                    addr, data[0]
                );
            }
            // MMIO读事件
            VcpuExit::MmioRead(addr, _data) => {
                println!("Received an MMIO Read Request for the address {:#x}.", addr);
            }
            // MMIO写事件
            VcpuExit::MmioWrite(addr, _data) => {
                println!("Received an MMIO Write Request to the address {:#x}.", addr);
            }
            // 关机
            VcpuExit::Hlt => {
                break;
            }
            r => panic!("Unexpected exit reason: {:?}", r),
        }
    }
}
```

## 参考

https://lwn.net/Articles/658511/

https://docs.rs/kvm-ioctls/0.8.0/kvm_ioctls/