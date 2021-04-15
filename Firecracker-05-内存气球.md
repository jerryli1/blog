## 功能

内存气球实现动态管理Guest内存(内存超卖，拆东墙补西墙)。

## 原理

在Guest物理内存里放一个气球，气球内的内存可以被Host拿走再利用。

- 膨胀(inflate)：Guest内存被Host给拿走。

- 压缩(deflate)：Host归还内存给Guest。

## 后端设备

- 协议说明文档：<https://docs.oasis-open.org/virtio/virtio/v1.1/csprd01/virtio-v1.1-csprd01.html#x1-2790005>。

- Balloon管理的单位是4K页。
- Balloon配置空间就两个寄存器：

```c
struct virtio_balloon_config {
	// Host发起:动态设置气球大小
    le32 num_pages; 
    // Guest发起：记录当前真实的气球大小
    le32 actual; 
};
```

### 设置气球大小

Firecracker提供API来改变气球大小，见：<https://github.com/firecracker-microvm/firecracker/blob/master/docs/ballooning.md#operating-the-balloon-device>。

如果num_pages大于actual则Guest驱动充气，否则什么也不做。

```rust
update_balloon_config
	->self.get_bus_device // 得到设备实例
	-> update_size() // 更新气球大小
	-> interrupt() // 通知Guest驱动
```



### 膨胀气球

Guest发起请求。主动上报多余的Guest物理页索引(pfn)，Host释放这些内存。

```rust
// src/devices/src/virtio/balloon
process_inflate()
	-> 从self.queues[INFLATE_INDEX]的avail区域获取所有的pfn数据
	-> compact_page_frame_numbers //对pfn数据进行排序+合并
	-> remove_range// Host拿走这些pfn
		-> GPA转换成HVA
    	-> 如果是膨胀，使用madvise(MADV_DONTNEED)把内存从Guest拿走
	-> queue.add_used() //处理used区域
	-> self.signal_used_queue
```

### 压缩气球

**什么也不做**。`madvise(MADV_DONTNEED)`只释放了页表，并没有释放虚拟地址空间。Firecracker并没有使用`VIRTIO_BALLOON_F_MUST_TELL_HOST `,VMM自己通过缺页中断重新分配物理内存。

## Guest前端驱动

文章<https://cloud.tencent.com/developer/article/1087348>介绍了Guest中balloon驱动代码。

```c
update_balloon_size_func
    // 从配置空间获取num_pages和当前气球大小比较
    -> diff = towards_target(vb);
    -> if (diff > 0) diff -= fill_balloon(vb, diff); // 充气
    -> else diff += leak_balloon(vb, -diff);         // 放气
    -> update_balloon_size(vb); // 更新配置空间的acrual
    // 如果没有处理完，加入队列继续处理
    -> if (diff) queue_work(system_freezable_wq, work);
```

充气

```c
fill_balloon
	-> balloon_page_enqueue // 取一个空闲的page过来
    -> set_page_pfns        // 得到物理页pfn
    -> tell_host            // inflate队列通知Host
```



