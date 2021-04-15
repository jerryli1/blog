@(security)[Windows, Minifilter]

# FltSetSecurityObject引起的Win2003Sp2死锁分析

> 2015-09-24, beijing, @elemeta
> 原创作者：shadow3、elemeta

## 0x00 前言

Minifilter是微软提供的开发Windows文件过滤驱动的一个框架，像安全防护类软件都有用到它。我们在客户的环境里发现了一个由fltmgr导致服务管理器死锁的bug。客户的环境是Win2003 SP2 x64，该服务器上安装了椒图的主机加固产品和某杀毒软件。问题来了，每次杀毒软件更新的时候都会导致服务器黑屏。经过我们排查发现是服务管理器的某个线程在等待杀毒软件的驱动卸载完成，但该线程一直无法完成卸载，好像是死锁了。最后我们找到了FltSetSecurityObject函数导致了死锁。

## 0x01 FltSetSecurityObject 实现原理

FltSetSecurityObject函数是FltMgr中的一个函数，它用来设置对象的ACL，它的函数原型为

	NTSTATUS FltSetSecurityObject(
	    IN PFLT_INSTANCE  Instance,
	    IN PFILE_OBJECT  FileObject,
	    IN SECURITY_INFORMATION  SecurityInformation,
	    IN PSECURITY_DESCRIPTOR  SecurityDescriptor);

该函数从Windows 2000就提供了，但是从Windows Vista开始才支持，之前的版本如果调用该函数会返回错误码`STATUS_NOT_IMPLEMENTED`表示该Windows版本不支持这个功能。详见MSDN的说明: https://msdn.microsoft.com/en-us/library/windows/hardware/ff544538(v=vs.85).aspx。

我们以Windows 2003 SP2 X86(3790)下的fltmgr.sys(md5:f978277ef786532195cdd9f88e908632)作为分析对象，先看看FltSetSecurityObject函数的实现

	NTSTATUS FltSetSecurityObject(
	    IN PFLT_INSTANCE  Instance,
	    IN PFILE_OBJECT  FileObject,
	    IN SECURITY_INFORMATION  SecurityInformation,
	    IN PSECURITY_DESCRIPTOR  SecurityDescriptor)
	{
	    NTSTATUS Status;
	    PFLT_CALLBACK_DATA CallbackData;
	    Status = FltAllocateCallbackData(Instance, FileObject, &CallbackData);
	    if (NT_SUCCESS(Status)) {
	        CallbackData->Iopb->MajorFunction = IRP_MJ_SET_SECURITY;
	        CallbackData->Iopb->Parameters.SetSecurity.SecurityInformation = SecurityInformation;
	        CallbackData->Iopb->Parameters.SetSecurity.SecurityDescriptor = SecurityDescriptor;
	        FltPerformSynchronousIo(CallbackData);
	        Status = CallbackData->IoStatus.Status;
	        FltFreeCallbackData(CallbackData);
	    }
	
	    return Status;
	}

该函数发起一个类型为`IRP_MJ_SET_SECURITY`的同步I/O操作。我们继续分析关键的FltPerformSynchronousIo函数,我们只看关键的部分

	status = FltpSetupPerformIo(IrpCtrl, 1, 0, 0, &callbackNode);
	  if (NT_SUCCESS(status)) {
	      irp = IrpCtrl->Irp;
	      IrpCtrl->Flags |= IRPCTRFL_SYNCHRONIZE;
	      v6 = FltpPassThroughInternal(&v7, 0u);
	      if (v12 & 4)
	          FltpLegacyProcessingAfterPreCallbacksCompleted(&v7, v6, 0);
	      FltObjectDereference(instance);
	  } else {
	      FltObjectDereference(instance);
	      callbackData->IoStatus.Information = 0;
	      callbackData->IoStatus.Status = status;
	  }

这里调用了关键函数FltpSetupPerformIo,该函数用来构造一个IRP，我们继续分析该函数FltpSetupPerformIo

	if (irpCtrl->Flags & IRPCTRFL_SYNC_IO_TO_INITIATING_INSTANCE)
	    *CallbackNode = FltpGetCallbackNodeForInstance(instance, majorIndex);
	
	if (!*CallbackNode)
	    *CallbackNode = FltpGetNextCallbackNodeForInstance(instance, majorIndex, FALSE);
	
	if (!IsIrpAllocated) {
	    if (!irpCtrl->Irp) {
	        irp = IoAllocateIrp(irpCtrl->DeviceObject->StackSize, FALSE);
	        if (!irp)
	            return STATUS_INSUFFICIENT_RESOURCES;
	        BYTE3(irpCtrl->Flags) |= IRP_QUOTA_CHARGED;
	        irpCtrl->Irp = irp;
	    }
	    status = FltpInitializeGeneratedIrp(irpCtrl, a2, UserIosb);
	}

这里有两个关键步骤：
1. 首先查找`MJ_IRP_SET_SECURITY`的处理函数，
2. 然后初始化一个IRP。我们先看看初始化IRP的函数FltpInitializeGeneratedIrp

		switch (IrpCtrl->Data.Iopb->MajorFunction) {
		    case 0x00:     // IRP_MJ_CREATE
		    case 0x01:     // IRP_MJ_CREATE_NAMED_PIPE
		    case 0x11:     // IRP_MJ_LOCK_CONTROL
		    case 0x13:     // IRP_MJ_CREATE_MAILSLOT
		    case 0x15:     // IRP_MJ_SET_SECURITY
		    case 0x17:     // IRP_MJ_SYSTEM_CONTROL
		    case 0x19:     // IRP_MJ_QUERY_QUOTA
		    case 0x1A:    // IRP_MJ_SET_QUOTA
		    case 0x1B:    //IRP_MJ_PNP
		        return 0xC0000002;     // STATUS_NOT_IMPLEMENTED
		……
		}

因为 `MajorFunction = IRP_MJ_SET_SECURITY(0x15)`，返回错误码`STATUS_NOT_IMPLEMENTED`，FltSetSecurityObject函数到这里就执行完毕了。

## 0x02 发现BUG

我们先梳理下上文提到的几个函数的调用关系：

![函数关系图](_images/20150924-FltSetSecurityObject-calltree.png)

上面还有一个关键代码没有分析，就是查找`MJ_IRP_SET_SECURITY`的处理函数的部分，FltpGetCallbackNodeForInstance和FltpGetNextCallbackNodeForInstance函数，下面看看这两个函数的代码。

**FltpGetCallbackNodeForInstance**

	_CALLBACK_NODE *__stdcall FltpGetCallbackNodeForInstance(PFLT_INSTANCE Instance, int MajorIndex)
	{
	    PCALLBACK_NODE Callback;
	    Callback = Instance->CallbackNodes[MajorIndex];
	    if (Callback && FltpExAcquireRundownProtectionCacheAwareEx(Instance->OperationRundownRef, 1))
	        return Callback;
	    else
	        return NULL;
	}

**FltpGetNextCallbackNodeForInstance**

	v5 = Instance->Base.PrimaryLink.Flink;
	
	while (v5 != &Instance->Volume->InstanceList.rList) {
	    if (!(v5->Flags & 6)) {
	        callbackNode = (_CALLBACK_NODE *)*((_DWORD *)&v5[4].PostOperation + MajorIndex);
	        if (callbackNode){
	            if (IsAsyncIo)
	                goto async_end;
	            if (FltpExAcquireRundownProtectionCacheAwareEx(v5->Instance, 1))
	                goto sync_end;
	        }
	        callbackNode = NULL;
	    }
	    v5 = v5->CallbackLinks.Flink;
	}

这里我们发现FltpGetNextCallbackNodeForInstance为下层的过滤驱动的实例增加了锁。但是我们在前面FltpSetupPerformIo函数中直接返回了错误码`STATUS_NOT_IMPLEMENTED`，而且并没有释放锁。这样任何执行FltpObjectRundownWait函数的内核线程将会无限期等待，导致死锁。

## 0x03 总结

结合之前我们在客户服务器上遇到的问题，当杀毒软件更新的时候，会有卸载自身防护驱动的过程。当卸载Minifilter过滤驱动的时候一般是通过服务管理器来通知内核调用FltUnregisterFilter函数，该函数就会调用FltpObjectRundownWait导致内核线程死锁，从而导致服务管理器死锁，最终任何依赖服务管理器的进程都死锁，造成拒绝服务。

另外从FltpInitializeGeneratedIrp函数的代码中我们看到除了`IRP_MJ_SET_SECURITY` ，还有`IRP_MJ_CREATE`、`IRP_MJ_CREATE_NAMED_PIPE`、`IRP_MJ_LOCK_CONTROL`、`IRP_MJ_CREATE_MAILSLOT`、`IRP_MJ_SYSTEM_CONTROL`、`IRP_MJ_QUERY_QUOTA`、 `IRP_MJ_SET_QUOTA`、`IRP_MJ_PNP`也是未实现的。

## 0x04 如何触发BUG

这里给出触发bug的代码和方法，我们修改WDK中的PassThrough例子来写一个test驱动:

	FLT_POSTOP_CALLBACK_STATUS
	PtPostOperationPassThroughWithBug (
	    __inout PFLT_CALLBACK_DATA Data,
	    __in PCFLT_RELATED_OBJECTS FltObjects,
	    __in_opt PVOID CompletionContext,
	    __in FLT_POST_OPERATION_FLAGS Flags
	    )
	
	{
	
	    NTSTATUS Status;
	    SIZE_T NumberOfBytes;
	    PSECURITY_DESCRIPTOR SecurityDescriptor;
	
	    if (IoGetTopLevelIrp())
	        return FLT_POSTOP_FINISHED_PROCESSING;
	
	    Status = FltQuerySecurityObject(FltObjects->Instance,
	                                    Data->Iopb->TargetFileObject,
	                                    OWNER_SECURITY_INFORMATION,
	                                    NULL,
	                                    0,
	                                    &NumberOfBytes);
	
	    if (Status != STATUS_BUFFER_TOO_SMALL)
	        return FLT_POSTOP_FINISHED_PROCESSING;
	
	    SecurityDescriptor = (PSECURITY_DESCRIPTOR)ExAllocatePoolWithTag(PagedPool, NumberOfBytes, 'lifj');
	
	    if (!SecurityDescriptor)
	        return FLT_POSTOP_FINISHED_PROCESSING;
	
	    Status = FltQuerySecurityObject(FltObjects->Instance,
	                                    Data->Iopb->TargetFileObject,
	                                    OWNER_SECURITY_INFORMATION,
	                                    SecurityDescriptor,
	                                    NumberOfBytes,
	                                    0);
	
	    if (NT_SUCCESS(Status)) {
	        Status = FltSetSecurityObject(FltObjects->Instance,
	                                    Data->Iopb->TargetFileObject,
	                                    OWNER_SECURITY_INFORMATION,
	                                    SecurityDescriptor);
	
	        if (Status == STATUS_NOT_IMPLEMENTED){
	            DbgPrint("PassThrough!PtPostOperationPassThroughWithBug: Microsoft Bug!!!\n");
	        }
	    }
	    ExFreePoolWithTag(SecurityDescriptor, 0);
	    return FLT_POSTOP_FINISHED_PROCESSING;
	}

### 步骤：

1. 先加载一个正常的minifilter驱动，比如可以用WDK中的例子PassThrough来表示；
2. 加载包含触发bug代码的minifilter驱动；
3. 执行任意的文件IO操作以执行触发BUG的代码；
4. 这时候通过服务管理器卸载正常的驱动时就会导致死锁了。
