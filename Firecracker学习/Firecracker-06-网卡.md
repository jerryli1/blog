## virtio-net

网卡处理的数据包是二层协议，叫数据帧(Frame)，MAC地址作为Key。
Virtio网络设备协议：<https://docs.oasis-open.org/virtio/virtio/v1.1/csprd01/virtio-v1.1-csprd01.html#x1-1940001>

### 配置空间

```c
struct virtio_net_config { 
    // Host设置一个网卡MAC地址，如果Host不设置，Guest就随机分配一个
    u8 mac[6]; 
    
    // 下面Firecracker没实现
    le16 status; 
    le16 max_virtqueue_pairs; 
    le16 mtu; 
};
```
### 队列

Firecracker不支持`VIRTIO_NET_F_MQ`和`VIRTIO_NET_F_CTRL_VQ `，所以只有两个队列:**receiveq1**和**transmitq1**。

```c
struct virtio_net_hdr { 
    u8 flags; 
    u8 gso_type; 
    le16 hdr_len; 
    le16 gso_size; 
    le16 csum_start; 
    le16 csum_offset; 
    le16 num_buffers;  // Firecracker始终是1
};
// 紧跟在后面的是packet
```

## 后端设备

Firecracker后端使用[tun/tap](https://www.kernel.org/doc/Documentation/networking/tuntap.txt)作为虚拟网桥配合iptables转发规则实现Guest网络和外网的通信。

如何配置网络见文档：<https://github.com/firecracker-microvm/firecracker/blob/main/docs/network-setup.md>。

### Guest发包(Tx)过程

```python
# guest报文加入transmitq1  -> host将报文转给tap虚拟网桥 -> iptabes转发给真实网卡

Guest驱动：
	数据包发给到transmitq1队列

Host后端：
	Net::process_tx_queue_event
		-> process_tx
			-> tx_iovec.push() # 循环取出所有的virtio_net_hdr,加入tx_iovec
            -> tx_frame_buf()  # 从virtio_net_hdr提取二层协议数据(frame)加入tx_frame_buf中
            -> write_to_mmds_or_tap() # 把数据交给Host的虚拟网卡
```
### Guest收包(Rx)过程

```python
# 真实网卡收包 -> iptables转发给tap虚拟网卡  -> host将报文加入receiveq1 -> guest驱动处理

Host后端：
	Net::process_tap_rx_event
		-> process_rx
        	-> read_from_mmds_or_tap
            	-> tap.read()        # 从tap收数据
            -> rate_limited_rx_single_frame
            -> write_frame_to_guest  # 数据加到receiveq1
            	-> do_write_frame_to_guest
            -> signal_rx_used_queue  # 通知队列
```

### MMDS

全称：[microVM Metadata Service](https://github.com/firecracker-microvm/firecracker/tree/main/docs/mmds)，这是Firecarcker自己搞的一个Guest和Host通信的方法。

1. 本质上是在虚拟网卡上Hook一道
2. 启动VM前配置一个特定的IP地址，默认是`169.254.169.254`。
3. Guest内的程序connect这个IP就能和Host通信。

> 另外，virtio-vsock也是实现Guest与Host通信的机制。



